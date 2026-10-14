{
  config,
  lib,
  pkgs,
  ...
}:
let
  caddyCfg = config.services.caddy;
in
{
  config = lib.mkIf caddyCfg.enable {
    networking.firewall = {
      allowedTCPPorts = [
        80
        443
      ];
      allowedUDPPorts = [ 443 ];
    };

    age.secrets.caddy-cloudflare-key = {
      file = ../../../secrets/caddy-cloudflare-key.age;
      owner = caddyCfg.user;
      inherit (caddyCfg) group;
    };

    systemd.services.caddy.serviceConfig = {
      EnvironmentFile = config.age.secrets.caddy-cloudflare-key.path;
    };

    services.caddy.package = pkgs.caddy.withPlugins {
      plugins = [ "github.com/caddy-dns/cloudflare@v0.2.2" ];
      hash = "sha256-UPd4CWjm8Cq5EZ9OkBCglE23hD8+przFBSw8Ey6zMz8=";
    };
  };
}
