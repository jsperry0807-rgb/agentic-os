#!/usr/bin/env node
/**
 * Web Research → Wiki Ingestion Pipeline
 *
 * Uses Playwright (bundled via @playwright/mcp) to browse a web page,
 * extract its main content, and save it into the LLM Wiki.
 *
 * Usage:
 *   node web-research.js <url>                          # print to stdout
 *   node web-research.js <url> --save                   # save to ~/wiki/raw/
 *   node web-research.js <url> --save --name my-topic   # custom filename
 *   node web-research.js --help
 *
 * Examples:
 *   node web-research.js "https://example.com"
 *   node web-research.js "https://docs.anthropic.com/en/docs" --save
 *   node web-research.js "https://react.dev" --save --name react-docs-overview
 */

// Find playwright-core from @playwright/mcp global install or local node_modules
const playwrightCorePath = (() => {
  try {
    return require.resolve('playwright-core', { paths: [__dirname, require('path').join(__dirname, '..')] });
  } catch {
    // Fallback: global npm installation
    const globalPath = require('child_process').execSync('npm root -g', { encoding: 'utf8' }).trim();
    try {
      return require.resolve('playwright-core', { paths: [globalPath,
        require('path').join(globalPath, '@playwright', 'mcp', 'node_modules')] });
    } catch {
      return null;
    }
  }
})();
if (!playwrightCorePath) {
  console.error('Error: playwright-core not found. Install it with: npm install -g playwright-core');
  process.exit(1);
}
const { chromium } = require(playwrightCorePath);

const WIKI_DIR = process.env.WIKI_DIR || require('path').join(require('os').homedir(), 'wiki');
const CHROMIUM_PATH = process.env.PLAYWRIGHT_CHROMIUM_EXECUTABLE
  || require('path').join(require('os').homedir(), '.cache', 'ms-playwright', 'chromium-1224', 'chrome-linux64', 'chrome');

// ── Parse args ──────────────────────────────────────────────────────────────
const args = process.argv.slice(2);
if (args.length === 0 || args[0] === '--help' || args[0] === '-h') {
  console.log(`
Web Research → Wiki Ingestion Pipeline

Usage:
  node web-research.js <url>                          print to stdout
  node web-research.js <url> --save                   save to ~/wiki/raw/
  node web-research.js <url> --save --name <name>     custom filename
  node web-research.js --help                         this help

Examples:
  node web-research.js "https://example.com"
  node web-research.js "https://react.dev" --save
  node web-research.js "https://docs.anthropic.com/en/docs" --save --name claude-docs
`);
  process.exit(0);
}

const url = args[0];
const save = args.includes('--save');
let name = '';
const nameIdx = args.indexOf('--name');
if (nameIdx >= 0 && nameIdx < args.length - 1) name = args[nameIdx + 1];

// ── Derive a filename from the URL ──────────────────────────────────────────
function urlToFilename(url) {
  try {
    const u = new URL(url);
    let slug = u.hostname + (u.pathname !== '/' ? u.pathname.replace(/\/$/, '') : '');
    slug = slug.replace(/^www\./, '');
    slug = slug.replace(/[^a-zA-Z0-9_-]/g, '_').replace(/_+/g, '_').replace(/^_|_$/g, '');
    return slug.slice(0, 120) + '.md';
  } catch {
    return 'web-research-' + Date.now() + '.md';
  }
}

async function extractContent(page) {
  // Wait for the page to be reasonably loaded
  await page.waitForLoadState('networkidle').catch(() => {});

  // Extract the main content using multiple strategies
  const result = await page.evaluate(() => {
    function getText(el) {
      if (!el) return '';
      return el.innerText.trim();
    }

    // Try article tag first
    let main = document.querySelector('article');
    // Then main tag
    if (!main || main.innerText.trim().length < 100) main = document.querySelector('main');
    // Then role=main
    if (!main || main.innerText.trim().length < 100) main = document.querySelector('[role="main"]');
    // Then #content or .content
    if (!main || main.innerText.trim().length < 100) main = document.getElementById('content');
    if (!main || main.innerText.trim().length < 100) main = document.querySelector('.content');
    // Fallback to body (filtered)
    if (!main || main.innerText.trim().length < 100) main = document.body;

    const content = main ? main.innerText.trim() : '(no content extracted)';

    return {
      title: document.title || '(no title)',
      url: window.location.href,
      content: content,
      meta: {
        description: document.querySelector('meta[name="description"]')?.content || '',
        keywords: document.querySelector('meta[name="keywords"]')?.content || '',
      },
    };
  });

  return result;
}

function formatMarkdown(data) {
  const lines = [];
  const now = new Date().toISOString().split('T')[0];

  lines.push(`# ${data.title}`);
  lines.push('');
  lines.push(`> **Source**: [${data.url}](${data.url})`);
  lines.push(`> **Fetched**: ${now}`);
  if (data.meta.description) lines.push(`> **Description**: ${data.meta.description}`);
  if (data.meta.keywords) lines.push(`> **Keywords**: ${data.meta.keywords}`);
  lines.push('');
  lines.push('---');
  lines.push('');
  lines.push(data.content);
  lines.push('');
  lines.push('---');
  lines.push(`_Auto-ingested by web-research.js on ${now}_`);

  return lines.join('\n');
}

// ── Main ────────────────────────────────────────────────────────────────────
async function main() {
  // On unsupported distros (e.g. Ubuntu 26.04), some deps ship with Playwright's Firefox bundle
  const firefoxLibDir = require('path').join(require('os').homedir(),
    '.cache', 'ms-playwright', 'firefox-1522', 'firefox');
  if (!process.env.LD_LIBRARY_PATH || !process.env.LD_LIBRARY_PATH.includes(firefoxLibDir)) {
    process.env.LD_LIBRARY_PATH = `${firefoxLibDir}:${process.env.LD_LIBRARY_PATH || ''}`;
  }

  const browser = await chromium.launch({
    executablePath: CHROMIUM_PATH,
    headless: true,
    args: ['--no-sandbox', '--disable-setuid-sandbox', '--disable-dev-shm-usage'],
  });

  const context = await browser.newContext({
    userAgent: 'Mozilla/5.0 (X11; Linux x86_64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/149.0.0.0 Safari/537.36',
  });
  const page = await context.newPage();

  try {
    console.error(`Navigating to ${url}...`);
    await page.goto(url, { waitUntil: 'domcontentloaded', timeout: 30000 });
    console.error('Extracting content...');

    const data = await extractContent(page);
    const markdown = formatMarkdown(data);

    if (save) {
      const fs = require('fs');
      const path = require('path');
      const rawDir = path.join(WIKI_DIR, 'raw');
      fs.mkdirSync(rawDir, { recursive: true });

      const filename = name ? name.replace(/[^a-zA-Z0-9_-]/g, '_') + '.md' : urlToFilename(url);
      const filepath = path.join(rawDir, filename);
      fs.writeFileSync(filepath, markdown, 'utf-8');
      console.error(`✓ Saved to ${filepath}`);
    } else {
      console.log(markdown);
    }

    // Preview
    const title = data.title;
    const charCount = data.content.length;
    console.error(`\n  URL:  ${url}`);
    console.error(`  Title: ${title}`);
    console.error(`  Size:  ${charCount} chars extracted`);
  } catch (err) {
    console.error(`✗ Error: ${err.message}`);
    process.exitCode = 1;
  } finally {
    await browser.close();
  }
}

main().catch(err => {
  console.error(`Fatal: ${err.message}`);
  process.exit(1);
});
