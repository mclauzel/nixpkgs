{ lib
, rustPlatform
, fetchFromGitHub
, wayland
, libxkbcommon
, pkg-config
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

  # Add these inputs to ensure Wayland support is compiled in
  nativeBuildInputs = [ pkg-config ];
  buildInputs = [ wayland libxkbcommon ];

  meta = with lib; {
    description = "Speedrun timer with autosplitter for fxpak/sd2snes";
    homepage = "https://github.com/dagit/annelid";
    license = licenses.mit;
    mainProgram = "annelid";
    platforms = platforms.linux;
  };
}
