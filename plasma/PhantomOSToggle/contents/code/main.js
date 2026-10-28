// KWin scripts run inside KWin and can invoke registered global shortcuts.
var workMode = true;

function setPanelsForMode(isWork) {
    var script = "var isWork = " + (isWork ? "true" : "false") + ";\n" +
        "var state = ConfigFile('phantomosrc'); state.group = 'PhantomOS'; state.writeEntry('Mode', isWork ? 'work' : 'relax');\n" +
        "var leftScreen = 0; var rightScreen = 0;\n" +
        "for (var i = 0; i < screenCount; i++) { var area = screenGeometry(i); if (area.x < screenGeometry(leftScreen).x) leftScreen = i; if (area.x > screenGeometry(rightScreen).x) rightScreen = i; }\n" +
        "panels().forEach(function(panel) {\n" +
        "  panel.location = isWork ? 'top' : (panel.screen === leftScreen ? 'left' : 'right');\n" +
        "  panel.widgetIds.slice().forEach(function(id) { var widget = panel.widgetById(id); if (widget && widget.type === 'org.kde.plasma.kickoff') { widget.currentConfigGroup = ['General']; widget.writeConfig('icon', 'phantomos'); widget.reloadConfig(); } });\n" +
        "  panel.height = isWork ? 34 : 54;\n" +
        "  var hasTasks = false;\n" +
        "  panel.widgetIds.slice().forEach(function(id) {\n" +
        "    var widget = panel.widgetById(id);\n" +
        "    if (widget && (widget.type === 'org.kde.plasma.icontasks' || widget.type === 'org.kde.plasma.taskmanager')) {\n" +
        "      hasTasks = true;\n" +
        "      if (isWork) widget.remove();\n" +
        "    }\n" +
        "  });\n" +
        "  if (!isWork && !hasTasks) panel.addWidget('org.kde.plasma.icontasks');\n" +
        "});";
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
        selectEngine(workMode ? "PoloniumSwitchKwin" : "PoloniumSwitchBTree", !workMode);
    }
);
registerShortcut(
    "PhantomOS: Work Mode",
    "Enable PhantomOS automatic tiling",
    "",
    function () { selectEngine("PoloniumSwitchBTree", true); }
);
registerShortcut(
    "PhantomOS: Relax Mode",
    "Enable PhantomOS floating windows",
    "",
    function () { selectEngine("PoloniumSwitchKwin", false); }
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

