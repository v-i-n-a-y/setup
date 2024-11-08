# Sets nvim as vim...lazy
function vim --wraps=nvim --description 'alias vim=nvim'
  nvim $argv
end
