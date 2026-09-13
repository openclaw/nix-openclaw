{
  lib,
  stdenvNoCC,
  fetchurl,
  nodejs_24,
  makeWrapper,
}:
stdenvNoCC.mkDerivation {
  pname = "node-semver";
  version = "7.8.5";
  src = fetchurl {
    url = "https://registry.npmjs.org/semver/-/semver-7.8.5.tgz";
    hash = "sha512-Y7/KDsb8LjooZpwaqGyulO6DQlksgCncchHGk+sZIY4SBvUocMBEFH5Ur1fI4dV+Jvl0w6cjvucaIi40puRioA==";
  };
  nativeBuildInputs = [ makeWrapper ];
  dontBuild = true;
  NODE_BIN = "${nodejs_24}/bin/node";
  installPhase = "${../scripts/node-semver-install.sh}";
  meta = {
    description = "npm semver CLI for maintainer plugin compatibility checks";
    homepage = "https://github.com/npm/node-semver";
    license = lib.licenses.isc;
    mainProgram = "node-semver";
  };
}
