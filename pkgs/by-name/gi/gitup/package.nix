{
  lib,
  fetchurl,
  unzip,
  stdenv,
  nix-update-script,
}:

stdenv.mkDerivation (finalAttrs: {
  pname = "gitup";
  version = "1.4.3";
  src = fetchurl {
    url = "https://github.com/git-up/GitUp/releases/download/v${finalAttrs.version}/GitUp.zip";
    hash = "sha256-8PGJba56F+P1H2hyzFenkGGrP0dpLWS1qCFs+23dtNw=";
  };

  sourceRoot = ".";

  nativeBuildInputs = [ unzip ];

  installPhase = ''
    runHook preInstall

    mkdir -p "$out/"{bin,Applications}
    mv GitUp.app "$out/Applications/"
    ln -s "$out/Applications/GitUp.app/Contents/SharedSupport/gitup" "$out/bin/gitup"

    runHook postInstall
  '';

  passthru.updateScript = nix-update-script { };

  meta = {
    description = "The Git interface you've been missing all your life has finally arrived.";
    homepage = "https://gitup.co";
    license = lib.licenses.gpl3;
    maintainers = with lib.maintainers; [ dudeofawesome ];
    platforms = lib.platforms.darwin;
    sourceProvenance = with lib.sourceTypes; [ binaryNativeCode ];
    mainProgram = "gitup";
  };
})
