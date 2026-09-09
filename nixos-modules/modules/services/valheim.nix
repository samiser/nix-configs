{
  config,
  lib,
  pkgs,
  ...
}:
let
  cfg = config.services.valheim;
  stateDir = "/var/lib/valheim";
  serverDir = "${stateDir}/server";
  port = 2456;

  updateScript = pkgs.writeShellScript "valheim-update" ''
    set -euo pipefail
    exec ${lib.getExe pkgs.steamcmd} \
      +force_install_dir ${serverDir} \
      +login anonymous \
      +app_update 896660 \
      +quit
  '';

  startScript = pkgs.writeShellScript "valheim-server" ''
    set -euo pipefail
    cd ${serverDir}
    exec ${lib.getExe pkgs.steam-run} ./valheim_server.x86_64 \
      -name ${lib.escapeShellArg cfg.serverName} \
      -world ${lib.escapeShellArg cfg.worldName} \
      -port ${toString port} \
      -savedir ${stateDir}/save \
      -public 0 \
      -password "$(< "$CREDENTIALS_DIRECTORY/password")"
  '';
in
{
  options.services.valheim = {
    enable = lib.mkEnableOption "Valheim dedicated server";

    serverName = lib.mkOption {
      type = lib.types.str;
      description = "Name shown in the server browser";
    };

    worldName = lib.mkOption {
      type = lib.types.str;
      description = "World save name";
    };

    passwordFile = lib.mkOption {
      type = lib.types.path;
      description = "File containing the server password";
    };
  };

  config = lib.mkIf cfg.enable {
    users = {
      users.valheim = {
        isSystemUser = true;
        group = "valheim";
        home = stateDir;
      };
      groups.valheim = { };
    };

    networking.firewall.allowedUDPPorts = [
      port
      (port + 1)
    ];

    systemd.services.valheim = {
      description = "Valheim Dedicated Server";
      wantedBy = [ "multi-user.target" ];
      wants = [ "network-online.target" ];
      after = [ "network-online.target" ];

      environment = {
        HOME = stateDir;
        SteamAppId = "892970";
        LD_LIBRARY_PATH = "${serverDir}/linux64";
      };

      serviceConfig = {
        User = "valheim";
        Group = "valheim";
        StateDirectory = "valheim";
        WorkingDirectory = stateDir;
        LoadCredential = "password:${cfg.passwordFile}";
        ExecStartPre = updateScript;
        ExecStart = startScript;
        KillSignal = "SIGINT";
        TimeoutStopSec = 120;
        Restart = "on-failure";
        RestartSec = 10;
      };
    };
  };
}
