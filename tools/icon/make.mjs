// Gera os ícones do app (img/app/*.png) a partir de tools/icon/icon.html com o Chrome headless + sips.
import { execFileSync } from 'node:child_process';
import { mkdtempSync, rmSync } from 'node:fs';
import { tmpdir } from 'node:os';
import { join, resolve } from 'node:path';
const root = resolve(new URL('../..', import.meta.url).pathname);
const prof = mkdtempSync(join(tmpdir(), 'icon-chrome-'));
const big = join(root, 'img/app/icon-1024.png');
execFileSync('/Applications/Google Chrome.app/Contents/MacOS/Google Chrome', [
  '--headless=new', `--user-data-dir=${prof}`, '--hide-scrollbars', '--window-size=1024,1024',
  '--default-background-color=00000000', `--screenshot=${big}`, 'file://' + join(root, 'tools/icon/icon.html'),
], { stdio: 'ignore' });
rmSync(prof, { recursive: true, force: true });
for (const [s, name] of [[512, 'icon-512.png'], [192, 'icon-192.png'], [180, 'apple-touch-icon.png']])
  execFileSync('sips', ['-z', String(s), String(s), big, '--out', join(root, 'img/app', name)], { stdio: 'ignore' });
rmSync(big);
console.log('ok');
