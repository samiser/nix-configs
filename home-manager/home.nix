{
  pkgs,
  config,
  my-neovim,
  agenix,
  ...
}: let
  gui = config.hostConfig.gui.enable;
in {
  home-manager = {
    extraSpecialArgs = {inherit my-neovim;};
    useGlobalPkgs = true;
    useUserPackages = true;
    backupFileExtension = "backup";

    users.sam = {
      imports = [
        agenix.homeManagerModules.default
        ./alacritty.nix
        ./colima.nix
        ./ghostty.nix
        ./git.nix
        ./hcloud.nix
        ./i3
        ./neovim.nix
        ./zsh
      ];

      home = {
        username = "sam";
        homeDirectory =
          if pkgs.stdenv.isDarwin
          then "/Users/sam"
          else "/home/sam";

        stateVersion = "25.05";
      };

      sam = {
        zsh.enable = true;
        git.enable = true;
        neovim.enable = true;
        ghostty.enable = pkgs.stdenv.isDarwin;
        colima.enable = pkgs.stdenv.isDarwin;
        alacritty.enable = pkgs.stdenv.isLinux && gui;
        i3.enable = pkgs.stdenv.isLinux && gui;
      };
    };
  };
}
