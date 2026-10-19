# CLAUDE.md

Dotfiles para CachyOS + KDE Plasma (GNOME opcional). Un comando (`bootstrap.sh`) deja
cualquier equipo igual: paquetes, AUR, Flatpak, rice de KDE (y de GNOME si está), pantalla de
inicio de sesión, terminal, IDEs con Claude Code y gaming. Lo instalan personas distintas en
equipos distintos: **nada de datos personales en el repo** (cuentas, correos, tokens, configs
con sesiones de OBS/Steam/Discord…) y el rendimiento se decide según el hardware detectado.

## Sobre quien lo usa

- Habla **español**: responde siempre en español.
- Puede ser su **primera vez en Linux**: explica las cosas sin dar por hecho conocimientos
  previos.
- Prioridades: que sea **bonito**, **estable**, rápido en juegos y que funcionen bien
  programas (Rider, VS Code).

## Decisiones de diseño (no reabrir sin que lo pida)

- **KDE Plasma es el escritorio principal**. **GNOME es secundario**: se instala con `--gnome`
  o si ya estaba, y se elige en SDDM.
- Aspecto de KDE: **paneles nativos de Plasma, sin shells aparte** (shells como Caelestia
  bajaban el rendimiento en juegos). `kde/apply.sh` + `kde/layout.js`: barra superior flotante
  de 34 px (kickoff, pager, reloj centrado, bandeja) y dock flotante que esquiva ventanas
  (icontasks con todas las apps abiertas + botón de rejilla de apps `kickerdash`), Darkly
  (estilo y decoración), Breeze Dark, Papirus-Dark, Inter, Bibata. `layout.js` conserva las
  apps ancladas del dock al rehacer los paneles; subir `LAYOUT_VERSION` al cambiarlo.
- **Flujo de GNOME**: Super = vista general de KWin, Super+A = rejilla de apps a pantalla
  completa (KWin no permite el doble toque de Super). KRunner con apps y ajustes como
  favoritos. Super+1…9 = escritorios (se quitan a los del dock), al menos 4 escritorios.
  `krunner_appstream` desactivado (con KWin 6.8 tumbaba kwin_wayland al buscar).
- **Sin desenfoque forzado** ni reglas de opacidad en todas las ventanas: solo el blur de KWin
  donde la app lo pide (forzarlo gasta GPU jugando).
- **Nada de atajos Alt+tecla en KDE**: chocan con los juegos (agacharse con Alt).
- Pantalla de inicio de sesión: **Breeze de KDE con el fondo del escritorio**; bloqueo,
  apagado y splash, los de serie de KDE. Nada de temas QML a medida para SDDM/bloqueo (dieron
  problemas al encender y al volver de AFK).
- SDDM en **Wayland** (no hay X11): `sddm/zzz-dotfiles.conf` se llama así para leerse después
  de los demás drop-ins.
- Con dos gráficas (iGPU + dedicada), la **gráfica principal se elige en la BIOS**
  (PCIe/PEG): si es la iGPU, KWin compone con ella y el escritorio va a tirones. Comprobar con
  `qdbus6 org.kde.KWin /KWin supportInformation | grep 'OpenGL renderer'`.
- **Caché de shaders** en disco sin limpieza para toda la sesión (`~/.config/environment.d/`):
  NVIDIA (`gaming/90-nvidia-shader-cache.conf`) y Mesa para AMD/Intel
  (`gaming/90-mesa-shader-cache.conf`). Son plantillas con `@SIZE@`: `bootstrap.sh` elige el
  tamaño según el disco (10 % del disco de `~`, entre 2 y 12 GB) para no llenar discos
  pequeños. Precacheo de shaders de Steam desactivado (wiki de CachyOS con proton-cachyos).
- Perfil gaming: `scx_lavd` modo Gaming persistente (`gaming/scx_loader.toml` →
  `/etc/scx_loader/config.toml` + hook de pacman `gaming/scx-restart.hook`), ntsync,
  `powerprofilesctl performance` solo sin batería. Docker por socket (`docker.socket`).
- **Proton-CachyOS** (`proton-cachyos-slr`) por defecto en Steam.
- **Siempre la última versión de GNOME** (rolling). **No forzar extensiones incompatibles**:
  las pendientes (Forge, Open Bar, Quick Settings Tweaks, Media Controls, Clipboard Indicator)
  están en `scripts/check-extensions.sh`.
- Terminal **kitty** con el GIF de Miku de kovasko/hyprland-dotfiles (`kitten icat … |
  fastfetch --raw -`). Ptyxis se desinstala.
- GNOME: acento según el fondo (Auto Accent Colour) + Accent Icons sobre **MoreWaita**.
- Repo **público**: se instala con `git clone` sin cuentas. Nada de pedir login para instalar.
- `bootstrap.sh` **pregunta la identidad de git**, nunca copia la de nadie.
- Fondo fijo del repo (`wallpapers/wallhaven-yq8yex.png`): escritorio, bloqueo y SDDM. Se pone
  solo la primera vez (marca `~/.config/dotfiles-kde-wallpaper`) o con `kde/apply.sh --wallpaper`.
- Con NVIDIA: `nvibrant-bin` + `gaming/nvibrant-apply` (por defecto 800, debe seguir con
  `#!/bin/sh` o el autostart falla con "Exec format error"). MangoHud con
  `gaming/MangoHud.conf` (generado con GOverlay).
- `CLAUDE.local.md` (en `.gitignore`) guarda lo que es solo de quien tiene el repo clonado.

## Estructura

- `bootstrap.sh` — instalación completa e idempotente (pide sudo).
- `packages/*.txt` — listas de paquetes. Repos: `base` (común), `kde`, `gnome`, `gaming`.
  AUR (solo lo que NO está en repos): `aur` (común + KDE), `gnome-aur`. `remove` = se desinstala.
  Se admiten comentarios al final de la línea.
- `kde/apply.sh` — rice de KDE (atajos vía D-Bus de kglobalaccel con el helper `shortcut`,
  aspecto, vista general, terminal, touchpad; quita restos de Caelestia/Better Blur DX). Sin
  sudo. `kde/layout.js` — los paneles (evaluateScript de plasmashell); se aplica la primera vez
  o con `--panels` (marca en `~/.config/dotfiles-kde-layout`).
- `gnome/apply.sh` — rice de GNOME; `gnome/appearance.sh` se ejecuta también en cada inicio
  de GNOME porque KDE sobrescribe `org.gnome.desktop.interface` (kde-gtk-config).
- `sddm/zzz-dotfiles.conf` — va a `/etc/sddm.conf.d/`.
- `sddm/install-theme.sh` — pone Breeze en SDDM con el fondo de Plasma (copiado a
  `/usr/share/sddm/themes/breeze/background.png` + `theme.conf.user`, porque el usuario sddm no
  lee `~`), el mismo fondo en el bloqueo, y limpia restos de temas antiguos (PS4/Caelestia).
  Volver a ejecutarlo para cambiar el fondo. `bootstrap.sh` lo ejecuta solo si falta
  `theme.conf.user`.
- `gaming/` — archivos del perfil gaming (cachés de shaders, scx_loader, MangoHud, nvibrant).
- `wallpapers/` — el fondo.
- `kitty/`, `fastfetch/`, `fish/`, `cava/`, `vscode/` — configs enlazadas con symlinks
  (`scripts/link-terminal.sh`, compartido por los dos escritorios).
- `scripts/` — `wallpaper-picker` (GNOME Super+W), `steam-proton-default.sh`,
  `check-packages.sh`, `check-extensions.sh`, `sync-packages.sh`, `remove-gnome.sh`.

## Convenciones

- Scripts en bash con `set -euo pipefail`, comentarios en español, **shellcheck limpio**
  (lo comprueba el CI en `.github/workflows/lint.yml`).
- Tras editar `packages/*.txt`, ejecutar `scripts/check-packages.sh`: un paquete en la lista
  equivocada (repos vs AUR) hace fallar toda la instalación.
- KDE: para descubrir una clave, cambia la opción en Ajustes y mira `git diff` de una copia
  de `~/.config` o `kreadconfig6`. Atajos globales con `shortcut` (no editando
  kglobalshortcutsrc a mano: kglobalaccel lo sobrescribe con lo que tiene en memoria). Ojo:
  "Super solo" es la tecla `Qt::Key_Meta` (0x01000022), no el modificador Meta.
- Los ajustes de extensiones van en `gnome/apply.sh` con el helper `ext` (no falla si la
  clave no existe). Para descubrir una clave: `dconf watch /` mientras se cambia la opción.
- Antes de añadir una extensión, comprobar que soporta la versión de GNOME instalada en
  `https://extensions.gnome.org/extension-info/?uuid=<uuid>`.
- Ojo con `pacman -Qq` sin argumentos: lista todo el sistema. Comprobar paquetes uno a uno.
- `bootstrap.sh` y los `apply.sh` deben seguir siendo idempotentes.
