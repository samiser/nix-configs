{
  lib,
  stdenv,
  fetchurl,
  curl,
  nix-update,
  writeShellScript,
  copyDesktopItems,
  makeDesktopItem,
  libglvnd,
  libxkbcommon,
  libX11,
  libXcursor,
  libXfixes,
  wayland,
}:

stdenv.mkDerivation (finalAttrs: {
  pname = "hyperline";
  version = "0.2.145";

  src = fetchurl {
    url = "https://cdn.hyperline.gg/download/${finalAttrs.version}/hyperline-linux-amd64.tar.gz";
    hash = "sha256-Q+8qOOxcOi5kVC5d93IK6p6K2FAtAqy3nWplV01OyHU=";
  };

  sourceRoot = ".";

  nativeBuildInputs = [ copyDesktopItems ];

  dontPatchELF = true;
  dontStrip = true;

  installPhase = ''
    runHook preInstall

    install -Dm755 hyperline -t $out/bin
    patchelf --set-rpath ${
      lib.makeLibraryPath [
        libglvnd
        libxkbcommon
        libX11
        libXcursor
        libXfixes
        wayland
      ]
    } $out/bin/hyperline
    patchelf --set-interpreter ${stdenv.cc.bintools.dynamicLinker} $out/bin/hyperline

    runHook postInstall
  '';

  desktopItems = [
    (makeDesktopItem {
      name = "hyperline";
      exec = "hyperline %u";
      icon = "applications-games";
      desktopName = "Hyperline";
      comment = "Play custom Deadlock games with friends";
      categories = [ "Game" ];
      mimeTypes = [ "x-scheme-handler/hyperline" ];
    })
  ];

  passthru.updateScript = writeShellScript "update-hyperline" ''
    set -eu
    version=$(${lib.getExe curl} -fsSI -o /dev/null -w '%{redirect_url}' https://hyperline.gg/download/linux | sed -E 's#.*/download/([^/]+)/.*#\1#')
    exec ${lib.getExe nix-update} hyperline --version "$version"
  '';

  meta = {
    description = "Tray app for playing custom Deadlock games with friends";
    homepage = "https://hyperline.gg/";
    downloadPage = "https://hyperline.gg/download/linux";
    license = lib.licenses.unfree;
    sourceProvenance = with lib.sourceTypes; [ binaryNativeCode ];
    platforms = [ "x86_64-linux" ];
    maintainers = with lib.maintainers; [ samiser ];
    mainProgram = "hyperline";
  };
})
