{
  fetchFromGitHub,
  vimUtils,
}:
vimUtils.buildVimPlugin {
  pname = "vimdoc-ja";
  version = "2026-07-15";
  src = fetchFromGitHub {
    owner = "vim-jp";
    repo = "vimdoc-ja";
    rev = "c8c3b339302b4e88be2859b3ba99a4f0a3a2f8bd";
    hash = "sha256-362QsKxCbqXrOru3p+ReoqtfwTLSSblNGzzxTE2DWoI=";
  };
}
