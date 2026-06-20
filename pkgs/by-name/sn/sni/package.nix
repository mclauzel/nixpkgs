{ lib
, stdenv
, fetchzip
, autoPatchelfHook
, makeWrapper
, libusb1
, gtk3
, glib
, libXtst
}:

stdenv.mkDerivation (finalAttrs: {
  pname = "sni";
  version = "0.0.103";

  src = fetchzip {
    url = "https://github.com/alttpo/sni/releases/download/v0.0.103/sni-v0.0.103-linux-amd64.tar.xz";
    sha256 = "sha256-AZ0vC6yH2Pd1eDP5ndZpvf6E6hhFybMA0noGjnBUP0A=";
  };

  nativeBuildInputs = [
    autoPatchelfHook
    makeWrapper
  ];

  buildInputs = [
    libusb1
    gtk3
    glib
    libXtst
  ];

  installPhase = ''
    runHook preInstall

    mkdir -p $out/bin
    mkdir -p $out/share/sni

    # binaries
    install -m755 sni $out/bin/sni
    install -m755 send_file $out/bin/send_file
    install -m755 manage_files $out/bin/manage_files

    # resources
    cp -r lua $out/share/sni/
    cp apps.yaml $out/share/sni/
    cp snfm_config_example.yaml $out/share/sni/
    cp snfm_user_manual.md $out/share/sni/

    # optional wrapper so runtime can find assets
    wrapProgram $out/bin/sni \
      --set SNI_DATA_DIR "$out/share/sni"

    runHook postInstall
  '';

  meta = with lib; {
    description = "SNI - SNES Interface (prebuilt distribution)";
    homepage = "https://github.com/alttpo/sni";
    license = licenses.mit;
    platforms = [ "x86_64-linux" ];
    mainProgram = "sni";
  };
})
