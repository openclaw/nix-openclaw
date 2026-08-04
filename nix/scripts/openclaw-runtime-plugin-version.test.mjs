import assert from "node:assert/strict";
import test from "node:test";

import {
  correctionBaseVersion,
  defaultCatalogVersion,
  resolveRuntimePluginVersion,
} from "./openclaw-runtime-plugin-version.mjs";

test("normal releases use the release version for official plugins", () => {
  assert.equal(correctionBaseVersion("2026.7.1"), null);
  assert.equal(resolveRuntimePluginVersion("2026.7.1", "2026.7.1"), "2026.7.1");
  assert.equal(defaultCatalogVersion("official", "2026.7.1", "2026.7.1"), "2026.7.1");
});

test("correction releases use tagged package metadata for official plugins", () => {
  assert.equal(correctionBaseVersion("2026.7.1-2"), "2026.7.1");
  assert.equal(resolveRuntimePluginVersion("2026.7.1-2", "2026.7.1"), "2026.7.1");
  assert.equal(
    defaultCatalogVersion("official", "2026.7.1-2", "2026.7.1"),
    "2026.7.1",
  );
  assert.equal(
    defaultCatalogVersion("community", "2026.7.1-2", "2026.7.1"),
    "2026.7.1-2",
  );
});

test("runtime plugin metadata cannot drift from the release line", () => {
  assert.throws(
    () => resolveRuntimePluginVersion("2026.7.1-2", "2026.7.2"),
    /must match release 2026\.7\.1-2 or its correction base version/,
  );
  assert.throws(
    () => resolveRuntimePluginVersion("2026.7.1-beta.2", "2026.7.1"),
    /must match release 2026\.7\.1-beta\.2 or its correction base version/,
  );
});
