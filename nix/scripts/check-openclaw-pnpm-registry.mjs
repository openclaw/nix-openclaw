import assert from "node:assert/strict";
import { spawn } from "node:child_process";
import { createHash } from "node:crypto";
import fs from "node:fs";
import http from "node:http";
import os from "node:os";
import path from "node:path";
import test from "node:test";

const contracts = JSON.parse(fs.readFileSync(process.env.PNPM_REGISTRY_CONTRACTS, "utf8"));
const policy = "packages:\n  - '.'\nminimumReleaseAge: 10080\nminimumReleaseAgeStrict: true\n";
const hash = (bytes, algorithm = "sha512") =>
  `${algorithm}-${createHash(algorithm).update(bytes).digest("base64")}`;
const write = (file, value) => fs.writeFileSync(file, value);
const mkdir = (dir) => fs.mkdirSync(dir, { recursive: true });

async function run(command, args, { cwd, env, input, status = 0 }) {
  const child = spawn(command, args, { cwd, env, timeout: 60_000, stdio: "pipe" });
  let stdout = "";
  let stderr = "";
  child.stdout.on("data", (data) => (stdout += data));
  child.stderr.on("data", (data) => (stderr += data));
  child.stdin.on("error", () => {});
  child.stdin.end(input);
  const code = await new Promise((resolve, reject) => {
    child.once("error", reject);
    child.once("close", (value, signal) => {
      if (signal) reject(new Error(`${command} terminated by ${signal}\n${stdout}${stderr}`));
      else resolve(value);
    });
  });
  assert.equal(code, status, `${command} ${args.join(" ")}\n${stdout}${stderr}`);
  return { stdout, stderr };
}

function environment(root, contract) {
  mkdir(`${root}/home`);
  mkdir(`${root}/tmp`);
  return {
    PATH: `${path.dirname(contract.pnpm)}:${process.env.PATH}`,
    HOME: `${root}/home`,
    XDG_CONFIG_HOME: `${root}/home/config`,
    XDG_CACHE_HOME: `${root}/home/cache`,
    XDG_DATA_HOME: `${root}/home/data`,
    PNPM_CONFIG_CACHE_DIR: `${root}/home/cache/pnpm`,
    pnpm_config_pm_on_fail: "ignore",
    pnpm_config_side_effects_cache: "false",
    pnpm_config_update_notifier: "false",
    NPM_CONFIG_USERCONFIG: "/dev/null",
    NPM_CONFIG_GLOBALCONFIG: "/dev/null",
    TMPDIR: `${root}/tmp`,
    PYTHONNOUSERSITE: "1",
    CI: "true",
    COPYFILE_DISABLE: "1",
    LC_ALL: "C",
  };
}

function assertUnchanged(project) {
  assert.equal(fs.readFileSync(`${project.cwd}/pnpm-lock.yaml`, "utf8"), project.lock);
  assert.equal(fs.readFileSync(`${project.cwd}/pnpm-workspace.yaml`, "utf8"), policy);
}

test("pnpm source producer and offline consumer contracts", async (t) => {
  const tmp = fs.mkdtempSync(path.join(os.tmpdir(), "pnpm-registry-"));
  const packages = new Map();
  const prepared = [];
  let registry;
  const server = http.createServer((req, res) => {
    const pathname = new URL(req.url, registry).pathname;
    const name = pathname.split("/")[1];
    const entry = packages.get(name);
    assert.equal(req.headers.authorization, undefined);
    if (req.method !== "GET" || !entry) {
      res.writeHead(404).end();
    } else if (pathname === `/${name}/-/${name}-1.0.0.tgz`) {
      res.writeHead(200, { "content-type": "application/octet-stream" }).end(entry.tarball);
    } else {
      res.setHeader("content-type", "application/json");
      res.end(
        JSON.stringify({
          name,
          "dist-tags": { latest: "1.0.0" },
          time: { created: entry.published, modified: entry.published, "1.0.0": entry.published },
          versions: {
            "1.0.0": {
              name,
              version: "1.0.0",
              main: "index.js",
              dist: {
                integrity: entry.integrity,
                tarball: `${registry}${name}/-/${name}-1.0.0.tgz`,
              },
            },
          },
        }),
      );
    }
  });
  try {
    for (const name of ["pnpm-contract-mature", "pnpm-contract-young"]) {
      const root = `${tmp}/${name}`;
      mkdir(`${root}/package`);
      write(
        `${root}/package/package.json`,
        JSON.stringify({ name, version: "1.0.0", main: "index.js" }),
      );
      write(`${root}/package/index.js`, 'module.exports = "registry-offline-ok";\n');
      await run("tar", ["-czf", `${root}/package.tgz`, "-C", root, "package"], {
        cwd: root,
        env: environment(root, contracts[0]),
      });
      const tarball = fs.readFileSync(`${root}/package.tgz`);
      packages.set(name, {
        tarball,
        integrity: hash(tarball),
        published: name.endsWith("young") ? new Date().toISOString() : "2020-01-01T00:00:00.000Z",
      });
    }
    await new Promise((resolve) => server.listen(0, "127.0.0.1", resolve));
    registry = `http://127.0.0.1:${server.address().port}/`;

    for (const contract of contracts) {
      const version = await run(contract.pnpm, ["--version"], {
        cwd: tmp,
        env: environment(`${tmp}/version-${contract.major}`, contract),
      });
      assert.equal(version.stdout.trim(), contract.version);
      for (const kind of ["standalone", "bootstrap", "env-only", "third-document", "young"]) {
        await t.test(`pnpm ${contract.major} producer ${kind}`, async (producerTest) => {
          const root = `${tmp}/${contract.major}-${kind}`;
          const cwd = `${root}/project`;
          mkdir(cwd);
          const name = kind === "young" ? "pnpm-contract-young" : "pnpm-contract-mature";
          const workspace = {
            lockfileVersion: "9.0",
            settings: { autoInstallPeers: true, excludeLinksFromLockfile: false },
            importers: {
              ".": { dependencies: { [name]: { specifier: "1.0.0", version: "1.0.0" } } },
            },
            packages: {
              [`${name}@1.0.0`]: { resolution: { integrity: packages.get(name).integrity } },
            },
            snapshots: { [`${name}@1.0.0`]: {} },
          };
          // The bootstrap manager is provided by Nix, not installed into the workspace store.
          const bootstrap = {
            lockfileVersion: "9.0",
            importers: {
              ".": {
                packageManagerDependencies: {
                  pnpm: { specifier: contract.version, version: contract.version },
                },
              },
            },
            packages: {
              [`pnpm@${contract.version}`]: { resolution: { integrity: hash("bootstrap") } },
            },
            snapshots: { [`pnpm@${contract.version}`]: {} },
          };
          const main = JSON.stringify(workspace) + "\n";
          const prefix = "---\n" + JSON.stringify(bootstrap) + "\n";
          const lock = ["standalone", "young"].includes(kind)
            ? main
            : kind === "env-only"
              ? prefix
              : prefix + "---\n" + main + (kind === "third-document" ? "---\n{}\n" : "");
          write(
            `${cwd}/package.json`,
            JSON.stringify({
              private: true,
              packageManager: `pnpm@${contract.version}`,
              dependencies: { [name]: "1.0.0" },
            }),
          );
          write(`${cwd}/pnpm-lock.yaml`, lock);
          write(`${cwd}/pnpm-workspace.yaml`, policy);
          const project = { root, cwd, lock, env: environment(root, contract), contract };
          const valid = ["standalone", "bootstrap"].includes(kind);
          const output = await run(
            contract.pnpm,
            [
              "install",
              "--force",
              "--ignore-scripts",
              "--frozen-lockfile",
              "--store-dir",
              `${root}/store`,
              "--registry",
              registry,
            ],
            { ...project, status: valid ? 0 : 1 },
          );
          assertUnchanged(project);
          if (!valid) {
            assert.match(
              output.stdout + output.stderr,
              kind === "young"
                ? /ERR_PNPM_MINIMUM_RELEASE_AGE_VIOLATION/
                : /ERR_PNPM_(BROKEN_LOCKFILE|NO_LOCKFILE)/,
            );
            return;
          }
          assert.match(output.stdout + output.stderr, /Lockfile passes supply-chain policies/);
          const deps = `${root}/deps`;
          mkdir(deps);
          const env = { ...project.env, storePath: `${root}/store`, out: deps };
          await run(process.env.BASH, ["-e", contract.postInstall], { cwd, env });
          if (kind === "standalone") prepared.push({ ...project, deps });
          await producerTest.test(`pnpm ${contract.major} ${kind} actual preFixup`, async () => {
            await run(process.env.BASH, ["-e", contract.preFixup], { cwd, env });
            assertUnchanged(project);
          });
          if (kind === "bootstrap") {
            const missing = `${root}/missing-store`;
            fs.cpSync(`${root}/store`, missing, { recursive: true });
            await run("sqlite3", [`${missing}/v11/index.db`, "DELETE FROM package_index;"], {
              cwd,
              env,
            });
            const missingOutput = await run(process.env.BASH, ["-e", contract.preFixup], {
              cwd,
              env: { ...env, storePath: missing },
              status: 1,
            });
            assert.match(
              missingOutput.stdout + missingOutput.stderr,
              /pnpm-contract-mature@1\.0\.0/,
            );
            assertUnchanged(project);
          }
        });
      }
    }
    await new Promise((resolve) => server.close(resolve));
    await assert.rejects(fetch(registry), (error) => error.cause?.code === "ECONNREFUSED");

    for (const producer of prepared) {
      const { contract, deps } = producer;
      const db = `${producer.root}/store/v11/index.db`;
      const dump = await run("sqlite3", [db, ".dump"], producer);
      write(`${db}.sql`, dump.stdout);
      fs.rmSync(db);
      write(`${deps}/.fetcher-version`, "4\n");
      await run(
        "tar",
        ["-cf", `${deps}/pnpm-store.tar`, "-C", `${producer.root}/store`, "."],
        producer,
      );
      await run("zstd", ["-q", "--rm", `${deps}/pnpm-store.tar`], producer);
      for (const mismatch of [false, true]) {
        await t.test(
          `pnpm ${contract.major} consumer ${mismatch ? "frozen rejection" : "offline import"}`,
          async () => {
            const root = `${producer.root}/consumer-${mismatch}`;
            const cwd = `${root}/project`;
            mkdir(cwd);
            mkdir(`${root}/build-top`);
            for (const file of ["package.json", "pnpm-lock.yaml", "pnpm-workspace.yaml"]) {
              fs.copyFileSync(`${producer.cwd}/${file}`, `${cwd}/${file}`);
            }
            const manifest = JSON.parse(fs.readFileSync(`${cwd}/package.json`, "utf8"));
            if (mismatch) manifest.dependencies["not-in-frozen-lock"] = "1.0.0";
            write(`${cwd}/package.json`, JSON.stringify(manifest));
            const env = {
              ...environment(root, contract),
              ...contract.consumerEnv,
              PNPM_DEPS: deps,
              NIX_BUILD_TOP: `${root}/build-top`,
              out: `${root}/out`,
            };
            for (const key of [
              "GATEWAY_PREBUILD_SH",
              "OPENCLAW_BUILD_ROOT_SH",
              "PROMOTE_PNPM_INTEGRITY_SH",
              "NODE_GYP_WRAPPER_SH",
              "REMOVE_PACKAGE_MANAGER_FIELD_SH",
            ]) {
              env[key] = process.env[key];
            }
            assert.deepEqual(fs.readdirSync(env.HOME), []);
            await run("sh", [env.REMOVE_PACKAGE_MANAGER_FIELD_SH, "package.json"], { cwd, env });
            delete manifest.packageManager;
            assert.deepEqual(JSON.parse(fs.readFileSync(`${cwd}/package.json`, "utf8")), manifest);
            assertUnchanged({ cwd, lock: producer.lock });
            const output = await run(
              "sh",
              [
                "-ec",
                `
. "$GATEWAY_PREBUILD_SH"
store_path="$(cat .pnpm-store-path)"
test -f "$store_path/v11/index.db"
test ! -f "$store_path/v11/index.db.sql"
pnpm install --offline --frozen-lockfile --ignore-scripts --store-dir "$store_path" --registry "$1"
node -e 'if (require("pnpm-contract-mature") !== "registry-offline-ok") process.exit(1); console.log("REAL_PACKAGE_IMPORT_OK");'
`,
                "sh",
                registry,
              ],
              { cwd, env, status: mismatch ? 1 : 0 },
            );
            assert.match(
              output.stdout + output.stderr,
              mismatch ? /ERR_PNPM_OUTDATED_LOCKFILE/ : /REAL_PACKAGE_IMPORT_OK/,
            );
            assertUnchanged({ cwd: `${root}/build-top/.openclaw-build`, lock: producer.lock });
          },
        );
      }
    }
    assert.equal(prepared.length, contracts.length);
  } finally {
    if (server.listening) await new Promise((resolve) => server.close(resolve));
    fs.rmSync(tmp, { recursive: true, force: true });
  }
});
