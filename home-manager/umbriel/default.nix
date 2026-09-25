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

  # A bare number selects a position on the focused output, so every workspace names its own.
  workspaceSelector =
    ws: "${ws}/${if builtins.elem ws landscapeWorkspaces then landscape else portrait}";

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
          "Mod+Return" = "spawn:${terminal}";
          "Mod+W" = "spawn:${browser}";
          "Mod+R" = "spawn:${menu}";
          "Mod+Tab" = "spawn:noctalia msg window-switcher";
          "Mod+E" = "spawn:noctalia msg session lock";
          "Mod+Comma" = "spawn:noctalia msg settings-toggle";
          "Mod+N" = "spawn:noctalia msg panel-toggle control-center";
          "Mod+Space" = "spawn:wl-kbptr";
          "Mod+X" = "spawn:${terminal} --class=com.samiser.clipse -e clipse";

          "Mod+Shift+Q" = "window-close";
          "Mod+F" = "window-toggle-fullscreen";
          "Mod+Shift+Space" = "window-toggle-floating";
          "Mod+P" = "window-toggle-pinned";
          "Mod+C" = "window-center";

          "Mod+V" = "workspace-set-layout:toggle";

          "Mod+O" = "overview-toggle";
          "Mod+Slash" = "cheatsheet-toggle";
          "Mod+Shift+C" = "config-reload";
          "Mod+Shift+E" = "session-quit";

          "Mod+Left" = "window-focus-left";
          "Mod+Right" = "window-focus-right";
          "Mod+Up" = "window-focus-up";
          "Mod+Down" = "window-focus-down";

          "Mod+Shift+Left" = "column-move-left";
          "Mod+Shift+Right" = "column-move-right";
          "Mod+Shift+Up" = "window-move-up";
          "Mod+Shift+Down" = "window-move-down";

          "Mod+BracketLeft" = "output-focus-left";
          "Mod+BracketRight" = "output-focus-right";
          "Mod+Shift+BracketLeft" = "window-move-to-output-left";
          "Mod+Shift+BracketRight" = "window-move-to-output-right";

          "Mod+Grave" = "scratchpad-toggle";
          "Mod+Shift+Grave" = "window-move-to-scratchpad";
          "Mod+Ctrl+Grave" = "window-restore-from-scratchpad";

          "Mod+S" = screenshot "-g \"$(slurp)\" ";
          "Mod+Shift+S" = screenshot "";

          "XF86AudioRaiseVolume" = "spawn:noctalia msg volume-up";
          "XF86AudioLowerVolume" = "spawn:noctalia msg volume-down";
          "XF86AudioMute" = "spawn:noctalia msg volume-mute";
          "XF86AudioMicMute" = "spawn:noctalia msg mic-mute";
          "XF86AudioNext" = "spawn:noctalia msg media next";
          "XF86AudioPause" = "spawn:noctalia msg media toggle";
          "XF86AudioPlay" = "spawn:noctalia msg media toggle";
          "XF86AudioPrev" = "spawn:noctalia msg media previous";
        }
        // workspaceBinds
        // workspaceMoveBinds;

        window_rule = [
          {
            match.app_id = "^com\\.samiser\\.clipse$";
            default_floating = true;
            default_size = [
              800
              900
            ];
            default_position = {
              x = 0;
              y = 0;
            };
          }
          {
            match.app_id = "^dev.noctalia.Noctalia$";
            default_floating = true;
            default_size = [
              1020
              900
            ];
            blur_popups = false;
          }
          {
            match.app_id = "^dev.noctalia.UmbrielSharePicker$";
            default_floating = true;
            default_size = [
              800
              600
            ];
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
            default_size = [
              720
              405
            ];
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
