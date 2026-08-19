#!/usr/bin/env node
// Validate docs/loops/catalog.json.
//
// Three checks, in order of what they protect:
//
//   1. Schema. The field set, length caps and formats are the Loop Library publication schema, so a
//      record here can be submitted without rework. Rules transcribed from Forward-Future/loop-library
//      at commit 75966cb, loop-library/worker/src/loop-schema.js (MIT). Nothing is vendored; if the
//      upstream schema moves, this file is what has to move with it.
//   2. Reference integrity. Every `related` slug resolves inside this catalog, so the series has no
//      dangling links.
//   3. The partition. Every aspect in aspects.json names at least one loop, and every loop is named
//      by at least one aspect. This is the project's own convention applied to its loop series: the
//      two legal sweeps must partition every generated name because a name that belongs to neither
//      kind is a name nothing checks. A loop nothing points at covers nothing anybody asked for.
//
// Plus a drift check: LOOPS.md must carry the same slugs and the same exact prompt text as the
// catalog, so the register an agent reads cannot quietly diverge from the record that was validated.
//
// Usage: node scripts/check-loops.mjs                  validate
//        node scripts/check-loops.mjs --write-register  regenerate LOOPS.md from the catalog, then validate

import { readFileSync, writeFileSync } from "node:fs";

const PREAMBLE = `# Project loops

Repeatable agent loops for finding and patching **unknown** faults in this project: faults no current
assertion is shaped to detect. Each one widens a detector first and runs it second, because running an
existing gate can only re-find faults that gate already knows how to see.

Format and method follow the Loop Library at <https://signals.forwardfuture.com/loop-library/>. The full
records, with steps, verification detail and rationale, are \`docs/loops/catalog.json\`; this file is the
register an agent reads. \`scripts/check-loops.mjs\` fails if the two disagree, so edit the catalog and
regenerate rather than editing here.

**These files carry no canon authority.** \`docs/DOC-MANIFEST.md\` is the authority on what is canon, and
nothing below amends a design decision. A loop that turns out to need one stops and says so.

## Standing rules every loop inherits

1. **Widen, then run.** A pass that only re-runs an existing check has not looked anywhere new.
2. **Fix the system, never the instrument.** Never widen a calibration band, relax an invariant,
   re-record a fingerprint, add a scan exemption or delete a commitment to reach green.
3. **Enumerate by construction.** A check over a hand-written list stops covering the codebase the day
   after it is written.
4. **Stop honestly.** Terminal states are success, clean no-op, blocked, approval required, exhausted
   and no progress. An error is never success, and an exhausted budget is never success.
5. **No progress means stop.** Absent a limit the owner set, stop after two consecutive passes that
   widen coverage and find nothing.
6. **Canon first.** A gameplay decision is amended in the documents before it is implemented. Never
   encode a design decision only in code.
7. **Escalate, do not resolve.** Legal identity questions, owner gates, device measurement and
   simulator walkthroughs are not agent decisions.
8. **Never claim an unrun gate.** With no Swift toolchain a loop stops as blocked. Write the code to the
   same standard, record it in \`docs/STATUS.md\` as unverified and never compiled, and do not report a
   build or a test run that did not happen.

## The loops

`;

const CATEGORIES = new Set(["engineering", "evaluation", "operations", "content", "design"]);

const REQUIRED_STRINGS = {
  number: 3, slug: 80, title: 120, summary: 240, seoTitle: 160, description: 320,
  categoryLabel: 120, author: 120, published: 10, modified: 10, prompt: 5000,
  verifyTitle: 240, verifyDetail: 1000, useWhen: 1200, why: 1600, note: 1600,
};

const ARRAYS = {
  steps: { min: 3, max: 12, itemMax: 1200 },
  keywords: { min: 3, max: 20, itemMax: 100 },
  related: { min: 1, max: 8, itemMax: 80 },
};

const SLUG = /^[a-z0-9]+(?:-[a-z0-9]+)*$/;
const failures = [];
const fail = (where, message) => failures.push(`${where}: ${message}`);

const catalog = JSON.parse(readFileSync("docs/loops/catalog.json", "utf8"));
const aspectFile = JSON.parse(readFileSync("docs/loops/aspects.json", "utf8"));

if (process.argv.includes("--write-register")) {
  const body = catalog
    .map((loop) =>
      [
        `### ${loop.number} — ${loop.title}`,
        "",
        `\`${loop.slug}\` · ${loop.categoryLabel} · saved ${loop.modified}`,
        "",
        loop.summary,
        "",
        "Prompt:",
        "",
        `> ${loop.prompt}`,
        "",
      ].join("\n"),
    )
    .join("\n");
  writeFileSync("LOOPS.md", PREAMBLE + body);
  console.log(`wrote LOOPS.md from the catalog: ${catalog.length} loops`);
}

const register = readFileSync("LOOPS.md", "utf8");

if (!Array.isArray(catalog) || catalog.length === 0) {
  fail("catalog", "must be a non-empty array");
}

const slugs = new Set();
const numbers = new Set();

for (const loop of catalog) {
  const where = `loop ${loop?.number ?? "?"} ${loop?.slug ?? "?"}`;

  for (const [field, maxLength] of Object.entries(REQUIRED_STRINGS)) {
    const value = loop?.[field];
    if (typeof value !== "string" || value.trim() === "") {
      fail(where, `${field} is required`);
    } else if (value.trim().length > maxLength) {
      fail(where, `${field} is ${value.trim().length} characters, over the ${maxLength} cap`);
    }
  }

  if (!/^\d{3}$/.test(loop.number ?? "")) fail(where, "number must be exactly three digits");
  if (numbers.has(loop.number)) fail(where, `number ${loop.number} is used twice`);
  numbers.add(loop.number);

  if (!SLUG.test(loop.slug ?? "")) fail(where, "slug must be lowercase words separated by hyphens");
  if (slugs.has(loop.slug)) fail(where, `slug ${loop.slug} is used twice`);
  slugs.add(loop.slug);

  for (const field of ["published", "modified"]) {
    const value = loop?.[field] ?? "";
    if (!/^\d{4}-\d{2}-\d{2}$/.test(value)) {
      fail(where, `${field} must use YYYY-MM-DD`);
    } else if (new Date(`${value}T00:00:00Z`).toISOString().slice(0, 10) !== value) {
      fail(where, `${field} is not a real calendar date`);
    }
  }
  if ((loop.modified ?? "") < (loop.published ?? "")) {
    fail(where, "modified cannot be earlier than published");
  }

  if (!CATEGORIES.has(loop.category)) {
    fail(where, `category must be one of: ${[...CATEGORIES].join(", ")}`);
  }
  if (typeof loop.featured !== "boolean") fail(where, "featured must be a boolean");

  for (const [field, { min, max, itemMax }] of Object.entries(ARRAYS)) {
    const value = loop?.[field];
    if (!Array.isArray(value) || value.length < min || value.length > max) {
      fail(where, `${field} must contain between ${min} and ${max} items`);
      continue;
    }
    value.forEach((item, index) => {
      if (typeof item !== "string" || item.trim() === "" || item.trim().length > itemMax) {
        fail(where, `${field}[${index}] must be between 1 and ${itemMax} characters`);
      }
    });
  }

  const keywords = loop.keywords ?? [];
  if (new Set(keywords.map((k) => String(k).toLowerCase())).size !== keywords.length) {
    fail(where, "keywords must be unique");
  }

  const related = loop.related ?? [];
  if (new Set(related).size !== related.length) fail(where, "related must not contain duplicates");
  for (const slug of related) {
    if (!SLUG.test(String(slug))) fail(where, `related slug ${slug} is malformed`);
    if (slug === loop.slug) fail(where, "related must not reference the loop itself");
  }

  const bytes = new TextEncoder().encode(JSON.stringify(loop)).byteLength;
  if (bytes > 64 * 1024) fail(where, `record is ${bytes} bytes, over the 64 KiB cap`);
}

for (const loop of catalog) {
  for (const slug of loop.related ?? []) {
    if (!slugs.has(slug)) {
      fail(`loop ${loop.number} ${loop.slug}`, `related slug ${slug} resolves to no loop in this catalog`);
    }
  }
}

const aspects = aspectFile.aspects ?? {};
const claimed = new Set();
for (const [aspect, loops] of Object.entries(aspects)) {
  if (!Array.isArray(loops) || loops.length === 0) {
    fail(`aspect ${aspect}`, "names no loop, so nothing hunts faults in it");
    continue;
  }
  for (const slug of loops) {
    if (!slugs.has(slug)) fail(`aspect ${aspect}`, `names ${slug}, which is not in the catalog`);
    claimed.add(slug);
  }
}
for (const slug of slugs) {
  if (!claimed.has(slug)) fail(`loop ${slug}`, "is named by no aspect, so it covers nothing the map asks for");
}

for (const loop of catalog) {
  if (!register.includes(loop.slug)) fail("LOOPS.md", `does not carry loop ${loop.slug}`);
  if (!register.includes(loop.prompt)) fail("LOOPS.md", `prompt for ${loop.slug} differs from the catalog`);
}

if (failures.length > 0) {
  console.error(`FAIL  ${failures.length} problem(s):`);
  for (const problem of failures) console.error(`  - ${problem}`);
  process.exit(1);
}

console.log(
  `PASS  ${catalog.length} loops, ${Object.keys(aspects).length} aspects, ` +
  `schema and partition clean, LOOPS.md in agreement.`
);
