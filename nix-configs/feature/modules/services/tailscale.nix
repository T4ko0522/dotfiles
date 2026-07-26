{
  services.tailscale.enable = true;

  networking.firewall.trustedInterfaces = ["tailscale0"];
  networking.firewall.allowedUDPPorts = [41641];
}
