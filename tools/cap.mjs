// Renderiza um item do estúdio 3D em PNG com fundo transparente (Chrome headless, sem dependências).
// uso: node tools/cap.mjs <item> <saida.png> [tamanho=1200]   (servidor do estúdio em http://localhost:8804)
import { spawn } from 'node:child_process';
import { mkdtempSync, rmSync, writeFileSync } from 'node:fs';
import { tmpdir } from 'node:os';
import { join } from 'node:path';
const [item, out, S = '1200'] = process.argv.slice(2);
const port = 9300 + Math.floor(Math.random() * 600);
const prof = mkdtempSync(join(tmpdir(), 'cap-chrome-'));
const chrome = spawn('/Applications/Google Chrome.app/Contents/MacOS/Google Chrome', [
  '--headless=new', `--remote-debugging-port=${port}`, `--user-data-dir=${prof}`, `--window-size=${S},${S}`,
  '--use-angle=metal', '--enable-gpu', '--ignore-gpu-blocklist', '--hide-scrollbars', 'about:blank',
], { stdio: 'ignore' });
const sleep = (ms) => new Promise((r) => setTimeout(r, ms));
let ws, id = 0; const pending = new Map();
const send = (method, params = {}) => new Promise((res) => { const i = ++id; pending.set(i, res); ws.send(JSON.stringify({ id: i, method, params })); });
const ev = async (expr) => (await send('Runtime.evaluate', { expression: expr, returnByValue: true, awaitPromise: true }))?.result?.value;
try {
  let target;
  for (let k = 0; k < 50 && !target; k++) { await sleep(200); try { target = (await (await fetch(`http://127.0.0.1:${port}/json`)).json()).find((t) => t.type === 'page'); } catch {} }
  ws = new WebSocket(target.webSocketDebuggerUrl); await new Promise((r) => (ws.onopen = r));
  const logs = [];
  ws.onmessage = (m) => { const d = JSON.parse(m.data); if (d.id && pending.has(d.id)) { pending.get(d.id)(d.result); pending.delete(d.id); }
    if (d.method === 'Runtime.exceptionThrown') logs.push('EXC ' + JSON.stringify(d.params.exceptionDetails).slice(0, 500));
    if (d.method === 'Runtime.consoleAPICalled' && d.params.type === 'error') logs.push('ERR ' + d.params.args.map(a => a.value ?? a.description).join(' ').slice(0, 500)); };
  await send('Runtime.enable'); await send('Page.enable');
  await send('Emulation.setDeviceMetricsOverride', { width: +S, height: +S, deviceScaleFactor: 1, mobile: false });
  await send('Emulation.setDefaultBackgroundColorOverride', { color: { r: 0, g: 0, b: 0, a: 0 } });
  await send('Page.navigate', { url: `http://localhost:8804/studio.html?item=${item}&s=${S}` });
  for (let k = 0; k < 120 && !(await ev('!!window.__done')); k++) await sleep(500);
  const err = await ev('window.__err||""'); if (err) console.log('STUDIO ERROR', err);
  const png = await ev('window.__png||""');
  if (png) { writeFileSync(out, Buffer.from(png.split(',')[1], 'base64')); console.log(`saved ${out}`); }
  if (logs.length) console.log(logs.join('\n'));
} catch (e) { console.error('cap failed', e); }
finally { chrome.kill('SIGKILL'); await sleep(300); rmSync(prof, { recursive: true, force: true }); process.exit(0); }
