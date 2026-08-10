#!/usr/bin/env node

import fs from "node:fs";
import path from "node:path";

const repositoryRoot = path.resolve(import.meta.dirname, "..");
const expected = fs.readFileSync(path.join(repositoryRoot, ".node-version"), "utf8").trim();
const actual = process.versions.node;

if (actual !== expected) {
  console.error(`V3 reference tooling requires Node ${expected}; found ${actual}.`);
  process.exit(1);
}

console.log(`Node ${actual} matches the pinned V3 reference toolchain.`);
