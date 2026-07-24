{
  fetchFromGitHub,
  vimUtils,
}:
vimUtils.buildVimPlugin {
  pname = "winresizer";
  version = "2026-07-15";
  src = fetchFromGitHub {
    owner = "simeji";
    repo = "winresizer";
    rev = "299076f7f79e2e2f7706b2dfacbb3c074ce53257";
    hash = "sha256-rTTe6hFgEz9CFPJFDUjoD3SQr97V5E5Lg6J4c8mU+6s=";
  };
}
