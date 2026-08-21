import assert from "node:assert/strict";
import test from "node:test";

import { markdownTableCell } from "./markdown-table.mjs";

test("escapes every backslash and table separator", () => {
  assert.equal(markdownTableCell(String.raw`left\|middle\\|right`), String.raw`left\\\|middle\\\\\|right`);
});

test("keeps untrusted values inside one table row", () => {
  assert.equal(markdownTableCell("first\r\nsecond\nthird\rfourth"), "first second third fourth");
});

test("normalizes non-string values", () => {
  assert.equal(markdownTableCell(42), "42");
});
