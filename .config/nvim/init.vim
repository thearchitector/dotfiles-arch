""
"" Plugins (using vim-plug)
""

call plug#begin('~/.local/share/nvim/plugins')
Plug 'mhinz/vim-startify'
Plug 'itchyny/lightline.vim'
Plug 'ajmwagar/vim-deus'
call plug#end()


""
"" Configuration Options
""

syntax on
set number
set tabstop=2 softtabstop=0 expandtab shiftwidth=2 smarttab
set encoding=utf8
set backspace=indent,eol,start
set noshowmode
set t_Co=256
set termguicolors

let &t_8f = "\<Esc>[38;2%lu;%lu;%lum"
let &t_8b = "\<Esc>[48;2%lu;%lu;%lum"

set background=dark
let g:lightline = { 'colorscheme': 'deus' }
colorscheme deus
let g:deus_termcolors=256
