function Rns --wraps='sudo pacman -Rns' --description 'alias Rns=sudo pacman -Rns'
    sudo pacman -Rns $argv
end
