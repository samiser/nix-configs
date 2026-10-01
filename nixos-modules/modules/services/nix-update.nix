{
  config,
  lib,
  pkgs,
  ...
}:
let
  cfg = config.services.nix-update;

  stateDir = "/var/lib/nix-update";

  knownHosts = pkgs.writeText "nix-update-known-hosts" ''
    github.com ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIOMqqnkVzrm0SdG6UOoqKLsabgH5C9okWi0dh2l9GKJl
    github.com ecdsa-sha2-nistp256 AAAAE2VjZHNhLXNoYTItbmlzdHAyNTYAAAAIbmlzdHAyNTYAAABBBEmKSENjQEezOmxkZMy7opKgwFB9nkt5YRrYMjNuG5N87uRgg6CLrbo5wAdT/y6v0mKV0U2w0WZ2YB/++Tpockg=
  '';

  specsFile = pkgs.writeText "nix-update-specs.json" (
    builtins.toJSON (
      map (p: {
        inherit (p) name versionPreference;
      }) cfg.packages
    )
  );

  runner = pkgs.writeShellApplication {
    name = "nix-update-run";
    runtimeInputs = [
      pkgs.coreutils
      pkgs.gh
      pkgs.git
      pkgs.gnused
      pkgs.jq
      config.nix.package
      (pkgs.nix-update.override { nix = config.nix.package; })
      pkgs.openssh
    ];
    text = builtins.readFile ./nix-update-run.sh;
  };
in
{
  options.services.nix-update = {
    enable = lib.mkEnableOption "automatic update PRs for maintained nixpkgs packages";

    packages = lib.mkOption {
      default = [ ];
      description = "nixpkgs packages to keep updated.";
      type = lib.types.listOf (
        lib.types.submodule {
          options = {
            name = lib.mkOption {
              type = lib.types.str;
              description = "nixpkgs attribute path.";
            };
            versionPreference = lib.mkOption {
              type = lib.types.enum [
                "stable"
                "unstable"
              ];
              default = "stable";
              description = ''
                Passed to `nix-update --version`. `unstable` includes versions
                matching alpha/beta/rc/nightly.
              '';
            };
          };
        }
      );
    };

    githubUser = lib.mkOption {
      type = lib.types.str;
      description = ''
        GitHub user with nixpkgs fork and nixpkgs-review-gha fork.
      '';
    };

    tokenFile = lib.mkOption {
      type = lib.types.path;
      description = ''
        File holding a classic GitHub token with public_repo scope.
      '';
    };

    sshKeyFile = lib.mkOption {
      type = lib.types.path;
      description = ''
        Private key pushing update branches to the fork.
      '';
    };

    gitAuthor = {
      name = lib.mkOption {
        type = lib.types.str;
        description = "Name for commits.";
      };
      email = lib.mkOption {
        type = lib.types.str;
        description = "Email for commits.";
      };
    };

    createPullRequests = lib.mkOption {
      type = lib.types.bool;
      default = false;
      description = ''
        Whether to actually push branches and open pull requests.
      '';
    };

    interval = lib.mkOption {
      type = lib.types.str;
      default = "hourly";
      description = "systemd calendar expression for how often to check.";
    };
  };

  config = lib.mkIf cfg.enable {
    users.users.nix-update = {
      isSystemUser = true;
      group = "nix-update";
      home = stateDir;
    };
    users.groups.nix-update = { };

    age.secrets.nixpkgs-update-token = {
      file = ../../../secrets/nixpkgs-update-token.age;
      owner = "nix-update";
      group = "nix-update";
    };

    age.secrets.nixpkgs-update-ssh-key = {
      file = ../../../secrets/nixpkgs-update-ssh-key.age;
      owner = "nix-update";
      group = "nix-update";
    };

    systemd.services.nix-update = {
      description = "Update maintained nixpkgs packages";
      after = [ "network-online.target" ];
      wants = [ "network-online.target" ];

      environment = {
        SPECS_FILE = "${specsFile}";
        GH_USER = cfg.githubUser;
        TOKEN_FILE = cfg.tokenFile;
        CREATE_PRS = lib.boolToString cfg.createPullRequests;
        STATE_DIR = stateDir;
        NIXPKGS_ALLOW_UNSUPPORTED_SYSTEM = "1";

        HOME = stateDir;

        GIT_SSH_COMMAND = lib.concatStringsSep " " [
          "ssh"
          "-i ${cfg.sshKeyFile}"
          "-o IdentitiesOnly=yes"
          "-o UserKnownHostsFile=${knownHosts}"
          "-o StrictHostKeyChecking=yes"
        ];

        GIT_AUTHOR_NAME = cfg.gitAuthor.name;
        GIT_AUTHOR_EMAIL = cfg.gitAuthor.email;
        GIT_COMMITTER_NAME = cfg.gitAuthor.name;
        GIT_COMMITTER_EMAIL = cfg.gitAuthor.email;
      };

      # a run triggered by resume-from-suspend beats DNS coming back
      unitConfig = {
        StartLimitIntervalSec = "30m";
        StartLimitBurst = 3;
      };

      serviceConfig = {
        Type = "oneshot";
        Restart = "on-failure";
        RestartSec = "2m";
        User = "nix-update";
        Group = "nix-update";
        ExecStart = lib.getExe runner;

        StateDirectory = "nix-update";
        StateDirectoryMode = "0700";
        WorkingDirectory = stateDir;

        Nice = 19;
        IOSchedulingClass = "idle";
        CPUSchedulingPolicy = "idle";

        TimeoutStartSec = "6h";

        PrivateTmp = true;
        ProtectHome = true;
        ProtectSystem = "strict";
        NoNewPrivileges = true;
      };
    };

    systemd.timers.nix-update = {
      description = "Check maintained nixpkgs packages for updates";
      wantedBy = [ "timers.target" ];
      timerConfig = {
        OnCalendar = cfg.interval;
        Persistent = true;
        RandomizedDelaySec = "5m";
      };
    };
  };
}
