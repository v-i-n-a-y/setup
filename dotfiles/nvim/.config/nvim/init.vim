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

set clipboard=unnamedplus
set undofile
set scrolloff=8
set sidescrolloff=8
set splitright
set splitbelow
set inccommand=split

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

highlight LineNr       guifg=#565f89
highlight CursorLineNr guifg=#ff9e64 gui=bold
highlight LineNrAbove  guifg=#bb9af7
highlight LineNrBelow  guifg=#7aa2f7

autocmd BufReadPost *
\ if line("'\"") > 1 && line("'\"") <= line("$") |
\   execute "normal! g`\"" |
\ endif

highlight Normal     guibg=NONE ctermbg=NONE
highlight NonText    guibg=NONE ctermbg=NONE
highlight SignColumn guibg=NONE ctermbg=NONE
