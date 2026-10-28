// KWin scripts run inside KWin and can invoke registered global shortcuts.
var workMode = true;

function setPanelsForMode(isWork) {
    var script = "var isWork = " + (isWork ? "true" : "false") + ";\n" +
        "var state = ConfigFile('phantomosrc'); state.group = 'PhantomOS'; state.writeEntry('Mode', isWork ? 'work' : 'relax');\n" +
        "var leftScreen = 0; var rightScreen = 0;\n" +
        "for (var i = 0; i < screenCount; i++) { var area = screenGeometry(i); if (area.x < screenGeometry(leftScreen).x) leftScreen = i; if (area.x > screenGeometry(rightScreen).x) rightScreen = i; }\n" +
        "function configurePanel(panel) {\n" +
        "  panel.location = isWork ? 'top' : (panel.screen === leftScreen ? 'left' : 'right'); panel.height = isWork ? 34 : 54;\n" +
        "  var hasTasks = false;\n" +
        "  panel.widgetIds.slice().forEach(function(id) { var widget = panel.widgetById(id); if (!widget) return;\n" +
        "    if (widget.type === 'org.kde.plasma.kickoff') { widget.currentConfigGroup = ['General']; widget.writeConfig('icon', 'phantomos'); widget.reloadConfig(); }\n" +
        "    if (widget.type === 'org.kde.plasma.icontasks' || widget.type === 'org.kde.plasma.taskmanager') { hasTasks = true; if (isWork) widget.remove(); }\n" +
        "  });\n" +
        "  if (!isWork && !hasTasks) panel.addWidget('org.kde.plasma.icontasks');\n" +
        "}\n" +
        "var existing = panels(); var covered = {};\n" +
        "existing.forEach(function(panel) { if (panel.screen >= 0) covered[panel.screen] = true; configurePanel(panel); });\n" +
        "for (var screen = 0; screen < screenCount; screen++) { if (covered[screen]) continue;\n" +
        "  if (parseFloat(applicationVersion) < 6.3) { print('PhantomOS: Plasma 6.3+ is required to create a panel on a specific screen.'); continue; }\n" +
        "  var panel = new Panel; panel.screen = screen;\n" +
        "  if (panel.screen !== screen) { panel.remove(); print('PhantomOS: could not assign a new panel to screen ' + screen); continue; }\n" +
        "  panel.addWidget('org.kde.plasma.kickoff'); panel.addWidget('org.kde.plasma.marginsseparator');\n" +
        "  if (!isWork) panel.addWidget('org.kde.plasma.icontasks');\n" +
        "  panel.addWidget('org.kde.plasma.systemtray'); panel.addWidget('org.kde.plasma.digitalclock'); configurePanel(panel);\n" +
        "}\n" +
        "";
    callDBus("org.kde.plasmashell", "/PlasmaShell", "org.kde.PlasmaShell", "evaluateScript", script);
}

function selectEngine(shortcut, nextMode) {
    callDBus(
        "org.kde.kglobalaccel",
        "/component/kwin",
        "org.kde.kglobalaccel.Component",
        "invokeShortcut",
        shortcut
    );
    workMode = nextMode;
    setPanelsForMode(nextMode);
    callDBus("org.freedesktop.Notifications", "/org/freedesktop/Notifications", "org.freedesktop.Notifications", "Notify", "PhantomOS", 0, "preferences-desktop", "PhantomOS", nextMode ? "Work mode: tiled windows" : "Relax mode: floating windows", [], {}, 1800);
}

registerShortcut(
    "PhantomOS: Toggle Work/Relax",
    "Switch between PhantomOS tiled and floating modes",
    "Meta+Tab",
    function () {
        selectEngine(workMode ? "PoloniumSetEngineKWin" : "PoloniumSetEngineBTree", !workMode);
    }
);
registerShortcut(
    "PhantomOS: Work Mode",
    "Enable PhantomOS automatic tiling",
    "",
    function () { selectEngine("PoloniumSetEngineBTree", true); }
);
registerShortcut(
    "PhantomOS: Relax Mode",
    "Enable PhantomOS floating windows",
    "",
    function () { selectEngine("PoloniumSetEngineKWin", false); }
);
registerShortcut(
    "PhantomOS: Open Terminal",
    "Open Konsole",
    "Meta+Q",
    function () {
        callDBus("org.freedesktop.DBus", "/org/freedesktop/DBus", "org.freedesktop.DBus", "StartServiceByName", "org.kde.konsole", 0);
    }
);
registerShortcut(
    "PhantomOS: Open File Manager",
    "Open Dolphin",
    "Meta+E",
    function () {
        callDBus("org.freedesktop.DBus", "/org/freedesktop/DBus", "org.freedesktop.DBus", "StartServiceByName", "org.kde.dolphin", 0);
    }
);

