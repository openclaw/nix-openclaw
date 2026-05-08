{
  owner = "openclaw";
  repo = "openclaw";
  releaseVersion = "2026.5.7-dogfood.20260508";
  rev = "954d20ece2de0fba3688f7800613183fbeb9685c";
  hash = "sha256-6CZWsH8dV6XZ4JeG5ItKLqGAOFqbzWosyCmMXVc+c/g=";
  pnpmDepsHash = "sha256-hNZA1OEuJgtoLz2hWLPk8Hm+7heLvhiZpDdBBQ1UXpc=";
  fsSafeSource = {
    owner = "openclaw";
    repo = "fs-safe";
    rev = "c7ccb99d3058f2acf2ad2758ad2470c7e113a53c";
    hash = "sha256-jndOOSSFROyrK4RiwAsJfUuCJTj7qbmmm4Qz8BqtJ/c=";
  };

  applyPublicSurfaceHardlinksPatch = false;
  applySkipPluginAutoEnableNixModePatch = false;
}
