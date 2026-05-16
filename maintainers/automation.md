# Maintainer Automation

Maintainer automation is an agentic repair loop for the public packaging pipeline. It is not a second release pipeline and not a private deployment monitor.

## Daily Objective

Answer first:

```text
Does nix-openclaw publish the latest upstream version for both supported tracks?
```

Answer `YES` only when:

- `openclaw-gateway` matches the newest stable upstream source release.
- `openclaw-app` matches the newest stable upstream release with a published public `OpenClaw-*.zip`.

If both tracks are current and stable pin automation/CI are healthy, stop with a short CTO-level report:

- current gateway
- latest upstream gateway
- current app
- latest published app
- whether action was needed

## Repair Loop

If the desired state is not true, keep working until it is true or until the exact blocker is proven.

Diagnose across:

- upstream release data
- stable release selection
- pin materialization
- generated config options
- package builds
- smoke checks
- module activation
- workflow behavior
- caches
- CI runner failures

Do not ask for a repair strategy when the desired state is clear.

If the fix belongs in `nix-openclaw`, edit the repo, self-review the diff until there are no actionable findings, run the relevant targeted checks plus the full gate, commit directly to `main`, push directly to `main`, and verify GitHub Actions on the pushed commit.

If upstream has not published public macOS app assets, call that out directly, keep the app pin on the newest public zip, keep packaging the latest stable source-built gateway, and repair `nix-openclaw` only if it fails to do that.
