# Saludo de la terminal: Miku animada (kitty) al lado de fastfetch, como kovasko/hyprland-dotfiles
function fish_greeting
    set -l gif ~/Pictures/miku/Miku-v2-smooth.gif
    if test "$TERM" = xterm-kitty; and test -f $gif
        kitten icat -n --place 30x30@0x0 --scale-up --align left $gif | fastfetch --logo-width 30 --raw -
    else
        fastfetch --config ~/.config/fastfetch/fallback.jsonc
    end
end

# clear: limpia la pantalla (y las imágenes de kitty) y vuelve a mostrar el saludo
function clear
    command clear $argv
    test "$TERM" = xterm-kitty; and kitten icat --clear 2>/dev/null
    fish_greeting
end
