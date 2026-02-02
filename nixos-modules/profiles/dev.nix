{
  config,
  lib,
  pkgs,
  sharedPackages,
  ...
}: {
  config = lib.mkIf config.host.profile.dev {
    environment.systemPackages = sharedPackages.dev {inherit pkgs;};
  };
}
