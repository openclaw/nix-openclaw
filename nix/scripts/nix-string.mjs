// Nix interpolation is not JSON interpolation; encode data before emitting source.
export function nixString(value) {
  if (value.includes("\0")) throw new Error("Nix strings cannot contain NUL bytes");
  const escapes = { "\\": "\\\\", '"': '\\"', "${": "\\${", "\n": "\\n", "\r": "\\r", "\t": "\\t" };
  return `"${value.replace(/\\|"|\$\{|\n|\r|\t/g, (character) => escapes[character])}"`;
}
