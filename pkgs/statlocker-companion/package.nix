{
  lib,
  stdenv,
  fetchurl,
  appimageTools,
  autoPatchelfHook,
  wrapGAppsHook3,
  cairo,
  curl,
  dbus,
  desktop-file-utils,
  gdk-pixbuf,
  glib,
  glib-networking,
  gtk3,
  jq,
  libayatana-appindicator,
  libsoup_3,
  libX11,
  libxcb,
  nix-update,
  obs-studio,
  squashfs-tools,
  wayland,
  webkitgtk_4_1,
  writeShellScript,
  xdg-utils,
  xz,
}:

stdenv.mkDerivation (finalAttrs: {
  pname = "statlocker-companion";
  version = "1.0.11";

  src = fetchurl {
    url = "https://updates.statlocker.gg/companion/${finalAttrs.version}/statlocker-companion_${finalAttrs.version}_amd64.AppImage";
    hash = "sha256-t4uKt+rrZZ2+Sl0sOJc86bpvA+mQi9go1vLl2WaiEB0=";
  };

  appimageContents = appimageTools.extract {
    inherit (finalAttrs) pname version src;
  };

  dontUnpack = true;
  dontConfigure = true;
  dontAutoPatchelf = true;
  dontPatchELF = true;
  dontStrip = true;

  nativeBuildInputs = [
    autoPatchelfHook
    squashfs-tools
    wrapGAppsHook3
  ];

  buildInputs = [
    cairo
    dbus
    gdk-pixbuf
    glib
    glib-networking
    gtk3
    libsoup_3
    libX11
    libxcb
    obs-studio
    wayland
    webkitgtk_4_1
    xz
  ];

  runtimeDependencies = [ libayatana-appindicator ];

  buildPhase = ''
    runHook preBuild

    cp -r ${finalAttrs.appimageContents}/usr/lib/statlocker-companion/resources/gsr gsr
    chmod -R u+w gsr
    runtimeSize=$(LC_ALL=C readelf -h ${finalAttrs.src} | awk 'NR==13{e_shoff=$5} NR==18{e_shentsize=$5} NR==19{e_shnum=$5} END{print e_shoff+e_shentsize*e_shnum}')
    head -c "$runtimeSize" ${finalAttrs.src} > gsr.AppImage
    mksquashfs gsr gsr.squashfs -root-owned -noappend -no-progress -comp zstd
    cat gsr.squashfs >> gsr.AppImage

    runHook postBuild
  '';

  installPhase = ''
    runHook preInstall

    install -Dm755 ${finalAttrs.appimageContents}/usr/bin/statlocker-companion -t $out/bin
    install -Dm755 ${finalAttrs.appimageContents}/usr/lib/statlocker-companion/resources/ffmpeg -t $out/lib/statlocker-companion/resources
    install -Dm755 gsr.AppImage -t $out/lib/statlocker-companion/resources
    install -Dm444 ${finalAttrs.appimageContents}/statlocker-companion.desktop -t $out/share/applications
    substituteInPlace $out/share/applications/statlocker-companion.desktop \
      --replace-fail 'Name=statlocker-companion' 'Name=Statlocker Companion'
    cp -r ${finalAttrs.appimageContents}/usr/share/icons $out/share/

    runHook postInstall
  '';

  preFixup = ''
    gappsWrapperArgs+=(
      --prefix PATH : ${
        lib.makeBinPath [
          desktop-file-utils
          xdg-utils
        ]
      }
    )
  '';

  postFixup = ''
    autoPatchelf $out/bin
  '';

  passthru.updateScript = writeShellScript "update-statlocker-companion" ''
    set -eu
    version=$(${lib.getExe curl} -fsSL https://updates.statlocker.gg/companion/latest.json | ${lib.getExe jq} -r .version)
    exec ${lib.getExe nix-update} statlocker-companion --version "$version"
  '';

  meta = {
    description = "Desktop companion for Statlocker.gg, a Deadlock match tracker";
    homepage = "https://statlocker.gg/";
    downloadPage = "https://updates.statlocker.gg/companion/download/statlocker-companion_amd64.AppImage";
    license = lib.licenses.unfree;
    sourceProvenance = with lib.sourceTypes; [ binaryNativeCode ];
    platforms = [ "x86_64-linux" ];
    maintainers = with lib.maintainers; [ samiser ];
    mainProgram = "statlocker-companion";
  };
})
