# dotfiles

Mis dotfiles con muchas cosas molonas, KDE Plasma

## Instalar en un equipo nuevo

1. Instala CachyOS desde el pen eligiendo **KDE Plasma** como escritorio.
2. Abre la terminal y pega **este único comando** (te pedirá tu contraseña; no hace falta
   ninguna cuenta):

   ```bash
   sudo pacman -S --needed --noconfirm git && git clone https://github.com/julenster/dotfiles ~/dotfiles && ~/dotfiles/bootstrap.sh
   ```

3. Reinicia.

Si ya tienes el repo, para actualizar:

```bash
cd ~/dotfiles && git pull && ./bootstrap.sh
```

`bootstrap.sh` se puede repetir siempre que quieras: instala solo lo que falte.
