{pkgs, ...}: {
  home.packages = with pkgs; [
    go
    rustup
    nodejs
    deno
    bun
    python3
    uv
    zig
    golangci-lint
    hyperfine
    kubectl
    pnpm
    terraform
    yarn
  ];
}
