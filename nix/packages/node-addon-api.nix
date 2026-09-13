{ stdenv, fetchurl }:

stdenv.mkDerivation {
  pname = "node-addon-api";
  version = "8.9.2";

  src = fetchurl {
    url = "https://registry.npmjs.org/node-addon-api/-/node-addon-api-8.9.2.tgz";
    hash = "sha256-TNZWmFQbGaM/eY8dwlwCxu0cnXdJuIJLGhzOzdGXyOo=";
  };

  dontConfigure = true;
  dontBuild = true;

  installPhase = "${../scripts/node-addon-api-install.sh}";
}
