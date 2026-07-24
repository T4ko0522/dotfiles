{
  localPackages,
  pkgs,
  ...
}: {
  home.packages = with pkgs; [
    rustup
    nodejs
    localPackages.vitePlus
    deno
    bun
    python3
    uv
    zig
    golangci-lint
    hyperfine
    kubectl
    pnpm
    qmk
    gcc-arm-embedded
    dfu-util
    avrdude
    terraform
    yarn
  ];
}
