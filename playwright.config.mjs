import { defineConfig } from "@playwright/test";

export default defineConfig({
  testDir: "./Tests/DesignReferences",
  testMatch: "rendered.spec.mjs",
  outputDir: "test-results/design-references",
  snapshotPathTemplate: "{testDir}/__snapshots__/{arg}{ext}",
  fullyParallel: false,
  forbidOnly: true,
  workers: 1,
  retries: 0,
  timeout: 120_000,
  expect: {
    timeout: 10_000,
    toHaveScreenshot: {
      animations: "disabled",
      caret: "hide",
      maxDiffPixelRatio: 0,
      scale: "css"
    }
  },
  reporter: [["line"]],
  use: {
    browserName: "chromium",
    colorScheme: "dark",
    headless: true,
    locale: "en-GB",
    reducedMotion: "reduce",
    serviceWorkers: "block",
    viewport: { width: 1100, height: 520 }
  }
});
