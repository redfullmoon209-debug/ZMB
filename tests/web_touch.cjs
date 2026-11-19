const { chromium } = require('playwright');
const http = require('node:http');
const fs = require('node:fs');
const path = require('node:path');
const assert = require('node:assert/strict');

const base = path.resolve('build');
const types = { '.html': 'text/html', '.js': 'text/javascript', '.wasm': 'application/wasm', '.pck': 'application/octet-stream', '.png': 'image/png' };
const server = http.createServer((req, res) => {
  const pathname = new URL(req.url, 'http://localhost').pathname;
  const file = path.join(base, pathname === '/' ? 'index.html' : pathname.slice(1));
  if (!file.startsWith(base + path.sep) || !fs.existsSync(file)) { res.writeHead(404); return res.end(); }
  res.setHeader('Content-Type', types[path.extname(file)] || 'application/octet-stream');
  fs.createReadStream(file).pipe(res);
});

(async () => {
  await new Promise(resolve => server.listen(0, '127.0.0.1', resolve));
  const browser = await chromium.launch({headless:true,args:['--use-gl=angle','--use-angle=swiftshader','--enable-unsafe-swiftshader']});
  try {
    const page = await browser.newPage({viewport:{width:932,height:430},deviceScaleFactor:2,isMobile:true,hasTouch:true});
    page.on('console', msg => { if (msg.type() === 'error') console.log('BROWSER:',msg.text()); });
    page.on('pageerror', err => console.log('BROWSER ERROR:',err.message));
    await page.goto(`http://127.0.0.1:${server.address().port}/?zmbtest=1`);
    await page.waitForFunction(() => window.zmbDiagnostics?.version === '0.1.3' && window.zmbDiagnostics.controls.START, {timeout:60000});
    const diag = () => page.evaluate(() => window.zmbDiagnostics);
    const initial = await diag();
    assert.equal(initial.ready,true,'Web touch queue failed to initialize');
    const canvas = await page.locator('canvas').boundingBox();
    function point(rect,x=0.5,y=0.5,id=1) {
      return {x:canvas.x+(rect[0]+(rect[2]-rect[0])*x)*canvas.width,y:canvas.y+(rect[1]+(rect[3]-rect[1])*y)*canvas.height,id};
    }
    const start = point(initial.controls.START);
    await page.touchscreen.tap(start.x,start.y);
    await page.waitForFunction(() => window.zmbDiagnostics.started);
    await page.waitForTimeout(350);
    const d = await diag();
    const joy = point(d.controls['◉'],0.5,0.15,1);
    const jump = point(d.controls.JUMP,0.5,0.5,2);
    const cdp = await page.context().newCDPSession(page);
    await cdp.send('Input.dispatchTouchEvent',{type:'touchStart',touchPoints:[joy]});
    await page.waitForFunction(() => window.zmbDiagnostics.stick[1] < -0.5 && window.zmbDiagnostics.velocity[2] < -1);
    console.log('Joystick moving:',await diag());
    await cdp.send('Input.dispatchTouchEvent',{type:'touchStart',touchPoints:[joy,jump]});
    await page.waitForFunction(() => {const d=window.zmbDiagnostics;return d.touches===2&&d.stick[1]<-0.5&&d.position[1]>0.1&&d.velocity[2]<-1;}, {timeout:5000});
    console.log('PASS: actual Godot Web build moves and jumps with two simultaneous browser touches');
    await cdp.send('Input.dispatchTouchEvent',{type:'touchEnd',touchPoints:[]});
    await page.waitForFunction(() => window.zmbDiagnostics.stick[0]===0&&window.zmbDiagnostics.stick[1]===0);
  } finally { await browser.close(); server.close(); }
})().catch(e=>{console.error(e);server.close();process.exitCode=1;});
