" set no compatible
set nocompatible

" Get in insert mode
startinsert

" Show line number
set number

" Show command in bottom bar 
set showcmd 
   
" Enable syntax processing
syntax enable 

" Turn on the WiLd menu
set wildmenu

" Ignore compiled files
set wildignore=*.o,*~,*.pyc

"Always show current position
set ruler

" A buffer becomes hidden when it is abandoned
set hid

" Configure backspace so it acts as it should act
set backspace=eol,start,indent
set whichwrap+=<,>,h,l

" Ignore case when searching
set ignorecase

" When searching try to be smart about cases 
set smartcase

" Highlight search results
set hlsearch

" Makes search act like search in modern browsers
set incsearch

" Don't redraw while executing macros (good performance config)
set lazyredraw

" For regular expressions turn magic on
set magic

" Show matching brackets when text indicator is over them
set showmatch
" How many tenths of a second to blink when matching brackets
set mat=2

" No annoying sound on errors
set noerrorbells
set novisualbell
set t_vb=
set tm=500

"""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""
" => Colors and Fonts
"""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""
" Enable syntax highlighting
syntax enable

colorscheme default
set background=dark

" Set extra options when running in GUI mode
if has("gui_running")
    set guioptions-=T
    set guioptions+=e
    set t_Co=256
    set guitablabel=%M\ %t
endif

" Set utf8 as standard encoding and en_US as the standard language
set encoding=utf8

" Use Unix as the standard file type
set ffs=unix,dos,mac


"""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""
" Text, tab and indent related
"""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""
" Use spaces instead of tabs
set expandtab

" Be smart when using tabs ;)
set smarttab

" 1 tab == 4 spaces
set shiftwidth=4
set tabstop=4

" Linebreak on 500 characters
set lbr
set tw=500

set ai "Auto indent
set si "Smart indent
set wrap "Wrap lines

"""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""
" Key binding
"""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""
" Ctrl-h to find and replace
inoremap <c-h> <esc>:%s@$@$@gc
map <c-h> :%s@$@$@gc

" Ctrl-c to copy line
inoremap <c-c> <esc>yyi
map <c-c> yyi

" Ctrl-v to paste
inoremap <c-v> <esc>p<esc><esc>:set nopaste<CR><esc>i
map <c-v> p<esc><esc>:set nopaste<CR><esc>i

" Ctrl-w to save file
inoremap <c-w> <esc>:w<CR>i
map <c-w> :w<CR>i

" Ctrl-e to exit 
inoremap <c-e> <esc>:q<CR>
map <c-e> :q<CR>

" Ctrl-d to delete line
inoremap <c-d> <esc>ddi
map <c-d> ddi

" Ctrl-z to undo
inoremap <c-z> <esc>ui
map <c-z> ui

" Ctrl-b to select block
inoremap <c-b> <esc>v
map <c-b> v

" Ctrl-g to go to line
inoremap <c-g> <esc>:
map <c-g> :

" Ctrl-f to find
inoremap <c-f> <esc>:/
map <c-f> :/

" F1 to set paste
inoremap <F1> <esc>:set paste<CR><esc>i
map <F1> :set paste<CR><esc>i

" F2 to set no paste
inoremap <F2> <esc>:set nopaste<CR><esc>i
map <F2> :set nopaste<CR><esc>i
