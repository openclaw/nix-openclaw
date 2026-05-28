#!/usr/bin/env node
"use strict";

const fs = require("node:fs");
const path = require("node:path");
const { DatabaseSync } = require("node:sqlite");

const fixedCheckedAt = Buffer.alloc(8);
fixedCheckedAt.writeDoubleBE(4102444800000, 0); // 2100-01-01T00:00:00Z
const fixedCheckedAtMillis = 4102444800000n; // 2100-01-01T00:00:00Z
const minTimestampMillis = 946684800000n; // 2000-01-01T00:00:00Z
const maxTimestampMillis = 4102444800000n;

function normalizeTimestampMillis(value) {
  return value > minTimestampMillis && value < maxTimestampMillis;
}

function need(buffer, offset, bytes) {
  if (offset + bytes > buffer.length) {
    throw new Error(`truncated msgpack payload at offset ${offset}`);
  }
}

function readLength(buffer, offset, bytes) {
  need(buffer, offset, bytes);
  if (bytes === 1) return [buffer.readUInt8(offset), offset + 1];
  if (bytes === 2) return [buffer.readUInt16BE(offset), offset + 2];
  if (bytes === 4) return [buffer.readUInt32BE(offset), offset + 4];
  throw new Error(`unsupported length width ${bytes}`);
}

function normalizeMsgpackFloats(buffer) {
  const out = Buffer.from(buffer);

  function walk(offset) {
    need(out, offset, 1);
    const token = out.readUInt8(offset++);

    if (token <= 0x7f || token >= 0xe0) return offset;

    if (token >= 0x80 && token <= 0x8f) {
      let count = (token & 0x0f) * 2;
      while (count-- > 0) offset = walk(offset);
      return offset;
    }

    if (token >= 0x90 && token <= 0x9f) {
      let count = token & 0x0f;
      while (count-- > 0) offset = walk(offset);
      return offset;
    }

    if (token >= 0xa0 && token <= 0xbf) {
      const length = token & 0x1f;
      need(out, offset, length);
      return offset + length;
    }

    switch (token) {
      case 0xc0:
      case 0xc2:
      case 0xc3:
        return offset;
      case 0xc4:
      case 0xd9: {
        const [length, next] = readLength(out, offset, 1);
        need(out, next, length);
        return next + length;
      }
      case 0xc5:
      case 0xda: {
        const [length, next] = readLength(out, offset, 2);
        need(out, next, length);
        return next + length;
      }
      case 0xc6:
      case 0xdb: {
        const [length, next] = readLength(out, offset, 4);
        need(out, next, length);
        return next + length;
      }
      case 0xc7: {
        const [length, next] = readLength(out, offset, 1);
        need(out, next, 1 + length);
        return next + 1 + length;
      }
      case 0xc8: {
        const [length, next] = readLength(out, offset, 2);
        need(out, next, 1 + length);
        return next + 1 + length;
      }
      case 0xc9: {
        const [length, next] = readLength(out, offset, 4);
        need(out, next, 1 + length);
        return next + 1 + length;
      }
      case 0xca:
        need(out, offset, 4);
        return offset + 4;
      case 0xcb:
        need(out, offset, 8);
        if (out.readDoubleBE(offset) > 946684800000 && out.readDoubleBE(offset) < 4102444800000) {
          fixedCheckedAt.copy(out, offset);
        }
        return offset + 8;
      case 0xcc:
      case 0xd0:
        need(out, offset, 1);
        return offset + 1;
      case 0xcd:
      case 0xd1:
        need(out, offset, 2);
        return offset + 2;
      case 0xce:
      case 0xd2:
        need(out, offset, 4);
        return offset + 4;
      case 0xcf:
        need(out, offset, 8);
        if (normalizeTimestampMillis(out.readBigUInt64BE(offset))) {
          out.writeBigUInt64BE(fixedCheckedAtMillis, offset);
        }
        return offset + 8;
      case 0xd3:
        need(out, offset, 8);
        if (normalizeTimestampMillis(out.readBigInt64BE(offset))) {
          out.writeBigInt64BE(fixedCheckedAtMillis, offset);
        }
        return offset + 8;
      case 0xd4:
        need(out, offset, 2);
        return offset + 2;
      case 0xd5:
        need(out, offset, 3);
        return offset + 3;
      case 0xd6:
        need(out, offset, 5);
        return offset + 5;
      case 0xd7:
        need(out, offset, 9);
        return offset + 9;
      case 0xd8:
        need(out, offset, 17);
        return offset + 17;
      case 0xdc: {
        let [count, next] = readLength(out, offset, 2);
        offset = next;
        while (count-- > 0) offset = walk(offset);
        return offset;
      }
      case 0xdd: {
        let [count, next] = readLength(out, offset, 4);
        offset = next;
        while (count-- > 0) offset = walk(offset);
        return offset;
      }
      case 0xde: {
        let [count, next] = readLength(out, offset, 2);
        offset = next;
        count *= 2;
        while (count-- > 0) offset = walk(offset);
        return offset;
      }
      case 0xdf: {
        let [count, next] = readLength(out, offset, 4);
        offset = next;
        count *= 2;
        while (count-- > 0) offset = walk(offset);
        return offset;
      }
      default:
        throw new Error(`unsupported msgpack token 0x${token.toString(16)} at offset ${offset - 1}`);
    }
  }

  let offset = 0;
  while (offset < out.length) {
    offset = walk(offset);
  }

  return out;
}

function normalizeDatabase(dbPath) {
  const source = new DatabaseSync(dbPath);
  const rows = source
    .prepare("SELECT key, data FROM package_index ORDER BY key")
    .all()
    .map(({ key, data }) => ({ key, data: normalizeMsgpackFloats(data) }));
  source.close();

  fs.rmSync(dbPath, { force: true });
  fs.rmSync(`${dbPath}-shm`, { force: true });
  fs.rmSync(`${dbPath}-wal`, { force: true });

  const db = new DatabaseSync(dbPath);
  db.exec(`
    PRAGMA journal_mode=DELETE;
    PRAGMA synchronous=OFF;
    CREATE TABLE package_index (
      key TEXT PRIMARY KEY,
      data BLOB NOT NULL
    ) WITHOUT ROWID;
    BEGIN IMMEDIATE;
  `);
  const insert = db.prepare("INSERT INTO package_index (key, data) VALUES (?, ?)");
  for (const { key, data } of rows) {
    insert.run(key, data);
  }
  db.exec("COMMIT; VACUUM;");
  db.close();
}

function normalizeStore(storePath) {
  for (const entry of fs.readdirSync(storePath, { withFileTypes: true })) {
    if (!entry.isDirectory() || !/^v[0-9]+$/.test(entry.name)) continue;

    const versionDir = path.join(storePath, entry.name);
    fs.rmSync(path.join(versionDir, "projects"), { force: true, recursive: true });

    const dbPath = path.join(versionDir, "index.db");
    if (fs.existsSync(dbPath)) {
      normalizeDatabase(dbPath);
    }
  }
}

const storePath = process.argv[2];
if (!storePath) {
  console.error("usage: normalize-pnpm-store-index.js STORE_PATH");
  process.exit(2);
}

normalizeStore(storePath);
