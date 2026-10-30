{ pkgs, nodejs }:
package:
# Both built-in delivery paths use this existing tool input. Darwin's native
# archive has no substitutable Node runtime and remains supplier-owned.
if pkgs.stdenv.hostPlatform.isLinux then package.override { inherit nodejs; } else package
