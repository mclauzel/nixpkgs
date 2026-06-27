{ lib
, stdenv
, fetchzip
, autoPatchelfHook
, makeWrapper
, copyDesktopItems
, makeDesktopItem
, alsa-lib
, dbus
, fontconfig
, freetype
, libGL
, libpulseaudio
, libxkbcommon
, libX11
, libXcursor
, libXext
, libXfixes
, libXi
, libXrandr
, libXrender
, udev
, vulkan-loader
, wayland
, zlib
}:

stdenv.mkDerivation (finalAttrs: {
  pname = "pngtuber-remix";
  version = "1.4.6"; # NOTE: pin to a real tag, e.g. from
                      # https://github.com/MudkipWorld/PNGTuber-Remix/releases

  src = fetchzip {
    # NOTE: confirm the exact asset name for this tag on the releases page —
    # naming has drifted slightly between versions (e.g. "PNGTubeRemixV1.3(Linux).zip"
    # vs newer "PNGTube-RemixV<ver>(Linux).zip"). Adjust to match.
    url = "https://github.com/MudkipWorld/PNGTuber-Remix/releases/download/V${finalAttrs.version}/PNGTubeRemixV${finalAttrs.version}.Linux.zip";
    # Placeholder — replace with the real hash. Get it with:
    #   nix-prefetch-url --unpack <url>
    # or:
    #   nix store prefetch-file --hash-type sha256 --unpack <url>
    hash = "sha256-v/vz6XRvADGRlpCHOh454VbnqvU8nopwQz7d073lGTc=";
  };

  nativeBuildInputs = [
    autoPatchelfHook
    makeWrapper
    copyDesktopItems
  ];

  # Typical runtime deps for a Godot 4 Linux export (Vulkan rendering backend,
  # X11/Wayland windowing, audio, input). Trim or extend after checking what
  # autoPatchelf still complains about — run `ldd PNGTube-Remix.x86_64` in
  # $out yourself if something's missing at runtime.
  buildInputs = [
    alsa-lib
    dbus
    fontconfig
    freetype
    libGL
    libpulseaudio
    libxkbcommon
    udev
    vulkan-loader
    wayland
    zlib
    libX11
    libXcursor
    libXext
    libXfixes
    libXi
    libXrandr
    libXrender
  ];

  dontConfigure = true;
  dontBuild = true;

  installPhase = ''
    runHook preInstall

    mkdir -p $out/share/pngtuber-remix $out/bin

    cp -r ./. $out/share/pngtuber-remix/

    binPath=$(find $out/share/pngtuber-remix -name 'PNGTube-Remix.x86_64')
    chmod +x "$binPath"

    makeWrapper "$binPath" $out/bin/pngtuber-remix

    runHook postInstall
  '';

  desktopItems = [
    (makeDesktopItem {
      name = "pngtuber-remix";
      exec = "pngtuber-remix";
      icon = "pngtuber-remix";
      desktopName = "PNGTuber-Remix";
      comment = finalAttrs.meta.description;
      categories = [ "AudioVideo" "Video" ];
    })
  ];

  meta = {
    description = "Open-source PNGTubing/VTubing app built with Godot";
    homepage = "https://github.com/MudkipWorld/PNGTuber-Remix";
    # Custom license: free to use, but commercial use/distribution/selling
    # requires the author's permission. Not OSI-approved -> not a stock
    # `lib.licenses.*` entry. See the upstream LICENSE file directly.
    license = {
      fullName = "PNGTuber-Remix Custom License";
      url = "https://github.com/MudkipWorld/PNGTuber-Remix/blob/1.4.x/LICENSE";
      free = false;
    };
    sourceProvenance = [ lib.sourceTypes.binaryNativeCode ];
    platforms = [ "x86_64-linux" ];
    mainProgram = "pngtuber-remix";
    maintainers = [ ]; # add yourself: with lib.maintainers; [ yourGithubHandle ]
  };
})
