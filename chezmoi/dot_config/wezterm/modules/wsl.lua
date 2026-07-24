local module = {}

function module.apply_to_config(config)
  config.wsl_domains = {
    {
      name = "WSL:NixOS",
      distribution = "NixOS",
      default_cwd = "~",
    },
  }
end

return module
