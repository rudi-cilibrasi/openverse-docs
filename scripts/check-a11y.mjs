// Accessibility check of the built site: axe-core's rules (WCAG 2 A/AA and best
// practices) on every page, at a desktop and a phone width.
//
//   node scripts/check-a11y.mjs build/site
//
// It serves the directory itself, waits for the playground and the simulator to
// settle, and exits 1 if axe reports any violation, printing each one with the
// elements and the fix axe suggests. Pages missing from the build are skipped.
import { createServer } from 'node:http';
import { readFile, stat } from 'node:fs/promises';
import { extname, join, normalize } from 'node:path';
import { chromium } from '@playwright/test';
import AxeBuilder from '@axe-core/playwright';

const root = process.argv[2] ?? 'build/site';
const pages = ['', 'verse-logic/', 'little-verser/', 'demo/', 'sim/'];
const sizes = [[1360, 900], [390, 844]];
const types = {
  '.html': 'text/html', '.css': 'text/css', '.js': 'text/javascript', '.mjs': 'text/javascript',
  '.json': 'application/json', '.wasm': 'application/wasm', '.svg': 'image/svg+xml',
  '.png': 'image/png', '.pdf': 'application/pdf', '.md': 'text/markdown; charset=utf-8',
};

const exists = async (path) => stat(path).then(() => true, () => false);
const server = createServer(async (req, res) => {
  const path = normalize(decodeURIComponent(new URL(req.url, 'http://site').pathname)).replace(/^(\.\.[/\\])+/, '');
  let file = join(root, path);
  try {
    if ((await stat(file)).isDirectory()) file = join(file, 'index.html');
    res.writeHead(200, { 'content-type': types[extname(file)] ?? 'application/octet-stream' });
    res.end(await readFile(file));
  } catch {
    res.writeHead(404);
    res.end('not found');
  }
});
await new Promise((resolve) => server.listen(0, '127.0.0.1', resolve));
const base = `http://127.0.0.1:${server.address().port}/`;

const browser = await chromium.launch({ executablePath: process.env.CHROMIUM_PATH || undefined });
let violations = 0;
for (const [width, height] of sizes) {
  const context = await browser.newContext({ viewport: { width, height } }); // AxeBuilder needs one
  const page = await context.newPage();
  for (const path of pages) {
    if (!(await exists(join(root, path, 'index.html')))) continue;
    await page.goto(base + path, { waitUntil: 'load' });
    await page.waitForTimeout(path === 'sim/' ? 4000 : 1500); // the toys load and compile a first program
    const result = await new AxeBuilder({ page }).analyze();
    for (const v of result.violations) {
      violations++;
      console.log(`${width}px /${path}: ${v.impact} ${v.id} on ${v.nodes.length} element(s): ${v.help}`);
      for (const node of v.nodes.slice(0, 3)) {
        console.log(`    ${node.target.join(' ')}: ${node.failureSummary.split('\n').slice(1).join(' ').trim()}`);
      }
    }
  }
  await context.close();
}
await browser.close();
server.close();
console.log(`check-a11y.mjs: ${pages.length} pages at ${sizes.length} widths, ${violations} violation(s)`);
process.exit(violations ? 1 : 0);
