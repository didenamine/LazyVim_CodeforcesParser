#!/usr/bin/env node
/**
 * fetch_page.js <url>
 * Launches a headless Chromium browser via Playwright, navigates to the given
 * Codeforces URL, waits for the problem statement to appear, then prints the
 * full page HTML to stdout and exits.
 *
 * This bypasses Cloudflare bot-protection that blocks plain curl/http requests.
 */

const { chromium } = require("playwright");

const url = process.argv[2];
if (!url) {
  process.stderr.write("Usage: node fetch_page.js <url>\n");
  process.exit(1);
}

(async () => {
  let browser;
  try {
    browser = await chromium.launch({ headless: true });
    const context = await browser.newContext({
      userAgent:
        "Mozilla/5.0 (X11; Linux x86_64) AppleWebKit/537.36 " +
        "(KHTML, like Gecko) Chrome/124.0.0.0 Safari/537.36",
      locale: "en-US",
      extraHTTPHeaders: {
        "Accept-Language": "en-US,en;q=0.9",
      },
    });

    const page = await context.newPage();

    // Navigate and wait until network is idle (Cloudflare challenge finishes)
    await page.goto(url, { waitUntil: "networkidle", timeout: 30000 });

    // Extra wait to let any JS-rendered content settle
    try {
      await page.waitForSelector(".problem-statement", { timeout: 10000 });
    } catch (_) {
      // problem-statement selector not found within timeout — still print HTML
    }

    const html = await page.content();
    process.stdout.write(html);
    await browser.close();
    process.exit(0);
  } catch (err) {
    if (browser) await browser.close().catch(() => {});
    process.stderr.write("Error: " + err.message + "\n");
    process.exit(1);
  }
})();
