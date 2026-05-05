set nocompatible

if $SHELL =~ "fish"
    set shell=/bin/sh
endif

set tabstop=4
set softtabstop=4
set shiftwidth=4
set expandtab
set smarttab
set autoindent

set backspace=indent,eol,start
set mouse=a

set spelllang=en_gb

set foldenable
set foldlevelstart=12
set foldnestmax=12
set foldmethod=indent

set encoding=utf-8
set colorcolumn=90
set wildmenu
set title
set showcmd
set noshowmode

set hlsearch
set incsearch
set showmatch
set smartcase
set ignorecase

syntax enable

set number
set relativenumber

autocmd BufReadPost *
\ if line("'\"") > 1 && line("'\"") <= line("$") |
\   execute "normal! g`\"" |
\ endif

" Let the terminal background show through so vim matches the terminal theme.
highlight Normal     guibg=NONE ctermbg=NONE
highlight NonText    guibg=NONE ctermbg=NONE
highlight LineNr     guibg=NONE ctermbg=NONE
highlight SignColumn guibg=NONE ctermbg=NONE
