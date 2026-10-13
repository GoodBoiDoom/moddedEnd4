function I --wraps='sudo pacman -S' --description 'alias I=sudo pacman -S'
    sudo pacman -S $argv
end
