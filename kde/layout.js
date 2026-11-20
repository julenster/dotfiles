// layout.js — paneles de Plasma (sustituyen a la barra de Caelestia, que se quitó porque bajaba
// el rendimiento en juegos). Lo ejecuta kde/apply.sh con evaluateScript de plasmashell
// (sustituye @LAUNCHERS@ por las apps del dock en un equipo nuevo). Borra los paneles que haya y crea dos:
//   - arriba: tres píldoras translúcidas (menú + escritorios | reloj | bandeja), estilo Hyprland
//   - abajo: dock flotante centrado que se aparta cuando una ventana lo tapa, con el botón de
//     "mostrar aplicaciones" de GNOME al final (también con Super+A)

// Si ya hay un dock, se conservan sus apps (las que se hayan anclado a mano)
var launchers = "";
panels().forEach(function (p) {
    p.widgets("org.kde.plasma.icontasks").forEach(function (w) {
        w.currentConfigGroup = ["General"];
        launchers = launchers || w.readConfig("launchers", "");
    });
});
if (!launchers) launchers = "@LAUNCHERS@";

panels().forEach(function (p) { p.remove(); });

// --- Barra superior estilo Hyprland/waybar (solo en el monitor principal) ---
// Tres "píldoras" flotantes del tamaño de su contenido en el borde de arriba:
//   izquierda: menú + escritorios (números) | centro: reloj | derecha: bandeja
function pill(alignment) {
    var p = new Panel();
    p.screen = 0;
    p.location = "top";
    p.height = 32;
    p.floating = true;
    p.hiding = "none";
    p.lengthMode = "fit";
    p.alignment = alignment;
    p.opacity = "translucent";   // siempre translúcida (tema klassy-glass de kde/apply.sh)
    return p;
}

var left = pill("left");
var menu = left.addWidget("org.kde.plasma.kickoff");
menu.currentConfigGroup = ["General"];
menu.writeConfig("icon", "start-here-kde-symbolic");
var pager = left.addWidget("org.kde.plasma.pager");
pager.currentConfigGroup = ["General"];
pager.writeConfig("displayedText", "Number");
pager.writeConfig("showWindowIcons", false);

var center = pill("center");
var clock = center.addWidget("org.kde.plasma.digitalclock");
clock.currentConfigGroup = ["Appearance"];
clock.writeConfig("showDate", true);
clock.writeConfig("dateDisplayFormat", "BesideTime");
// 24 h y fecha día/mes: cifras de ancho fijo, así el texto queda centrado en su píldora (en
// 12 h el reloj reserva sitio para "04" pero escribe "4" y sobra hueco a la derecha)
clock.writeConfig("use24hFormat", 2);
clock.writeConfig("dateFormat", "custom");
clock.writeConfig("customDateFormat", "ddd dd/MM");
clock.writeConfig("autoFontAndSize", false);
clock.writeConfig("fontFamily", "JetBrainsMono Nerd Font");   // la de la terminal (kitty)
clock.writeConfig("fontWeight", 400);
clock.writeConfig("fontSize", 10);

var right = pill("right");
right.addWidget("org.kde.plasma.systemtray");
right.addWidget("org.kde.plasma.minimizeall");

// --- Dock ---
var dock = new Panel();
dock.screen = 0;
dock.location = "bottom";
dock.height = 52;
dock.floating = true;
dock.hiding = "dodgewindows";
dock.lengthMode = "fit";
dock.alignment = "center";
dock.opacity = "translucent";

var tasks = dock.addWidget("org.kde.plasma.icontasks");
tasks.currentConfigGroup = ["General"];
tasks.writeConfig("launchers", launchers);
// Mostrar siempre todas las apps abiertas (minimizadas, en el otro monitor o en otro escritorio)
tasks.writeConfig("showOnlyCurrentScreen", false);
tasks.writeConfig("showOnlyCurrentDesktop", false);
tasks.writeConfig("showOnlyMinimized", false);
tasks.writeConfig("groupedTaskVisualization", 1);   // clic en app agrupada: ver sus ventanas

dock.addWidget("org.kde.plasma.marginsseparator");

// Rejilla de apps a pantalla completa con buscador: el botón "mostrar aplicaciones" de GNOME
var grid = dock.addWidget("org.kde.plasma.kickerdash");
grid.currentConfigGroup = ["General"];
grid.writeConfig("icon", "view-app-grid-symbolic");
grid.globalShortcut = "Meta+A";
