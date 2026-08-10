#!/usr/bin/env node

import { spawn } from "node:child_process";
import { once } from "node:events";
import fs from "node:fs";
import os from "node:os";
import path from "node:path";
import { pathToFileURL } from "node:url";

const repositoryRoot = path.resolve(import.meta.dirname, "..");
const chromeExecutable = process.argv[2] || "/Applications/Google Chrome.app/Contents/MacOS/Google Chrome";
const screenshotDirectory = process.argv[3] ? path.resolve(process.argv[3]) : null;
const commandTimeoutMilliseconds = 5000;
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
  ["Components-v3.dc.html", "components-1"],
  ["Components-v3.dc.html", "components-2"],
  ["Components-v3.dc.html", "components-3"],
  ["Components-v3.dc.html", "components-4"],
  ["Components-v3.dc.html", "components-5"],
  ["Broadcast-v3.dc.html", "broadcast-college-regular"],
  ["Broadcast-v3.dc.html", "broadcast-college-rivalry"],
  ["Broadcast-v3.dc.html", "broadcast-college-conference-championship"],
  ["Broadcast-v3.dc.html", "broadcast-college-playoff"],
  ["Broadcast-v3.dc.html", "broadcast-college-final"],
  ["Broadcast-v3.dc.html", "broadcast-pro-regular"],
  ["Broadcast-v3.dc.html", "broadcast-pro-elimination"],
  ["Broadcast-v3.dc.html", "broadcast-pro-final"],
  ["Appearance-v3.dc.html", "appearance-light-map-regular"],
  ["Appearance-v3.dc.html", "appearance-light-match-regular"],
  ["Appearance-v3.dc.html", "appearance-light-continuity-regular"],
  ["Appearance-v3.dc.html", "appearance-light-roster-regular"],
  ["Continuity-v3.dc.html", "match-exit"],
  ["Offseason-v3.dc.html", "draft-live-pick"],
  ["Tokens-v3.dc.html", "tokens-elevation-dark"],
  ["Tokens-v3.dc.html", "tokens-elevation-light"],
  ["League-v3.dc.html", "map-reach"],
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

function withTimeout(promise, label, milliseconds = commandTimeoutMilliseconds) {
  let timer;
  return Promise.race([
    promise,
    new Promise((_, reject) => {
      timer = setTimeout(() => reject(new Error(`${label} timed out after ${milliseconds}ms`)), milliseconds);
    }),
  ]).finally(() => clearTimeout(timer));
}

async function devtoolsPort() {
  const activePortPath = path.join(profileDirectory, "DevToolsActivePort");
  for (let attempt = 0; attempt < 100; attempt += 1) {
    if (fs.existsSync(activePortPath)) {
      return fs.readFileSync(activePortPath, "utf8").split("\n", 1)[0];
    }
    if (chrome.exitCode !== null) throw new Error(`Chrome exited before publishing a DevTools port (${chrome.exitCode})`);
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

  rejectPending(error) {
    for (const { reject, timer } of this.pending.values()) {
      clearTimeout(timer);
      reject(error);
    }
    this.pending.clear();
  }

  async open() {
    await withTimeout(new Promise((resolve, reject) => {
      this.socket.addEventListener("open", resolve, { once: true });
      this.socket.addEventListener("error", () => reject(new Error("DevTools socket failed while opening")), { once: true });
    }), "DevTools socket open");
    this.socket.addEventListener("message", (event) => {
      let message;
      try {
        message = JSON.parse(event.data);
      } catch (error) {
        this.rejectPending(new Error(`Invalid DevTools response: ${error.message}`));
        return;
      }
      if (!message.id || !this.pending.has(message.id)) return;
      const { resolve, reject, timer } = this.pending.get(message.id);
      clearTimeout(timer);
      this.pending.delete(message.id);
      if (message.error) reject(new Error(message.error.message));
      else resolve(message.result);
    });
    this.socket.addEventListener("close", () => this.rejectPending(new Error("DevTools socket closed")));
    this.socket.addEventListener("error", () => this.rejectPending(new Error("DevTools socket error")));
  }

  command(method, params = {}) {
    if (this.socket.readyState !== WebSocket.OPEN) {
      return Promise.reject(new Error(`DevTools socket is not open for ${method}`));
    }
    const id = this.nextId;
    this.nextId += 1;
    return new Promise((resolve, reject) => {
      const timer = setTimeout(() => {
        this.pending.delete(id);
        reject(new Error(`${method} timed out after ${commandTimeoutMilliseconds}ms`));
      }, commandTimeoutMilliseconds);
      this.pending.set(id, { resolve, reject, timer });
      try {
        this.socket.send(JSON.stringify({ id, method, params }));
      } catch (error) {
        clearTimeout(timer);
        this.pending.delete(id);
        reject(error);
      }
    });
  }

  close() {
    this.rejectPending(new Error("DevTools session closed"));
    if (this.socket.readyState === WebSocket.OPEN || this.socket.readyState === WebSocket.CONNECTING) this.socket.close();
  }
}

async function waitForFrame(session, frameId) {
  for (let attempt = 0; attempt < 40; attempt += 1) {
    const evaluation = await session.command("Runtime.evaluate", {
      expression: `document.readyState === "complete" && Boolean(document.getElementById(${JSON.stringify(`reference-${frameId}`)}))`,
      returnByValue: true,
    });
    if (evaluation.result.value) return;
    await delay(50);
  }
  throw new Error(`${frameId} did not become ready`);
}

function auditExpression(frameId) {
  return `(() => {
    const article = document.getElementById(${JSON.stringify(`reference-${frameId}`)});
    if (!article) return { errors: ["missing reference article"] };
    article.scrollIntoView({ block: "start" });
    const frame = article.querySelector(".product-frame");
    const frameRect = frame.getBoundingClientRect();
    const tolerance = 1;
    const errors = [];
    let contrastChecks = 0;
    let overlapChecks = 0;
    const visible = (element) => {
      const style = getComputedStyle(element);
      const rect = element.getBoundingClientRect();
      return style.display !== "none" && style.visibility !== "hidden" && Number(style.opacity) !== 0 && rect.width > 0 && rect.height > 0;
    };
    const inside = (rect, outer = frameRect) => rect.left >= outer.left - tolerance && rect.top >= outer.top - tolerance && rect.right <= outer.right + tolerance && rect.bottom <= outer.bottom + tolerance;
    const horizontallyInside = (rect, outer) => rect.left >= outer.left - tolerance && rect.right <= outer.right + tolerance;
    const overlaps = (left, right) => left.right > right.left + tolerance && right.right > left.left + tolerance && left.bottom > right.top + tolerance && right.bottom > left.top + tolerance;
    const checkSiblingOverlap = (container, label) => {
      const children = [...container.children].filter(visible);
      for (let first = 0; first < children.length; first += 1) {
        for (let second = first + 1; second < children.length; second += 1) {
          overlapChecks += 1;
          if (overlaps(children[first].getBoundingClientRect(), children[second].getBoundingClientRect())) errors.push(label + " has overlapping siblings");
        }
      }
    };
    const parseColour = (value) => {
      const parts = value.match(/[\\d.]+/g)?.map(Number) || [];
      return parts.length >= 3 ? { r: parts[0], g: parts[1], b: parts[2], a: parts.length > 3 ? parts[3] : 1 } : null;
    };
    const composite = (top, bottom) => {
      const alpha = top.a + bottom.a * (1 - top.a);
      if (alpha === 0) return { r: 0, g: 0, b: 0, a: 0 };
      return {
        r: (top.r * top.a + bottom.r * bottom.a * (1 - top.a)) / alpha,
        g: (top.g * top.a + bottom.g * bottom.a * (1 - top.a)) / alpha,
        b: (top.b * top.a + bottom.b * bottom.a * (1 - top.a)) / alpha,
        a: alpha,
      };
    };
    const background = (element) => {
      let result = { r: 0, g: 0, b: 0, a: 0 };
      for (let node = element; node; node = node.parentElement) {
        const colour = parseColour(getComputedStyle(node).backgroundColor);
        if (colour) result = composite(result, colour);
        if (result.a >= .999) break;
      }
      return result;
    };
    const channel = (value) => {
      const normalised = value / 255;
      return normalised <= .04045 ? normalised / 12.92 : ((normalised + .055) / 1.055) ** 2.4;
    };
    const luminance = (colour) => .2126 * channel(colour.r) + .7152 * channel(colour.g) + .0722 * channel(colour.b);
    const contrast = (element) => {
      const backdrop = background(element);
      const foreground = composite(parseColour(getComputedStyle(element).color), backdrop);
      const values = [luminance(foreground), luminance(backdrop)].sort((left, right) => right - left);
      return (values[0] + .05) / (values[1] + .05);
    };

    const criticalSelectors = [
      ".status-bar", ".app-header", ".pane-actions", ".match-exit", ".direction",
      ".ax5-inbox-reduction", ".ax5-roster-reduction", ".ax5-attribute", ".ax5-type-ramp",
      ".job-board", ".job-dimensions", ".arrival-summary", ".arrival-next-decision",
      ".destination-bar", ".map-layout", ".score-bug", ".exit-sheet", ".warning-banner",
      ".component-grid", ".broadcast-frame", ".broadcast-field", ".broadcast-overlay",
      ".rivalry-seam", ".visual-fieldcanvas", ".visual-attributerow.state-poor",
      ".visual-attributerow.state-bad"
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
    for (const container of frame.querySelectorAll(".ax5-inbox-reduction, .ax5-roster-controls, .ax5-roster-reduction, .arrival-summary, .arrival-terms, .component-grid, .specimen")) {
      checkSiblingOverlap(container, container.className);
    }
    for (const specimen of frame.querySelectorAll(".component-grid > .specimen")) {
      if (!horizontallyInside(specimen.getBoundingClientRect(), specimen.parentElement.getBoundingClientRect())) errors.push("component specimen clips outside grid");
      for (const child of specimen.children) {
        if (visible(child) && !horizontallyInside(child.getBoundingClientRect(), specimen.getBoundingClientRect())) errors.push("component content clips outside specimen");
      }
    }

    const destination = frame.querySelector(".destination-bar");
    if (destination) {
      const destinationRect = destination.getBoundingClientRect();
      for (const selector of [".ax5-inbox-reduction", ".ax5-roster-reduction", ".arrival-next-decision", ".pane-actions", ".map-layout"]) {
        for (const element of frame.querySelectorAll(selector)) {
          if (visible(element) && overlaps(element.getBoundingClientRect(), destinationRect)) errors.push(selector + " is occluded by destination bar");
        }
      }
    }

    const actions = frame.querySelectorAll("[data-action-role=primary]");
    for (const action of actions) {
      if (!action.closest(".pane-actions")) errors.push("primary action is not pane-pinned");
      if (!inside(action.getBoundingClientRect())) errors.push("primary action leaves frame");
    }
    for (const actionRow of frame.querySelectorAll(".pane-actions")) {
      if (actionRow.scrollWidth > actionRow.clientWidth + tolerance) errors.push("action row requires horizontal scrolling");
    }
    for (const actionContainer of frame.querySelectorAll("[data-action-container]")) {
      const actionRow = actionContainer.querySelector(".pane-actions");
      if (!actionRow) {
        errors.push("action container has no pane actions");
        continue;
      }
      const containerRect = actionContainer.getBoundingClientRect();
      const style = getComputedStyle(actionContainer);
      const expectedBottom = containerRect.bottom - parseFloat(style.borderBottomWidth) - parseFloat(style.paddingBottom);
      if (Math.abs(actionRow.getBoundingClientRect().bottom - expectedBottom) > 2) errors.push("pane actions are not pinned to container bottom");
    }

    if (frame.dataset.typeScale === "ax5") {
      const expected = { display: 60, title: 56, headline: 53, body: 53, callout: 51, caption: 43, numeral: 58 };
      const checks = [
        [".status-bar", "caption"], [".app-header h2", "headline"], [".button", "callout"],
        [".score-bug strong", "numeral"], [".score-bug .state-tag", "caption"],
        [".match-exit", "callout"], [".direction", "body"], [".attribute-label", "body"],
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
    if (matchExit && direction && overlaps(matchExit.getBoundingClientRect(), direction.getBoundingClientRect())) errors.push("match exit overlaps direction");

    for (const selector of [".score-bug > span", ".score-bug > strong", ".exit-sheet h2", ".exit-sheet p", ".exit-sheet small", ".exit-sheet .button"]) {
      for (const element of frame.querySelectorAll(selector)) {
        if (!visible(element)) continue;
        contrastChecks += 1;
        const ratio = contrast(element);
        if (ratio < 4.5) errors.push(selector + " local contrast is " + ratio.toFixed(2));
      }
    }

    const broadcast = frame.querySelector(".broadcast-screen");
    if (broadcast) {
      const bug = broadcast.querySelector(".broadcast-frame");
      const expectedHeight = broadcast.classList.contains("final") ? 52 : broadcast.classList.contains("elimination") ? 48 : 44;
      if (Math.round(bug.getBoundingClientRect().height) !== expectedHeight) errors.push("broadcast bug height differs from escalation canon");
      if (broadcast.classList.contains("elimination") && Math.round(parseFloat(getComputedStyle(bug).borderTopWidth)) !== 2) errors.push("elimination rule is not 2pt");
      const corners = [...broadcast.querySelectorAll(".broadcast-corner")];
      if (broadcast.classList.contains("final")) {
        const style = getComputedStyle(broadcast);
        for (const side of ["Top", "Right", "Bottom", "Left"]) {
          if (Math.round(parseFloat(style["border" + side + "Width"])) !== 2) errors.push("final frame is incomplete");
        }
        if (corners.length !== 4 || corners.some((corner) => !visible(corner))) errors.push("final corner marks are incomplete");
      } else if (corners.length) errors.push("corner marks leaked below final escalation");
      const marks = [...broadcast.querySelectorAll(".player-mark")];
      for (const side of ["home", "opponent"]) {
        if (marks.filter((mark) => mark.dataset.side === side).length !== 11) errors.push(side + " formation does not have 11 marks");
      }
      const rivalry = broadcast.querySelector(".rivalry-seam");
      if (rivalry && (getComputedStyle(rivalry).backgroundImage.match(/rgb/g) || []).length < 2) errors.push("rivalry seam does not use both secondary colours");
    }

    const elevation = frame.querySelector(".elevation-grid");
    if (elevation?.dataset.elevationMechanism === "surface-hairline-scrim") {
      const one = parseColour(getComputedStyle(elevation.querySelector(".elevation-one")).borderTopColor);
      const two = parseColour(getComputedStyle(elevation.querySelector(".elevation-two")).borderTopColor);
      const three = parseColour(getComputedStyle(elevation.querySelector(".elevation-three")).borderTopColor);
      const scrim = elevation.querySelector(".elevation-scrim");
      const scrimColour = parseColour(getComputedStyle(scrim).backgroundColor);
      if (Math.abs(one.a - .09) > .005 || Math.abs(two.a - .14) > .005 || Math.abs(three.a - .22) > .005) errors.push("dark elevation hairline strengths differ");
      if (Math.abs(scrimColour.a - .22) > .005) errors.push("dark elevation scrim is not 22 percent");
      if (!overlaps(scrim.getBoundingClientRect(), elevation.querySelector(".elevation-covered").getBoundingClientRect())) errors.push("dark elevation scrim does not dim covered content");
      if (Number(getComputedStyle(scrim).zIndex) >= Number(getComputedStyle(elevation.querySelector(".elevation-three")).zIndex)) errors.push("dark elevation scrim covers the raised decision");
    }
    if (elevation?.dataset.elevationMechanism === "shadow") {
      for (const level of ["one", "two", "three"]) {
        if (getComputedStyle(elevation.querySelector(".elevation-" + level)).boxShadow === "none") errors.push("light elevation lacks shadow");
      }
    }

    return {
      errors: [...new Set(errors)],
      rect: { x: frameRect.x + window.scrollX, y: frameRect.y + window.scrollY, width: frameRect.width, height: frameRect.height },
      criticalCount: criticalSelectors.reduce((count, selector) => count + frame.querySelectorAll(selector).length, 0),
      contrastChecks,
      overlapChecks,
    };
  })()`;
}

async function stopChrome() {
  if (chrome.exitCode !== null) return;
  const exited = once(chrome, "exit");
  chrome.kill("SIGTERM");
  const stopped = await Promise.race([exited.then(() => true), delay(1500).then(() => false)]);
  if (!stopped && chrome.exitCode === null) {
    chrome.kill("SIGKILL");
    await Promise.race([once(chrome, "exit"), delay(1500)]);
  }
}

let session;
try {
  const port = await devtoolsPort();
  const targetsResponse = await fetch(`http://127.0.0.1:${port}/json/list`, { signal: AbortSignal.timeout(commandTimeoutMilliseconds) });
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
    await waitForFrame(session, frameId);
    const evaluation = await session.command("Runtime.evaluate", { expression: auditExpression(frameId), returnByValue: true });
    const result = evaluation.result.value;
    results.push({ frame: frameId, errors: result.errors, criticalCount: result.criticalCount, contrastChecks: result.contrastChecks, overlapChecks: result.overlapChecks });
    if (result.errors.length) failures.push({ frame: frameId, errors: result.errors });
    if (screenshotDirectory) {
      const screenshot = await session.command("Page.captureScreenshot", { format: "png", clip: { ...result.rect, scale: 1 }, captureBeyondViewport: true });
      fs.writeFileSync(path.join(screenshotDirectory, `${frameId}.png`), Buffer.from(screenshot.data, "base64"));
    }
  }
  console.log(JSON.stringify({ checked: results.length, failures, results }, null, 2));
  if (failures.length) process.exitCode = 1;
} finally {
  if (session) session.close();
  await stopChrome();
  const resolvedProfile = fs.realpathSync(profileDirectory);
  const resolvedTemporaryRoot = fs.realpathSync(os.tmpdir()) + path.sep;
  if (!resolvedProfile.startsWith(resolvedTemporaryRoot) || path.basename(resolvedProfile).startsWith("pfc-v3-layout-") === false) {
    throw new Error(`Refusing to remove unexpected Chrome profile: ${resolvedProfile}`);
  }
  fs.rmSync(resolvedProfile, { recursive: true, force: true });
}
