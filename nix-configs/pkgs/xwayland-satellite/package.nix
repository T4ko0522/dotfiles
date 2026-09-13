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
        hash = "sha256-XD93f8m8h0o0Vs3QcmWkHGGi5mZwf9wkx9qEiq6sjnw=";
      })
    ];
})
