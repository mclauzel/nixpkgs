{ lib
, rustPlatform
, fetchFromGitHub
, wayland
, libxkbcommon
, pkg-config
, makeWrapper
, libGL
, libX11
, libXcursor
, libXrandr
, libXi
, stdenv
, ...
}:

rustPlatform.buildRustPackage rec {
  pname = "annelid";
  version = "unstable-2026-06-23";

  src = fetchFromGitHub {
    owner = "dagit";
    repo = "annelid";
    rev = "1b682654f0b7ca055a4eb37ea49f0bfe11f5989b";
    hash = "sha256-YCJ58kwNhL0YRHTRntRxfcvzq8I1PMIlCOoKzQ4yxbc=";
  };

  cargoHash = "sha256-RWqeRw/TgnNtq+T5zw8Ntj42ofvr3Fksl6gtNRkQiyE=";

  nativeBuildInputs = [ pkg-config makeWrapper ];
  buildInputs = [ wayland libxkbcommon libGL libX11 libXcursor libXrandr libXi ];

  postFixup = ''
    wrapProgram $out/bin/annelid \
      --prefix LD_LIBRARY_PATH : "${lib.makeLibraryPath [
        libGL libxkbcommon wayland libX11 libXcursor libXrandr libXi
      ]}"
  '';

  meta = with lib; {
    description = "Speedrun timer with autosplitter for fxpak/sd2snes";
    homepage = "https://github.com/dagit/annelid";
    license = licenses.mit;
    mainProgram = "annelid";
    platforms = platforms.linux;
  };
}
