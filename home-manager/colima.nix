{
  lib,
  config,
  ...
}:
with lib; let
  cfg = config.sam.colima;
in {
  options.sam.colima.enable = mkEnableOption "colima container runtime";

  config = mkIf cfg.enable {
    services.colima = {
      enable = true;
      profiles.default = {
        isActive = true;
        isService = true;
        settings = {
          cpu = 4;
          memory = 8;
          vmType = "vz";
        };
      };
    };
  };
}
