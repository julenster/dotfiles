#!/usr/bin/env bash
# sync-packages.sh — muestra los paquetes que has instalado tú y aún no están en packages/*.txt,
# para que los añadas y se instalen también en tus otros equipos.
# Ignora lo que trae de serie una instalación de CachyOS (paquetes que no están en las listas
# pero dependen del instalador): revisa la salida y añade solo lo que quieras.
set -euo pipefail
DOTFILES="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
listed=$(sed -E 's/[[:space:]]*#.*//' "$DOTFILES"/packages/*.txt | grep -v '^[[:space:]]*$' | sort -u)

# Paquetes instalados explícitamente más de 30 min después de instalar el sistema
install_date=$(stat -c %W /)
mapfile -t explicit < <(pacman -Qqe)
recent=$(expac --timefmt=%s '%l %n' "${explicit[@]}" 2>/dev/null \
    | awk -v t="$((install_date + 1800))" '$1 > t {print $2}' | sort)

echo "== Repos (añádelos a packages/base.txt o kde.txt):"
comm -23 <(comm -12 <(pacman -Qqen | sort) <(echo "$recent")) <(echo "$listed") | sed 's/^/  /'
echo "== AUR (añádelos a packages/aur.txt):"
comm -23 <(pacman -Qqem | sort) <(echo "$listed") | sed 's/^/  /'
echo "== Flatpak (añádelos a packages/flatpak.txt):"
comm -23 <(flatpak list --app --columns=application | sort) <(echo "$listed") | sed 's/^/  /'
