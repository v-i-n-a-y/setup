# I really like vim matching my terminal colour
function get_bg_color
    set -l bg_color (tput setab 0)
    echo $bg_color
end

