"
" Native config
"
" --tes
" Preventing netrw to load, for nvim-tree
let g:loaded_netrw       = 1
let g:loaded_netrwPlugin = 1

" Text
set encoding=utf-8
set expandtab             " Insert spaces for a <tab>.
set tabstop=4             " Tab size
set softtabstop=4         " When editing, must be consistent with previous
set shiftwidth=4          " Indentation for < and > commands

" Inputs
set mouse=a               " Enable mouse in all modes
nnoremap <C-e> 3<C-e>
nnoremap <C-y> 3<C-y>
set mousemoveevent
set clipboard=unnamedplus  " Yank and paste from system clipboard
let mapleader=" "
let maplocalleader=" "

set updatetime=300        " Delay before writing to disk
set noswapfile
set noshowmode            " Don't show Insert/Replace/Visual
set autowrite
set autowriteall
set hidden                " Buffer management?

" Visuals
set scrolloff=8           " Minimum #lines on top/bottom when scrolling
set splitbelow
set splitright
set signcolumn=yes        " When to draw the sign column
syntax on
set number relativenumber
autocmd TermOpen * setlocal nonumber norelativenumber

" Toggle invisible characters
set list
set listchars=tab:→\ ,trail:~,extends:❯,precedes:❮
set showbreak=↪

" True colors
set termguicolors
colorscheme tokyonight-moon

" Search
set ignorecase            " Search is case insensitive 
set smartcase             " ... unless the query has capital letters

" Save undo / redo across sessions
set sessionoptions+=globals
set undofile
set undodir=~/.vim/undo

"
" File type specific
"

" 2 space width
autocmd filetype nix,lua,typescript,graphql,javascript,json,fish setlocal tabstop=2 shiftwidth=2 softtabstop=2
" Disable LSP diagnostic for .env files
autocmd BufRead,BufNewFile .env lua vim.diagnostic.disable()
" Define Tinybird data files as SQL
au BufRead,BufNewFile *.pipe,*.datasource setfiletype sql

" Sudo tee hack, write as root
cmap w!! w !sudo tee > /dev/null %

noremap ; :
noremap : ;


