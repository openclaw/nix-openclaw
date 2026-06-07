start_all()

machine.wait_until_succeeds(
    "systemctl show -p Result home-manager-alice.service | grep -q 'Result=success'"
)

machine.wait_until_succeeds("test -f /home/alice/.openclaw/openclaw.json")
machine.wait_until_succeeds("test -f /home/alice/.openclaw/workspace/AGENTS.md")
machine.succeed("test ! -L /home/alice/.openclaw/workspace/AGENTS.md")
machine.succeed("test -f /home/alice/.openclaw/workspace/IDENTITY.md")
machine.succeed("test -f /home/alice/.openclaw/workspace/USER.md")
machine.succeed("test -f /home/alice/.openclaw/workspace/HEARTBEAT.md")
machine.succeed("test -f /home/alice/.openclaw/workspace/LORE.md")
machine.succeed("grep -q '\"skipBootstrap\":true' /home/alice/.openclaw/openclaw.json")
machine.succeed("grep -q 'BEGIN NIX-REPORT' /home/alice/.openclaw/workspace/TOOLS.md")
machine.succeed(
    "unit=/home/alice/.config/systemd/user/openclaw-gateway.service; "
    "openclaw_bin=$(sed -n 's/^ExecStart=\\([^ ]*\\).*/\\1/p' \"$unit\"); "
    "test -x \"$openclaw_bin\"; "
    "grep -Eq 'hello-[^/]+/bin' \"$openclaw_bin\"; "
    "! grep -q 'OPENCLAW_CODEX_APP_SERVER_ARGS' \"$openclaw_bin\"; "
    "! grep -q 'OPENCLAW_CODEX_APP_SERVER_BIN' \"$openclaw_bin\"; "
    "grep -q '\"pathPrepend\"' /home/alice/.openclaw/openclaw.json; "
    "grep -Eq 'hello-[^/]+/bin' /home/alice/.openclaw/openclaw.json"
)

uid = machine.succeed("id -u alice").strip()
machine.succeed("loginctl enable-linger alice")
machine.succeed(f"systemctl start user@{uid}.service")
machine.wait_for_unit(f"user@{uid}.service")

machine.wait_until_succeeds("test -S /run/user/1000/bus")

machine.succeed("mkdir -p /tmp/openclaw")
machine.succeed("chmod 1777 /tmp/openclaw")

user_env = "XDG_RUNTIME_DIR=/run/user/1000 DBUS_SESSION_BUS_ADDRESS=unix:path=/run/user/1000/bus"
machine.succeed(f"su - alice -c '{user_env} systemctl --user daemon-reload'")
machine.succeed(f"su - alice -c '{user_env} systemctl --user start openclaw-gateway.service'")
machine.wait_for_unit("openclaw-gateway.service", user="alice")

try:
    machine.wait_for_open_port(18999)
except Exception:
    machine.succeed(
        f"su - alice -c '{user_env} systemctl --user status openclaw-gateway.service --no-pager -n 200 > /tmp/openclaw/systemctl-status.txt 2>&1' || true"
    )
    machine.succeed(
        f"su - alice -c '{user_env} journalctl --user -u openclaw-gateway.service --no-pager -n 200 -o cat > /tmp/openclaw/journalctl.txt 2>&1' || true"
    )
    machine.succeed("coredumpctl info --no-pager | tail -n 200 >&2 || true")
    machine.succeed("ls -la /tmp/openclaw 1>&2 || true")
    machine.succeed("ls -la /tmp/openclaw/node-report* 1>&2 || true")
    machine.succeed(
        f"su - alice -c '{user_env} systemctl --user show openclaw-gateway.service --no-pager -p Environment > /tmp/openclaw/systemctl-env.txt 2>&1' || true"
    )
    machine.succeed("sed -n '1,200p' /tmp/openclaw/systemctl-env.txt >&2 || true")
    machine.succeed("wc -c /tmp/openclaw/systemctl-env.txt >&2 || true")
    machine.succeed(
        f"su - alice -c '{user_env} systemctl --user cat openclaw-gateway.service --no-pager > /tmp/openclaw/systemctl-unit.txt 2>&1' || true"
    )
    machine.succeed("sed -n '1,200p' /tmp/openclaw/systemctl-unit.txt >&2 || true")
    machine.succeed("wc -c /tmp/openclaw/systemctl-unit.txt >&2 || true")
    machine.succeed("tail -n 40 /tmp/openclaw/systemctl-status.txt >&2 || true")
    machine.succeed("tail -n 40 /tmp/openclaw/journalctl.txt >&2 || true")
    raise
