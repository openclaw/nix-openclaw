import assert from "node:assert/strict";
import fs from "node:fs";
import path from "node:path";
import test from "node:test";
import {
  fixture, patch, load, snapshot, change, envFor, paramsFor, restoreEnv, packageFixture, templateDocs,
} from "./patch-openclaw-npm-dist.fixtures.mjs";

for (const ext of ["js", "mjs"]) {
  test(`${ext}: emitted ownership/policy preserve guards and env boundaries`, async (t) => {
    const f = fixture(t, ext),
      result = patch(f);
    assert.equal(result.status, 0, result.stderr);
    const facts = await load(f, f.dependency),
      policy = (await load(f, f.policy)).t;
    const { checkPathStatAndPermissions: check, findCandidateBlockIssue: discover } = await load(f, f.discovery);
    restoreEnv(t);
    for (const [rootDir, canonical, store] of [
      ["/nix/store", "/nix/store", true],
      ["/nix/store/pkg", "/nix/store/pkg", true],
      ["/nix/store-other/pkg", "/nix/store-other/pkg", false],
      ["/alias", "/nix/store/pkg", true],
      ["/nix/store/escape", "/ordinary", false],
    ]) {
      facts.realpaths.set(rootDir, canonical);
      facts.stats.set(rootDir, { mode: 0o755, uid: 200 });
      for (const ambient of ["0", "1"])
        for (const supplied of [undefined, {}, envFor("1"), envFor("true")]) {
          process.env.OPENCLAW_NIX_MODE = ambient;
          const nix = (supplied ?? process.env).OPENCLAW_NIX_MODE === "1";
          for (const origin of ["config", "global", "bundled"]) {
            const params = { ...paramsFor(rootDir), origin, env: supplied };
            const reject = origin !== "bundled" && !(nix && store);
            assert.equal(policy(params), reject);
            assert.equal(check(params)?.reason ?? null, reject ? "path_suspicious_ownership" : null);
            for (const uid of [null, 200]) assert.equal(check({ ...params, uid }), null);
          }
        }
    }
    process.env.OPENCLAW_NIX_MODE = "0";
    const params = { ...paramsFor("/nix/store/pkg"), ownershipUid: 100, env: envFor("1") };
    assert.equal(check(params), null);
    assert.equal(discover(params).reason, "path_suspicious_ownership"); // Existing caller-env loss is not repaired here.
    facts.stats.set(params.rootDir, { mode: 0o755, uid: 0 });
    assert.equal(check({ ...params, env: {} }), null);
    facts.stats.set(params.rootDir, { mode: 0o777, uid: 0 });
    assert.equal(check(params).reason, "path_world_writable");
    facts.stats.set(params.rootDir, null);
    assert.equal(check(params).reason, "path_stat_failed");
    // Existing lexical fallback is retained when realpath fails.
    assert.equal(policy({ ...params, rootDir: "/nix/store/nonexistent" }), false);
  });
  test(`${ext}: real filesystem escapes, permissions and hardlinks stay independent`, async (t) => {
    const f = fixture(t, ext);
    assert.equal(patch(f).status, 0);
    const dir = path.join(f.root, "plugin"),
      outside = path.join(f.root, "outside");
    fs.mkdirSync(dir);
    fs.writeFileSync(outside, "");
    const source = path.join(dir, "index.js");
    fs.symlinkSync(outside, source);
    const { findCandidateBlockIssue: check } = await load(f, f.discovery);
    const params = { ...paramsFor(dir), source, ownershipUid: process.getuid() };
    assert.equal(check(params).reason, "source_escapes_root");
    fs.unlinkSync(source);
    fs.linkSync(outside, source);
    const facts = await load(f, f.dependency);
    facts.roots.clear();
    assert.equal(check(params), null);
    assert.equal(fs.statSync(source).nlink, 2);
    assert.equal((await load(f, f.policy)).t(params), true);
    fs.chmodSync(source, 0o666);
    assert.equal(check(params).reason, "path_world_writable");
    fs.unlinkSync(source);
    facts.roots.clear();
    assert.equal(check(params).reason, "path_stat_failed");
  });
  test(`${ext}: candidate effects and existing diagnostic/recorded-repair limitations`, async (t) => {
    const f = fixture(t, ext);
    assert.equal(patch(f).status, 0);
    const module = await load(f, f.install),
      cfg = { candidates: [{ id: "candidate-install" }] };
    restoreEnv(t);
    for (const ambient of ["0", "1"])
      for (const mode of ["0", "1"]) {
        process.env.OPENCLAW_NIX_MODE = ambient;
        module.effects.length = 0;
        const params = { cfg, env: envFor(mode), recorded: true };
        await module.repair(params);
        const candidates = mode === "1" ? [] : ["candidate-install"];
        assert.deepEqual(module.effects, ["recorded-update", ...candidates]);
        assert.deepEqual(await module.health(params), candidates);
      }
    const before = snapshot(f),
      second = patch(f);
    assert.ok(second.status === 0 || second.status === 1);
    assert.deepEqual(snapshot(f), before);
  });
  const mutations = {
    "wrong-binding": ["discovery", "{ t as shouldReject", "{ x as shouldReject"],
    "comment-binding": ["discovery", "import { t as shouldReject", "// import { t as shouldReject"],
    "extra-exception": ["policy", "\treturn true;", "\tif (params.extra) return false;\n\treturn true;"],
    "return-newline": ["policy", "\treturn true;", "\treturn\n\ttrue;"],
    "store-prefix": ["policy", "${NIX_STORE_ROOT}/", "${NIX_STORE_ROOT}"],
    "cache-call": ["policy", "?? path.resolve(rootDir)", '?? "/nix/store"'],
    "cache-body": ["dependency", ext === "js" ? "return resolved;" : "return facts[key];", 'return "/nix/store";'],
    "env-contract": ["environment", '=== "1"', '!== "0"'],
    "late-loop": ["install", "HealthIssues", "UnrecognizedHealth"],
    "mixed-patched": ["install", "\tfor (const candidate", "\tif (true) for (const candidate"],
  };
  const missing = ["policy", "discovery", "install"].flatMap((role) => [`missing-${role}`, `duplicate-${role}`]);
  const ownerFaults = [...missing, ...Object.keys(mutations), "co-located"];
  for (const fault of [...ownerFaults, "nested-only", "symlink-only", "directory-only"]) {
    test(`${ext}: rejects ${fault} before any write`, (t) => {
      const f = fixture(t, ext);
      f.environment = `paths-fixture.${ext}`;
      const file = f[fault.split("-")[1]];
      if (fault.startsWith("missing-")) fs.unlinkSync(path.join(f.dist, file));
      else if (fault.startsWith("duplicate-"))
        fs.copyFileSync(path.join(f.dist, file), path.join(f.dist, `duplicate-${file}`));
      else if (fault === "co-located") {
        fs.appendFileSync(path.join(f.dist, f.discovery), fs.readFileSync(path.join(f.dist, f.install)));
        fs.unlinkSync(path.join(f.dist, f.install));
      } else if (mutations[fault]) {
        const [role, from, to] = mutations[fault];
        change(f, f[role], from, to);
      } else {
        const bytes = fs.readFileSync(path.join(f.dist, f.policy));
        fs.unlinkSync(path.join(f.dist, f.policy));
        fs.mkdirSync(path.join(f.dist, "worker"));
        fs.writeFileSync(path.join(f.dist, "worker", "worker.mjs"), bytes);
        if (fault === "symlink-only") fs.symlinkSync(path.join("worker", "worker.mjs"), path.join(f.dist, f.policy));
        if (fault === "directory-only") fs.mkdirSync(path.join(f.dist, f.policy));
      }
      const before = snapshot(f),
        result = patch(f);
      assert.equal(result.status, 1, `${fault}: ${result.stderr}`);
      assert.deepEqual(snapshot(f), before);
    });
  }
}
const loaderFaults = ["none", "missing", "duplicate", "worker-only", "symlink-only"];
const contentFaults = ["reject-hardlinks", "missing-path", "broken-alias", "empty-artifact"];
for (const ext of ["js", "mjs"])
  for (const fault of [...loaderFaults, ...contentFaults]) {
    test(`package checker ${ext}: ${fault}`, (t) => {
      const f = packageFixture(t, ext);
      if (fault === "missing") fs.unlinkSync(f.loader);
      if (fault === "duplicate") fs.copyFileSync(f.loader, path.join(path.dirname(f.loader), `another.${ext}`));
      if (fault === "worker-only" || fault === "symlink-only") {
        fs.mkdirSync(path.join(f.root, "dist/worker"));
        fs.renameSync(f.loader, path.join(f.root, "dist/worker/worker.mjs"));
        if (fault === "symlink-only") fs.symlinkSync("worker/worker.mjs", f.loader);
      }
      if (fault === "reject-hardlinks") fs.appendFileSync(f.loader, "\n// rejectHardlinks: true\n");
      if (fault === "missing-path") fs.unlinkSync(path.join(f.root, "dist-runtime/extensions/acpx/setup-api.js"));
      if (fault === "broken-alias") fs.unlinkSync(path.join(f.root, "dist/target.js"));
      if (fault === "empty-artifact") f.put("dist/provider-policy-api.cjs", "module.exports = null;\n");
      const result = f.run();
      assert.equal(result.status === 0, fault === "none", result.stderr);
      if (fault === "none")
        assert.equal(fs.readFileSync(path.join(f.root, "dist/loaded"), "utf8"), "public artifact loaded");
    });
  }
for (const ext of ["js", "mjs"])
  for (const legacy of [false, true])
    for (const missing of [
      null,
      "src/agents/templates/HEARTBEAT.md",
      ...templateDocs.map((name) => `docs/reference/templates/${name}.md`),
    ]) {
      test(`package templates ${ext} ${legacy ? "legacy" : "retired"}: ${missing ?? "complete"}`, (t) => {
        const f = packageFixture(t, ext, legacy ? ["src/agents/templates/"] : ["dist/", "docs/", "skills/"]);
        if (missing) fs.unlinkSync(path.join(f.root, missing));
        if (legacy && missing === "src/agents/templates/HEARTBEAT.md")
          f.put("docs/reference/templates/HEARTBEAT.md", "Documentation cannot replace the runtime template.");
        const result = f.run(),
          passes = missing === null || (!legacy && missing === "src/agents/templates/HEARTBEAT.md");
        assert.equal(result.status, passes ? 0 : 1, result.stdout + result.stderr);
        if (passes) assert.equal(fs.readFileSync(path.join(f.root, "dist/loaded"), "utf8"), "public artifact loaded");
        else assert.ok(result.stderr.includes(missing), result.stderr);
      });
    }
