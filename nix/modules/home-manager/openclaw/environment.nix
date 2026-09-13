{ lib, pkgs }:
{
  renderExports = entries: ''
    . ${../openclaw-export-env.sh}
    ${lib.concatMapStringsSep "\n" (
      entry:
      "openclawExportEnv ${
        lib.escapeShellArgs [
          entry.key
          entry.value
          (lib.getExe' pkgs.coreutils "cat")
        ]
      }"
    ) entries}
  '';

  renderGuards =
    entries:
    lib.concatMapStringsSep "\n" (
      entry:
      "${pkgs.bash}/bin/bash ${../openclaw-check-env-file.sh} ${
        lib.escapeShellArgs [
          entry.key
          entry.value
          entry.plugin
          entry.instance
        ]
      }"
    ) entries;
}
