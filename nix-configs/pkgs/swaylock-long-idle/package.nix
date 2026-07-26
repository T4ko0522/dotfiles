{swaylock}:
swaylock.overrideAttrs (old: {
  postPatch =
    (old.postPatch or "")
    + ''
      substituteInPlace password.c \
        --replace-fail "state->eventloop, 1500, set_input_idle, state" \
        "state->eventloop, 10000, set_input_idle, state"
    '';
})
