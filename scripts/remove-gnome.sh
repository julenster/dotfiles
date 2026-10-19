#!/usr/bin/env bash
# remove-gnome.sh — desinstala GNOME y su rice si ya no lo quieres. Ejecútalo dentro de KDE.
# -u: solo quita lo que ningún otro paquete necesita. gnome-keyring se queda (lo usan VS Code
# y otras apps para guardar contraseñas).
set -euo pipefail
if [[ ${XDG_CURRENT_DESKTOP:-} != *KDE* ]]; then
    echo "Ejecútalo desde una sesión de KDE Plasma, no desde GNOME." >&2
    exit 1
fi
candidates=(gnome-shell gnome-session gnome-control-center nautilus gdm xdg-desktop-portal-gnome
    cachyos-gnome-settings gnome-tweaks extension-manager gnome-shell-extension-appindicator
    gnome-shell-extension-blur-my-shell gnome-shell-extension-just-perfection-desktop
    gnome-shell-extension-rounded-window-corners-reborn morewaita-icon-theme ptyxis)
pkgs=()
for p in "${candidates[@]}"; do
    if pacman -Qq "$p" &>/dev/null; then pkgs+=("$p"); fi
done
((${#pkgs[@]} == 0)) && { echo "GNOME ya no está instalado."; exit 0; }
echo "Se van a desinstalar (más sus dependencias que queden huérfanas):"; printf '%s\n' "${pkgs[@]}" | column
sudo pacman -Rsnu "${pkgs[@]}"
# Extensiones descargadas y arranque automático del rice de GNOME
rm -rf ~/.local/share/gnome-shell/extensions
rm -f ~/.config/autostart/dotfiles-gnome-appearance.desktop ~/.config/autostart/dotfiles-firstrun-gnome.desktop
echo "GNOME eliminado."
