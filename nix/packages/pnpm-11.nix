{
  lib,
  stdenvNoCC,
  fetchurl,
  nodejs_22,
}:

stdenvNoCC.mkDerivation (finalAttrs: {
  pname = "pnpm";
  version = "11.1.0";

  src = fetchurl {
    url = "https://registry.npmjs.org/pnpm/-/pnpm-${finalAttrs.version}.tgz";
    hash = "sha256-VzyCrTVuiwl+bKxIG3OB+d7tM6MYr38xGYSFjr4fl+8=";
  };

  preConfigure = ''
    rm -rf dist/reflink.*node dist/vendor
  '';

  buildInputs = [ nodejs_22 ];
  nativeBuildInputs = [ nodejs_22 ];

  installPhase = ''
    runHook preInstall

    install -d $out/{bin,libexec}
    cp -R . $out/libexec/pnpm
    chmod +x $out/libexec/pnpm/bin/pnpm.cjs $out/libexec/pnpm/bin/pnpx.cjs
    substitute ${../scripts/pnpm-11-wrapper.sh} $out/bin/pnpm \
      --subst-var-by node ${nodejs_22}/bin/node \
      --subst-var-by entrypoint $out/libexec/pnpm/bin/pnpm.cjs
    substitute ${../scripts/pnpm-11-wrapper.sh} $out/bin/pnpx \
      --subst-var-by node ${nodejs_22}/bin/node \
      --subst-var-by entrypoint $out/libexec/pnpm/bin/pnpx.cjs
    chmod +x $out/bin/pnpm $out/bin/pnpx

    runHook postInstall
  '';

  passthru.majorVersion = lib.versions.major finalAttrs.version;

  meta = {
    description = "Fast, disk space efficient package manager for JavaScript";
    homepage = "https://pnpm.io/";
    changelog = "https://github.com/pnpm/pnpm/releases/tag/v${finalAttrs.version}";
    license = lib.licenses.mit;
    platforms = lib.platforms.unix;
    mainProgram = "pnpm";
  };
})
