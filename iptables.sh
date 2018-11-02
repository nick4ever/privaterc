#!/bin/sh

# define external IP
EXTERNAL_IP=172.0.0.1

# define iptables command
IPTABLES=/sbin/iptables
SERVICE=/sbin/service

# define host
HOST=nat

# define interface
LAN=eno1
WAN=ppp0

WAN_INCOMING_PORT_ARR=(22 80)
LAN_INCOMING_PORT_ARR=(22 80)

forward() {
    FROM_INTERFACE=$1
    FROM_PORT=$2
    TO_IP=$3
    TO_PORT=$4
    echo ">>> Forwarding $FROM_INTERFACE:$FROM_PORT to $TO_IP:$TO_PORT..."
    $IPTABLES -t nat -A PREROUTING -i $FROM_INTERFACE -p tcp --dport $FROM_PORT -j DNAT --to $TO_IP:$TO_PORT
}

blockIp() {
    echo ">>> Blocking $1..."
    IF=$1
    TARGET=$2
    $IPTABLES -A INPUT -i $IF -s $TARGET -j DROP    
}

save() {
    $SERVICE iptables save
    $SERVICE iptables restart
}

execFirewallRules() {
    sysctl -w net.ipv4.ip_forward=1
    sysctl -w net.ipv6.conf.all.disable_ipv6=1
    sysctl -w net.ipv6.conf.default.disable_ipv6=1
    sysctl -p

    # Clear all the rules
    $IPTABLES -F
    $IPTABLES -X
    $IPTABLES -Z
    $IPTABLES -t $HOST -F
    $IPTABLES -t $HOST -X
    $IPTABLES -t $HOST -Z
    $IPTABLES -t mangle -F
    $IPTABLES -t mangle -X
    $IPTABLES -t mangle -Z

    ### 
    $IPTABLES -P INPUT DROP
    $IPTABLES -P OUTPUT ACCEPT
    $IPTABLES -P FORWARD ACCEPT

    ## Allow loopback OUTPUT 
    $IPTABLES -A OUTPUT -o lo -j ACCEPT
    $IPTABLES -A OUTPUT -m state --state ESTABLISHED,RELATED -j ACCEPT
    $IPTABLES -A INPUT -i lo -j ACCEPT

    # Accept connection
    $IPTABLES -A INPUT -i $WAN -m state --state ESTABLISHED,RELATED -j ACCEPT
    #$IPTABLES -N WAN-INCOMING-LOG
    #$IPTABLES -A WAN-INCOMING-LOG -j LOG --log-tcp-options --log-ip-options --log-prefix "# WAN INCOMING: "
    #$IPTABLES -A WAN-INCOMING-LOG -j ACCEPT
    #$IPTABLES -A INPUT -i $WAN -m state --state ESTABLISHED,RELATED -j WAN-INCOMING-LOG
    #$IPTABLES -N LAN-INCOMING-LOG
    #$IPTABLES -A LAN-INCOMING-LOG -j LOG --log-tcp-options --log-ip-options --log-prefix "# LAN INCOMING: "
    #$IPTABLES -A LAN-INCOMING-LOG -j ACCEPT
    #$IPTABLES -A INPUT -i $LAN -m state --state ESTABLISHED,RELATED -j LAN-INCOMING-LOG
   

    # DROPspoofing packets
    $IPTABLES -A INPUT -s 10.0.0.0/8 -j DROP 
    $IPTABLES -A INPUT -s 169.254.0.0/16 -j DROP
    $IPTABLES -A INPUT -s 172.16.0.0/12 -j DROP
    $IPTABLES -A INPUT -s 127.0.0.0/8 -j DROP
    #$IPTABLES -A INPUT -s 192.168.0.0/24 -j DROP
    $IPTABLES -A INPUT -s 224.0.0.0/4 -j DROP
    $IPTABLES -A INPUT -d 224.0.0.0/4 -j DROP
    $IPTABLES -A INPUT -s 240.0.0.0/5 -j DROP
    $IPTABLES -A INPUT -d 240.0.0.0/5 -j DROP
    $IPTABLES -A INPUT -s 0.0.0.0/8 -j DROP
    $IPTABLES -A INPUT -d 0.0.0.0/8 -j DROP
    $IPTABLES -A INPUT -d 239.255.255.0/24 -j DROP
    $IPTABLES -A INPUT -d 255.255.255.255 -j DROP

    #for SMURF attack protection
    #$IPTABLES -A INPUT -p icmp -m icmp --icmp-type address-mask-request -j DROP
    #$IPTABLES -A INPUT -p icmp -m icmp --icmp-type timestamp-request -j DROP
    #$IPTABLES -A INPUT -p icmp -m icmp -m limit --limit 1/second -j ACCEPT

    # Droping all invalid packets
    $IPTABLES -A INPUT -m state --state INVALID -j DROP
    $IPTABLES -A FORWARD -m state --state INVALID -j DROP
    $IPTABLES -A OUTPUT -m state --state INVALID -j DROP

    # flooding of RST packets, smurf attack Rejection
    $IPTABLES -A INPUT -p tcp -m tcp --tcp-flags RST RST -m limit --limit 2/second --limit-burst 2 -j ACCEPT

    # Allow ping means ICMP port is open (If you do not want ping replace ACCEPT with REJECT)
    $IPTABLES -A INPUT -p icmp -m icmp --icmp-type 8 -j DROP

    # SYN-Flooding Protection
    $IPTABLES -N syn-flood
    $IPTABLES -A INPUT -i $WAN -p tcp --syn -j syn-flood
    $IPTABLES -A syn-flood -m limit --limit 1/s --limit-burst 4 -j RETURN
    $IPTABLES -A syn-flood -j DROP

    $IPTABLES -A INPUT -p tcp --tcp-flags SYN,FIN SYN,FIN -j DROP 
    $IPTABLES -A INPUT -p tcp --tcp-flags SYN,RST SYN,RST -j DROP 
    $IPTABLES -A INPUT -p tcp --tcp-flags FIN,RST FIN,RST -j DROP 
    $IPTABLES -A INPUT -p tcp --tcp-flags ACK,FIN FIN -j DROP

    # Make sure that new TCP connections are SYN packets
    $IPTABLES -A INPUT -i $WAN -p tcp ! --syn -m state --state NEW -j DROP

    # NAT to internal network 
    $IPTABLES -t nat -A POSTROUTING -o $WAN -j MASQUERADE
    $IPTABLES -A FORWARD -i $LAN -j ACCEPT
    $IPTABLES -A INPUT -i $LAN -j ACCEPT

    # Open TCP port(s)
    echo "*** Opening $WAN tcp port $PORT..."
    for WAN_PORT in ${WAN_INCOMING_PORT_ARR[@]}; do
        echo ">>> Opening port $PORT..."
        $IPTABLES -A INPUT -i $WAN -p tcp --dport $PORT -j ACCEPT
    done
    
    echo "Opening $LAN tcp port $PORT..."
    for LAN_PORT in ${LAN_INCOMING_PORT_ARR[@]}; do
        echo ">>> Opening port $PORT..."
        $IPTABLES -A INPUT -i $LAN -p tcp --dport $PORT -j ACCEPT
    done

    # NAT Reflection
    #echo "NAT Reflection"
    #$IPTABLES -t $HOST -A PREROUTING -d $EXTERNAL_IP/32 -p tcp -m multiport --dports 5678,30800,30810 -j DNAT --to-destination 192.168.10.5
    #$IPTABLES -t $HOST -A POSTROUTING -s 192.168.10.0/24 -d 192.168.10.5/24 -p tcp -m multiport --dports 5678,30800,30810 -j MASQUERADE

    $IPTABLES -A INPUT -j DROP
    #$IPTABLES -N DROPPED 
    #$IPTABLES -A DROPPED -j LOG --log-prefix "DROPPED: "
    #$IPTABLES -A DROPPED -j DROP
    #$IPTABLES -A INPUT -j DROPPED

    save
}

case $1 in
   "block")
      echo "It should be ./iptables.sh block <interface> <ip to block>"
      blockIp $2 $3
      ;;
   "forward")
      echo "It should be ./iptables.sh forward <from interface> <from port> <to ip> <to port>"
      forward $2 $3 $4 $5
      ;;
   "start")
      execFirewallRules
      ;;
   *)
      echo "You better run: sudo sh iptables.sh start"
      ;;
esac
