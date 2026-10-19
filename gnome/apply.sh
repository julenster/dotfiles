#!/usr/bin/env bash
# apply.sh — rice de GNOME: oscuro, transparencias (Blur my Shell), dock flotante, color de
# acento que sigue al fondo de pantalla, iconos MoreWaita y terminal kitty con Miku animada.
# Mantiene el flujo de GNOME (tecla Super = Actividades con búsqueda).
# Debe ejecutarse dentro de una sesión de GNOME. Idempotente: puedes ejecutarlo cuando quieras.
set -uo pipefail
DOTFILES="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"

# Extensiones del rice. Solo extensiones bien mantenidas y compatibles con la versión actual
# de GNOME (ver scripts/check-extensions.sh para las que están pendientes).
EXTENSIONS=(
    blur-my-shell@aunetx                                          # transparencias/blur
    just-perfection-desktop@just-perfection                       # animaciones rápidas
    appindicatorsupport@rgcjonas.gmail.com                        # iconos de bandeja
    rounded-window-corners@fxgn                                   # esquinas redondeadas
    dash-to-dock@micxgx.gmail.com                                 # dock flotante
    auto-accent-colour@Wartybix                                   # acento según el fondo
    accent-directories@taiwbi.com                                 # carpetas del color de acento
    workspace-indicator@gnome-shell-extensions.gcampax.github.com # escritorios en la barra
    system-monitor@gnome-shell-extensions.gcampax.github.com      # CPU/RAM en la barra
)
# Las que no están empaquetadas en los repos/AUR se bajan de extensions.gnome.org
# (y GNOME las actualiza solo)
EGO_EXTENSIONS=(
    dash-to-dock@micxgx.gmail.com
    auto-accent-colour@Wartybix
    accent-directories@taiwbi.com
    workspace-indicator@gnome-shell-extensions.gcampax.github.com
    system-monitor@gnome-shell-extensions.gcampax.github.com
)

# Apps del dock, en orden (las que no estén instaladas se ignoran)
DOCK_APPS=(
    firefox.desktop
    org.gnome.Nautilus.desktop
    kitty.desktop
    com.microsoft.VSCode.desktop
    jetbrains-rider.desktop
    steam.desktop
    vesktop.desktop
    tidal-hifi.desktop
    org.gnome.Settings.desktop
)

# gs <schema> <clave> <valor> — solo aplica si la clave existe (no falla si falta algo)
gs() {
    if gsettings writable "$1" "$2" &>/dev/null; then
        gsettings set "$1" "$2" "$3"
    else
        echo "  (omitido: $1 $2)"
    fi
}
ext_dir() {
    local d
    for d in ~/.local/share/gnome-shell/extensions/"$1" /usr/share/gnome-shell/extensions/"$1"; do
        [[ -d $d ]] && { echo "$d"; return; }
    done
}
# ext <uuid> <schema> <clave> <valor> — ajustes de una extensión, aunque su esquema
# no esté compilado a nivel de sistema
ext() {
    local dir
    dir="$(ext_dir "$1")/schemas"
    if gsettings writable "$2" "$3" &>/dev/null; then
        gsettings set "$2" "$3" "$4"
    elif [[ -d $dir ]]; then
        gsettings --schemadir "$dir" set "$2" "$3" "$4" 2>/dev/null || echo "  (omitido: $2 $3)"
    fi
}
install_ego() {
    [[ -n $(ext_dir "$1") ]] && return
    local v tmp
    v=$(gnome-shell --version | grep -oE '[0-9]+' | head -1)
    tmp=$(mktemp --suffix=.zip)
    if curl -fsSL -o "$tmp" "https://extensions.gnome.org/download-extension/$1.shell-extension.zip?shell_version=$v"; then
        gnome-extensions install --force "$tmp" && echo "  instalada: $1"
    else
        echo "  (no disponible para GNOME $v: $1)"
    fi
    rm -f "$tmp"
}
# keybinding <id> <nombre> <comando> <atajo> — atajo de teclado personalizado
keybinding() {
    local path=/org/gnome/settings-daemon/plugins/media-keys/custom-keybindings/$1/
    local schema=org.gnome.settings-daemon.plugins.media-keys
    local list
    list=$(gsettings get $schema custom-keybindings)
    if [[ $list != *"'$path'"* ]]; then
        if [[ $list == "@as []" || $list == "[]" ]]; then list="['$path']"; else list="${list%]}, '$path']"; fi
        gsettings set $schema custom-keybindings "$list"
    fi
    gsettings set "$schema.custom-keybinding:$path" name "$2"
    gsettings set "$schema.custom-keybinding:$path" command "$3"
    gsettings set "$schema.custom-keybinding:$path" binding "$4"
}

# --- Apariencia general (tema, iconos, cursor, fuentes) ---
# Va aparte porque KDE la sobrescribe al usarlo: se vuelve a aplicar al entrar en GNOME.
"$DOTFILES/gnome/appearance.sh"
mkdir -p ~/.config/autostart
sed "s|@DOTFILES@|$DOTFILES|" "$DOTFILES/gnome/dotfiles-appearance.desktop" \
    > ~/.config/autostart/dotfiles-gnome-appearance.desktop

# Flatpaks con el mismo tema
flatpak override --user --env=GTK_THEME=adw-gtk3-dark --filesystem=xdg-config/gtk-3.0:ro 2>/dev/null || true

# --- Extensiones ---
for uuid in "${EGO_EXTENSIONS[@]}"; do install_ego "$uuid"; done
current=$(gsettings get org.gnome.shell enabled-extensions)
for uuid in "${EXTENSIONS[@]}"; do
    [[ -n $(ext_dir "$uuid") ]] || { echo "  (no instalada: $uuid)"; continue; }
    [[ $current == *"'$uuid'"* ]] && continue
    if [[ $current == "@as []" || $current == "[]" ]]; then
        current="['$uuid']"
    else
        current="${current%]}, '$uuid']"
    fi
done
gsettings set org.gnome.shell enabled-extensions "$current"
gsettings set org.gnome.shell disable-user-extensions false

# Blur my Shell: desenfoque en barra, Actividades, carpetas, dock y pantalla de bloqueo.
# De las ventanas solo se desenfoca kitty (desenfocar todas es lo que más GPU gasta).
# En juegos a pantalla completa no afecta.
B=org.gnome.shell.extensions.blur-my-shell
ext blur-my-shell@aunetx $B hacks-level 1
ext blur-my-shell@aunetx $B.panel blur true
ext blur-my-shell@aunetx $B.panel static-blur true
ext blur-my-shell@aunetx $B.overview blur true
ext blur-my-shell@aunetx $B.appfolder blur true
ext blur-my-shell@aunetx $B.lockscreen blur true
ext blur-my-shell@aunetx $B.dash-to-dock blur true
ext blur-my-shell@aunetx $B.applications blur true
ext blur-my-shell@aunetx $B.applications enable-all false
ext blur-my-shell@aunetx $B.applications whitelist "['kitty']"
ext blur-my-shell@aunetx $B.applications unblur-when-fullscreen true

# Just Perfection: animaciones más rápidas y arrancar en el escritorio
J=org.gnome.shell.extensions.just-perfection
ext just-perfection-desktop@just-perfection $J animation 3
ext just-perfection-desktop@just-perfection $J startup-status 0

# Dash to Dock: dock flotante translúcido abajo, se esconde cuando una ventana lo tapa.
# Al pulsar Super sigue apareciendo con todo lo abierto, como en GNOME normal.
D=org.gnome.shell.extensions.dash-to-dock
ext dash-to-dock@micxgx.gmail.com $D dock-position BOTTOM
ext dash-to-dock@micxgx.gmail.com $D dash-max-icon-size 42
ext dash-to-dock@micxgx.gmail.com $D extend-height false
ext dash-to-dock@micxgx.gmail.com $D dock-fixed false
ext dash-to-dock@micxgx.gmail.com $D intellihide true
ext dash-to-dock@micxgx.gmail.com $D intellihide-mode FOCUS_APPLICATION_WINDOWS
ext dash-to-dock@micxgx.gmail.com $D apply-custom-theme false
ext dash-to-dock@micxgx.gmail.com $D custom-theme-shrink true
ext dash-to-dock@micxgx.gmail.com $D custom-background-color true
ext dash-to-dock@micxgx.gmail.com $D background-color "#0b1416"
ext dash-to-dock@micxgx.gmail.com $D transparency-mode FIXED
ext dash-to-dock@micxgx.gmail.com $D background-opacity 0.35
ext dash-to-dock@micxgx.gmail.com $D running-indicator-style DOTS
ext dash-to-dock@micxgx.gmail.com $D show-trash false
ext dash-to-dock@micxgx.gmail.com $D show-mounts false
ext dash-to-dock@micxgx.gmail.com $D click-action minimize-or-previews
ext dash-to-dock@micxgx.gmail.com $D disable-overview-on-startup true

# Accent Icons: colorear solo carpetas (los iconos de apps se quedan como son)
ext accent-directories@taiwbi.com org.gnome.shell.extensions.accent-directories change-app-colors false

# --- Dock ---
dock="["
for app in "${DOCK_APPS[@]}"; do
    for dir in /usr/share/applications ~/.local/share/applications /var/lib/flatpak/exports/share/applications; do
        if [[ -f $dir/$app ]]; then dock+="'$app', "; break; fi
    done
done
dock="${dock%, }]"
gs org.gnome.shell favorite-apps "$dock"

# --- Fondos de pantalla ---
mkdir -p ~/Pictures/wallpapers ~/.local/bin
ln -sfn "$DOTFILES/scripts/wallpaper-picker" ~/.local/bin/wallpaper-picker
keybinding wallpaper "Elegir fondo de pantalla" "$HOME/.local/bin/wallpaper-picker" "<Super>w"

# --- Terminal: kitty + Miku animada + fastfetch, cava (compartido con KDE) ---
"$DOTFILES/scripts/link-terminal.sh"

# kitty en Ctrl+Alt+T
keybinding kitty "Terminal (kitty)" kitty "<Control><Alt>t"

echo "Rice aplicado. Si se ha instalado alguna extensión nueva, cierra sesión y vuelve a entrar."
