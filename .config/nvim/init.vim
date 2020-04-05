

""
"" Plugins (using vim-plug)
""

call plug#begin('~/.local/share/nvim/plugins')
Plug 'mhinz/vim-startify'
Plug 'itchyny/lightline.vim'
Plug 'drewtempelmeyer/palenight.vim'
call plug#end()


""
"" Configuration Options
""


" generics
syntax on
set number
set showmatch
set tabstop=2 softtabstop=0 expandtab shiftwidth=2 smarttab nojoinspaces
set encoding=utf8
set backspace=indent,eol,start
set noshowmode
set splitbelow
set splitright
set formatoptions+=o

" colorstuffs
set background=dark
colorscheme palenight
let g:lightline = { 'colorscheme': 'palenight' }
set termguicolors
let g:palenight_terminal_italics=1
