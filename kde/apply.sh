#!/usr/bin/env bash
# apply.sh — rice de KDE con lo que trae Plasma, sin shells aparte (Caelestia se quitó porque
# bajaba el rendimiento en juegos): barra superior + dock con paneles de Plasma, Darkly, Papirus,
# Inter, Super = vista general como en GNOME, Super+A rejilla de apps, kitty con Miku, atajos
# libres para jugar y el touchpad.
# Debe ejecutarse dentro de una sesión de Plasma. Idempotente: puedes ejecutarlo cuando quieras.
#
#   kde/apply.sh            # aplica el rice (los paneles solo la primera vez o si cambian)
#   kde/apply.sh --panels   # además rehace los paneles aunque ya estén puestos
#   kde/apply.sh --wallpaper  # vuelve a poner el fondo del repo
set -uo pipefail
DOTFILES="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"

# Súbelo cuando cambies kde/layout.js para que se vuelva a aplicar en todos los equipos
LAYOUT_VERSION=3
LAYOUT_STAMP=~/.config/dotfiles-kde-layout
# Apps del dock en un equipo nuevo (las que no estén instaladas se saltan). Si ya hay un dock,
# layout.js conserva sus apps
DOCK_APPS=(
    firefox.desktop
    org.kde.dolphin.desktop
    com.microsoft.VSCode.desktop
    blender.desktop
    org.gnome.Resources.desktop
)
# Fondo de escritorio y de la pantalla de bloqueo (solo la primera vez o con --wallpaper, para
# no quitarte el que hayas puesto después)
WALLPAPER="$DOTFILES/wallpapers/wallhaven-yq8yex.png"
WALLPAPER_STAMP=~/.config/dotfiles-kde-wallpaper

if [[ ${XDG_CURRENT_DESKTOP:-} != *KDE* ]]; then
    echo "Ejecútalo dentro de una sesión de KDE Plasma." >&2
    exit 1
fi

kw() { kwriteconfig6 --file "$@"; }
installed_app() {
    local dir
    for dir in /usr/share/applications ~/.local/share/applications \
        /var/lib/flatpak/exports/share/applications ~/.local/share/flatpak/exports/share/applications; do
        [[ -f $dir/$1 ]] && return 0
    done
    return 1
}
# keycode "Ctrl+Alt+T" -> número que usa Qt para ese atajo
keycode() {
    # "Super" sola es la tecla Meta (Qt::Key_Meta), no el modificador
    [[ $1 == Meta ]] && { echo $((0x01000022)); return; }
    local code=0 part c parts
    IFS=+ read -ra parts <<<"$1"
    for part in "${parts[@]}"; do
        case $part in
            Shift) ((code |= 0x02000000)) ;;
            Ctrl) ((code |= 0x04000000)) ;;
            Alt) ((code |= 0x08000000)) ;;
            Meta) ((code |= 0x10000000)) ;;
            Space) ((code |= 0x20)) ;;
            Tab) ((code |= 0x01000001)) ;;
            ?) printf -v c '%d' "'${part^^}"; ((code |= c)) ;;
            *) echo "  (tecla desconocida: $part)" >&2; return 1 ;;
        esac
    done
    echo "$code"
}
# shortcut <componente> <nombre del componente> <acción> <nombre de la acción> [atajo…]
# Atajo global (sin atajos = desactivado). Se aplica al momento a través de kglobalaccel, que
# además lo guarda en kglobalshortcutsrc. Para lanzar una app, el componente es su archivo
# .desktop y la acción "_launch".
shortcut() {
    local id="['$1','$3','$2','$4']" keys=() k ai="@ai []"
    for k in "${@:5}"; do keys+=("$(keycode "$k")") || return; done
    ((${#keys[@]})) && ai="[$(IFS=,; echo "${keys[*]}")]"
    gdbus call --session --dest org.kde.kglobalaccel --object-path /kglobalaccel \
        --method org.kde.KGlobalAccel.doRegister "$id" >/dev/null
    # 6 = guardar como atajo actual sin cargar el que hubiera guardado
    gdbus call --session --dest org.kde.kglobalaccel --object-path /kglobalaccel \
        --method org.kde.KGlobalAccel.setShortcut "$id" "$ai" 6 >/dev/null \
        || echo "  (no se pudo cambiar el atajo: $1 $3)"
}

# --- Restos de versiones anteriores del repo (Caelestia, Better Blur DX) ---
kw kwinrc --group ModifierOnlyShortcuts --key Meta --delete
rm -f ~/.local/share/applications/wallpaper-picker.desktop
for c in wallpaper-picker.desktop caelestia-shell; do
    gdbus call --session --dest org.kde.kglobalaccel --object-path /kglobalaccel \
        --method org.kde.KGlobalAccel.unregister "$c" _launch >/dev/null 2>&1 || true
done
kw kwinrc --group Plugins --key better_blur_dxEnabled --delete
kw kwinrc --group Plugins --key quickshell-kde-bridgeEnabled --delete
# Reglas de ventanas transparentes al 80 % (se quitan de la lista y se borran sus grupos)
rules=$(kreadconfig6 --file kwinrulesrc --group General --key rules)
if [[ ,$rules, == *,dotfiles-opaque,* || ,$rules, == *,caelestia-opacity,* ]]; then
    rules=$(tr ',' '\n' <<<"$rules" | grep -vxE 'dotfiles-opaque|caelestia-opacity' | paste -sd,)
    kw kwinrulesrc --group General --key rules "$rules"
    kw kwinrulesrc --group General --key count "$(tr ',' '\n' <<<"$rules" | grep -c .)"
    sed -i '/^\[dotfiles-opaque\]$/,/^\[/{/^\[dotfiles-opaque\]$/d;/^[^[]/d}; /^\[caelestia-opacity\]$/,/^\[/{/^\[caelestia-opacity\]$/d;/^[^[]/d}' \
        ~/.config/kwinrulesrc
fi

# --- Apariencia ---
echo "Apariencia"
kw kdeglobals --group KDE --key widgetStyle Darkly
kw kwinrc --group org.kde.kdecoration2 --key library org.kde.darkly
kw kwinrc --group org.kde.kdecoration2 --key theme Darkly
kw kwinrc --group org.kde.kdecoration2 --key BorderSize None
kw kwinrc --group org.kde.kdecoration2 --key BorderSizeAuto false
# Botones de las ventanas: menú, fijar, sombrear y "en todos los escritorios" a la izquierda;
# ayuda, minimizar, maximizar y cerrar a la derecha
kw kwinrc --group org.kde.kdecoration2 --key ButtonsOnLeft MFSE
kw kwinrc --group org.kde.kdecoration2 --key ButtonsOnRight HIAX
# Animaciones el doble de rápidas y minimizar con la "lámpara mágica"
kw kdeglobals --group KDE --key AnimationDurationFactor 0.5
kw kwinrc --group Plugins --key magiclampEnabled true
kw kwinrc --group Plugins --key squashEnabled false
# Sin avisos en pantalla al cambiar volumen/brillo
kw kdeglobals --group KDE --key OSDEnabled false
kw powerdevilrc --group BrightnessControl --key showOSD false
plasma-apply-colorscheme BreezeDark >/dev/null 2>&1 || true
# Color de acento sacado del fondo de escritorio
kw kdeglobals --group General --key accentColorFromWallpaper true
FONT="Inter,10,-1,5,400,0,0,0,0,0,0,0,0,0,0,1"
kw kdeglobals --group General --key font "$FONT"
kw kdeglobals --group General --key menuFont "$FONT"
kw kdeglobals --group General --key toolBarFont "$FONT"
kw kdeglobals --group General --key smallestReadableFont "Inter,8,-1,5,400,0,0,0,0,0,0,0,0,0,0,1"
kw kdeglobals --group General --key fixed "JetBrainsMono Nerd Font,10,-1,5,400,0,0,0,0,0,0,0,0,0,0,1"
kw kdeglobals --group WM --key activeFont "Inter,10,-1,5,700,0,0,0,0,0,0,0,0,0,0,1"
/usr/lib/plasma-changeicons Papirus-Dark >/dev/null 2>&1 || echo "  (falta papirus-icon-theme)"
plasma-apply-cursortheme --size 24 Bibata-Modern-Classic >/dev/null 2>&1 || true
# Desenfoque normal de KWin (solo donde la app lo pide: paneles, menús, kitty). Forzarlo en
# todas las ventanas, como hacía Better Blur DX, gasta GPU también mientras se juega
kw kwinrc --group Plugins --key blurEnabled true

# --- Atajos ---
echo "Atajos"
# Libres para juegos: nada en Alt+tecla (Alt+Espacio abría KRunner al agacharse y saltar)
shortcut org.kde.krunner.desktop KRunner _launch KRunner
shortcut org.kde.krunner.desktop KRunner RunClipboard "Run command on clipboard contents"
shortcut kwin KWin "Window Operations Menu" "Window Menu"
shortcut kwin KWin "Walk Through Windows of Current Application" \
    "Walk Through Windows of Current Application" "Meta+\`"
shortcut kwin KWin "Walk Through Windows of Current Application (Reverse)" \
    "Walk Through Windows of Current Application (Reverse)" "Meta+~"
shortcut kwin KWin "Walk Through Windows" "Walk Through Windows" "Alt+Tab"
shortcut kwin KWin "Walk Through Windows (Reverse)" "Walk Through Windows (Reverse)" "Alt+Shift+Tab"
# Super sola = vista general de KWin (ventanas + escritorios + búsqueda), como Actividades de
# GNOME. Super+A = rejilla de apps (el atajo lo pone layout.js en su botón del dock)
shortcut plasmashell Plasma "activate application launcher" "Activate Application Launcher"
shortcut kwin KWin Overview "Toggle Overview" Meta "Meta+W"
shortcut ActivityManager "Activity Manager" "manage activities" "Show Activity Switcher"
# Super+1…9 = ir al escritorio N (Plasma los usa por defecto para abrir apps del dock)
for i in {1..9}; do
    shortcut plasmashell Plasma "activate task manager entry $i" "Activate Task Manager Entry $i"
    shortcut kwin KWin "Switch to Desktop $i" "Switch to Desktop $i" "Meta+$i"
done
# Terminal: kitty con Miku en Ctrl+Alt+T
shortcut org.kde.konsole.desktop Konsole _launch Konsole
shortcut kitty.desktop kitty _launch kitty "Ctrl+Alt+T"
kw kdeglobals --group General --key TerminalApplication kitty
kw kdeglobals --group General --key TerminalService kitty.desktop

# --- Vista general (Super) y su buscador ---
# Sin las ventanas minimizadas: menos miniaturas que dibujar al abrirla
kw kwinrc --group Effect-overview --key IgnoreMinimized true
# Al escribir en la vista general (o en KRunner) salen primero las apps y los ajustes, como
# en GNOME, y no se buscan cosas que solo meten ruido
kw krunnerrc --group Plugins --group Favorites --key plugins "krunner_services,krunner_systemsettings"
# krunner_appstream (buscar en Discover) va fuera también por estabilidad: con KWin 6.8 corrompe
# la memoria al escribir en la vista general y tumba kwin_wayland (2026-10-17 y 2026-10-18)
for p in krunner_webshortcuts krunner_bookmarksrunner krunner_recentdocuments krunner_spellcheck \
    krunner_dictionary krunner_charrunner krunner_katesessions krunner_konsoleprofiles \
    krunner_appstream; do
    kw krunnerrc --group Plugins --key "${p}Enabled" false
done

# --- Escritorios: al menos 4 ---
kw kwinrc --group Plugins --key dynamic_workspacesEnabled false
n=$(kreadconfig6 --file kwinrc --group Desktops --key Number)
if ((${n:-1} < 4)); then
    for ((i = ${n:-1}; i < 4; i++)); do
        qdbus6 org.kde.KWin /VirtualDesktopManager org.kde.KWin.VirtualDesktopManager.createDesktop \
            "$i" "Desktop $((i + 1))" >/dev/null 2>&1 || true
    done
fi

# --- Touchpad (portátil): tocar para hacer clic, como en GNOME ---
while IFS=: read -r vendor product name; do
    kw kcminputrc --group Libinput --group "$((16#$vendor))" --group "$((16#$product))" --group "$name" \
        --key TapToClick true
done < <(awk '/^I:/ {split($3, v, "="); split($4, p, "=")}
    /^N: Name=/ && tolower($0) ~ /touchpad/ {sub(/^N: Name="/, ""); sub(/"$/, ""); print v[2] ":" p[2] ":" $0}' \
    /proc/bus/input/devices)

# --- Terminal: kitty + Miku animada + fastfetch, cava (compartido con GNOME) ---
echo "Terminal (kitty con Miku)"
"$DOTFILES/scripts/link-terminal.sh"

# --- Paneles: barra superior + dock ---
if [[ " $* " == *" --panels "* || $(cat "$LAYOUT_STAMP" 2>/dev/null) != "$LAYOUT_VERSION" ]]; then
    echo "Paneles (barra superior + dock)"
    launchers=()
    for app in "${DOCK_APPS[@]}"; do
        installed_app "$app" && launchers+=("applications:$app")
    done
    script=$(sed "s|@LAUNCHERS@|$(IFS=,; echo "${launchers[*]}")|" "$DOTFILES/kde/layout.js")
    # Los atajos de los widgets que se van a borrar se quedarían registrados (y Meta+A
    # duplicado): se quitan antes de rehacer los paneles
    qdbus6 --literal org.kde.kglobalaccel /component/plasmashell \
        org.kde.kglobalaccel.Component.shortcutNames 2>/dev/null \
        | grep -o 'activate widget [0-9]*' | while read -r name; do
            qdbus6 org.kde.kglobalaccel /kglobalaccel org.kde.KGlobalAccel.unregister plasmashell "$name" >/dev/null
        done
    if qdbus6 org.kde.plasmashell /PlasmaShell org.kde.PlasmaShell.evaluateScript "$script" >/dev/null; then
        echo "$LAYOUT_VERSION" > "$LAYOUT_STAMP"
    else
        echo "  (no se pudieron crear los paneles)"
    fi
fi

# --- Fondo ---
if [[ " $* " == *" --wallpaper "* || ! -f $WALLPAPER_STAMP ]]; then
    echo "Fondo de escritorio"
    mkdir -p ~/Pictures/Wallpapers
    cp -n "$WALLPAPER" ~/Pictures/Wallpapers/
    wall=~/Pictures/Wallpapers/$(basename "$WALLPAPER")
    if plasma-apply-wallpaperimage "$wall" >/dev/null 2>&1; then
        kw kscreenlockerrc --group Greeter --group Wallpaper --group org.kde.image --group General \
            --key Image "file://$wall"
        touch "$WALLPAPER_STAMP"
    else
        echo "  (no se pudo poner el fondo)"
    fi
fi

# Recargar KWin y el estilo para ver los cambios sin cerrar sesión
qdbus6 org.kde.KWin /KWin reconfigure >/dev/null 2>&1 || true
dbus-send --session --type=signal /KGlobalSettings org.kde.KGlobalSettings.notifyChange int32:2 int32:0 2>/dev/null || true
echo "Ajustes de KDE aplicados. Si algo no se ve aún (estilo de las apps abiertas), cierra sesión y vuelve a entrar."
