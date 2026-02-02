let
  base = {pkgs}:
    with pkgs; [
      dig
      fd
      fzf
      git
      gotop
      htop
      jq
      pv
      ripgrep
      tmux
      tree
      unzip
      wget
      zsh
    ];

  dev = {pkgs}:
    with pkgs; [
      claude-code
      direnv
      docker
      docker-compose
      entr
      nix-tree
      nixfmt
      python3
    ];

  desktop = {pkgs}:
    with pkgs; [
      _1password-cli
      ffmpeg
      imagemagick
      neofetch
      pandoc
    ];

  all = {pkgs}:
    (base {inherit pkgs;})
    ++ (dev {inherit pkgs;})
    ++ (desktop {inherit pkgs;});
in {
  inherit base dev desktop all;
}
