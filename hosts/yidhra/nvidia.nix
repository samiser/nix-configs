{ config, pkgs, ... }:
{
  services.xserver.videoDrivers = [ "nvidia" ];

  hardware = {
    nvidia = {
      package = config.boot.kernelPackages.nvidiaPackages.new_feature;
      open = true;
      modesetting.enable = true;
      powerManagement = {
        enable = true;
        kernelSuspendNotifier = false;
      };
    };
    graphics.extraPackages = [ pkgs.nvidia-vaapi-driver ];
  };

  systemd.services.nvidia-uvm = {
    wantedBy = [ "multi-user.target" ];
    after = [ "systemd-modules-load.service" ];
    unitConfig.ConditionPathExists = "!/dev/nvidia-uvm";
    serviceConfig = {
      Type = "oneshot";
      ExecStart = "${pkgs.kmod}/bin/modprobe nvidia_uvm";
      Restart = "on-failure";
      RestartSec = 1;
    };
  };
}
