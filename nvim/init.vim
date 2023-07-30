set number
set relativenumber
set mouse=a
set autoindent
colorscheme slate
set backspace=indent,eol,start
set tabstop=4
set so=25
set splitright
autocmd BufReadPost *
\ if line("'\"") > 1 && line("'\"") <= line("$") |
\   execute "normal! g`\"" |
\ endif

