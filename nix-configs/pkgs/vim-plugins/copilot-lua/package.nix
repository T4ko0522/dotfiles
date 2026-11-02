{
  fetchFromGitHub,
  vimPlugins,
}:
vimPlugins.copilot-lua.overrideAttrs (_: {
  # v2.0.4 moved; the original release commit matches nixpkgs' source hash.
  src = fetchFromGitHub {
    owner = "zbirenbaum";
    repo = "copilot.lua";
    rev = "407349117f176789df6ec1c23bca72f34e15b4e8";
    hash = "sha256-+hQ4Og0ZZS/tvs4z5733qRu5+W4D24HgHHPIL5vd0Eo=";
  };
})
