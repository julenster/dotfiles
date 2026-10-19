#!/usr/bin/env bash
# link-terminal.sh — kitty + Miku animada + fastfetch y cava, enlazados al repo (symlinks).
# Lo usan kde/apply.sh y gnome/apply.sh. Idempotente.
set -euo pipefail
DOTFILES="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"

mkdir -p ~/.config/{kitty,fastfetch,cava,fish/conf.d} ~/Pictures/miku
ln -sfn "$DOTFILES/kitty/kitty.conf" ~/.config/kitty/kitty.conf
ln -sfn "$DOTFILES/fastfetch/config.jsonc" ~/.config/fastfetch/config.jsonc
ln -sfn "$DOTFILES/fastfetch/fallback.jsonc" ~/.config/fastfetch/fallback.jsonc
ln -sfn "$DOTFILES/cava/config" ~/.config/cava/config
# config.fish carga lo de CachyOS y después lo de Miku (guarda copia del que hubiera)
if [[ -f ~/.config/fish/config.fish && ! -L ~/.config/fish/config.fish ]]; then
    mv ~/.config/fish/config.fish ~/.config/fish/config.fish.bak
fi
ln -sfn "$DOTFILES/fish/config.fish" ~/.config/fish/config.fish
rm -f ~/.config/fish/conf.d/miku.fish   # versiones anteriores lo enlazaban aquí
[[ -f ~/Pictures/miku/Miku-v2.gif ]] || curl -fsSL -o ~/Pictures/miku/Miku-v2.gif \
    https://raw.githubusercontent.com/kovasko/hyprland-dotfiles/main/fastfetch/GIF/Miku-v2.gif

# kitty como terminal por defecto (xdg-terminal-exec)
echo kitty.desktop > ~/.config/xdg-terminals.list
