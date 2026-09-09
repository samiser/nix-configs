let
  keys = import ../shared-modules/keys.nix;
  inherit (keys)
    sam
    nix-lab
    minecraft
    jelly
    radar
    argus
    yidhra
    ;

  servers = [
    nix-lab
    minecraft
    jelly
    radar
    argus
  ];
in
builtins.mapAttrs (_: hostKeys: { publicKeys = [ sam ] ++ hostKeys; }) {
  "hcloud-token.age" = [ ];
  "caddy-cloudflare-key.age" = [
    nix-lab
    minecraft
    jelly
  ];
  "ssc-secrets.age" = [ nix-lab ];
  "miniflux-admin-credentials.age" = [ nix-lab ];
  "storagebox-credentials.age" = [
    nix-lab
    jelly
    radar
  ];
  "tailscale-auth-key.age" = servers;
  "grafana-secret-key.age" = [ argus ];
  "mullvad-privkey.age" = [ radar ];
  "markovi-discord-token.age" = [ nix-lab ];
  "attic-jwt-secret.age" = [ nix-lab ];
  "github-runner-sambee.age" = [ nix-lab ];
  "nixpkgs-update-token.age" = [ yidhra ];
  "nixpkgs-update-ssh-key.age" = [ yidhra ];
  "valheim-password.age" = [ minecraft ];
}
