/* node render.cjs /absolute/path/manifest.json
   PLAYWRIGHT_MODULE and CHROME_PATH may point to installed dependencies. */
const fs=require('node:fs'),path=require('node:path'),{pathToFileURL}=require('node:url');
process.argv[2] ||= path.join(__dirname,'manifest.json');
process.env.PLAYWRIGHT_MODULE ||= path.join(require('node:os').homedir(),'.cache/codex-runtimes/codex-primary-runtime/dependencies/node/node_modules/playwright');
if(!process.env.CHROME_PATH && fs.existsSync('/Applications/Google Chrome.app/Contents/MacOS/Google Chrome')) process.env.CHROME_PATH='/Applications/Google Chrome.app/Contents/MacOS/Google Chrome';
let pw;try{pw=require(process.env.PLAYWRIGHT_MODULE||'playwright')}catch(e){throw Error('Playwright is required. Set PLAYWRIGHT_MODULE to its installed package directory.')}
async function audit(page,width){return page.evaluate(({width})=>{
 const result=[],walker=document.createTreeWalker(document.body,NodeFilter.SHOW_TEXT);let node;
 while(node=walker.nextNode()){
  const text=node.textContent.trim(),el=node.parentElement;
  if(!text||!el||el.closest('script,style,noscript,[data-store-ignore="icon"]'))continue;
  let visible=true,scale=1;
  for(let p=el;p;p=p.parentElement){const c=getComputedStyle(p);if(c.display==='none'||c.visibility==='hidden'||Number(c.opacity)===0)visible=false;if(c.transform!=='none'){const m=new DOMMatrix(c.transform);scale*=Math.hypot(m.c,m.d)}}
  if(!visible)continue;
  const range=document.createRange();range.selectNodeContents(node);const box=range.getBoundingClientRect();if(!box.width||!box.height)continue;
  const role=el.closest('[data-store-role]')?.dataset.storeRole||(el.closest('h1,h2')?'headline':el.closest('p')?'support':'label');
  const minimum={headline:28,support:18,label:16}[role]||16;
  const px=parseFloat(getComputedStyle(el).fontSize)*scale*320/width;
  result.push({text,role,previewPx:+px.toFixed(2),minimum,pass:px+0.01>=minimum});
 }
 return result;
},{width})}
(async()=>{
 if(!process.argv[2])throw Error('Usage: node render.cjs /path/to/manifest.json');
 const file=path.resolve(process.argv[2]),base=path.dirname(file),m=JSON.parse(fs.readFileSync(file,'utf8'));
 const html=path.resolve(base,m.html),out=path.resolve(base,m.out||'exports');
 if(!Array.isArray(m.frames)||!m.frames.length)throw Error('frames must be nonempty');
 const options={headless:true};if(process.env.CHROME_PATH)options.executablePath=process.env.CHROME_PATH;
 const browser=await pw.chromium.launch(options),reports=[];
 try{
  for(const f of m.frames){
   if(!/^[a-zA-Z0-9_/-]+$/.test(f.name)||f.name.includes('..'))throw Error('Unsafe frame name');
   if(![f.width,f.height,f.scale||2].every(v=>Number.isFinite(v)&&v>0))throw Error('Invalid canvas dimensions');
   const ctx=await browser.newContext({viewport:{width:f.width,height:f.height},deviceScaleFactor:f.scale||2});
   await ctx.route('**/*',r=>/^https?:/.test(r.request().url())?r.abort():r.continue());
   const page=await ctx.newPage();await page.goto(pathToFileURL(html).href+(f.query?'?'+f.query:''));
   await page.evaluate(async()=>{await document.fonts.ready;await Promise.all([...document.images].map(i=>i.decode().catch(()=>{})))});
   const missing=await page.locator('img').evaluateAll(imgs=>imgs.filter(i=>!i.naturalWidth).map(i=>i.getAttribute('src')));
   if(missing.length)throw Error('Missing images: '+missing.join(', '));
   const report={frame:f.name,text:await audit(page,f.width)};reports.push(report);
   const failures=report.text.filter(t=>!t.pass);
   if(failures.length)throw Error('Text too small at 320px: '+JSON.stringify(failures));
   const dest=path.join(out,f.name+'.png');fs.mkdirSync(path.dirname(dest),{recursive:true});
   await page.screenshot({path:dest,type:'png',omitBackground:false});await ctx.close();
   const preview=await browser.newContext({viewport:{width:320,height:Math.round(f.height*320/f.width)},deviceScaleFactor:1});
   const p=await preview.newPage();
   const data='data:image/png;base64,'+fs.readFileSync(dest).toString('base64');
   await p.setContent(`<html><style>html,body{margin:0;background:white}img{display:block;width:320px}</style><img src="${data}"></html>`,{waitUntil:'domcontentloaded'});
   await p.locator('img').evaluate(i=>i.decode());
   const thumb=path.join(out,'previews',f.name+'.png');fs.mkdirSync(path.dirname(thumb),{recursive:true});
   await p.screenshot({path:thumb});await preview.close();
   console.log(`${f.name}: ${f.width*(f.scale||2)}×${f.height*(f.scale||2)}, typography PASS`);
  }
 }finally{fs.mkdirSync(out,{recursive:true});fs.writeFileSync(path.join(out,'typography-report.json'),JSON.stringify(reports,null,2));await browser.close()}
})().catch(e=>{console.error(e.message);process.exitCode=1});
