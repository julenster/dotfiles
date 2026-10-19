#!/usr/bin/env bash
# appearance.sh — tema, iconos, cursor y fuentes de GNOME. Lo usa gnome/apply.sh y se ejecuta
# también cada vez que entras en GNOME, porque KDE cambia estos mismos ajustes al usarlo.
set -uo pipefail

gs() {
    if gsettings writable "$1" "$2" &>/dev/null; then
        gsettings set "$1" "$2" "$3"
    fi
}

# El color de acento lo pone Auto Accent Colour a partir del fondo de pantalla, y
# Accent Icons cambia el tema de iconos (MoreWaita) al color de acento.
gs org.gnome.desktop.interface color-scheme prefer-dark
gs org.gnome.desktop.interface gtk-theme adw-gtk3-dark      # apps GTK3 iguales que las GTK4
gs org.gnome.desktop.interface icon-theme MoreWaita
gs org.gnome.desktop.interface cursor-theme Bibata-Modern-Classic
gs org.gnome.desktop.interface font-name "Inter 11"
gs org.gnome.desktop.interface document-font-name "Inter 11"
gs org.gnome.desktop.interface monospace-font-name "JetBrainsMono Nerd Font 11"
gs org.gnome.desktop.interface font-antialiasing rgba
gs org.gnome.desktop.interface clock-show-weekday true
gs org.gnome.desktop.interface show-battery-percentage true
gs org.gnome.desktop.wm.preferences titlebar-font "Inter Bold 11"
gs org.gnome.desktop.wm.preferences button-layout "appmenu:minimize,maximize,close"
