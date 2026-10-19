# config.fish — gestionado desde ~/dotfiles (fish/config.fish)

# Configuración base de CachyOS: alias, colores, etc.
if test -f /usr/share/cachyos-fish-config/cachyos-config.fish
    source /usr/share/cachyos-fish-config/cachyos-config.fish
end

source (path dirname (path resolve (status filename)))/miku.fish

