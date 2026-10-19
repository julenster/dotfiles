// layout.js — paneles de Plasma (sustituyen a la barra de Caelestia, que se quitó porque bajaba
// el rendimiento en juegos). Lo ejecuta kde/apply.sh con evaluateScript de plasmashell
// (sustituye @LAUNCHERS@ por las apps del dock en un equipo nuevo). Borra los paneles que haya y crea dos:
//   - arriba: menú | escritorios | reloj centrado | bandeja
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

// --- Barra superior (solo en el monitor principal) ---
var top = new Panel();
top.screen = 0;
top.location = "top";
top.height = 34;
top.floating = true;
top.hiding = "none";
top.lengthMode = "fill";

var menu = top.addWidget("org.kde.plasma.kickoff");
menu.currentConfigGroup = ["General"];
menu.writeConfig("icon", "start-here-kde-symbolic");

top.addWidget("org.kde.plasma.pager");
top.addWidget("org.kde.plasma.panelspacer");

var clock = top.addWidget("org.kde.plasma.digitalclock");
clock.currentConfigGroup = ["Appearance"];
clock.writeConfig("showDate", true);
clock.writeConfig("dateDisplayFormat", "BesideTime");

top.addWidget("org.kde.plasma.panelspacer");
top.addWidget("org.kde.plasma.systemtray");

// --- Dock ---
var dock = new Panel();
dock.screen = 0;
dock.location = "bottom";
dock.height = 52;
dock.floating = true;
dock.hiding = "dodgewindows";
dock.lengthMode = "fit";
dock.alignment = "center";

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
