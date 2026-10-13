function Rs --wraps='sudo pacman -Rs' --description 'alias Rs=sudo pacman -Rs'
    sudo pacman -Rs $argv
end
