#!/usr/bin/env bash
# bootstrap.sh — instala y configura el entorno completo (KDE Plasma + rice + apps + Claude).
# Es idempotente: puedes ejecutarlo tantas veces como quieras.
#
# Uso:
#   ./bootstrap.sh              # detecta solo si hace falta el perfil gaming
#   ./bootstrap.sh --gaming     # fuerza el perfil gaming
#   ./bootstrap.sh --no-gaming  # nunca instala el perfil gaming
#   ./bootstrap.sh --gnome      # instala también GNOME con su rice (se elige al iniciar sesión).
#                               # Si GNOME ya está instalado se mantiene sin pasar esta opción.
set -euo pipefail

DOTFILES="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
GAMING=auto
GNOME=no
pacman -Qq gnome-shell &>/dev/null && GNOME=yes
for arg in "$@"; do
    case "$arg" in
        --gaming) GAMING=yes ;;
        --no-gaming) GAMING=no ;;
        --gnome) GNOME=yes ;;
        *) echo "Opción desconocida: $arg" >&2; exit 1 ;;
    esac
done

info() { printf '\n\e[1;34m==>\e[0m \e[1m%s\e[0m\n' "$*"; }
warn() { printf '\e[1;33m  ! %s\e[0m\n' "$*"; }
# Quita comentarios (también los del final de la línea) y líneas vacías
list() { sed -E 's/[[:space:]]*#.*//' "$1" | grep -v '^[[:space:]]*$'; }

if [[ $EUID -eq 0 ]]; then
    echo "No lo ejecutes como root; el script pedirá sudo cuando lo necesite." >&2
    exit 1
fi

# Pide la contraseña una vez y mantiene sudo vivo mientras dura el script
sudo -n true 2>/dev/null || sudo -v
while true; do sudo -n true; sleep 50; kill -0 "$$" || exit; done 2>/dev/null &
# Se guarda el PID: $! cambia con cada < <(…) del script
keepalive=$!
trap 'kill "$keepalive" 2>/dev/null || true' EXIT

# --- 1. yay -----------------------------------------------------------------
if ! command -v yay >/dev/null; then
    info "Instalando yay"
    sudo pacman -S --needed --noconfirm yay
fi

# --- 2. Paquetes de repos -----------------------------------------------------
# El rice de KDE no usa cachyos-kde-settings, y choca con cachyos-gnome-settings
if [[ $GNOME == yes ]] && pacman -Qq cachyos-kde-settings &>/dev/null; then
    info "Quitando cachyos-kde-settings (conflicto con cachyos-gnome-settings)"
    sudo pacman -R --noconfirm cachyos-kde-settings
fi

info "Actualizando el sistema e instalando KDE Plasma y los paquetes base"
mapfile -t pkgs < <(list "$DOTFILES/packages/base.txt"; list "$DOTFILES/packages/kde.txt")
[[ $GNOME == yes ]] && mapfile -t -O "${#pkgs[@]}" pkgs < <(list "$DOTFILES/packages/gnome.txt")
sudo pacman -Syu --needed --noconfirm "${pkgs[@]}"

# --- 3. Paquetes de AUR -------------------------------------------------------
info "Instalando paquetes de AUR"
mapfile -t pkgs < <(list "$DOTFILES/packages/aur.txt")
[[ $GNOME == yes ]] && mapfile -t -O "${#pkgs[@]}" pkgs < <(list "$DOTFILES/packages/gnome-aur.txt")
yay -S --needed --noconfirm --answerdiff None --answerclean None --removemake "${pkgs[@]}"

# --- 4. Perfil gaming (solo con GPU dedicada) ---------------------------------
if [[ $GAMING == auto ]]; then
    if lspci | grep -Ei 'vga|3d|display' | grep -qEi 'nvidia|radeon rx|navi|arc a|battlemage'; then
        GAMING=yes
    else
        GAMING=no
    fi
fi
if [[ $GAMING == yes ]]; then
    info "Perfil gaming: drivers + Steam/Proton/gamemode/MangoHud"
    sudo chwd --autoconfigure || warn "chwd falló; revisa los drivers con 'chwd --list'"
    mapfile -t pkgs < <(list "$DOTFILES/packages/gaming.txt")
    sudo pacman -S --needed --noconfirm "${pkgs[@]}"
    sudo usermod -aG gamemode "$USER"
    # ntsync acelera Proton/Wine (lo usa proton-cachyos si el módulo está cargado)
    echo ntsync | sudo tee /etc/modules-load.d/ntsync.conf >/dev/null
    # Modo rendimiento solo en torres: en un portátil gastaría la batería (se queda equilibrado)
    if ! compgen -G '/sys/class/power_supply/BAT*' >/dev/null; then
        powerprofilesctl set performance 2>/dev/null || true
    fi
    # Planificador de CPU para juegos (scx_lavd Gaming), activo desde el arranque
    sudo install -Dm644 "$DOTFILES/gaming/scx_loader.toml" /etc/scx_loader/config.toml
    sudo install -Dm644 "$DOTFILES/gaming/scx-restart.hook" /etc/pacman.d/hooks/scx-restart.hook
    sudo systemctl enable scx_loader.service
    sudo systemctl restart scx_loader.service || warn "scx_loader no arrancó; se intentará al reiniciar"
    # MangoHud (FPS y temperaturas en los juegos: Shift derecho+F12)
    mkdir -p ~/.config/MangoHud
    ln -sfn "$DOTFILES/gaming/MangoHud.conf" ~/.config/MangoHud/MangoHud.conf
    # Caché de shaders grande para que los juegos no recompilen en plena partida: la de Mesa
    # (AMD/Intel) siempre, y la de NVIDIA si hay NVIDIA. Va en el disco, así que el tamaño
    # depende de él: 10 % del disco, sin pasar del 20 % de lo libre, entre 2 y 12 GB
    # (disco de 1 TB → 12 GB; de 128 GB → 12 GB si hay sitio; de 64 GB → ~6 GB)
    read -r disk free < <(df -B1G --output=size,avail ~ | tail -1)
    cache_gb=$(( disk / 10 < free / 5 ? disk / 10 : free / 5 ))
    (( cache_gb > 12 )) && cache_gb=12
    (( cache_gb < 2 )) && cache_gb=2
    info "Caché de shaders: $cache_gb GB (disco de $disk GB, $free GB libres)"
    mkdir -p ~/.config/environment.d
    # rm antes: en instalaciones antiguas eran symlinks al repo y sed > escribiría en la plantilla
    rm -f ~/.config/environment.d/90-mesa-shader-cache.conf ~/.config/environment.d/90-nvidia-shader-cache.conf
    sed "s|@SIZE@|${cache_gb}G|" "$DOTFILES/gaming/90-mesa-shader-cache.conf" \
        > ~/.config/environment.d/90-mesa-shader-cache.conf
    if lspci | grep -Ei 'vga|3d' | grep -qi nvidia; then
        # NVIDIA lo quiere en bytes
        sed "s|@SIZE@|$(( cache_gb * 1000000000 ))|" "$DOTFILES/gaming/90-nvidia-shader-cache.conf" \
            > ~/.config/environment.d/90-nvidia-shader-cache.conf
        # Colores más vivos (digital vibrance): en Wayland nvidia-settings no puede, nvibrant sí
        yay -S --needed --noconfirm --answerdiff None --answerclean None nvibrant-bin \
            || warn "No se pudo instalar nvibrant"
        mkdir -p ~/.local/bin ~/.config/autostart
        ln -sfn "$DOTFILES/gaming/nvibrant-apply" ~/.local/bin/nvibrant-apply
        sed "s|@HOME@|$HOME|" "$DOTFILES/gaming/nvibrant.desktop" > ~/.config/autostart/nvibrant.desktop
    fi
    "$DOTFILES/scripts/steam-proton-default.sh"
else
    info "Sin GPU dedicada: se omite el perfil gaming (usa --gaming para forzarlo)"
fi

# --- 5. Flatpak -----------------------------------------------------------------
info "Instalando Flatpaks"
sudo flatpak remote-add --if-not-exists flathub https://dl.flathub.org/repo/flathub.flatpakrepo
mapfile -t pkgs < <(list "$DOTFILES/packages/flatpak.txt")
sudo flatpak install -y --noninteractive flathub "${pkgs[@]}" || warn "Algún flatpak falló"

# --- 6. Servicios -----------------------------------------------------------------
info "Configurando servicios"
# Docker solo arranca cuando algo lo usa (socket): no gasta RAM ni retrasa el arranque
sudo systemctl disable docker.service 2>/dev/null || true
sudo systemctl enable docker.socket
sudo usermod -aG docker "$USER"

# Pantalla de inicio de sesión: SDDM (con el tema Breeze y tu fondo, que pone el paso 8). Desde
# ella se elige el escritorio (Plasma o GNOME)
for dm in gdm plasmalogin lightdm; do
    if systemctl is-enabled "$dm.service" &>/dev/null; then sudo systemctl disable "$dm.service"; fi
done
sudo rm -f /etc/sddm.conf.d/10-dotfiles.conf   # nombre antiguo
sudo install -Dm644 "$DOTFILES/sddm/zzz-dotfiles.conf" /etc/sddm.conf.d/zzz-dotfiles.conf
sudo systemctl enable sddm.service

# Identidad de git para hacer commits. Se pregunta (no se copia la del autor del repo: si lo
# instala otra persona, sus commits saldrían a nombre del autor)
if [[ -z $(git config --global user.name) && -t 0 ]]; then
    info "Git: tu nombre y correo para los commits (Intro para saltarlo)"
    read -rp "  Nombre: " name
    read -rp "  Correo: " email
    [[ -n $name ]] && git config --global user.name "$name"
    [[ -n $email ]] && git config --global user.email "$email"
fi
git config --global init.defaultBranch main

# --- 7. Claude Code + IDEs ---------------------------------------------------------
if ! command -v claude >/dev/null && [[ ! -x ~/.local/bin/claude ]]; then
    info "Instalando Claude Code"
    curl -fsSL https://claude.ai/install.sh | bash
fi

info "VS Code: extensiones y ajustes"
while read -r ext; do
    code --install-extension "$ext" --force >/dev/null
done < <(list "$DOTFILES/vscode/extensions.txt")
mkdir -p ~/.config/Code/User
ln -sfn "$DOTFILES/vscode/settings.json" ~/.config/Code/User/settings.json

info "Rider: plugin de Claude Code"
if pgrep -f /opt/rider/bin >/dev/null; then
    warn "Rider está abierto; ciérralo y vuelve a ejecutar el script para instalar el plugin"
else
    /opt/rider/bin/rider.sh installPlugins com.anthropic.code.plugin >/dev/null 2>&1 \
        || warn "No se pudo instalar el plugin; hazlo desde Settings > Plugins > 'Claude Code'"
fi

# --- 8. Pantalla de inicio de sesión --------------------------------------------------
# Breeze con el fondo del repo. Si ya está puesto no se toca, para no cambiarle el fondo
if [[ ! -f /usr/share/sddm/themes/breeze/theme.conf.user ]]; then
    info "Tema de la pantalla de inicio de sesión"
    "$DOTFILES/sddm/install-theme.sh" "$DOTFILES/wallpapers/wallhaven-yq8yex.png" || warn "No se pudo instalar el tema de SDDM"
fi

# Vesktop (Discord) al iniciar sesión
if [[ -x /opt/vesktop/vesktop && ! -f ~/.config/autostart/vesktop.desktop ]]; then
    mkdir -p ~/.config/autostart
    printf '%s\n' '[Desktop Entry]' 'Type=Application' 'Name=Vesktop' 'Exec=/opt/vesktop/vesktop' \
        'StartupNotify=false' 'Terminal=false' 'Icon=vesktop' > ~/.config/autostart/vesktop.desktop
fi

# --- 9. Rice ----------------------------------------------------------------------
# Cada rice se aplica dentro de su escritorio: si ahora no estás en él, se aplicará solo la
# primera vez que entres
rm -f ~/.config/autostart/dotfiles-firstrun.desktop ~/.config/autostart/dotfiles-firstrun-gnome.desktop
mkdir -p ~/.config/autostart
if [[ ${XDG_CURRENT_DESKTOP:-} == *KDE* ]]; then
    info "Aplicando los ajustes de KDE"
    "$DOTFILES/kde/apply.sh"
else
    info "Los ajustes de KDE se aplicarán automáticamente al entrar en Plasma"
    sed "s|@DOTFILES@|$DOTFILES|" "$DOTFILES/kde/dotfiles-firstrun.desktop" \
        > ~/.config/autostart/dotfiles-firstrun.desktop
fi
if [[ $GNOME == yes ]]; then
    if [[ ${XDG_CURRENT_DESKTOP:-} == *GNOME* ]]; then
        info "Aplicando el rice de GNOME"
        "$DOTFILES/gnome/apply.sh"
    else
        info "El rice de GNOME se aplicará automáticamente al entrar en GNOME"
        sed "s|@DOTFILES@|$DOTFILES|" "$DOTFILES/gnome/dotfiles-firstrun.desktop" \
            > ~/.config/autostart/dotfiles-firstrun-gnome.desktop
    fi
fi

# --- 10. Limpieza -------------------------------------------------------------------
# Solo los que estén instalados. Ojo: "pacman -Qq" sin argumentos lista TODO el sistema,
# por eso se comprueba uno a uno.
unwanted=()
while read -r p; do
    # No quitar la terminal desde la que se está ejecutando este script
    [[ $p == ptyxis && -n ${PTYXIS_VERSION:-} ]] && { warn "Ptyxis se quitará la próxima vez (ejecútalo desde kitty)"; continue; }
    if pacman -Qq "$p" &>/dev/null; then unwanted+=("$p"); fi
done < <(list "$DOTFILES/packages/remove.txt" | awk '{print $1}')
if ((${#unwanted[@]})); then
    info "Quitando paquetes que no se usan: ${unwanted[*]}"
    sudo pacman -Rns --noconfirm "${unwanted[@]}"
fi

info "¡Listo!"
echo "  - Reinicia el equipo. En la pantalla de inicio de sesión elige 'Plasma (Wayland)'"
echo "    (abajo a la izquierda); la recordará para las siguientes veces."
[[ $GNOME == yes ]] && echo "  - GNOME sigue disponible en esa misma lista. Para quitarlo: $DOTFILES/scripts/remove-gnome.sh"
echo "  - Abre una terminal (Ctrl+Alt+T) y ejecuta 'claude' para iniciar sesión en Claude Code."
