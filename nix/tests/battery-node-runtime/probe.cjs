const fs = require("node:fs");
fs.writeFileSync(process.env.OPENCLAW_BATTERY_RUNTIME_PROBE, process.execPath);
