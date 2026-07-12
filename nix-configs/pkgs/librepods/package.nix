{
  appimageTools,
  fetchurl,
  lib,
}: let
  pname = "librepods";
  version = "0.1.0";

  src = fetchurl {
    url = "https://github.com/librepods-org/librepods/releases/download/linux-v${version}/librepods-x86_64.AppImage";
    hash = "sha256-BWm6mhWqWOZg7DzLTS05/9iADWpdo3QYAq79hv1LVaY=";
  };

  appimageContents = appimageTools.extractType2 {
    inherit pname version src;
  };
in
  appimageTools.wrapType2 {
    inherit pname version src;

    profile = ''
      export WGPU_BACKEND=gl
    '';

    extraInstallCommands = ''
      install -Dm444 ${appimageContents}/librepods.desktop $out/share/applications/librepods.desktop
      install -Dm444 ${appimageContents}/me.kavishdevar.librepods.png \
        $out/share/icons/hicolor/512x512/apps/me.kavishdevar.librepods.png
    '';

    meta = {
      description = "AirPods feature controller for Linux";
      homepage = "https://github.com/librepods-org/librepods";
      license = lib.licenses.gpl3Only;
      mainProgram = "librepods";
      platforms = ["x86_64-linux"];
      sourceProvenance = with lib.sourceTypes; [binaryNativeCode];
    };
  }
