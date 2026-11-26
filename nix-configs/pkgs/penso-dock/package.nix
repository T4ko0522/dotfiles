{
  adwaita-icon-theme,
  coreutils,
  fetchFromGitHub,
  gdk-pixbuf,
  glib,
  gobject-introspection,
  gtk3,
  hicolor-icon-theme,
  lib,
  librsvg,
  makeWrapper,
  python3,
  qt6,
  quickshell,
  stdenvNoCC,
  showDelayMs ? 130,
  hideDelayMs ? 650,
  slideDurationMs ? 240,
}: let
  # Dock requires Quickshell 0.3.2. Use the newer release only for Dock.
  dockQuickshell = quickshell.overrideAttrs (_: {
    version = "0.3.2";
    src = fetchFromGitHub {
      owner = "quickshell-mirror";
      repo = "quickshell";
      tag = "v0.3.2";
      hash = "sha256-lPbqsyAD5ZoGFMZ1eqAlTULfeP5Nwhy+XvOowF7BE+E=";
    };
  });
  dockPython = python3.withPackages (ps: [ps.pygobject3 ps.pillow]);
in
  stdenvNoCC.mkDerivation {
    pname = "penso-dock";
    version = "0.1.0-unstable-2026-10-14";

    src = fetchFromGitHub {
      owner = "penso";
      repo = "dock";
      rev = "ed4284d4b57b33214deaf3cfd7f3c3e66280d239";
      hash = "sha256-0ScTbX4DomA7sZhJj8CuXzsDY7n7RpsyoRKpfDrhNjE=";
    };

    patches = [
      ./bottom-edge-hotspot.patch
      ./disable-hover-previews.patch
      ./liquid-glass.patch
    ];

    nativeBuildInputs = [gobject-introspection makeWrapper qt6.qtshadertools];
    buildInputs = [gdk-pixbuf glib gtk3];
    dontBuild = true;
    dontWrapQtApps = true;

    postPatch = ''
      substituteInPlace qml/shell.qml \
        --replace-fail 'id: revealDelay; interval: 130' 'id: revealDelay; interval: ${toString showDelayMs}' \
        --replace-fail 'id: hideDelay; interval: 650' 'id: hideDelay; interval: ${toString hideDelayMs}' \
        --replace-fail 'duration: 240; easing.type: Easing.OutCubic' 'duration: ${toString slideDurationMs}; easing.type: Easing.InOutCubic'
    '';

    preInstall = ''
      qsb --glsl "100 es,120,150" -o qml/shaders/liquid-glass.frag.qsb ${./liquid-glass.frag}
    '';

    installPhase = ''
      runHook preInstall

      install -Dm755 bin/dock "$out/bin/dock"
      install -d "$out/share/dock"
      cp -r bin config qml "$out/share/dock/"
      install -Dm644 packaging/dock.desktop "$out/share/applications/io.github.penso.dock.desktop"
      install -Dm644 qml/icons/application.svg "$out/share/icons/hicolor/scalable/apps/dock.svg"
      install -Dm644 LICENSE "$out/share/licenses/penso-dock/LICENSE"

      wrapProgram "$out/bin/dock" \
        --prefix PATH : "${lib.makeBinPath [coreutils dockPython glib]}" \
        --prefix XDG_DATA_DIRS : "${lib.makeSearchPath "share" [adwaita-icon-theme hicolor-icon-theme]}" \
        --prefix GI_TYPELIB_PATH : "$GI_TYPELIB_PATH" \
        --set GDK_PIXBUF_MODULE_FILE "${librsvg}/${gdk-pixbuf.binaryDir}/loaders.cache" \
        --set-default DOCK_QUICKSHELL "${lib.getExe dockQuickshell}" \
        --set-default DOCK_DBUS_PYTHON "${dockPython}/bin/python3" \
        --set-default DOCK_ICON_PYTHON "${dockPython}/bin/python3"

      runHook postInstall
    '';

    meta = {
      description = "Application dock for Wayland desktops";
      homepage = "https://github.com/penso/dock";
      license = lib.licenses.mit;
      mainProgram = "dock";
      platforms = lib.platforms.linux;
    };
  }
