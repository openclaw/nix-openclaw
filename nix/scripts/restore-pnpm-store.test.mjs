import assert from "node:assert/strict";
import fs from "node:fs";
import os from "node:os";
import path from "node:path";
import { DatabaseSync } from "node:sqlite";
import test from "node:test";
import { restorePnpmStore } from "./restore-pnpm-store.mjs";

function fixture(t) {
  const root = fs.mkdtempSync(path.join(os.tmpdir(), "pnpm-store-restore-"));
  t.after(() => fs.rmSync(root, { recursive: true, force: true }));
  fs.mkdirSync(path.join(root, "v11"));
  return { root, database: path.join(root, "v11/index.db"), dump: path.join(root, "v11/index.db.sql") };
}
test("restore the reproducible SQLite dump before offline pnpm reads its package index", (t) => {
  const f = fixture(t);
  fs.writeFileSync(f.dump, "BEGIN TRANSACTION; CREATE TABLE package_index (key TEXT PRIMARY KEY, value BLOB); INSERT INTO package_index VALUES ('sha512-package', X'010203'); COMMIT;");
  restorePnpmStore(f.root);
  const db = new DatabaseSync(f.database, { readOnly: true });
  assert.equal(db.prepare("SELECT hex(value) AS value FROM package_index WHERE key = ?").get("sha512-package").value, "010203");
  db.close();
  assert.equal(fs.existsSync(f.dump), false);
  const bytes = fs.readFileSync(f.database);
  restorePnpmStore(f.root);
  assert.deepEqual(fs.readFileSync(f.database), bytes);
});
test("invalid dumps fail without replacing an existing package index or consuming the dump", (t) => {
  const f = fixture(t);
  const db = new DatabaseSync(f.database);
  db.exec("CREATE TABLE original (id INTEGER)");
  db.close();
  const before = fs.readFileSync(f.database);
  fs.writeFileSync(f.dump, "CREATE TABLE partial (id INTEGER); INVALID SQL;");
  assert.throws(() => restorePnpmStore(f.root));
  assert.deepEqual(fs.readFileSync(f.database), before);
  assert.equal(fs.existsSync(f.dump), true);
  assert.equal(fs.existsSync(`${f.database}.restore`), false);
});
