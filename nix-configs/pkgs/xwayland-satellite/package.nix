{
  fetchpatch,
  xwayland-satellite,
}:
xwayland-satellite.overrideAttrs (old: {
  patches =
    (old.patches or [])
    ++ [
      (fetchpatch {
        url = "https://github.com/Supreeeme/xwayland-satellite/commit/add2795134593faafce60e404a0a75df68e9ee0c.patch";
        hash = "sha256-/1zJYAIHC+xiVytHH5HDt83lZKLBGQQdAoS/y2ObTLc=";
      })
    ];
})
