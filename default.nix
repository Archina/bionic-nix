{
  lib,
  stdenv,
  fetchurl,
  appimageTools,
}:

let
  pname = "bionic";

  # Bionic is distributed as a self-contained Electron AppImage.
  # The installers are ~1.3-1.5 GB, so versions/hashes are pinned per platform.
  sources = {
    x86_64-linux = {
      version = "1.2.1-10";
      url = "https://bionic-installers.lmstudio.ai/linux/x64/1.2.1-10/Bionic-1.2.1-10-x64.AppImage";
      hash = "sha256-doqBFreJa6ty9vM4Hc3ojBP5+hcz86AD/1IdRr5bU1Q=";
    };
    aarch64-linux = {
      version = "1.2.1-10";
      url = "https://bionic-installers.lmstudio.ai/linux/arm64/1.2.1-10/Bionic-1.2.1-10-arm64.AppImage";
      hash = "sha256-j876XmHhFyXnmZOhKX49gZyj/aI6n3yTSS8lP9MxUUU=";
    };
  };

  source =
    sources.${stdenv.hostPlatform.system}
      or (throw "bionic: unsupported platform ${stdenv.hostPlatform.system}");

  src = fetchurl { inherit (source) url hash; };

  appimageContents = appimageTools.extract {
    inherit pname src;
    version = source.version;
  };
in

lib.fix (self: appimageTools.wrapType2 {
  inherit pname src;
  version = source.version;

  # ocl-icd lets the bundled runtimes enumerate OpenCL devices.
  extraPkgs = pkgs: [ pkgs.ocl-icd ];

  extraInstallCommands = ''
    # Upstream ships pre-rendered icons for every hicolor size.
    mkdir -p $out/share/icons
    cp -r ${appimageContents}/usr/share/icons/hicolor $out/share/icons/

    install -m 444 -D ${appimageContents}/ai.elementlabs.bionic.desktop \
      -t $out/share/applications

    substituteInPlace $out/share/applications/ai.elementlabs.bionic.desktop \
      --replace-fail 'Exec=AppRun %U' 'Exec=bionic %U'
    # Drop the invalid lowercase `category=` key shipped upstream.
    sed -i '/^category=/d' $out/share/applications/ai.elementlabs.bionic.desktop
  '';

  passthru.tests.basic = stdenv.mkDerivation {
    name = "bionic-basic-test";
    buildCommand = ''
      [ -x ${self}/bin/bionic ] || exit 1
      [ -f ${self}/share/applications/ai.elementlabs.bionic.desktop ] || exit 1
      [ -f ${self}/share/icons/hicolor/512x512/apps/bionic.png ] || exit 1
      touch $out
    '';
  };

  meta = with lib; {
    description = "Bionic - LM Studio's agent for work and code";
    homepage = "https://lmstudio.ai/";
    license = licenses.unfree;
    mainProgram = "bionic";
    sourceProvenance = with sourceTypes; [ binaryNativeCode ];
    platforms = [ "x86_64-linux" "aarch64-linux" ];
    maintainers = with maintainers; [ ];
  };
})
