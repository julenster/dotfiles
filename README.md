# dotfiles

Mi entorno **CachyOS + KDE Plasma** listo en un comando: barra superior y dock con los paneles
de Plasma, flujo de GNOME (Super = vista general, Super+A = todas las apps), estilo Darkly,
pantalla de inicio de sesión Breeze con tu fondo, terminal kitty con Miku animada, VS Code y Rider con
Claude Code, Tidal y perfil gaming para la torre. GNOME se puede instalar también y elegir al
iniciar sesión.

> Antes usaba el shell de [Caelestia](https://github.com/ladybug-me/caelestia-kde) entero; se
> quitó porque bajaba el rendimiento en juegos. Ahora todo es KDE de serie.

## Instalar en un equipo nuevo

1. Instala CachyOS desde el pen eligiendo **KDE Plasma** como escritorio.
2. Abre la terminal y pega **este único comando** (te pedirá tu contraseña; no hace falta
   ninguna cuenta):

   ```bash
   sudo pacman -S --needed --noconfirm git && git clone https://github.com/julenster/dotfiles ~/dotfiles && ~/dotfiles/bootstrap.sh
   ```

3. Reinicia. Abre kitty (`Ctrl+Alt+T`) y ejecuta `claude` para iniciar sesión en Claude Code.
   Para seguir mejorando el rice con Claude: `cd ~/dotfiles && claude` (lee `CLAUDE.md`).

El perfil gaming (Steam, Proton, MangoHud, caché de shaders grande, planificador de CPU para
juegos y, con NVIDIA, colores vivos con nvibrant) se activa solo si se detecta GPU dedicada
(NVIDIA / AMD RX / Intel Arc). Fuérzalo con
`--gaming` o desactívalo con `--no-gaming`.

`bootstrap.sh` se puede repetir siempre que quieras: instala solo lo que falte.

### En un equipo que ya tiene el repo (p. ej. el portátil)

```bash
cd ~/dotfiles && git pull && ./bootstrap.sh
```

Reinicia y, en la pantalla de inicio de sesión, elige **Plasma (Wayland)** (abajo a la
izquierda). Si el portátil ya tenía otro fondo puesto y quieres el del repo:
`~/dotfiles/kde/apply.sh --wallpaper`.

### Pasárselo a un amigo

El repo es público: le basta con el comando de *Instalar en un equipo nuevo*, sin cuenta de
GitHub. No se lleva ninguna cuenta tuya: el script le pregunta **su** nombre y correo para git,
y Claude Code, Steam, Discord, etc. los inicia él con sus cuentas. El rendimiento se adapta solo
a su equipo (NVIDIA, AMD o Intel; torre o portátil).

## Qué incluye

| | |
|---|---|
| `bootstrap.sh` | Instala todo: paquetes, AUR (yay), Flatpak, servicios, SDDM, Claude Code, IDEs y el rice |
| `packages/base.txt` | Paquetes de los repos comunes |
| `packages/kde.txt` | KDE Plasma, sus apps y SDDM |
| `packages/aur.txt` | Paquetes de AUR (Darkly, VS Code, Rider, Tidal…) |
| `packages/gnome.txt`, `gnome-aur.txt` | GNOME y sus extensiones (solo con `--gnome` o si ya estaba) |
| `packages/gaming.txt` | Solo torre: Steam, Proton-CachyOS, gamemode, MangoHud, Heroic, Lutris |
| `packages/flatpak.txt` | Flatpaks |
| `packages/remove.txt` | Paquetes que se desinstalan (p. ej. Ptyxis, porque se usa kitty) |
| `kde/apply.sh` | El rice de KDE: aspecto, atajos (libres para jugar), vista general, kitty con Miku, touchpad |
| `wallpapers/` | El fondo de escritorio (también el de la pantalla de bloqueo y la de inicio de sesión) |
| `kde/layout.js` | Los paneles: barra superior y dock (`kde/apply.sh --panels` los rehace) |
| `sddm/` | SDDM en Wayland y `install-theme.sh`, que pone el tema Breeze con tu fondo (vuelve a ejecutarlo para cambiar el fondo) |
| `gaming/` | MangoHud, caché de shaders grande (NVIDIA y AMD/Intel), planificador scx_lavd y saturación de color con nvibrant (solo NVIDIA) |
| `gnome/apply.sh` | El rice de GNOME: extensiones, dock, atajos |
| `kitty/`, `fastfetch/`, `fish/`, `cava/` | Terminal con Miku animada ([kovasko/hyprland-dotfiles](https://github.com/kovasko/hyprland-dotfiles)) |
| `vscode/` | Extensiones (Claude Code, tema Miku) y ajustes de VS Code |
| `scripts/wallpaper-picker` | Selector de fondos con vista previa (Super+W en GNOME) |
| `scripts/steam-proton-default.sh` | Proton-CachyOS como Proton por defecto en Steam |
| `CLAUDE.md` | Contexto para Claude Code: decisiones, estructura y convenciones del repo |
| `scripts/check-packages.sh` | Comprueba que todos los paquetes de las listas existen (ejecútalo tras editarlas) |
| `scripts/sync-packages.sh` | Lista lo que has instalado y aún no está en `packages/` |
| `scripts/check-extensions.sh` | GNOME: avisa cuando las extensiones pendientes ya son compatibles |

Las configuraciones están **enlazadas** (symlinks) al repo: si cambias `kitty.conf` o los
ajustes de VS Code, el cambio ya está en `~/dotfiles` listo para hacer commit.

## Atajos (KDE)

| Atajo | Acción |
|---|---|
| `Super` | Vista general como en GNOME: ventanas abiertas, escritorios y búsqueda (escribe directamente) |
| `Super + A` | Todas las apps a pantalla completa con buscador (como pulsar Super otra vez en GNOME); también con el botón de la rejilla al final del dock |
| `Super + 1…4` | Cambiar de escritorio |
| `Super + Shift + S` | Captura de pantalla |
| `Ctrl + Alt + T` | Terminal (kitty con Miku) |
| `Alt + Tab` | Cambiar de ventana |

Ningún atajo de KDE usa `Alt` + otra tecla de juego: `Alt+Espacio` (KRunner) y compañía están
desactivados para poder agacharse con `Alt` en los juegos.

## Personalizar

Todo desde *Ajustes del sistema*:
- **Fondo**: clic derecho en el escritorio → *Configurar escritorio y fondo*. Para que la
  pantalla de inicio de sesión use el mismo: `~/dotfiles/sddm/install-theme.sh`.
- **Paneles**: clic derecho en la barra o el dock → *Mostrar configuración del panel* (o
  *Entrar en modo de edición*). Para volver a los del repo: `~/dotfiles/kde/apply.sh --panels`.
- **Apps del dock**: arrastra una app al dock, o clic derecho en una abierta → *Anclar al gestor
  de tareas*.
- **Bordes y botones de las ventanas**: *Apariencia → Decoraciones de ventanas* (ahora Darkly).
- **Vista general** (Super): *Gestión de ventanas → Efectos de escritorio → Vista general*. Lo
  que sale al buscar: *Búsqueda → KRunner* (el repo deja primero apps y ajustes).

El desenfoque es el normal de KWin (solo paneles, menús y apps que lo piden, como kitty): forzarlo
en todas las ventanas gastaba GPU también jugando.

## GNOME (opcional)

Mismo rice que antes: Blur my Shell, Dash to Dock, acento según el fondo (Auto Accent Colour),
iconos MoreWaita. KDE cambia algunos ajustes de apariencia compartidos (fuentes, iconos); GNOME
los recupera solo al iniciar sesión. Solo se usan extensiones compatibles con la versión de
GNOME instalada: `scripts/check-extensions.sh` avisa cuando las pendientes ya lo son.

## Gaming

- **Proton-CachyOS** es el Proton por defecto (lo pone `bootstrap.sh` con Steam cerrado; si
  estaba abierto: `scripts/steam-proton-default.sh`). Si un juego da problemas: Propiedades →
  Compatibilidad → Proton Experimental.
- Opciones de lanzamiento en Steam: `game-performance %command%` (añade `mangohud` delante de
  `%command%` para ver FPS).
- **Caché de shaders** grande y sin limpieza (`gaming/90-nvidia-shader-cache.conf` con NVIDIA,
  `gaming/90-mesa-shader-cache.conf` con AMD/Intel; para todos los juegos). Está en el disco
  (no gasta RAM ni VRAM) y su tamaño depende de él: 10 % del disco, como mucho el 20 % de lo
  libre, entre 2 y 12 GB. Así el driver no borra los shaders compilados y no los vuelve a
  compilar en plena partida (tirones). Se aplica al cerrar sesión y volver a entrar. Como recomienda la wiki de CachyOS con
  proton-cachyos, desactiva también el precacheo de Steam:
  *Steam → Ajustes → Descargas → Caché de shaders* (Proton-CachyOS ya los compila solo).
- **Planificador de CPU para juegos**: `scx_lavd` en modo Gaming desde el arranque
  (`gaming/scx_loader.toml`), da prioridad al juego y mejora los FPS mínimos. Para quitarlo:
  `sudo systemctl disable --now scx_loader`.
- **Modo rendimiento** (`powerprofilesctl`) en torres; en portátiles se queda en equilibrado
  para no gastar batería. Docker solo arranca cuando se usa.
- **Monitores en la gráfica dedicada** y, en la BIOS, la gráfica principal en **PCIe/PEG** (no
  la integrada). Si no, KDE dibuja el escritorio con la gráfica del procesador: se pone al
  100 % y Alt+Tab y la vista general van a tirones. Comprobar:
  `qdbus6 org.kde.KWin /KWin supportInformation | grep 'OpenGL renderer'` debe decir la dedicada.
- Deadlock: Reflex desactivado (en Linux puede dar tirones con el tiempo).
- VRR (FreeSync/G-Sync) y HDR: Ajustes del sistema → Pantalla y monitor.

## Mantener sincronizado

```bash
cd ~/dotfiles
./scripts/sync-packages.sh          # ¿he instalado algo nuevo? → añádelo a packages/
./scripts/check-packages.sh         # ¿están bien las listas?
git add -A && git commit -m "..." && git push
```

En el otro equipo: `cd ~/dotfiles && git pull && ./bootstrap.sh`.
