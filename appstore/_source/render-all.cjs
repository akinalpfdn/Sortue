/* node render-all.cjs [locale ...]
   Renders every locale in copy.js (except en-US, whose artwork lives in ../en) into ../<locale>/{iphone,ipad,previews}.
   Pass locale codes to render a subset; pass "en-US" explicitly to render the English check set.
   Same Playwright setup and 320px typography audit as ../en/render.cjs, plus a copy/visual overlap check. */
const fs = require('node:fs'), path = require('node:path'), vm = require('node:vm'), os = require('node:os');
const { pathToFileURL } = require('node:url');
process.env.PLAYWRIGHT_MODULE ||= path.join(os.homedir(), '.cache/codex-runtimes/codex-primary-runtime/dependencies/node/node_modules/playwright');
if (!process.env.CHROME_PATH && fs.existsSync('/Applications/Google Chrome.app/Contents/MacOS/Google Chrome'))
  process.env.CHROME_PATH = '/Applications/Google Chrome.app/Contents/MacOS/Google Chrome';
const pw = require(process.env.PLAYWRIGHT_MODULE);

const ctx = { window: {} };
vm.runInNewContext(fs.readFileSync(path.join(__dirname, 'copy.js'), 'utf8'), ctx);
const all = Object.keys(ctx.window.COPY);
const locales = process.argv.length > 2 ? process.argv.slice(2) : all.filter(l => l !== 'en-US');
for (const l of locales) if (!all.includes(l)) throw Error(`Unknown locale ${l}`);

const SLIDES = ['01-color-and-calm', '02-every-shade', '03-start-small', '04-every-mood'];
const DEVICES = { iphone: { width: 660, height: 1434 }, ipad: { width: 1032, height: 1376 } };
const MIN_GAP = 12; // px between the last line of copy and the top of the artwork

async function audit(page, width) {
  return page.evaluate(({ width }) => {
    const result = [], walker = document.createTreeWalker(document.body, NodeFilter.SHOW_TEXT); let node;
    while (node = walker.nextNode()) {
      const text = node.textContent.trim(), el = node.parentElement;
      if (!text || !el || el.closest('script,style,noscript,[data-store-ignore="icon"]')) continue;
      let visible = true, scale = 1;
      for (let p = el; p; p = p.parentElement) {
        const c = getComputedStyle(p);
        if (c.display === 'none' || c.visibility === 'hidden' || Number(c.opacity) === 0) visible = false;
        if (c.transform !== 'none') { const m = new DOMMatrix(c.transform); scale *= Math.hypot(m.c, m.d); }
      }
      if (!visible) continue;
      const range = document.createRange(); range.selectNodeContents(node); const box = range.getBoundingClientRect();
      if (!box.width || !box.height) continue;
      const role = el.closest('[data-store-role]')?.dataset.storeRole || (el.closest('h1,h2') ? 'headline' : el.closest('p') ? 'support' : 'label');
      const minimum = { headline: 28, support: 18, label: 16 }[role] || 16;
      const px = parseFloat(getComputedStyle(el).fontSize) * scale * 320 / width;
      result.push({ text, role, previewPx: +px.toFixed(2), minimum, pass: px + 0.01 >= minimum });
    }
    return result;
  }, { width });
}

(async () => {
  const html = pathToFileURL(path.join(__dirname, 'listing.html')).href;
  const options = { headless: true }; if (process.env.CHROME_PATH) options.executablePath = process.env.CHROME_PATH;
  const browser = await pw.chromium.launch(options), problems = [];
  try {
    for (const locale of locales) {
      const out = path.join(__dirname, '..', locale), reports = [];
      for (const [device, size] of Object.entries(DEVICES)) {
        for (const [i, slide] of SLIDES.entries()) {
          const name = `${device}/${slide}`;
          const c = await browser.newContext({ viewport: size, deviceScaleFactor: 2 });
          await c.route('**/*', r => /^https?:/.test(r.request().url()) ? r.abort() : r.continue());
          const page = await c.newPage();
          await page.goto(`${html}?locale=${locale}&device=${device}&slide=${i + 1}`);
          await page.evaluate(async () => { await window.layoutReady; await Promise.all([...document.images].map(i => i.decode().catch(() => {}))); });
          const missing = await page.locator('img').evaluateAll(imgs => imgs.filter(i => !i.naturalWidth).map(i => i.getAttribute('src')));
          if (missing.length) throw Error(`${locale} ${name}: missing images ${missing.join(', ')}`);
          const layout = await page.evaluate(() => window.layout);
          const text = await audit(page, size.width); reports.push({ frame: name, layout, text });
          for (const t of text.filter(t => !t.pass)) problems.push(`${locale} ${name}: too small at 320px: "${t.text}" ${t.previewPx}px < ${t.minimum}px`);
          if (layout.copyBottom + MIN_GAP > layout.visualTop) problems.push(`${locale} ${name}: copy overlaps artwork (${layout.copyBottom.toFixed(0)} > ${layout.visualTop.toFixed(0)} - ${MIN_GAP})`);
          if (layout.wrapped) problems.push(`${locale} ${name}: a line had to wrap`);
          const dest = path.join(out, name + '.png'); fs.mkdirSync(path.dirname(dest), { recursive: true });
          await page.screenshot({ path: dest, type: 'png' }); await c.close();
          const pc = await browser.newContext({ viewport: { width: 320, height: Math.round(size.height * 320 / size.width) }, deviceScaleFactor: 1 });
          const pp = await pc.newPage();
          await pp.setContent(`<html><style>html,body{margin:0;background:white}img{display:block;width:320px}</style><img src="data:image/png;base64,${fs.readFileSync(dest).toString('base64')}"></html>`, { waitUntil: 'domcontentloaded' });
          await pp.locator('img').evaluate(i => i.decode());
          const thumb = path.join(out, 'previews', name + '.png'); fs.mkdirSync(path.dirname(thumb), { recursive: true });
          await pp.screenshot({ path: thumb }); await pc.close();
        }
      }
      fs.writeFileSync(path.join(out, 'typography-report.json'), JSON.stringify(reports, null, 2));
      console.log(`${locale}: 8 frames`);
    }
  } finally { await browser.close(); }
  if (problems.length) { console.error(problems.join('\n')); process.exitCode = 1; }
})().catch(e => { console.error(e.message); process.exitCode = 1; });
