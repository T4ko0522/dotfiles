{config, ...}: {
  services.xserver.videoDrivers = ["nvidia"];

  hardware.nvidia = {
    modesetting.enable = true;
    open = true;
    nvidiaSettings = true;
    package = config.boot.kernelPackages.nvidiaPackages.stable;
  };

  # Limit OpenGL frame queue depth to 1 to reduce input latency on Wayland
  environment.sessionVariables.__GL_MaxFramesAllowed = "1";
}
