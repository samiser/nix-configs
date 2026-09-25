{
  config,
  lib,
  pkgs,
  mango,
  umbriel,
  waypak,
  ...
}:
{
  imports = [
    mango.nixosModules.mango
    umbriel.nixosModules.default
  ];

  config = lib.mkIf config.host.profile.desktop {
    hardware = {
      graphics = {
        enable = true;
        enable32Bit = true;
      };
      bluetooth = {
        enable = true;
        powerOnBoot = true;
      };
    };

    security.rtkit.enable = true;

    networking.networkmanager.enable = true;

    services = {
      upower.enable = true;

      pipewire = {
        enable = true;
        alsa.enable = true;
        pulse.enable = true;
        jack.enable = true;
      };

      displayManager.noctalia-greeter.enable = true;
    };

    xdg.portal.wlr.settings.screencast = {
      chooser_type = "dmenu";
      chooser_cmd = "${pkgs.fuzzel}/bin/fuzzel -d -l 10 -p 'Select a source to share: '";
    };

    environment.sessionVariables.NIXOS_OZONE_WL = "1";

    nixpkgs.overlays = [
      (_final: prev: {
        wl-kbptr = prev.wl-kbptr.overrideAttrs (old: {
          patches = (old.patches or [ ]) ++ [ ./wl-kbptr-pixman-stride.patch ];
        });
      })
    ];

    fonts = {
      enableDefaultPackages = true;
      packages = with pkgs; [
        noto-fonts
        noto-fonts-color-emoji
        font-awesome
      ];
      fontconfig.defaultFonts.monospace = [ "JetBrainsMono Nerd Font Mono" ];
    };

    programs = {
      hyprland.enable = true;
      mango.enable = true;
      umbriel.enable = true;
      noctalia.enable = true;
      gpu-screen-recorder.enable = true;

      _1password.enable = true;
      _1password-gui.enable = true;

      steam = {
        enable = pkgs.stdenv.hostPlatform.system == "x86_64-linux";
        remotePlay.openFirewall = true;
        dedicatedServer.openFirewall = true;
        extraCompatPackages = [ pkgs.proton-ge-bin ];
      };
      gamescope.enable = true;
      gamemode.enable = true;

      dconf.profiles.user.databases = [
        {
          settings."org/gnome/desktop/interface" = {
            gtk-theme = "Adwaita";
            icon-theme = "Flat-Remix-Red-Dark";
            font-name = "Noto Sans Medium 11";
            document-font-name = "Noto Sans Medium 11";
            monospace-font-name = "Noto Sans Mono Medium 11";
          };
        }
      ];
    };

    environment.systemPackages = with pkgs; [
      acpi
      flat-remix-icon-theme
      ghostty
      gimp
      (google-chrome.override {
        commandLineArgs = "--disable-features=WaylandFractionalScaleV1";
      })
      grim
      imv
      mpv
      mupdf
      nnn
      pavucontrol
      playerctl
      slurp
      wdisplays
      wf-recorder
      wl-clipboard
      wl-kbptr
    ];

    # sandboxed apps need the compositor to re-grant these wayland globals
    home-manager.users.sam.programs.umbriel.settings.security_context_rule =
      waypak.lib.toUmbrielRules config.waypak.waylandGrants;

    waypak.apps = {
      clipse.package = pkgs.clipse;
      obsidian = {
        package = pkgs.obsidian;
        binds = [ "$HOME/notes" ];
      };
    }
    // lib.optionalAttrs (pkgs.stdenv.hostPlatform.system == "x86_64-linux") {
      spotify.package = pkgs.spotify;
      vesktop = {
        package = pkgs.vesktop;
        binds = [ "$HOME/Downloads" ];
        # noctalia writes its vesktop theme to the host config dir
        roBinds = [
          "$HOME/Pictures"
          "$HOME/.config/vesktop/themes"
        ];
      };
    };
  };
}
