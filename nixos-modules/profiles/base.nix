{
  pkgs,
  keys,
  sharedPackages,
  ...
}: {
  environment.systemPackages =
    (sharedPackages.base {inherit pkgs;})
    ++ (with pkgs; [
      pciutils
      sysstat
      tcpdump
    ]);

  services = {
    openssh.enable = true;
    tailscale.enable = true;
  };

  nix.package = pkgs.nixVersions.stable;

  users.mutableUsers = false;
  programs.zsh.enable = true;

  users.users.sam = {
    isNormalUser = true;
    extraGroups = ["wheel" "networkmanager" "video" "libvirtd" "docker"];
    shell = pkgs.zsh;
    hashedPassword = "$6$YvQ.LsWTIYp2jkWe$brA.AICuG4BEvRBchrVmrHwe.6Mr6RgfTcwHBTXTmhjqgVP9Ql5vktY/zPWJc5Y3aEp5EYkFO0fpP/RnUU0dH0";
    openssh.authorizedKeys.keys = [keys.sam];
  };
}
