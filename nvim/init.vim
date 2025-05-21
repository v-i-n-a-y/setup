
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
set ttymouse=sgr
set term=xterm-256color


set spelllang=en_gb


set foldenable
set foldlevelstart=12
set foldnestmax=12
set foldmethod=indent

set encoding=utf-8
set termencoding=utf-8
set colourcolumn=90
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

# Sets vim's background colour to fish's
if exists('$BACKGROUND_COLOR')
    highlight Normal guibg=$BACKGROUND_COLOR
endif

