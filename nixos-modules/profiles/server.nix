{
  config,
  lib,
  pkgs,
  keys,
  ...
}: {
  config = lib.mkIf config.host.profile.server {
    boot.tmp.cleanOnBoot = true;
    zramSwap.enable = true;

    environment.systemPackages = with pkgs; [
      ghostty.terminfo
    ];

    users.users.root.openssh.authorizedKeys.keys = [keys.sam];
  };
}
