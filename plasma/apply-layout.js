// Initial PhantomOS Plasma layout. Called by install.sh through plasmashell's
// scripting API after the user's current panel file has been backed up.
var phantomWallpaper = "__PHANTOM_WALLPAPER_URI__";
var phantomStartUrl = "__PHANTOM_START_URI__";

desktops().forEach(function (desktop) {
    desktop.wallpaperPlugin = "org.kde.image";
    desktop.currentConfigGroup = ["Wallpaper", "org.kde.image", "General"];
    desktop.writeConfig("Image", phantomWallpaper);
    desktop.reloadConfig();
});

panels().slice().forEach(function (panel) {
    panel.remove();
});

for (var screen = 0; screen < screenCount; screen++) {
    var panel = new Panel;
    panel.screen = screen;
    if (panel.screen !== screen) {
        panel.remove();
        print("PhantomOS: unable to assign panel to display " + screen);
        continue;
    }

    panel.location = "top";
    panel.height = 36;
    panel.lengthMode = "fill";

    var kickoff = panel.addWidget("org.kde.plasma.icon");
    kickoff.currentConfigGroup = ["General"];
    kickoff.writeConfig("url", phantomStartUrl);
    kickoff.reloadConfig();

    panel.addWidget("org.kde.plasma.pager");
    panel.addWidget("org.kde.plasma.panelspacer");
    panel.addWidget("org.kde.plasma.systemtray");
    panel.addWidget("org.kde.plasma.digitalclock");
}
