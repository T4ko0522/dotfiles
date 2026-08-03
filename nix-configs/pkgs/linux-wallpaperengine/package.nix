{linux-wallpaperengine}:
linux-wallpaperengine.overrideAttrs (old: {
  patches = (old.patches or []) ++ [./capture-before-fullscreen-pause.patch];
})
