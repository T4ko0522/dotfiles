{
  config,
  pkgs,
  ...
}: {
  # Intel iGPU (i915) + NVIDIA dGPU の hybrid 環境向け。
  # 外部モニタが NVIDIA 側 output に直結しているため PRIME sync で
  # 両 GPU を同時稼働させ、動画デコードなど VA-API 経路は Intel iGPU に流す。
  services.xserver.videoDrivers = ["nvidia"];

  hardware.nvidia = {
    modesetting.enable = true;
    open = true;
    nvidiaSettings = true;
    package = config.boot.kernelPackages.nvidiaPackages.stable;

    prime = {
      sync.enable = true;
      intelBusId = "PCI:0:2:0";
      nvidiaBusId = "PCI:1:0:0";
    };
  };

  hardware.graphics.extraPackages = with pkgs; [
    egl-wayland
    libva
    libva-utils
    intel-media-driver
    nvidia-vaapi-driver
  ];

  boot.kernelModules = ["nvidia-uvm"];
  boot.kernelParams = ["nvidia.NVreg_PreserveVideoMemoryAllocations=1"];

  environment.sessionVariables = {
    __GL_MaxFramesAllowed = "1";
    __GLX_VENDOR_LIBRARY_NAME = "nvidia";
    LIBVA_DRIVER_NAME = "iHD";
  };
}
