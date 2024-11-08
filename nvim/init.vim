
set number
set relativenumber
set mouse=a
set autoindent
set backspace=indent,eol,start
set tabstop=2
set so=25
set splitright
autocmd BufReadPost *
\ if line("'\"") > 1 && line("'\"") <= line("$") |
\   execute "normal! g`\"" |
\ endif

# Sets vim's background colour to fish's
if exists('$BACKGROUND_COLOR')
    highlight Normal guibg=$BACKGROUND_COLOR
endif

