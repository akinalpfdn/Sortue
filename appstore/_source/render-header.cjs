/* node render-header.cjs
   Exports header.html as ../creative/universal-5244x2950.png (16:9 universal asset) and
   ../creative/header-3840x1646.png (21:9 product page header, center crop of the same scene). */
const fs = require('node:fs'), path = require('node:path'), os = require('node:os');
const { pathToFileURL } = require('node:url');
process.env.PLAYWRIGHT_MODULE ||= path.join(os.homedir(), '.cache/codex-runtimes/codex-primary-runtime/dependencies/node/node_modules/playwright');
if (!process.env.CHROME_PATH && fs.existsSync('/Applications/Google Chrome.app/Contents/MacOS/Google Chrome'))
  process.env.CHROME_PATH = '/Applications/Google Chrome.app/Contents/MacOS/Google Chrome';
const pw = require(process.env.PLAYWRIGHT_MODULE);

(async () => {
  const out = path.join(__dirname, '..', 'creative'); fs.mkdirSync(out, { recursive: true });
  const options = { headless: true }; if (process.env.CHROME_PATH) options.executablePath = process.env.CHROME_PATH;
  const browser = await pw.chromium.launch(options);
  try {
    const ctx = await browser.newContext({ viewport: { width: 2622, height: 1475 }, deviceScaleFactor: 2 });
    await ctx.route('**/*', r => /^https?:/.test(r.request().url()) ? r.abort() : r.continue());
    const page = await ctx.newPage();
    await page.goto(pathToFileURL(path.join(__dirname, 'header.html')).href);
    await page.evaluate(async () => { await Promise.all([...document.images].map(i => i.decode())); });
    await page.screenshot({ path: path.join(out, 'universal-5244x2950.png'), type: 'png' });
    await ctx.close();
    // 21:9 header: 2622 × 1124 CSS px scaled by 3840/2622 gives exactly 3840 × 1646.
    const wide = await browser.newContext({ viewport: { width: 2622, height: 1124 }, deviceScaleFactor: 3840 / 2622 });
    await wide.route('**/*', r => /^https?:/.test(r.request().url()) ? r.abort() : r.continue());
    const wp = await wide.newPage();
    await wp.goto(pathToFileURL(path.join(__dirname, 'header.html')).href + '?ratio=21');
    await wp.evaluate(async () => { await Promise.all([...document.images].map(i => i.decode())); });
    await wp.screenshot({ path: path.join(out, 'header-3840x1646.png'), type: 'png' });
    await wide.close();
  } finally { await browser.close(); }
  console.log('wrote', out);
})().catch(e => { console.error(e.message); process.exitCode = 1; });
