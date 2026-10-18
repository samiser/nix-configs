{
  pkgs,
  my-neovim,
  agenix,
  umbriel,
  ...
}:
{
  nixpkgs.overlays = [
    (_final: prev: {
      my-neovim = my-neovim.packages.${prev.stdenv.hostPlatform.system}.default;
      my-neovim-minimal = my-neovim.packages.${prev.stdenv.hostPlatform.system}.minimal;
    })
  ];

  home-manager = {
    useGlobalPkgs = true;
    useUserPackages = true;
    backupFileExtension = "backup";

    users.sam = {
      imports = [
        agenix.homeManagerModules.default
        umbriel.homeModules.default
        ./colima.nix
        ./ghostty.nix
        ./git.nix
        ./hcloud.nix
        ./neovim.nix
        ./umbriel
        ./omniwm
        ./wl-kbptr.nix
        ./zsh
      ];

      home = {
        username = "sam";
        homeDirectory = if pkgs.stdenv.hostPlatform.isDarwin then "/Users/sam" else "/home/sam";

        sessionVariables = {
          EDITOR = "vim";
          VISUAL = "vim";
        };

        stateVersion = "25.05";
      };

      manual.manpages.enable = false;

      launchd.agents = pkgs.lib.mkIf pkgs.stdenv.hostPlatform.isDarwin {
        activate-agenix.waitForNixStore = false;
        colima-default = {
          waitForNixStore = false;
          domain = "gui";
        };
      };
    };
  };
}
