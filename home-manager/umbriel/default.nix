{
  config,
  lib,
  pkgs,
  osConfig,
  ...
}:
let
  inherit (lib)
    listToAttrs
    mkIf
    nameValuePair
    range
    ;

  terminal = "ghostty";
  browser = "google-chrome-stable";
  menu = "noctalia msg panel-toggle launcher";

  landscape = "DP-2";
  portrait = "DP-1";

  landscapeWorkspaces = map toString (range 1 5);
  portraitWorkspaces = map toString (range 6 10);
  allWorkspaces = landscapeWorkspaces ++ portraitWorkspaces;

  workspaceKey = ws: if ws == "10" then "0" else ws;

  workspaceSelector =
    ws: "\"${ws}\"/${if builtins.elem ws landscapeWorkspaces then landscape else portrait}";

  once = action: {
    inherit action;
    repeat = false;
  };

  workspaceBinds = listToAttrs (
    map (
      ws: nameValuePair "Mod+${workspaceKey ws}" "workspace-switch:${workspaceSelector ws}"
    ) allWorkspaces
  );

  workspaceMoveBinds = listToAttrs (
    map (
      ws: nameValuePair "Mod+Shift+${workspaceKey ws}" "window-move-to-workspace:${workspaceSelector ws}"
    ) allWorkspaces
  );
  shaders = "${config.home.homeDirectory}/umbriel-shaders";
  screenshot =
    grimArgs:
    "spawn:mkdir -p ~/shots && f=~/shots/$(date +%Y-%m-%d_%H-%M-%S).png && grim ${grimArgs}\"$f\" && wl-copy < \"$f\"";
in
{
  config = mkIf (pkgs.stdenv.hostPlatform.isLinux && osConfig.host.profile.desktop) {
    programs.umbriel = {
      enable = true;

      settings = {
        include.optional.files = [
          "noctalia.toml"
          "local.toml"
        ];

        general = {
          autostart = [
            "noctalia"
            "tailscale systray"
            "clipse-listener"
          ];
          xwayland = true;
          show_cheatsheet = false;
        };

        environment.XCURSOR_SIZE = "24";

        appearance = {
          corner_radius = 0;
        };

        layout = {
          mode = "dwindle";
          gap = 5;
        };

        output.${landscape} = {
          mode = "3840x2160@60";
          position = [
            0
            672
          ];
          scale = 1.25;
          workspaces = landscapeWorkspaces;
        };

        output.${portrait} = {
          mode = "3840x2160@60";
          position = [
            3072
            0
          ];
          scale = 1.25;
          transform = "90";
          workspaces = portraitWorkspaces;
        };

        animation = {
          workspaces = {
            duration_ms = 300;
            curve = "easeinout";
            shader = "${shaders}/bijection-flow.glsl";
          };
          windows_out = {
            duration_ms = 300;
            curve = "easeout";
            shader = "${shaders}/dither.glsl";
          };
        };

        input = {
          keyboard = {
            layout = "us";
            options = "compose:menu";
          };
          focus.follows_mouse = true;
          cursor = {
            hide_when_typing = true;
            hide_timeout_ms = 3000;
          };
        };

        keybinds = {
          "Mod+Return" = once "spawn:${terminal}";
          "Mod+W" = once "spawn:${browser}";
          "Mod+R" = once "spawn:${menu}";
          "Mod+Tab" = once "spawn:noctalia msg window-switcher";
          "Mod+E" = once "spawn:noctalia msg session lock";
          "Mod+Comma" = once "spawn:noctalia msg settings-toggle";
          "Mod+N" = once "spawn:noctalia msg panel-toggle control-center";
          "Mod+Space" = once "spawn:wl-kbptr";
          "Mod+X" = once "spawn:${terminal} --class=com.samiser.clipse -e clipse";

          "Mod+Shift+Q" = once "window-close";
          "Mod+F" = once "window-toggle-fullscreen";
          "Mod+Shift+Space" = once "window-toggle-floating";
          "Mod+P" = once "window-toggle-pinned";
          "Mod+C" = "window-center";

          "Mod+V" = once "workspace-set-layout:toggle";

          "Mod+O" = once "overview-toggle";
          "Mod+Slash" = once "cheatsheet-toggle";
          "Mod+Shift+C" = once "config-reload";
          "Mod+Shift+E" = once "session-quit";
          "Mod+Shift+Escape" = {
            action = "shortcuts-inhibit-toggle";
            allow_when_inhibited = true;
            repeat = false;
          };

          "Mod+Left" = "window-focus-or-output-left";
          "Mod+Right" = "window-focus-or-output-right";
          "Mod+Up" = "window-focus-or-output-up";
          "Mod+Down" = "window-focus-or-output-down";

          "Mod+Shift+Left" = "window-move-or-output-left";
          "Mod+Shift+Right" = "window-move-or-output-right";
          "Mod+Shift+Up" = "window-move-or-output-up";
          "Mod+Shift+Down" = "window-move-or-output-down";

          "Mod+BracketLeft" = "output-focus-previous";
          "Mod+BracketRight" = "output-focus-next";
          "Mod+Shift+BracketLeft" = "window-move-to-output-previous";
          "Mod+Shift+BracketRight" = "window-move-to-output-next";

          "Mod+Grave" = "scratchpad-toggle";
          "Mod+Shift+Grave" = "window-move-to-scratchpad";
          "Mod+Ctrl+Grave" = "window-restore-from-scratchpad";

          "Mod+S" = once (screenshot "-g \"$(slurp)\" ");
          "Mod+Shift+S" = once (screenshot "");

          "XF86AudioRaiseVolume" = "spawn:noctalia msg volume-up";
          "XF86AudioLowerVolume" = "spawn:noctalia msg volume-down";
          "XF86AudioMute" = once "spawn:noctalia msg volume-mute";
          "XF86AudioMicMute" = once "spawn:noctalia msg mic-mute";
          "XF86AudioNext" = once "spawn:noctalia msg media next";
          "XF86AudioPause" = once "spawn:noctalia msg media toggle";
          "XF86AudioPlay" = once "spawn:noctalia msg media toggle";
          "XF86AudioPrev" = once "spawn:noctalia msg media previous";
        }
        // workspaceBinds
        // workspaceMoveBinds;

        window_rule = [
          {
            match.app_id = "^com\\.samiser\\.clipse$";
            default_floating = true;
            default_floating_size_px = {
              width = 800;
              height = 900;
            };
            default_position = {
              x = 0;
              y = 0;
            };
          }
          {
            match.app_id = "^dev.noctalia.Noctalia$";
            default_floating = true;
            default_floating_size_px = {
              width = 1020;
              height = 900;
            };
            blur_popups = false;
          }
          {
            match.app_id = "^dev.noctalia.UmbrielSharePicker$";
            default_floating = true;
            default_floating_size_px = {
              width = 800;
              height = 600;
            };
            default_position = {
              x = 32;
              y = 32;
              anchor = "bottom_right";
            };
          }
          {
            match.title = "^Picture in picture$";
            default_floating = true;
            opacity = 0.9;
            default_floating_size_px = {
              width = 720;
              height = 405;
            };
            default_output = landscape;
            default_position = {
              x = 10;
              y = 10;
              anchor = "top_right";
            };
            default_focused = false;
            default_pinned = true;
          }
        ];

        layer_rule = [
          {
            match.namespace = "^noctalia-(bar-[^\"]+|notification|dock|panel|attached-panel|osd)$";
            blur = true;
            blur_ignore_alpha = 0.5;
            blur_optimized = false;
          }
        ];
      };
    };
  };
}
