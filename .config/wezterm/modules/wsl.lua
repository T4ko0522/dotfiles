local module = {}

function module.apply_to_config(config)
  config.wsl_domains = {
    {
      name = "WSL:Arch",
      distribution = "Arch",
      default_cwd = "~",
    },
  }
end

return module
