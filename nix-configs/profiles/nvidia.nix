{
  config,
  pkgs,
  ...
}: {
  services.xserver.videoDrivers = ["nvidia"];

  hardware.nvidia = {
    modesetting.enable = true;
    open = true;
    nvidiaSettings = true;
    package = config.boot.kernelPackages.nvidiaPackages.stable;
  };

  hardware.graphics.extraPackages = with pkgs; [
    egl-wayland
    libva
    libva-utils
    nvidia-vaapi-driver
  ];

  boot.kernelModules = ["nvidia-uvm"];
  boot.kernelParams = ["nvidia.NVreg_PreserveVideoMemoryAllocations=1"];

  # Limit OpenGL frame queue depth to 1 to reduce input latency on Wayland
  environment.sessionVariables = {
    __GL_MaxFramesAllowed = "1";
    __GLX_VENDOR_LIBRARY_NAME = "nvidia";
    GBM_BACKEND = "nvidia-drm";
    LIBVA_DRIVER_NAME = "nvidia";
  };
}
