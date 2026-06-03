{pkgs, ...}: {
  services.udev.packages = with pkgs; [
    qmk-udev-rules
  ];

  services.udev.extraRules = ''
    # Corne v4 Vial raw HID access.
    SUBSYSTEM=="hidraw", ATTRS{idVendor}=="4653", ATTRS{idProduct}=="0004", MODE="0660", GROUP="users", TAG+="uaccess"
  '';
}
