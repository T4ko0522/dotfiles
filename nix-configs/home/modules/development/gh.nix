{
  lib,
  pkgs,
  ...
}: let
  scopes = [
    "repo"
    "read:org"
    "gist"
    "project"
    "workflow"
    "admin:ssh_signing_key"
    # write:packages は取得も許可し、GitHub の表示では read:packages が省略される。
    "write:packages"
    "admin:public_key"
  ];
  ghAuthSetup = pkgs.writeShellApplication {
    name = "gh-auth-setup";
    runtimeInputs = [pkgs.gh];
    text = ''
      scopes=${lib.escapeShellArg (lib.concatStringsSep "," scopes)}
      current_scopes=$(gh auth status --active --hostname github.com --json hosts \
        --jq '.hosts["github.com"][] | select(.active and .state == "success") | .scopes' 2>/dev/null || true)

      if [[ -n "$current_scopes" ]]; then
        missing_scope=false
        for scope in ${lib.escapeShellArgs scopes}; do
          if [[ ",''${current_scopes// /}," != *",$scope,"* ]]; then
            missing_scope=true
            break
          fi
        done
        if [[ "$missing_scope" == false ]]; then
          echo "gh already has the declared scopes."
          exit 0
        fi
      fi

      if [[ -n "$current_scopes" ]]; then
        exec gh auth refresh --hostname github.com --scopes "$scopes"
      else
        exec gh auth login --hostname github.com --git-protocol https --scopes "$scopes"
      fi
    '';
  };
in {
  home.packages = [ghAuthSetup];
}
