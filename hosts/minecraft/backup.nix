{
  config,
  lib,
  pkgs,
  ...
}:
let
  mcEnabled = config.services.minecraft-servers.servers.minecraft.enable;
  backupDir = "/var/lib/minecraft-backups";

  backupScript = pkgs.writeShellScript "minecraft-backup" ''
    set -euo pipefail
    export PATH="${pkgs.gzip}/bin:${pkgs.gnutar}/bin:${pkgs.coreutils}/bin:${pkgs.findutils}/bin:$PATH"

    TIMESTAMP=$(date +%Y-%m-%d_%H-%M-%S)
    BACKUP_FILE="${backupDir}/world-$TIMESTAMP.tar.gz"

    mkdir -p ${backupDir}

    # Create compressed backup
    tar -czf "$BACKUP_FILE" -C /srv/minecraft/minecraft world

    # Keep only the last 7 backups
    ls -t ${backupDir}/world-*.tar.gz 2>/dev/null | tail -n +8 | xargs -r rm -f

    echo "Backup created: $BACKUP_FILE"
  '';
in
{
  systemd.services.minecraft-backup = lib.mkIf mcEnabled {
    description = "Minecraft World Backup";
    serviceConfig = {
      Type = "oneshot";
      ExecStart = backupScript;
    };
  };

  systemd.timers.minecraft-backup = lib.mkIf mcEnabled {
    description = "Minecraft World Backup Timer";
    wantedBy = [ "timers.target" ];
    timerConfig = {
      OnCalendar = "daily";
      Persistent = true;
    };
  };

  # Serve backups via Caddy (mkBefore so it comes before the catch-all handle)
  services.caddy.virtualHosts."mc.samiser.xyz".extraConfig = pkgs.lib.mkBefore ''
    handle_path /backups/* {
      root * ${backupDir}
      file_server browse
    }
  '';
}
