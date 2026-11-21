{
  config,
  lib,
  pkgs,
  keys,
  ...
}:
{
  config = lib.mkIf config.host.profile.server {
    boot.tmp.cleanOnBoot = true;
    zramSwap.enable = true;

    nix = {
      gc = {
        automatic = true;
        dates = "weekly";
        options = "--delete-older-than 30d";
      };
      optimise.automatic = true;
    };

    system = {
      etc.overlay.enable = true;
      tools = {
        nixos-rebuild.enable = false;
        nixos-generate-config.enable = false;
      };
    };

    environment.defaultPackages = [ ];
    documentation = {
      info.enable = false;
      nixos.enable = false;
    };

    services = {
      journald.settings.Journal.SystemMaxUse = "500M";
      userborn.enable = true;

      openssh.hostKeys = [
        {
          path = "/var/lib/ssh/ssh_host_ed25519_key";
          type = "ed25519";
        }
        {
          path = "/var/lib/ssh/ssh_host_rsa_key";
          type = "rsa";
          bits = 4096;
        }
      ];

      closured.enable = true;
      monitoring-agent.enable = true;
      tailscale-auth.enable = true;
    };

    environment.systemPackages = with pkgs; [
      ghostty.terminfo
      (lib.lowPrio gitMinimal)
    ];

    users.users.root.openssh.authorizedKeys.keys = [ keys.sam ];
  };
}
