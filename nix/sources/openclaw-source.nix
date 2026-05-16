# Pinned OpenClaw source for nix-openclaw
{
  owner = "openclaw";
  repo = "openclaw";
  pnpmMajor = "11";
  publicSurfaceHardlinksPatch = ../patches/allow-package-public-surface-hardlinks-open-root.patch;
  applySkipPluginAutoEnableNixModePatch = false;
  releaseTag = "v2026.5.12";
  releaseVersion = "2026.5.12";
  rev = "f066dd2f31c231f38fbcaacd6f6dfce0801143b3";
  hash = "sha256-URuoljISNcDLuWUwOpZoFjPNVOmbThC9r00uShPR4Co=";
  pnpmDepsHash = "sha256-0c11ZIH3oK2ZAG6qcU/He5E/8L5SBP1pwA8SrGUG3O4=";
}
