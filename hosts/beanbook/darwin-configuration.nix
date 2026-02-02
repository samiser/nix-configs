{
  pkgs,
  my-neovim,
  sharedPackages,
  ...
}: {
  environment.systemPackages =
    (sharedPackages.all {inherit pkgs;})
    ++ [
      my-neovim.packages.${pkgs.stdenv.hostPlatform.system}.default
    ];

  sam = {
    services = {
      yabai.enable = true;
      jankyborders.enable = true;
      skhd.enable = true;
    };
  };

  users.users.sam = {
    name = "sam";
    home = "/Users/sam";
  };

  homebrew = {
    enable = true;
    onActivation.cleanup = "zap";

    taps = ["FelixKratz/formulae"];
    casks = [
      "tailscale"
      "1password"
      "bitwig-studio"
      "colemak-dh"
      "discord"
      "font-jetbrains-mono-nerd-font"
      "ghostty"
      "gimp"
      "godot"
      "google-chrome"
      "iina"
      "obsidian"
      "raycast"
      "spotify"
      "utm"
    ];
  };

  networking = {
    computerName = "beanbook";
    hostName = "beanbook";
  };

  nix.settings = {
    sandbox = true;
    trusted-users = ["root" "sam" "@admin"];
  };

  system = {
    primaryUser = "sam";
    stateVersion = 6;
  };

  nixpkgs.hostPlatform = "aarch64-darwin";
}
