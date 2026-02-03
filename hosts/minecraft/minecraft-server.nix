{
  pkgs,
  nix-minecraft,
  ...
}: let
  inherit (import ../../shared-modules/lib.nix) cloudflareTls;
in {
  imports = [
    nix-minecraft.nixosModules.minecraft-servers
    nix-minecraft.nixosModules.minecraft-lazymc
  ];

  nixpkgs.overlays = [nix-minecraft.overlay];
  services = {
    minecraft-servers = {
      enable = true;
      eula = true;

      servers.minecraft = {
        enable = true;
        package = pkgs.paperServers.paper;
        openFirewall = false;

        serverProperties = {
          server-port = 25566;
          difficulty = "normal";
          gamemode = "survival";
          max-players = 20;
          motd = "\\u00A7bsam's \\u00A7ocool\\u00A7r\\u00A7b server :)";
          white-list = true;
          enable-command-block = true;
        };

        whitelist = {
          "real_bean" = "ba5f35d3-c04a-4ec0-820c-14172299ea41";
          "legoboomey" = "401835f5-b512-455a-9a0d-e09d9241542a";
          "leafeater69" = "58312496-a917-4a6b-94ba-5fdc56af610b";
          "AbbiePlum" = "500488ec-1774-4f91-b89e-fce1a4569165";
          "Nightshroud" = "933c09bb-2de6-44a7-a9a2-866d48bf71ec";
        };

        operators = {
          "real_bean" = "ba5f35d3-c04a-4ec0-820c-14172299ea41";
        };

        symlinks = {
          "plugins/dead-chest.jar" = pkgs.fetchurl {
            url = "https://mediafilez.forgecdn.net/files/6999/10/dead-chest-4.23.0.jar";
            sha256 = "sha256-5bp7Uuxpr0LH5Oy/9f4SWDzpQ4QW7kXSzID+l4lFdWE=";
          };
          "plugins/bluemap.jar" = pkgs.fetchurl {
            url = "https://github.com/BlueMap-Minecraft/BlueMap/releases/download/v5.15/bluemap-5.15-paper.jar";
            sha256 = "sha256-FgWc3yM8CqDS2n2Lat0eOyCQfxokE0zCB/VX18Gy444=";
          };
          "plugins/BlueMap/webserver.conf" = pkgs.writeText "webserver.conf" ''
            enabled: true
            webroot: "bluemap/web"
            ip: "127.0.0.1"
            port: 8100
          '';
          "plugins/BlueMap/core.conf" = pkgs.writeText "core.conf" ''
            accept-download: true
          '';
        };

        files = {
          "plugins/DeadChest/config.yml".value = {
            DeadChestDuration = 0;
          };
        };

        jvmOpts = "-Dpaperclip.patchdir=./cache -Xms6G -Xmx6G";
      };
    };

    minecraft-lazymc.servers.minecraft = {
      enable = true;
      publicAddress = "0.0.0.0:25565";
      openFirewall = true;
      extraConfig = {
        time.sleep_after = 300; # 5 minutes idle
        motd.sleeping = "§3§oserver is sleepy... connect to wake it up...";
        server.directory = "/srv/minecraft/minecraft";
        # https://minecraft.wiki/w/Protocol_version
        public.version = "Paper 1.21.11";
        public.protocol = 774;
      };
    };

    caddy.virtualHosts."mc.samiser.xyz".extraConfig = cloudflareTls ''
      reverse_proxy localhost:8100 {
        fail_duration 10s
      }
      handle_errors {
        respond "Server is sleeping - map unavailable"
      }
    '';
  };
}
