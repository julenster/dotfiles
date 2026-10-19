#!/usr/bin/env bash
# check-packages.sh — comprueba que todos los paquetes de packages/*.txt existen y están en
# la lista correcta (repos vs AUR). Ejecútalo después de editar las listas.
set -uo pipefail
DOTFILES="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
# Quita comentarios (también los del final de la línea) y líneas vacías
list() { sed -E 's/[[:space:]]*#.*//' "$1" | grep -v '^[[:space:]]*$'; }
ok=true

# Listas de repos: se comprueban juntas para detectar también conflictos entre ellas
for f in base kde gnome gaming; do
    mapfile -t pkgs < <(list "$DOTFILES/packages/$f.txt")
    if out=$(pacman -S --needed --print --print-format '%n' "${pkgs[@]}" 2>&1); then
        echo "✅ $f.txt"
    else
        echo "❌ $f.txt: $out"; ok=false
    fi
done

for f in aur gnome-aur; do
    mapfile -t aur < <(list "$DOTFILES/packages/$f.txt")
    good=true
    for p in "${aur[@]}"; do
        if pacman -Si "$p" &>/dev/null; then
            echo "⚠️  $p está en los repos: muévelo a una lista de repos"; good=false
        elif ! yay -Si --aur "$p" &>/dev/null; then
            echo "❌ $p no existe en AUR"; good=false
        fi
    done
    $good && echo "✅ $f.txt" || ok=false
done
$ok
