{
  stdenv,
  swift,
  apple-sdk_14,
}: stdenv.mkDerivation {
  pname = "omniwm-overview";
  version = "0.1.0";

  src = ./.;
  nativeBuildInputs = [swift];
  buildInputs = [apple-sdk_14];
  dontStrip = true;

  buildPhase = ''
    runHook preBuild
    swiftc -O -swift-version 5 -target arm64-apple-macosx14.0 \
      -framework AppKit -framework ScreenCaptureKit \
      Overview.swift -o OmniWMOverview
    swiftc -O -swift-version 5 -parse-as-library -target arm64-apple-macosx14.0 \
      -framework AppKit -framework IOKit \
      Gestures.swift -o omniwm-overview-gestures
    runHook postBuild
  '';

  installPhase = ''
    runHook preInstall
    app="$out/Applications/OmniWMOverview.app"
    mkdir -p "$app/Contents/MacOS" "$out/bin"
    install -m755 OmniWMOverview "$app/Contents/MacOS/OmniWMOverview"
    install -m644 Info.plist "$app/Contents/Info.plist"
    install -m755 omniwm-overview-gestures "$out/bin/omniwm-overview-gestures"
    cat > "$out/bin/omniwm-overview" <<EOF
    #!${stdenv.shell}
    exec /usr/bin/open -g -a "$app" "omniwm-overview://\''${1:-toggle}"
    EOF
    chmod +x "$out/bin/omniwm-overview"
    runHook postInstall
  '';

  meta = {
    description = "Native-resolution workspace overview for OmniWM";
    mainProgram = "omniwm-overview";
    platforms = ["aarch64-darwin"];
  };
}
