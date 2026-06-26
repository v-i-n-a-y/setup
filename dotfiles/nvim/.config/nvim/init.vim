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

" --- Quality-of-life (none of these are nvim defaults) ---
set clipboard=unnamedplus   " yank/put through the system clipboard (ties into tmux yank)
set undofile                " persist undo history across sessions
set scrolloff=8             " keep context lines above/below the cursor
set sidescrolloff=8
set splitright              " new splits open to the right / below (matches tmux | and -)
set splitbelow
set inccommand=split        " live preview of :s/// substitutions

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
