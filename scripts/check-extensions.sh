#!/usr/bin/env bash
# check-extensions.sh — dice qué extensiones "pendientes" (las del rice de rion, que aún no
# soportaban tu versión de GNOME) ya son compatibles y se pueden instalar sin riesgo.
set -euo pipefail

PENDING=(
    forge@jmmaranan.com                  # ventanas en mosaico tipo Hyprland
    openbar@neuromorph                   # barra flotante de colores
    quick-settings-tweaks@qwreey         # ajustes rápidos mejorados
    mediacontrols@cliffniff.github.com   # controles de música en la barra
    clipboard-indicator@tudmotu.com      # historial del portapapeles
)

v=$(gnome-shell --version | grep -oE '[0-9]+' | head -1)
echo "GNOME $v"
for uuid in "${PENDING[@]}"; do
    info=$(curl -fsS "https://extensions.gnome.org/extension-info/?uuid=$uuid") || { echo "  ?  $uuid (sin conexión)"; continue; }
    if python3 -I -c 'import json,sys; sys.exit(0 if sys.argv[1] in json.loads(sys.argv[2])["shell_version_map"] else 1)' "$v" "$info"; then
        echo "  ✅ $uuid — ya compatible: instálala desde el Gestor de extensiones"
    else
        echo "  ⏳ $uuid — todavía no"
    fi
done
