import fs from "node:fs";
import path from "node:path";
import { DatabaseSync } from "node:sqlite";
import { pathToFileURL } from "node:url";

export function restorePnpmStore(storePath) {
  for (const entry of fs.readdirSync(storePath, { withFileTypes: true })) {
    if (!entry.isDirectory() || !/^v[0-9]+$/.test(entry.name)) continue;
    const databasePath = path.join(storePath, entry.name, "index.db");
    const dumpPath = `${databasePath}.sql`;
    if (!fs.existsSync(dumpPath)) continue;
    const temporary = `${databasePath}.restore`;
    const database = new DatabaseSync(temporary);
    try {
      database.exec(fs.readFileSync(dumpPath, "utf8"));
    } catch (error) {
      database.close();
      fs.rmSync(temporary);
      throw error;
    }
    database.close();
    fs.renameSync(temporary, databasePath);
    fs.unlinkSync(dumpPath);
  }
}

if (process.argv[1] && import.meta.url === pathToFileURL(path.resolve(process.argv[1])).href) {
  if (!process.argv[2]) throw new Error("usage: restore-pnpm-store.mjs STORE_PATH");
  restorePnpmStore(process.argv[2]);
}
