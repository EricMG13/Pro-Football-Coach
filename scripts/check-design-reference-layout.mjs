#!/usr/bin/env node

import { spawn } from "node:child_process";
import fs from "node:fs";
import os from "node:os";
import path from "node:path";
import { pathToFileURL } from "node:url";

const repositoryRoot = path.resolve(import.meta.dirname, "..");
const chromeExecutable = process.argv[2] || "/Applications/Google Chrome.app/Contents/MacOS/Google Chrome";
const screenshotDirectory = process.argv[3] ? path.resolve(process.argv[3]) : null;
const targets = [
  ["Accessibility-v3.dc.html", "ax5-inbox"],
  ["Accessibility-v3.dc.html", "ax5-plan"],
  ["Accessibility-v3.dc.html", "ax5-save"],
  ["Accessibility-v3.dc.html", "ax5-match"],
  ["Career-v3.dc.html", "career-security-ax5"],
  ["Throughput-v3.dc.html", "throughput-ax5"],
  ["Throughput-v3.dc.html", "throughput-attributes-ax5"],
  ["Tokens-v3.dc.html", "tokens-type-ax5"],
  ["FirstRun-v3.dc.html", "entry-board"],
  ["FirstRun-v3.dc.html", "entry-offer"],
  ["Career-v3.dc.html", "pro-arrival"],
  ["Components-v3.dc.html", "components-2"],
  ["Components-v3.dc.html", "components-4"],
  ["Broadcast-v3.dc.html", "broadcast-college-rivalry"],
  ["Broadcast-v3.dc.html", "broadcast-pro-elimination"],
  ["Appearance-v3.dc.html", "appearance-light-map-regular"],
  ["Appearance-v3.dc.html", "appearance-light-match-regular"],
  ["Appearance-v3.dc.html", "appearance-light-continuity-regular"],
  ["Appearance-v3.dc.html", "appearance-light-roster-regular"],
];

if (!fs.existsSync(chromeExecutable)) {
  console.error(`Chrome executable not found: ${chromeExecutable}`);
  process.exit(2);
}

const profileDirectory = fs.mkdtempSync(path.join(os.tmpdir(), "pfc-v3-layout-"));
const chrome = spawn(
  chromeExecutable,
  [
    "--headless",
    "--disable-background-networking",
    "--disable-component-update",
    "--disable-default-apps",
    "--disable-gpu",
    "--hide-scrollbars",
    "--no-first-run",
    "--no-default-browser-check",
    "--remote-debugging-port=0",
    `--user-data-dir=${profileDirectory}`,
    "--window-size=1100,520",
    "about:blank",
  ],
  { stdio: "ignore" },
);

const delay = (milliseconds) => new Promise((resolve) => setTimeout(resolve, milliseconds));

async function devtoolsPort() {
  const activePortPath = path.join(profileDirectory, "DevToolsActivePort");
  for (let attempt = 0; attempt < 100; attempt += 1) {
    if (fs.existsSync(activePortPath)) {
      return fs.readFileSync(activePortPath, "utf8").split("\n", 1)[0];
    }
    await delay(50);
  }
  throw new Error("Chrome did not publish a DevTools port");
}

class DevToolsSession {
  constructor(webSocketUrl) {
    this.nextId = 1;
    this.pending = new Map();
    this.socket = new WebSocket(webSocketUrl);
  }

  async open() {
    await new Promise((resolve, reject) => {
      this.socket.addEventListener("open", resolve, { once: true });
      this.socket.addEventListener("error", reject, { once: true });
    });
    this.socket.addEventListener("message", (event) => {
      const message = JSON.parse(event.data);
      if (!message.id || !this.pending.has(message.id)) return;
      const { resolve, reject } = this.pending.get(message.id);
      this.pending.delete(message.id);
      if (message.error) reject(new Error(message.error.message));
      else resolve(message.result);
    });
  }

  command(method, params = {}) {
    const id = this.nextId;
    this.nextId += 1;
    return new Promise((resolve, reject) => {
      this.pending.set(id, { resolve, reject });
      this.socket.send(JSON.stringify({ id, method, params }));
    });
  }

  close() {
    this.socket.close();
  }
}

function auditExpression(frameId) {
  return `(() => {
    const article = document.getElementById(${JSON.stringify(`reference-${frameId}`)});
    if (!article) return { errors: ["missing reference article"] };
    article.scrollIntoView({ block: "start" });
    const frame = article.querySelector(".product-frame");
    const frameRect = frame.getBoundingClientRect();
    const tolerance = 1;
    const inside = (rect) => rect.left >= frameRect.left - tolerance && rect.top >= frameRect.top - tolerance && rect.right <= frameRect.right + tolerance && rect.bottom <= frameRect.bottom + tolerance;
    const visible = (element) => {
      const style = getComputedStyle(element);
      const rect = element.getBoundingClientRect();
      return style.display !== "none" && style.visibility !== "hidden" && rect.width > 0 && rect.height > 0;
    };
    const errors = [];
    const criticalSelectors = [
      ".status-bar", ".app-header", ".pane-actions", ".match-exit", ".direction",
      ".ax5-attribute", ".ax5-type-ramp", ".job-board", ".job-dimensions",
      ".arrival-summary", ".destination-bar", ".map-layout", ".score-bug",
      ".exit-sheet", ".warning-banner", ".component-grid", ".broadcast-frame",
      ".broadcast-field", ".broadcast-overlay", ".rivalry-seam",
      ".visual-fieldcanvas", ".visual-attributerow.state-poor", ".visual-attributerow.state-bad"
    ];
    for (const selector of criticalSelectors) {
      for (const element of frame.querySelectorAll(selector)) {
        if (visible(element) && !inside(element.getBoundingClientRect())) errors.push(selector + " leaves frame");
      }
    }
    const status = frame.querySelector(".status-bar");
    const header = frame.querySelector(".app-header");
    const content = frame.querySelector(".app-content");
    if (status && header && status.getBoundingClientRect().bottom > header.getBoundingClientRect().top + tolerance) errors.push("status overlaps header");
    if (header && content && header.getBoundingClientRect().bottom > content.getBoundingClientRect().top + tolerance) errors.push("header overlaps content");
    const actions = frame.querySelectorAll("[data-action-role=primary]");
    for (const action of actions) {
      if (!action.closest(".pane-actions")) errors.push("primary action is not pane-pinned");
      if (!inside(action.getBoundingClientRect())) errors.push("primary action leaves frame");
    }
    for (const actionRow of frame.querySelectorAll(".pane-actions")) {
      if (actionRow.scrollWidth > actionRow.clientWidth + tolerance) errors.push("action row requires horizontal scrolling");
    }
    if (frame.dataset.typeScale === "ax5") {
      const expected = { display: 60, title: 56, headline: 53, body: 53, callout: 51, caption: 43, numeral: 58 };
      const checks = [
        [".status-bar", "caption"], [".app-header h2", "headline"],
        [".button", "callout"], [".score-bug strong", "numeral"],
        [".score-bug .state-tag", "caption"], [".match-exit", "callout"],
        [".direction", "body"], [".attribute-label", "body"],
        [".rating-value", "body"], [".ax5-plan-reduction strong", "headline"],
        [".ax5-plan-reduction p", "body"]
      ];
      for (const [selector, role] of checks) {
        for (const element of frame.querySelectorAll(selector)) {
          if (Math.round(parseFloat(getComputedStyle(element).fontSize)) !== expected[role]) errors.push(selector + " is not " + role);
        }
      }
      for (const element of frame.querySelectorAll("[data-type-role]")) {
        const role = element.dataset.typeRole;
        if (Math.round(parseFloat(getComputedStyle(element).fontSize)) !== expected[role]) errors.push(role + " ramp size differs");
        if (!inside(element.getBoundingClientRect())) errors.push(role + " ramp sample leaves frame");
      }
    }
    const matchExit = frame.querySelector(".match-exit");
    const direction = frame.querySelector(".direction");
    if (matchExit && direction) {
      const a = matchExit.getBoundingClientRect();
      const b = direction.getBoundingClientRect();
      if (!(a.right <= b.left || b.right <= a.left || a.bottom <= b.top || b.bottom <= a.top)) errors.push("match exit overlaps direction");
    }
    return {
      errors,
      rect: {
        x: frameRect.x + window.scrollX,
        y: frameRect.y + window.scrollY,
        width: frameRect.width,
        height: frameRect.height,
      },
      criticalCount: criticalSelectors.reduce((count, selector) => count + frame.querySelectorAll(selector).length, 0),
    };
  })()`;
}

let session;
try {
  const port = await devtoolsPort();
  const targetsResponse = await fetch(`http://127.0.0.1:${port}/json/list`);
  const pageTarget = (await targetsResponse.json()).find((target) => target.type === "page");
  if (!pageTarget) throw new Error("Chrome did not expose a page target");
  session = new DevToolsSession(pageTarget.webSocketDebuggerUrl);
  await session.open();
  await session.command("Page.enable");
  const failures = [];
  const results = [];
  if (screenshotDirectory) fs.mkdirSync(screenshotDirectory, { recursive: true });
  for (const [filename, frameId] of targets) {
    const url = `${pathToFileURL(path.join(repositoryRoot, filename)).href}#reference-${frameId}`;
    await session.command("Page.navigate", { url });
    await delay(150);
    const evaluation = await session.command("Runtime.evaluate", {
      expression: auditExpression(frameId),
      returnByValue: true,
    });
    const result = evaluation.result.value;
    results.push({ frame: frameId, errors: result.errors, criticalCount: result.criticalCount });
    if (result.errors.length) failures.push({ frame: frameId, errors: result.errors });
    if (screenshotDirectory) {
      const screenshot = await session.command("Page.captureScreenshot", {
        format: "png",
        clip: { ...result.rect, scale: 1 },
        captureBeyondViewport: true,
      });
      fs.writeFileSync(path.join(screenshotDirectory, `${frameId}.png`), Buffer.from(screenshot.data, "base64"));
    }
  }
  console.log(JSON.stringify({ checked: results.length, failures, results }, null, 2));
  if (failures.length) process.exitCode = 1;
} finally {
  if (session) session.close();
  chrome.kill("SIGTERM");
  await delay(100);
  if (fs.realpathSync(profileDirectory).startsWith(fs.realpathSync(os.tmpdir()) + path.sep)) {
    fs.rmSync(profileDirectory, { recursive: true, force: true });
  }
}
