{swaynotificationcenter}:
swaynotificationcenter.overrideAttrs (old: {
  patches = (old.patches or []) ++ [./swaync-control-center-slide.patch];
  postPatch =
    (old.postPatch or "")
    + ''
      substituteInPlace data/ui/notification.blp \
        --replace-fail "transition-type: crossfade;" "transition-type: slide_right;"
    '';
})
