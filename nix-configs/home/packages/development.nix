{pkgs, ...}: {
  home.packages = with pkgs; [
    rustup
    nodejs
    (pkgs.callPackage ../../pkgs/vite-plus/package.nix {})
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
