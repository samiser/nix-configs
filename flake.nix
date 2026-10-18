{
  inputs = {
    nixpkgs.url = "https://channels.nixos.org/nixos-unstable/nixexprs.tar.zst";

    nixos-hardware = {
      url = "github:nixos/nixos-hardware/master";
      inputs.nixpkgs.follows = "nixpkgs";
    };
    nixos-wsl = {
      url = "github:nix-community/nixos-wsl/main";
      inputs.nixpkgs.follows = "nixpkgs";
    };
    nix-darwin = {
      url = "github:LnL7/nix-darwin";
      inputs.nixpkgs.follows = "nixpkgs";
    };
    home-manager = {
      url = "github:nix-community/home-manager/master";
      inputs.nixpkgs.follows = "nixpkgs";
    };
    disko = {
      url = "github:nix-community/disko";
      inputs.nixpkgs.follows = "nixpkgs";
    };
    agenix = {
      url = "github:ryantm/agenix";
      inputs = {
        nixpkgs.follows = "nixpkgs";
        darwin.follows = "nix-darwin";
        home-manager.follows = "home-manager";
      };
    };
    deploy-rs = {
      url = "github:serokell/deploy-rs";
      inputs.nixpkgs.follows = "nixpkgs";
    };
    nix-minecraft = {
      url = "github:samiser/nix-minecraft/lazymc-module";
      inputs.nixpkgs.follows = "nixpkgs";
    };
    my-neovim = {
      url = "github:samiser/neovim-config";
      inputs.nixpkgs.follows = "nixpkgs";
    };
    static-site-compiler = {
      url = "github:samiser/static-site-compiler";
      inputs.nixpkgs.follows = "nixpkgs";
    };
    markovi = {
      url = "github:samiser/markovi";
      inputs.nixpkgs.follows = "nixpkgs";
    };
    closured = {
      url = "github:samiser/closured";
      inputs.nixpkgs.follows = "nixpkgs";
    };
    umbriel = {
      url = "git+https://github.com/noctalia-dev/umbriel";
      inputs.nixpkgs.follows = "nixpkgs";
    };
    waypak = {
      url = "github:samiser/waypak";
      inputs.nixpkgs.follows = "nixpkgs";
    };
  };

  outputs = inputs: import ./lib { inherit inputs; };
}
