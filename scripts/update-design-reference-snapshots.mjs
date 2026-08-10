#!/usr/bin/env node

import fs from "node:fs";
import path from "node:path";
import { spawnSync } from "node:child_process";

const repositoryRoot = path.resolve(import.meta.dirname, "..");

if (process.env.CI) {
  console.error("Reference snapshots are owner-reviewed artefacts and cannot be updated in CI.");
  process.exit(1);
}
if (process.env.PFC_OWNER_SNAPSHOT_UPDATE !== "1") {
  console.error("Owner-only command refused. Re-run with PFC_OWNER_SNAPSHOT_UPDATE=1 after reviewing the rendered change.");
  process.exit(1);
}
if (typeof process.getuid === "function" && fs.statSync(repositoryRoot).uid !== process.getuid()) {
  console.error("Owner-only command refused because the current user does not own the repository checkout.");
  process.exit(1);
}

const playwright = path.join(repositoryRoot, "node_modules", ".bin", "playwright");
if (!fs.existsSync(playwright)) {
  console.error("Playwright is not installed. Run npm install; missing browser tooling never skips validation.");
  process.exit(1);
}

console.log("Updating owner-reviewed V3 reference snapshots outside CI.");
const result = spawnSync(playwright, ["test", "--update-snapshots=all"], {
  cwd: repositoryRoot,
  stdio: "inherit"
});
if (result.error) throw result.error;
process.exit(result.status ?? 1);
