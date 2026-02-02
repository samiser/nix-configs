{
  config,
  lib,
  pkgs,
  ...
}: let
  cfg = config.services.colima;

  startScript = pkgs.writeShellScript "colima-start" ''
    exec ${cfg.package}/bin/colima start \
      --foreground \
      ${lib.optionalString (cfg.vmType != null) "--vm-type ${cfg.vmType}"} \
      ${lib.optionalString (cfg.cpu != null) "--cpu ${toString cfg.cpu}"} \
      ${lib.optionalString (cfg.memory != null) "--memory ${toString cfg.memory}"} \
      ${lib.optionalString (cfg.disk != null) "--disk ${toString cfg.disk}"} \
      ${lib.optionalString (cfg.arch != null) "--arch ${cfg.arch}"} \
      ${lib.optionalString (cfg.runtime != null) "--runtime ${cfg.runtime}"} \
      ${lib.optionalString cfg.kubernetes "--kubernetes"} \
      ${lib.optionalString (cfg.profile != "default") "--profile ${cfg.profile}"} \
      ${lib.escapeShellArgs cfg.extraFlags}
  '';

  serviceName = "colima${lib.optionalString (cfg.profile != "default") "-${cfg.profile}"}";
in {
  options.services.colima = {
    enable = lib.mkEnableOption "Colima, container runtimes on macOS with minimal setup";

    package = lib.mkPackageOption pkgs "colima" {};

    vmType = lib.mkOption {
      type = lib.types.nullOr (lib.types.enum ["qemu" "vz"]);
      default = null;
      description = ''
        Virtual machine type to use.
        - `qemu`: QEMU (default, works on all Macs)
        - `vz`: Apple Virtualization.framework (Apple Silicon only, better performance)

        If null, Colima will use its default (qemu).
      '';
    };

    cpu = lib.mkOption {
      type = lib.types.nullOr lib.types.ints.positive;
      default = null;
      example = 4;
      description = ''
        Number of CPUs to allocate to the VM.
        If null, Colima will use its default (2).
      '';
    };

    memory = lib.mkOption {
      type = lib.types.nullOr lib.types.ints.positive;
      default = null;
      example = 8;
      description = ''
        Memory in GiB to allocate to the VM.
        If null, Colima will use its default (2).
      '';
    };

    disk = lib.mkOption {
      type = lib.types.nullOr lib.types.ints.positive;
      default = null;
      example = 60;
      description = ''
        Disk size in GiB for the VM.
        If null, Colima will use its default (60).
      '';
    };

    arch = lib.mkOption {
      type = lib.types.nullOr (lib.types.enum ["aarch64" "x86_64"]);
      default = null;
      description = ''
        Architecture of the VM.
        If null, defaults to the host architecture.
        Can be used for cross-architecture emulation (slower).
      '';
    };

    runtime = lib.mkOption {
      type = lib.types.nullOr (lib.types.enum ["docker" "containerd" "incus"]);
      default = null;
      description = ''
        Container runtime to use.
        - `docker`: Docker (default)
        - `containerd`: containerd with nerdctl
        - `incus`: Incus containers and VMs

        If null, Colima will use its default (docker).
      '';
    };

    kubernetes = lib.mkOption {
      type = lib.types.bool;
      default = false;
      description = "Enable Kubernetes.";
    };

    profile = lib.mkOption {
      type = lib.types.str;
      default = "default";
      example = "work";
      description = ''
        Colima profile name. Use different profiles to run multiple instances.
        Each profile is a separate VM with its own configuration.

        Note: If using multiple profiles, you'll need to create separate
        service definitions for each (not yet supported by this module).
      '';
    };

    stdoutPath = lib.mkOption {
      type = lib.types.nullOr lib.types.str;
      default = null;
      example = "/Users/myuser/Library/Logs/colima/colima.log";
      description = ''
        Absolute path for stdout logging.

        If null, stdout will go to launchd's default (nowhere useful).

        Note: launchd does not expand ~ or $HOME. You must use an absolute path.
        The directory must exist and be writable.
      '';
    };

    stderrPath = lib.mkOption {
      type = lib.types.nullOr lib.types.str;
      default = null;
      example = "/Users/myuser/Library/Logs/colima/colima.log";
      description = ''
        Absolute path for stderr logging.

        If null, defaults to the same as stdoutPath.
        If both are null, stderr will go to launchd's default.

        Note: launchd does not expand ~ or $HOME. You must use an absolute path.
      '';
    };

    extraFlags = lib.mkOption {
      type = lib.types.listOf lib.types.str;
      default = [];
      example = ["--network-address" "--ssh-agent"];
      description = "Extra command-line flags to pass to `colima start`.";
    };

    environment = lib.mkOption {
      type = lib.types.attrsOf lib.types.str;
      default = {};
      example = {
        LIMA_INSTANCE_DIR = "/custom/path";
      };
      description = "Environment variables to set for the Colima process.";
    };
  };

  config = lib.mkIf cfg.enable {
    environment.systemPackages =
      [
        cfg.package
        pkgs.lima
      ]
      ++ lib.optional (cfg.runtime == "docker" || cfg.runtime == null) pkgs.docker-client;

    launchd.user.agents.${serviceName} = {
      command = "${startScript}";

      path = [
        cfg.package
        pkgs.lima
        pkgs.qemu
      ];

      serviceConfig = {
        KeepAlive = {
          SuccessfulExit = true;
        };

        RunAtLoad = true;

        ProcessType = "Background";

        StandardOutPath = cfg.stdoutPath;
        StandardErrorPath =
          if cfg.stderrPath != null
          then cfg.stderrPath
          else cfg.stdoutPath;

        ExitTimeOut = 120;

        LowPriorityIO = true;

        EnvironmentVariables = lib.mkIf (cfg.environment != {}) cfg.environment;
      };
    };
  };
}
