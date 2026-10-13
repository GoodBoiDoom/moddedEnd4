function U --wraps='sudo pacman -Syu' --description 'alias U=sudo pacman -Syu'
    sudo pacman -Syu $argv
end
