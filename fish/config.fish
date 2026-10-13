# Commands to run in interactive sessions can go here
if status is-interactive
    # No greeting
    set fish_greeting

    neofetch
    #fortune | cowsay -r
    #neofetch | cowsay -r
    # Use starship
    function starship_transient_prompt_func
        starship module character
    end
    if test "$TERM" != "linux"
        starship init fish | source
        enable_transience
    end
    
    # Colors
    if test -f ~/.local/state/quickshell/user/generated/terminal/sequences.txt
        cat ~/.local/state/quickshell/user/generated/terminal/sequences.txt
    end

    # Aliases
    # kitty doesn't clear properly so we need to do this weird printing
    alias clear "printf '\033[2J\033[3J\033[1;1H'"
    alias celar "printf '\033[2J\033[3J\033[1;1H'"
    alias claer "printf '\033[2J\033[3J\033[1;1H'"
    alias pamcan pacman
    alias q 'qs -c ii'
    if test "$TERM" != "linux"
        alias ls 'eza --icons'
    end
    if test "$TERM" = "xterm-kitty"
        alias ssh 'kitten ssh'
    end
    if set -q KITTY_PID
    	neofetch
    end
end

fish_add_path /home/om/.spicetify

# QML modules (CavaMonitor cava plugin)
set -gx QML2_IMPORT_PATH "$HOME/.local/lib/qt6/qml"
