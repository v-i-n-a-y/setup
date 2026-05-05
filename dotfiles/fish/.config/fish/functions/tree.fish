function tree --wraps=tree --description 'tree, ignoring __pycache__'
    command tree -I '*pycache*' $argv
end
