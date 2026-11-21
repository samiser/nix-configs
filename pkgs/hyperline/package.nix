{
  lib,
  stdenv,
  requireFile,
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
  version = "0.2.116";

  src = requireFile {
    name = "hyperline-linux-amd64.tar.gz";
    url = "https://hyperline.gg/download/linux";
    hash = "sha256-HBG0VTHCVbHoE+4miSJBmTP2a7/xOch/kUWrkiBL8PA=";
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
