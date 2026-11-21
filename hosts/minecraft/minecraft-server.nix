{
  pkgs,
  nix-minecraft,
  sharedLib,
  ...
}:
let
  inherit (sharedLib) cloudflareTls;
  players = {
    "real_bean" = "ba5f35d3-c04a-4ec0-820c-14172299ea41";
    "legoboomey" = "401835f5-b512-455a-9a0d-e09d9241542a";
    "leafeater69" = "58312496-a917-4a6b-94ba-5fdc56af610b";
    "AbbiePlum" = "500488ec-1774-4f91-b89e-fce1a4569165";
    "Nightshroud" = "933c09bb-2de6-44a7-a9a2-866d48bf71ec";
  };
in
{
  imports = [
    nix-minecraft.nixosModules.minecraft-servers
  ];

  nixpkgs.overlays = [ nix-minecraft.overlay ];
  services = {
    minecraft-servers = {
      enable = true;
      eula = true;

      servers.minecraft = {
        enable = true;
        package = pkgs.paperServers.paper;
        openFirewall = true;

        serverProperties = {
          server-port = 25565;
          difficulty = "normal";
          gamemode = "survival";
          max-players = 20;
          motd = "\\u00A7bsam's \\u00A7ocool\\u00A7r\\u00A7b server :)";
          white-list = true;
          enable-command-block = true;
          level-seed = "lol";
        };

        whitelist = players;
        operators = players;

        symlinks = {
          "plugins/dead-chest.jar" = pkgs.fetchurl {
            url = "https://cdn.modrinth.com/data/pKqnV03Y/versions/mBSgqYZH/dead-chest-4.30.0.jar";
            sha256 = "sha256-iMbxkSxw7koTzLrUcVpX44ohjqaT6PYI/9StO/RZcF4=";
          };
          "plugins/bluemap.jar" = pkgs.fetchurl {
            url = "https://github.com/BlueMap-Minecraft/BlueMap/releases/download/v5.15/bluemap-5.15-paper.jar";
            sha256 = "sha256-FgWc3yM8CqDS2n2Lat0eOyCQfxokE0zCB/VX18Gy444=";
          };
          "plugins/worldedit.jar" = pkgs.fetchurl {
            url = "https://hangarcdn.papermc.io/plugins/EngineHub/WorldEdit/versions/7.4.0/PAPER/worldedit-bukkit-7.4.0.jar";
            sha256 = "sha256-KEGOxSIjeFrT3bD6u+00YOrLf9nXd0yEL0Q/tcf7STc=";
          };
          "plugins/treeforce.jar" = pkgs.fetchurl {
            url = "https://hangarcdn.papermc.io/plugins/demi/TreeForce/versions/1.0/PAPER/TreeForce-1.0.jar";
            sha256 = "sha256-FJcqyQQE/UU9jdkAoD62RRvb3QuQb15qwf7luOXcQpA=";
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
          "plugins/BlueMap/maps/world_nether.conf" = pkgs.writeText "world_nether.conf" ''
            world: "world"
            dimension: "minecraft:the_nether"
            sorting: 100
          '';
          "plugins/BlueMap/maps/world_the_end.conf" = pkgs.writeText "world_the_end.conf" ''
            world: "world"
            dimension: "minecraft:the_end"
            sorting: 200
          '';
        };

        files = {
          "plugins/DeadChest/config.yml".value = {
            chest."duration-seconds" = 0;
            updates."auto-check" = false;
          };
        };

        jvmOpts = "-Dpaperclip.patchdir=./cache -Xms6G -Xmx6G";
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
