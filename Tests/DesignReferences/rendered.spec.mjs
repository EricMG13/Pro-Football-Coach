import { expect, test } from "@playwright/test";
import fs from "node:fs";
import path from "node:path";
import { pathToFileURL } from "node:url";

const repositoryRoot = path.resolve(import.meta.dirname, "../..");
const outputNames = [
  "Accessibility-v3.dc.html",
  "Appearance-v3.dc.html",
  "Broadcast-v3.dc.html",
  "Career-v3.dc.html",
  "Components-v3.dc.html",
  "Continuity-v3.dc.html",
  "Failure-v3.dc.html",
  "FirstRun-v3.dc.html",
  "League-v3.dc.html",
  "Offseason-v3.dc.html",
  "Screens-v3.dc.html",
  "Squad-v3.dc.html",
  "System-v3.dc.html",
  "Teaching-v3.dc.html",
  "Throughput-v3.dc.html",
  "Tokens-v3.dc.html"
];
const requiredFrameAttributes = [
  "data-frame",
  "data-canon",
  "data-fixture",
  "data-status",
  "data-device",
  "data-width-class",
  "data-appearance",
  "data-type-scale",
  "data-flow",
  "data-state"
];
const requiredFlowStates = {
  entry: ["no-career", "board", "offer", "accepted-appointment", "continue-exact"],
  match: ["live", "awaiting-input", "background-paused", "foreground-resumed", "resolved-deferred", "exit", "resumable-return", "aftermath"],
  draft: ["live-pick", "background-paused", "foreground-resumed", "user-selection", "expiry-auto-pick"],
  map: ["reach", "talent", "rivalries"],
  persistence: ["saving", "saved", "failed", "continuing-warning", "recovered"],
  promotion: ["offered", "declined", "accepted", "pro-arrival"]
};
const componentStates = {
  Card: ["default", "selected"],
  Row: ["default", "selected", "disabled"],
  StatCell: ["default", "selected"],
  Chip: ["default", "selected", "disabled"],
  Meter: ["default", "over-capacity"],
  Badge: ["default", "live"],
  SegmentedControl: ["default", "selected", "disabled"],
  PrimaryButton: ["default", "pressed", "disabled", "loading"],
  DestructiveButton: ["default", "confirmation", "disabled"],
  InboxItem: ["unread", "resolved"],
  CallInCard: ["awaiting", "accepted", "deferred", "paused"],
  FieldCanvas: ["formation", "key-moment", "outcome"],
  EmptyState: ["empty", "action"],
  ErrorBanner: ["error", "recovery"],
  OpposedBar: ["neutral", "outlier"],
  Sparkline: ["positive", "negative"],
  LowerThird: ["default", "ax5-reduced"],
  ScoreBug: ["full", "compact", "live"],
  StakeholderCard: ["default", "dissatisfied"],
  MapCanvas: ["reach", "talent", "rivalries", "list-twin"],
  ListControls: ["default", "active", "multi-select", "collapsed"],
  AttributeRow: ["elite", "good", "average", "poor", "bad"]
};
const flowScenario = [
  ["FirstRun-v3.dc.html", "entry-no-career", "entry", "no-career", "Start a new career"],
  ["FirstRun-v3.dc.html", "entry-board", "entry", "board", "Review offer"],
  ["FirstRun-v3.dc.html", "entry-offer", "entry", "offer", "Accept appointment"],
  ["FirstRun-v3.dc.html", "entry-appointment", "entry", "accepted-appointment", "Meet your staff"],
  ["Screens-v3.dc.html", "screen-inbox", "screens", "inbox", "Open game plan"],
  ["Teaching-v3.dc.html", "teaching-recommended", "teaching", "recommended", "Use recommendation"],
  ["Teaching-v3.dc.html", "teaching-manual", "teaching", "manual", "Commit manual plan"],
  ["Screens-v3.dc.html", "match-call", "match", "awaiting-input", "Accept call"],
  ["Continuity-v3.dc.html", "match-exit", "match", "exit", "Leave and resume here later"],
  ["Continuity-v3.dc.html", "match-return", "match", "resumable-return", "Resume match"],
  ["Squad-v3.dc.html", "match-aftermath", "match", "aftermath", "Advance to Monday"],
  ["System-v3.dc.html", "system-progress", "system", "advancing-week", "LIVE RESULTS"]
];
const visualMatrix = [
  ["Appearance-v3.dc.html", "appearance-dark-floor", "matrix-dark-844.png"],
  ["Appearance-v3.dc.html", "appearance-light-floor", "matrix-light-844.png"],
  ["Appearance-v3.dc.html", "appearance-dark-ceiling", "matrix-dark-932.png"],
  ["Appearance-v3.dc.html", "appearance-light-ceiling", "matrix-light-932.png"],
  ["Accessibility-v3.dc.html", "ax5-inbox", "matrix-ax5-inbox.png"],
  ["Accessibility-v3.dc.html", "ax5-match", "matrix-ax5-match.png"]
];

function referenceUrl(filename, frameId) {
  return `${pathToFileURL(path.join(repositoryRoot, filename)).href}#reference-${frameId}`;
}

async function openReference(page, filename, frameId) {
  await page.goto(referenceUrl(filename, frameId));
  const article = page.locator(`#reference-${frameId}`);
  await expect(article).toBeVisible();
  return article.locator(".product-frame");
}

function extractSwiftBlocklist() {
  const source = fs.readFileSync(path.join(repositoryRoot, "Sources/FootballSimCore/Generation/Blocklist.swift"), "utf8");
  const names = [];
  for (const collection of ["institutions", "nicknames", "conferences", "venues", "cities", "people"]) {
    const match = source.match(new RegExp(`private static let ${collection} = \\[([\\s\\S]*?)\\n    \\]`));
    if (!match) throw new Error(`could not parse Blocklist.${collection}`);
    names.push(...[...match[1].matchAll(/"([^"]+)"/g)].map((entry) => entry[1]));
  }
  return names;
}

function words(value) {
  return value.toLocaleLowerCase("en-GB").match(/[\p{L}\p{N}]+/gu) ?? [];
}

function blockedIdentity(text, blockedNames) {
  const candidate = words(text);
  for (const blockedName of blockedNames) {
    const blocked = words(blockedName);
    for (let index = 0; index <= candidate.length - blocked.length; index += 1) {
      if (blocked.every((word, offset) => candidate[index + offset] === word)) return blockedName;
    }
  }
  return null;
}

test("browser inventory, manifests, fixtures, identities, and state contracts are exact", async ({ page }) => {
  const actualOutputs = fs.readdirSync(repositoryRoot).filter((name) => name.endsWith("-v3.dc.html")).sort();
  expect(actualOutputs).toEqual([...outputNames].sort());

  const blockedNames = extractSwiftBlocklist();
  const extraRealIdentities = /\b(?:NFL|NCAA|ESPN|Football Manager|Madden NFL|Fox Sports|CBS Sports|NBC Sports)\b/i;
  const frameIds = new Set();
  const observedFlowStates = new Map();
  let frameCount = 0;
  let factCount = 0;
  for (const filename of outputNames) {
    const unexpectedRequests = [];
    const onRequest = (request) => {
      if (!request.url().startsWith("file:") && !request.url().startsWith("data:")) unexpectedRequests.push(request.url());
    };
    page.on("request", onRequest);
    await page.goto(referenceUrl(filename, ""));
    await expect(page.locator(".product-frame").first()).toBeVisible();

    const result = await page.evaluate(({ requiredFrameAttributes, componentStates }) => {
      const manifestNodes = [...document.querySelectorAll('script[type="text/x-dc"][data-reference-manifest]')];
      if (manifestNodes.length !== 1) return { errors: [`expected one manifest, found ${manifestNodes.length}`] };
      const manifest = JSON.parse(manifestNodes[0].textContent);
      const errors = [];
      const frames = [...document.querySelectorAll(".product-frame")];
      if (manifest.frames.length !== frames.length) errors.push("manifest/DOM frame count differs");
      const facts = [];
      for (const [index, frame] of frames.entries()) {
        for (const attribute of requiredFrameAttributes) {
          if (!frame.hasAttribute(attribute)) errors.push(`${frame.dataset.frame ?? index} lacks ${attribute}`);
        }
        const expected = manifest.frames[index];
        for (const [attribute, value] of Object.entries(expected)) {
          if (frame.getAttribute(attribute) !== value) errors.push(`${frame.dataset.frame} manifest ${attribute} differs`);
        }
        const [width, height] = frame.dataset.device.split("x").map(Number);
        const rectangle = frame.getBoundingClientRect();
        if (Math.round(rectangle.width) !== width || Math.round(rectangle.height) !== height) errors.push(`${frame.dataset.frame} rendered device size differs`);
        const inlineNames = [...frame.style].filter((name) => !name.startsWith("--"));
        if (inlineNames.length) errors.push(`${frame.dataset.frame} has non-token inline styles: ${inlineNames.join(", ")}`);
        for (const element of frame.querySelectorAll("[style]")) {
          const rawNames = [...element.style].filter((name) => !name.startsWith("--"));
          if (rawNames.length) errors.push(`${frame.dataset.frame} has non-token child inline styles: ${rawNames.join(", ")}`);
        }
        const fixture = manifest.fixtures[frame.dataset.fixture];
        if (!fixture) errors.push(`${frame.dataset.frame} fixture is absent from manifest`);
        for (const fact of frame.querySelectorAll("[data-fact-key]")) {
          const expectedFact = fixture?.facts?.[fact.dataset.factKey];
          const value = fact.textContent.replace(/\s+/g, " ").trim();
          facts.push({ frame: frame.dataset.frame, key: fact.dataset.factKey, value });
          if (value !== expectedFact) errors.push(`${frame.dataset.frame} fact ${fact.dataset.factKey} differs`);
        }
      }
      const runtimeScripts = [...document.scripts].filter((script) => script.type !== "text/x-dc");
      if (runtimeScripts.length) errors.push("executable runtime script found");
      if (document.querySelector("link, img[src], iframe, object, embed, video[src], audio[src], source[src]")) errors.push("external-capable asset element found");
      for (const element of document.querySelectorAll("[href], [src], [action], [poster]")) {
        for (const attribute of ["href", "src", "action", "poster"]) {
          const value = element.getAttribute(attribute) ?? "";
          if (/^(?:https?:)?\/\//i.test(value)) errors.push(`external ${attribute} found`);
        }
      }
      if (manifest.componentStates) {
        const observedComponents = Object.keys(manifest.componentStates).sort();
        const expectedComponents = Object.keys(componentStates).sort();
        if (JSON.stringify(observedComponents) !== JSON.stringify(expectedComponents)) errors.push("component inventory differs");
        for (const component of expectedComponents) {
          const observedStates = [...(manifest.componentStates[component] ?? [])].sort();
          const expectedStates = [...componentStates[component]].sort();
          if (JSON.stringify(observedStates) !== JSON.stringify(expectedStates)) errors.push(`${component} state inventory differs`);
        }
      }
      return {
        errors,
        facts,
        frameMetadata: frames.map((frame) => Object.fromEntries(requiredFrameAttributes.map((attribute) => [attribute, frame.getAttribute(attribute)]))),
        visibleFrameText: frames.map((frame) => frame.innerText).join("\n"),
        manifestFormat: manifest.format,
        canonicalAuthority: manifest.canonicalAuthority,
        nonCanonical: manifest.nonCanonical
      };
    }, { requiredFrameAttributes, componentStates });
    page.off("request", onRequest);

    expect(result.errors, filename).toEqual([]);
    expect(unexpectedRequests, filename).toEqual([]);
    expect(result.manifestFormat).toBe("pro-football-coach.design-reference.v3");
    expect(result.canonicalAuthority).toBe("docs/04-UX-AND-DESIGN-SYSTEM.md");
    expect(result.nonCanonical).toBe(true);
    expect(extraRealIdentities.test(result.visibleFrameText), filename).toBe(false);
    expect(blockedIdentity(result.visibleFrameText, blockedNames), filename).toBeNull();
    factCount += result.facts.length;
    for (const metadata of result.frameMetadata) {
      const frameId = metadata["data-frame"];
      expect(frameIds.has(frameId), frameId).toBe(false);
      frameIds.add(frameId);
      frameCount += 1;
      const flow = metadata["data-flow"];
      if (!observedFlowStates.has(flow)) observedFlowStates.set(flow, new Set());
      observedFlowStates.get(flow).add(metadata["data-state"]);
    }
  }
  expect(frameCount).toBe(92);
  expect(factCount).toBeGreaterThan(250);
  for (const [flow, states] of Object.entries(requiredFlowStates)) {
    for (const state of states) expect(observedFlowStates.get(flow)?.has(state), `${flow}/${state}`).toBe(true);
  }

  await page.goto(referenceUrl("FirstRun-v3.dc.html", "entry-offer"));
  const commitments = page.locator('[data-commitment="true"]');
  await expect(commitments).toHaveCount(1);
  await expect(commitments).toHaveText("Accept appointment");
});

test("all native frames pass browser semantics, contrast, target, focus, canvas-twin, and AX5 checks", async ({ page }) => {
  let auditedFrames = 0;
  let auditedText = 0;
  let auditedTargets = 0;
  let auditedFills = 0;
  for (const filename of outputNames) {
    await page.goto(referenceUrl(filename, ""));
    const audits = await page.locator(".product-frame").evaluateAll((frames) => {
      const parseColour = (value) => {
        const hex = value.trim().match(/^#([0-9a-f]{6})$/i)?.[1];
        if (hex) return { r: Number.parseInt(hex.slice(0, 2), 16), g: Number.parseInt(hex.slice(2, 4), 16), b: Number.parseInt(hex.slice(4, 6), 16), a: 1 };
        const parts = value.match(/[\d.]+/g)?.map(Number) ?? [];
        return parts.length >= 3 ? { r: parts[0], g: parts[1], b: parts[2], a: parts.length > 3 ? parts[3] : 1 } : null;
      };
      const composite = (top, bottom) => {
        const alpha = top.a + bottom.a * (1 - top.a);
        if (alpha === 0) return { r: 0, g: 0, b: 0, a: 0 };
        return {
          r: (top.r * top.a + bottom.r * bottom.a * (1 - top.a)) / alpha,
          g: (top.g * top.a + bottom.g * bottom.a * (1 - top.a)) / alpha,
          b: (top.b * top.a + bottom.b * bottom.a * (1 - top.a)) / alpha,
          a: alpha
        };
      };
      const background = (element) => {
        let colour = { r: 0, g: 0, b: 0, a: 0 };
        for (let node = element; node; node = node.parentElement) {
          const layer = parseColour(getComputedStyle(node).backgroundColor);
          if (layer) colour = composite(colour, layer);
          if (colour.a >= 0.999) break;
        }
        return colour;
      };
      const channel = (value) => {
        const normalised = value / 255;
        return normalised <= 0.04045 ? normalised / 12.92 : ((normalised + 0.055) / 1.055) ** 2.4;
      };
      const luminance = (colour) => 0.2126 * channel(colour.r) + 0.7152 * channel(colour.g) + 0.0722 * channel(colour.b);
      const ratio = (first, second) => {
        const values = [luminance(first), luminance(second)].sort((left, right) => right - left);
        return (values[0] + 0.05) / (values[1] + 0.05);
      };
      const visible = (element) => {
        const style = getComputedStyle(element);
        const rectangle = element.getBoundingClientRect();
        return style.display !== "none" && style.visibility !== "hidden" && Number(style.opacity) !== 0 && rectangle.width > 0 && rectangle.height > 0;
      };
      const inside = (rectangle, outer, tolerance = 1) => rectangle.left >= outer.left - tolerance && rectangle.top >= outer.top - tolerance && rectangle.right <= outer.right + tolerance && rectangle.bottom <= outer.bottom + tolerance;
      const isDisabled = (element) => element.matches(":disabled") || element.getAttribute("aria-disabled") === "true";
      const fillSelectors = [".rating-fill", ".progress > i", ".security-meter > i", ".mini-meter > i", ".mini-opposed b", ".mini-spark > i", ".league-map .map-dot", ".mini-map > i", ".line-of-scrimmage"];

      return frames.map((frame) => {
        const errors = [];
        const frameRectangle = frame.getBoundingClientRect();
        let textChecks = 0;
        let targetChecks = 0;
        let fillChecks = 0;
        const textElements = new Set();
        const walker = document.createTreeWalker(frame, NodeFilter.SHOW_TEXT);
        while (walker.nextNode()) {
          if (!walker.currentNode.textContent.trim()) continue;
          const element = walker.currentNode.parentElement;
          if (!element || element.closest('[aria-hidden="true"], .snap-voiceover, .cvd-definitions')) continue;
          if (visible(element)) textElements.add(element);
        }
        for (const element of textElements) {
          textChecks += 1;
          const style = getComputedStyle(element);
          const size = parseFloat(style.fontSize);
          if (size < 11.95) errors.push(`${element.className || element.tagName} management text is ${size}px`);
          if (element.closest(":disabled, [aria-disabled=true]")) continue;
          const seam = element.closest(".rivalry-seam");
          const backdrop = background(element);
          const foreground = composite(parseColour(style.color), backdrop);
          const contrast = seam
            ? Math.min(...["--team-secondary", "--opponent-secondary"].map((token) => ratio(parseColour(style.color), parseColour(getComputedStyle(frame).getPropertyValue(token)))))
            : ratio(foreground, backdrop);
          const large = size >= 24 || (size >= 18.66 && Number.parseInt(style.fontWeight, 10) >= 700);
          const required = large ? 3 : 4.5;
          if (contrast + 0.01 < required) errors.push(`${element.className || element.tagName} text contrast ${contrast.toFixed(2)} < ${required}`);
        }

        for (const control of frame.querySelectorAll("button, input, select, textarea, [role=button], [tabindex]")) {
          if (!visible(control)) continue;
          targetChecks += 1;
          const labelledBy = (control.getAttribute("aria-labelledby") ?? "")
            .split(/\s+/)
            .filter(Boolean)
            .map((id) => document.getElementById(id)?.textContent ?? "")
            .join(" ");
          const accessibleName = control.getAttribute("aria-label")
            || labelledBy
            || [...(control.labels ?? [])].map((label) => label.textContent).join(" ")
            || control.textContent
            || control.getAttribute("title")
            || control.getAttribute("value");
          if (!accessibleName?.trim()) errors.push(`${control.tagName} has no accessible name`);
          let rectangle = control.getBoundingClientRect();
          if (rectangle.width < 43.95 || rectangle.height < 43.95) errors.push(`${control.textContent.trim() || control.tagName} target is ${rectangle.width.toFixed(1)}x${rectangle.height.toFixed(1)}`);
          if (!inside(rectangle, frame.getBoundingClientRect())) {
            control.scrollIntoView({ block: "nearest", inline: "nearest" });
            rectangle = control.getBoundingClientRect();
            if (!inside(rectangle, frame.getBoundingClientRect())) errors.push(`${control.textContent.trim() || control.tagName} cannot be scrolled into the product frame`);
          }
          if (isDisabled(control)) {
            if (!control.matches(":disabled") || control.getAttribute("aria-disabled") !== "true") errors.push(`${control.textContent.trim() || control.tagName} disabled semantics incomplete`);
            control.focus();
            if (document.activeElement === control) errors.push(`${control.textContent.trim() || control.tagName} disabled control accepts focus`);
          } else {
            if (control.tabIndex < 0) errors.push(`${control.textContent.trim() || control.tagName} is not keyboard reachable`);
            control.focus();
            if (document.activeElement !== control) errors.push(`${control.textContent.trim() || control.tagName} cannot receive focus`);
            const focused = getComputedStyle(control);
            if (focused.outlineStyle === "none" && focused.boxShadow === "none") errors.push(`${control.textContent.trim() || control.tagName} has no visible focus treatment`);
          }
        }

        for (const fill of frame.querySelectorAll(fillSelectors.join(","))) {
          if (!visible(fill)) continue;
          fillChecks += 1;
          const style = getComputedStyle(fill);
          const landing = background(fill.parentElement);
          const colour = composite(parseColour(style.backgroundColor), landing);
          const fillRatio = ratio(colour, landing);
          const boundaryColours = [style.borderTopColor, style.borderRightColor, style.borderBottomColor, style.borderLeftColor].map(parseColour);
          const boundaryWidths = [style.borderTopWidth, style.borderRightWidth, style.borderBottomWidth, style.borderLeftWidth].map(parseFloat);
          const completeBoundary = boundaryWidths.every((width, index) => width >= 1 && ratio(composite(boundaryColours[index], landing), landing) >= 3);
          if (fillRatio + 0.01 < 3 && !completeBoundary) errors.push(`${fill.parentElement.className || fill.parentElement.tagName} > ${fill.className || fill.tagName} fill contrast ${fillRatio.toFixed(2)} has no compliant complete boundary`);
        }

        for (const visualField of frame.querySelectorAll(".field")) {
          if (visualField.getAttribute("aria-hidden") !== "true") errors.push("visual field is exposed to assistive reading");
          const twins = frame.querySelectorAll(".snap-voiceover");
          if (twins.length !== 1 || !twins[0].textContent.trim()) errors.push("visual field lacks one composed text twin");
        }
        for (const map of frame.querySelectorAll(".league-map")) {
          if (map.getAttribute("aria-hidden") !== "true") errors.push("visual map is exposed to assistive reading");
          const twin = map.parentElement.querySelector(".semantic-twin");
          if (!twin || twin.dataset.lens !== map.dataset.lens || twin.querySelectorAll("li[data-program-index]").length !== 134) errors.push("visual map lacks its matching 134-programme text twin");
        }
        if (frame.dataset.typeScale === "ax5") {
          const expected = { display: 60, title: 56, headline: 53, body: 53, callout: 51, caption: 43, numeral: 58 };
          for (const element of frame.querySelectorAll("[data-type-role]")) {
            if (Math.round(parseFloat(getComputedStyle(element).fontSize)) !== expected[element.dataset.typeRole]) errors.push(`${element.dataset.typeRole} is not the true AX5 size`);
          }
          if (parseFloat(getComputedStyle(frame).fontSize) !== expected.body) errors.push("AX5 frame body does not render at 53px");
        }
        return { frame: frame.dataset.frame, errors: [...new Set(errors)], textChecks, targetChecks, fillChecks };
      });
    });
    for (const audit of audits) {
      expect(audit.errors, `${filename}#${audit.frame}`).toEqual([]);
      auditedFrames += 1;
      auditedText += audit.textChecks;
      auditedTargets += audit.targetChecks;
      auditedFills += audit.fillChecks;
    }
  }
  expect(auditedFrames).toBe(92);
  expect(auditedText).toBeGreaterThan(1_000);
  expect(auditedTargets).toBeGreaterThan(150);
  expect(auditedFills).toBeGreaterThan(500);
});

test("compact, regular, light, dark, both landscape rotations, AX5, and 667 reachability are rendered", async ({ page }) => {
  for (const [filename, frameId, snapshotName] of visualMatrix) {
    const frame = await openReference(page, filename, frameId);
    await expect(frame).toHaveScreenshot(snapshotName);
  }

  const compactFrames = [];
  for (const filename of outputNames) {
    await page.goto(referenceUrl(filename, ""));
    compactFrames.push(...await page.locator('.product-frame[data-device="844x390"]').evaluateAll((frames) => frames.map((frame) => ({ filename: document.location.pathname.split("/").pop(), frameId: frame.dataset.frame }))));
  }
  expect(compactFrames.length).toBeGreaterThan(70);

  for (const rotation of ["landscape-primary", "landscape-secondary"]) {
    for (const { filename, frameId } of compactFrames) {
      const frame = await openReference(page, filename, frameId);
      const errors = await frame.evaluate((element, rotationName) => {
        element.dataset.validationRotation = rotationName;
        element.style.setProperty("--frame-width", "667px");
        element.style.setProperty("--frame-height", "375px");
        const errors = [];
        const frameRectangle = element.getBoundingClientRect();
        const visible = (candidate) => {
          const style = getComputedStyle(candidate);
          const rectangle = candidate.getBoundingClientRect();
          return style.display !== "none" && style.visibility !== "hidden" && Number(style.opacity) !== 0 && rectangle.width > 0 && rectangle.height > 0;
        };
        const inside = (rectangle, outer, tolerance = 1) => rectangle.left >= outer.left - tolerance && rectangle.top >= outer.top - tolerance && rectangle.right <= outer.right + tolerance && rectangle.bottom <= outer.bottom + tolerance;
        const scrollableAncestor = (candidate) => {
          for (let ancestor = candidate.parentElement; ancestor && ancestor !== element; ancestor = ancestor.parentElement) {
            const style = getComputedStyle(ancestor);
            const horizontal = /(auto|scroll)/.test(style.overflowX) && ancestor.scrollWidth > ancestor.clientWidth;
            const vertical = /(auto|scroll)/.test(style.overflowY) && ancestor.scrollHeight > ancestor.clientHeight;
            if (horizontal || vertical) return ancestor;
          }
          return null;
        };
        for (const control of element.querySelectorAll("button, input, select, textarea, [role=button], [tabindex]")) {
          if (!visible(control)) continue;
          const wasInside = inside(control.getBoundingClientRect(), frameRectangle);
          const scrollContainer = scrollableAncestor(control);
          control.scrollIntoView({ block: "nearest", inline: "nearest" });
          const rectangle = control.getBoundingClientRect();
          if (!inside(rectangle, element.getBoundingClientRect())) errors.push(`${control.textContent.trim() || control.tagName} is unreachable`);
          if (!wasInside && !scrollContainer) errors.push(`${control.textContent.trim() || control.tagName} starts off-screen without a scroll path`);
        }
        for (const selector of [".status-bar", ".app-header", ".destination-bar", ".score-bug", ".match-exit", ".direction", ".draft-bug"]) {
          for (const candidate of element.querySelectorAll(selector)) {
            if (visible(candidate) && !inside(candidate.getBoundingClientRect(), frameRectangle)) errors.push(`${selector} leaves the 667x375 frame`);
          }
        }
        return [...new Set(errors)];
      }, rotation);
      expect(errors, `${rotation} ${filename}#${frameId}`).toEqual([]);
    }
  }

  for (const rotation of ["landscape-primary", "landscape-secondary"]) {
    const frame = await openReference(page, "League-v3.dc.html", "map-reach");
    await frame.evaluate((element, rotationName) => {
      element.dataset.validationRotation = rotationName;
      element.style.setProperty("--frame-width", "667px");
      element.style.setProperty("--frame-height", "375px");
    }, rotation);
    await expect(frame).toHaveScreenshot(`matrix-667-${rotation}.png`);
  }
});

test("the complete fifteen-minute flow is ordered, actionable, and snapshotted", async ({ page }) => {
  const observed = [];
  for (const [filename, frameId, flow, state, expectedText] of flowScenario) {
    const frame = await openReference(page, filename, frameId);
    await expect(frame).toHaveAttribute("data-flow", flow);
    await expect(frame).toHaveAttribute("data-state", state);
    await expect(frame).toContainText(expectedText);
    observed.push(`${flow}/${state}`);
    const sequence = String(observed.length).padStart(2, "0");
    await expect(frame).toHaveScreenshot(`flow-${sequence}-${frameId}.png`);
  }
  expect(observed).toEqual(flowScenario.map(([, , flow, state]) => `${flow}/${state}`));
});
