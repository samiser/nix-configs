{
  config,
  lib,
  pkgs,
  sharedPackages,
  ...
}: {
  config = lib.mkIf config.host.profile.desktop {
    hostConfig.gui.enable = true;

    hardware.graphics.enable = true;

    services.pipewire = {
      enable = true;
      pulse.enable = true;
    };

    fonts = {
      packages = with pkgs; [nerd-fonts.jetbrains-mono];
      fontconfig.defaultFonts.monospace = ["JetBrainsMono Nerd Font Mono"];
    };

    programs._1password.enable = true;
    programs._1password-gui.enable = true;

    environment.systemPackages =
      (sharedPackages.desktop {inherit pkgs;})
      ++ (with pkgs; [
        # Linux-specific GUI and X11 tools
        acpi
        alacritty
        arandr
        chromium
        feh
        ghostty.terminfo
        gimp
        godot_4
        gotop
        mpv
        mupdf
        obsidian
        peek
        playerctl
        scrot
        xclip
        discord
        spotify
        steam
      ]);

    nixpkgs.config.permittedInsecurePackages = ["python-2.7.18.8" "electron-24.8.6"];

    virtualisation.docker.enable = true;
  };
}
