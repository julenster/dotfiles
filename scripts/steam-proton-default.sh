#!/usr/bin/env bash
# steam-proton-default.sh — pone Proton-CachyOS como Proton por defecto para todos los juegos
# (Steam → Ajustes → Compatibilidad). Los juegos que tengan uno elegido a mano lo mantienen.
# Steam tiene que estar cerrado: si no, sobrescribe el archivo al salir.
set -euo pipefail

TOOL=proton-cachyos-slr
CONFIG=~/.local/share/Steam/config/config.vdf

if [[ ! -f $CONFIG ]]; then
    echo "  (Steam aún no se ha abierto nunca: ábrelo una vez, ciérralo y vuelve a ejecutar esto)"
    exit 0
fi
if pgrep -x steam >/dev/null; then
    echo "  (Steam está abierto: ciérralo y ejecuta $0 para poner $TOOL por defecto)"
    exit 0
fi
[[ -d /usr/share/steam/compatibilitytools.d/$TOOL ]] || { echo "  (falta el paquete $TOOL)"; exit 0; }

cp "$CONFIG" "$CONFIG.bak"
python3 -I - "$CONFIG" "$TOOL" <<'EOF'
# Lee el config.vdf (formato de texto de Valve), pone CompatToolMapping/"0" y lo vuelve a escribir
import re, sys

path, tool = sys.argv[1], sys.argv[2]
tokens = re.findall(r'"((?:[^"\\]|\\.)*)"|([{}])', open(path, encoding="utf-8").read())

def parse(it):
    node = {}
    for s, brace in it:
        if brace == "}":
            return node
        _, brace2 = value = next(it)
        node[s] = parse(it) if brace2 == "{" else value[0]
    return node

def dump(node, depth=0):
    out = []
    for k, v in node.items():
        tabs = "\t" * depth
        if isinstance(v, dict):
            out += [f'{tabs}"{k}"', tabs + "{", *dump(v, depth + 1), tabs + "}"]
        else:
            out.append(f'{tabs}"{k}"\t\t"{v}"')
    return out

root = parse(iter(tokens))
steam = root["InstallConfigStore"]["Software"]["Valve"]["Steam"]
steam.setdefault("CompatToolMapping", {})["0"] = {"name": tool, "config": "", "priority": "75"}
open(path, "w", encoding="utf-8").write("\n".join(dump(root)) + "\n")
EOF
echo "  Proton por defecto: $TOOL"
