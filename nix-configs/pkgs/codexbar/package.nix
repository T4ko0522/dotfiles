{
  coreutils,
  curl,
  fetchFromGitHub,
  gnused,
  jq,
  lib,
  libnotify,
  makeWrapper,
  stdenvNoCC,
}:
stdenvNoCC.mkDerivation {
  pname = "codexbar";
  version = "unstable-2026-07-13";

  src = fetchFromGitHub {
    owner = "mryll";
    repo = "codexbar";
    rev = "c00cd586c25cfe0b3149fdcfa33153c7df9e88b9";
    hash = "sha256-wZhSYrDoLCQQvxXz9NIsp8n1+YIXlGZNGfBwvZEIAZk=";
  };

  nativeBuildInputs = [makeWrapper];

  dontBuild = true;

  installPhase = ''
    runHook preInstall

    install -Dm755 codexbar "$out/bin/codexbar"
    wrapProgram "$out/bin/codexbar" \
      --prefix PATH : ${lib.makeBinPath [
      coreutils
      curl
      gnused
      jq
      libnotify
    ]}

    runHook postInstall
  '';

  meta = {
    description = "Waybar widget for OpenAI Codex usage limits";
    homepage = "https://github.com/mryll/codexbar";
    license = lib.licenses.mit;
    mainProgram = "codexbar";
    platforms = lib.platforms.linux;
  };
}
