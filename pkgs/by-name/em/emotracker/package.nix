# package.nix for EmoTracker (https://github.com/EmoTracker-Community/EmoTracker)

{ lib
, buildDotnetModule
, dotnetCorePackages
, fetchFromGitHub
, portaudio
, icu
, openssl
, fontconfig
, zlib
, libX11
, libICE
, libSM
, libXi
, libXcursor
, libXrandr
, libXrender
, libXext
, libXtst
}:

buildDotnetModule (finalAttrs: {
  pname = "emotracker";
  version = "3.0.3.2";

  src = fetchFromGitHub {
    owner = "EmoTracker-Community";
    repo = "EmoTracker";
    tag = "v${finalAttrs.version}";
    hash = "sha256-MTTJbj1mdEwmWU2J6SjoHFI219c4yr0dUbnnTDrMAI0=";
  };

  # Generate with the `fetch-deps` passthru script (see notes above).
  nugetDeps = ./deps.json;

  dotnet-sdk = dotnetCorePackages.sdk_10_0;
  dotnet-runtime = dotnetCorePackages.runtime_10_0;

  projectFile = "EmoTracker/EmoTracker.csproj";

  # Matches upstream's own release process (dotnet publish --self-contained).
  selfContainedBuild = true;
  useAppHost = true;

  executables = [ "EmoTracker" ];

  # Mirrors the job-level `EnableWindowsTargeting: true` env var in
  # .github/workflows/release.yml — needed for restore to succeed because of
  # NetSparkleUpdater.UI.Avalonia's windows-flavoured TFM.
  env.EnableWindowsTargeting = "true";

  # The app dynamically loads/P-invokes these natively at runtime.
  runtimeDeps = [
    portaudio    # PortAudioSharp (voice-recognition mic input)
    icu          # Avalonia/.NET globalization
    openssl      # TLS for gRPC (SNI provider) / NetSparkleUpdater / TwitchLib
    fontconfig
    zlib
    libX11       # Avalonia X11 backend
    libICE
    libSM
    libXi
    libXcursor
    libXrandr
    libXrender
    libXext
    libXtst
  ];

  # Upstream CI bundles libvosk.so manually post-publish because `dotnet
  # publish` doesn't pick it up automatically on Linux; replicate that here.
  postInstall = ''
    voskLib=$(find "$NUGET_PACKAGES" -ipath '*/vosk/*/build/lib/linux-x64/libvosk.so' -print -quit || true)
    if [ -n "$voskLib" ]; then
      cp "$voskLib" "$out/lib/${finalAttrs.pname}/libvosk.so"
    else
      echo "WARNING: libvosk.so not found in NuGet cache; voice recognition will not work" >&2
      echo "  (debug: contents of \$NUGET_PACKAGES follow)" >&2
      find "$NUGET_PACKAGES" -maxdepth 2 >&2 || true
    fi
  '';

  meta = {
    description = "Advanced item and location tracker for randomized games (e.g. A Link to the Past Randomizer)";
    homepage = "https://github.com/EmoTracker-Community/EmoTracker";
    license = lib.licenses.mit;
    mainProgram = "EmoTracker";
    platforms = [ "x86_64-linux" ];
    maintainers = [ ];
  };
})
