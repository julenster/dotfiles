#!/usr/bin/env bash
# Pantalla de inicio de sesión: el tema Breeze de KDE (el que viene con Plasma, sencillo y
# estable) con el fondo del escritorio. También quita lo que quede del tema PS4 o del de
# Caelestia (login, bloqueo, pantalla de apagado y splash) y deja todo como en KDE de serie.
#
# SDDM se ejecuta como el usuario sddm y no puede leer tu carpeta personal, así que el fondo
# se copia. Para cambiarlo más adelante, vuelve a ejecutarlo:  sddm/install-theme.sh [imagen]
set -euo pipefail

[[ $EUID -ne 0 ]] || { echo "Ejecútalo como tu usuario normal, sin sudo (ya lo pide él)." >&2; exit 1; }

T=/usr/share/sddm/themes/breeze
LOCK=/usr/share/plasma/shells/org.kde.plasma.desktop/contents/lockscreen

# Fondo: el argumento, o el fondo actual del escritorio de Plasma
WALL="${1:-}"
if [[ -z $WALL ]]; then
    WALL="$(grep -m1 '^Image=' ~/.config/plasma-org.kde.plasma.desktop-appletsrc 2>/dev/null | sed 's|^Image=||; s|^file://||' || true)"
fi
# Equipo recién instalado (aún sin fondo propio): el de Plasma por defecto
[[ -n $WALL && -f $WALL ]] || WALL=/usr/share/wallpapers/Next/contents/images/5120x2880.png

# --- Restos del tema PS4 --------------------------------------------------------------
if [[ -e /etc/systemd/system/ps4-lockscreen.path || -d $LOCK/ps4 || -d /usr/share/sddm/themes/ps4 ]]; then
    echo "==> Quitando el tema PS4"
    sudo systemctl disable --now ps4-lockscreen.path 2>/dev/null || true
    [[ -f $LOCK/LockScreen.breeze.qml ]] && sudo mv -f "$LOCK/LockScreen.breeze.qml" "$LOCK/LockScreen.qml"
    sudo rm -rf "$LOCK/ps4" /usr/share/sddm/themes/ps4 /usr/local/share/ps4-lockscreen
    sudo rm -f /etc/sddm.conf.d/zzzz-ps4-theme.conf \
        /usr/local/bin/ps4-lockscreen-apply /usr/local/bin/ps4-lockscreen-restore \
        /etc/systemd/system/ps4-lockscreen.path /etc/systemd/system/ps4-lockscreen.service
    sudo systemctl daemon-reload
fi
# El bloqueo de KDE tiene que quedar exactamente como lo instala el paquete
# (en una variable: con pipefail, "pacman | grep -q" falla cuando grep cierra la tubería antes)
pkgcheck="$(pacman -Qkk plasma-desktop 2>&1 || true)"
if grep -q "$LOCK" <<<"$pkgcheck"; then
    echo "==> Reinstalando plasma-desktop para dejar el bloqueo original"
    sudo pacman -S --noconfirm plasma-desktop
fi

# Pantalla de apagado y splash de vuelta a los de Breeze (son de tu cuenta, sin sudo)
if [[ "$(kreadconfig6 --file kdeglobals --group KDE --key LookAndFeelPackage)" == com.github.julenster.ps4 ]]; then
    kwriteconfig6 --file kdeglobals --group KDE --key LookAndFeelPackage org.kde.breezedark.desktop
fi
if [[ "$(kreadconfig6 --file ksplashrc --group KSplash --key Theme)" == com.github.julenster.ps4 ]]; then
    kwriteconfig6 --file ksplashrc --group KSplash --key Engine KSplashQML
    kwriteconfig6 --file ksplashrc --group KSplash --key Theme org.kde.breeze.desktop
fi
rm -rf ~/.local/share/plasma/look-and-feel/com.github.julenster.ps4 ~/.config/ps4-theme

# --- Restos del tema de Caelestia -----------------------------------------------------
sudo rm -rf /usr/share/sddm/themes/caelestia

# --- Breeze con tu fondo --------------------------------------------------------------
echo "==> Inicio de sesión: Breeze con $(basename "$WALL")"
tmp="$(mktemp --suffix=.png)"
# 2560 px de ancho como mucho: una imagen enorme tarda en cargar al encender
magick "$WALL" -resize '2560x>' "$tmp"
sudo install -m 644 "$tmp" "$T/background.png"
rm -f "$tmp"
# theme.conf.user es donde Ajustes del sistema guarda lo mismo; el paquete no lo pisa
printf '[General]\ntype=image\nbackground=%s/background.png\n' "$T" | sudo tee "$T/theme.conf.user" >/dev/null

# Ajustes de SDDM del repo (Wayland, cursor)
sudo install -m 644 "$(dirname "$0")/zzz-dotfiles.conf" /etc/sddm.conf.d/zzz-dotfiles.conf

# Elegir el tema. /etc/sddm.conf manda sobre los drop-ins, así que se cambia también ahí si
# lo tiene puesto
printf '[Theme]\nCurrent=breeze\n' | sudo tee /etc/sddm.conf.d/zz-theme.conf >/dev/null
if [[ -f /etc/sddm.conf ]] && sudo grep -q '^Current=' /etc/sddm.conf; then
    sudo sed -i 's/^Current=.*/Current=breeze/' /etc/sddm.conf
fi

# El bloqueo (Meta+L / al volver de AFK) es el de KDE con el mismo fondo
kwriteconfig6 --file kscreenlockerrc --group Greeter --key Theme org.kde.breeze.desktop
kwriteconfig6 --file kscreenlockerrc --group Greeter --key WallpaperPlugin org.kde.image
kwriteconfig6 --file kscreenlockerrc --group Greeter --group Wallpaper --group org.kde.image --group General \
    --key Image "file://$WALL"

echo "Listo. Pruébalo sin reiniciar con:  sddm-greeter-qt6 --test-mode --theme $T"
