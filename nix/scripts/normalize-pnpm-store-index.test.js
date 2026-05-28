#!/usr/bin/env node
"use strict";

const assert = require("node:assert/strict");
const { spawnSync } = require("node:child_process");
const fs = require("node:fs");
const os = require("node:os");
const path = require("node:path");
const test = require("node:test");
const { DatabaseSync } = require("node:sqlite");

const script = path.join(__dirname, "normalize-pnpm-store-index.js");

function msgpackCheckedAt(token, value) {
  const valueBuffer = Buffer.alloc(8);
  if (token === 0xcf) {
    valueBuffer.writeBigUInt64BE(value);
  } else {
    valueBuffer.writeBigInt64BE(value);
  }
  return Buffer.concat([Buffer.from([0x81, 0xa9]), Buffer.from("checkedAt"), Buffer.from([token]), valueBuffer]);
}

function createStore(data) {
  const root = fs.mkdtempSync(path.join(os.tmpdir(), "pnpm-store-index-"));
  const versionDir = path.join(root, "v10");
  fs.mkdirSync(versionDir, { recursive: true });
  const db = new DatabaseSync(path.join(versionDir, "index.db"));
  db.exec("CREATE TABLE package_index (key TEXT PRIMARY KEY, data BLOB NOT NULL) WITHOUT ROWID");
  db.prepare("INSERT INTO package_index (key, data) VALUES (?, ?)").run("sha512-test\tpackage", data);
  db.close();
  return root;
}

function readData(root) {
  const db = new DatabaseSync(path.join(root, "v10", "index.db"), { readOnly: true });
  const row = db.prepare("SELECT data FROM package_index WHERE key = ?").get("sha512-test\tpackage");
  db.close();
  return row.data;
}

test("normalizes integer msgpack checkedAt timestamps", () => {
  for (const token of [0xcf, 0xd3]) {
    const root = createStore(msgpackCheckedAt(token, 1764230400123n));
    const result = spawnSync(process.execPath, [script, root], { encoding: "utf8" });
    assert.equal(result.status, 0, result.stderr);

    const got = Buffer.from(readData(root));
    assert.equal(got.readBigUInt64BE(got.length - 8), 4102444800000n);
  }
});
