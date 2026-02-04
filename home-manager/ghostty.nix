{
  lib,
  config,
  ...
}:
with lib; let
  cfg = config.sam.ghostty;
in {
  options.sam.ghostty.enable = mkEnableOption "ghostty config";

  config = mkIf cfg.enable {
    programs.ghostty.enable = true;
    programs.ghostty.package = null;
    programs.ghostty.settings = {
      macos-titlebar-style = "hidden";
      window-padding-x = 5;
      window-padding-y = 5;
      font-size = 11;
      background-opacity = 0.9;
      background-blur = true;
    };
  };
}
