# package.nix for EmoTracker (https://github.com/EmoTracker-Community/EmoTracker)
#
# EmoTracker is a .NET 10 / Avalonia 11 desktop app (item & location tracker for
# randomized games). The solution is multi-project (EmoTracker.Core,
# EmoTracker.Data, EmoTracker.UI, EmoTracker.SourceGenerators(+.Tests),
# EmoTracker) but only EmoTracker/EmoTracker.csproj needs to be built — it
# pulls the others in via ProjectReference.
#
# Build facts pulled directly from the repo (.csproj files + .github/workflows):
#   - TargetFramework: net10.0 (EmoTracker.SourceGenerators targets netstandard2.0
#     since it's a Roslyn analyzer, but that's an implementation detail of the
#     build, not something you need to set here).
#   - Upstream CI publishes with:
#       dotnet publish EmoTracker/EmoTracker.csproj --framework net10.0 \
#         --configuration Release --runtime linux-x64 --self-contained
#   - Upstream CI sets `EnableWindowsTargeting=true` as a job-level env var on
#     Linux/macOS runners — needed because NetSparkleUpdater.UI.Avalonia ships a
#     net*-windows TFM in its lib set that NuGet restore wants to evaluate even
#     though we never use it.
#   - libvosk (native voice-recognition lib) is NOT picked up automatically by
#     `dotnet publish` on Linux — upstream CI copies it manually from the `Vosk`
#     NuGet package's `build/lib/<rid>/` folder after publishing. We replicate
#     that in postInstall below.
#   - PortAudioSharp (microphone access for voice recognition) expects a system
#     libportaudio at runtime on Linux (upstream doesn't bundle it for linux-x64
#     in CI either) — provided via runtimeDeps.
#   - NDI broadcasting (NDILibDotNetCoreBase) P/Invokes into the proprietary NDI
#     runtime library, which Nixpkgs cannot legally redistribute. It's optional
#     at runtime: without libndi installed system-side, NDI broadcasting simply
#     won't be available — this is not a build-breaking dependency.
#
# THINGS YOU MUST FILL IN / VERIFY YOURSELF — I do not have a working `nix` or
# `dotnet` toolchain in the environment I drafted this in, so I could not
# actually build this or compute real hashes:
#
#   1. `hash` below is `lib.fakeHash`. Run a build, copy the "got: sha256-..."
#      hash from the error into its place, and repeat.
#   2. `nugetDeps` needs a real lockfile. With a modern nixpkgs, buildDotnetModule
#      exposes a `fetch-deps` passthru script:
#         nix build .#emotracker.fetch-deps   # (adjust attr path to wherever
#                                              #  you wire this up, e.g. via
#                                              #  callPackage in your own flake)
#         ./result ./deps.json
#      That runs `dotnet restore` against every csproj in the tree (including
#      the test project — harmless, just extra deps) and writes deps.json next
#      to this file. Commit that file alongside package.nix.
#   3. Verify `dotnetCorePackages.sdk_10_0` exists in the nixpkgs revision you're
#      pinned to. .NET 10 is very recent; if it's missing, point `dotnet-sdk`/
#      `dotnet-runtime` at a nixpkgs revision that has it (or an overlay).
#   4. The `runtimeDeps` list is my best-effort guess based on what Avalonia 11
#      (X11 backend) + SkiaSharp + PortAudioSharp typically need on Linux —
#      treat it as a starting point and trim/extend based on `ldd`/runtime
#      errors you actually see.
#   5. The `postInstall` libvosk copy step assumes buildDotnetModule's NuGet
#      package cache is still reachable at `$NUGET_PACKAGES` during `installPhase`
#      and that the package layout matches what CI found
#      (`vosk/<version>/build/lib/linux-x64/libvosk.so`). Confirm the path once
#      you can actually inspect the build sandbox.

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
    hash = "sha256-MTTJbj1mdEwmWU2J6SjoHFI219c4yr0dUbnnTDrMAI0="; # TODO: replace with the real hash, see notes above
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
    voskLib=$(find "$NUGET_PACKAGES/vosk" -path '*/build/lib/linux-x64/libvosk.so' -print -quit)
    if [ -n "$voskLib" ]; then
      cp "$voskLib" "$out/lib/${finalAttrs.pname}/libvosk.so"
    else
      echo "WARNING: libvosk.so not found in NuGet cache; voice recognition will not work" >&2
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
