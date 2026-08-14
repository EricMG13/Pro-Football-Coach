// Render one *-v4.dc.html sheet headless, at 1600pt wide, full content height.
// Downscaling to 1280px — the recipe docs/proofs/README.md documents for the
// committed PNGs ("headless Chrome at 1600 pt wide, cropped to content,
// downscaled to 1280 px") — is a separate step this script does not perform.
// Used first to prove the pipeline against a v3 sheet whose committed render
// could be compared against, then reused for the full v4 set.
const { chromium } = require('playwright');
const path = require('path');

async function main() {
  const [, , inputPath, outputPath] = process.argv;
  if (!inputPath || !outputPath) {
    console.error('usage: node render_sheet.js <input.html> <output.png>');
    process.exit(1);
  }
  const browser = await chromium.launch({
    executablePath: '/opt/pw-browsers/chromium',
  });
  const page = await browser.newPage({
    viewport: { width: 1600, height: 1200 },
    deviceScaleFactor: 1,
  });
  await page.goto('file://' + path.resolve(inputPath));
  await page.waitForTimeout(150); // let any CSS transitions/fonts settle
  const height = await page.evaluate(() => document.documentElement.scrollHeight);
  await page.setViewportSize({ width: 1600, height });
  await page.screenshot({ path: outputPath, fullPage: true });
  await browser.close();
  console.log(`rendered ${inputPath} -> ${outputPath} (1600 x ${height})`);
}

main().catch((e) => {
  console.error(e);
  process.exit(1);
});
