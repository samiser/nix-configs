{ config, ... }:
{
  imports = [
    ./hardware-configuration.nix
    ./boot.nix
    ./nvidia.nix
    ./audio.nix
    ./tailscale.nix
  ];

  host.profile = {
    desktop = true;
    dev = true;
  };

  services.displayManager.noctalia-greeter.settings.keyboard.layout = "us";

  services = {
    closured.enable = true;

    nix-update = {
      enable = true;
      githubUser = "samiser";
      gitAuthor = {
        name = "Samiser";
        email = "github@me.samiser.xyz";
      };
      tokenFile = config.age.secrets.nixpkgs-update-token.path;
      sshKeyFile = config.age.secrets.nixpkgs-update-ssh-key.path;
      packages = [
        { name = "hyprmag"; }
        { name = "noctalia-greeter"; }
        { name = "omniwm"; }
        {
          name = "noctalia";
          versionPreference = "unstable";
        }
      ];
      createPullRequests = true;
    };
  };

  networking = {
    interfaces = {
      enp4s0 = {
        wakeOnLan.enable = true;
      };
    };
    firewall = {
      allowedUDPPorts = [ 9 ];
    };
  };

  networking.hostName = "yidhra";

  system.stateVersion = "26.05";
}
