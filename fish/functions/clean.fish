function clean --wraps='sudo pacman -Sc && sudo yay -Sc' --description 'alias clean=sudo pacman -Sc && sudo yay -Sc'
    sudo pacman -Sc && sudo yay -Sc $argv
end
