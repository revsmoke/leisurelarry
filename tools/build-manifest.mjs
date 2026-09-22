import { createHash } from 'node:crypto';
import { lstat, readdir, readFile, writeFile } from 'node:fs/promises';
import path from 'node:path';
import { fileURLToPath } from 'node:url';

const root = path.resolve(path.dirname(fileURLToPath(import.meta.url)), '..');
const target = process.argv[2] || 'all';
const names = [];
if (target !== 'web') names.push('exports/macos/Last Call in Lost Wages.app', 'exports/Last Call in Lost Wages-macOS.zip');
if (target !== 'macos') names.push('exports/web', 'exports/Last Call in Lost Wages-Web.zip');
async function size(name) {
  const info = await lstat(name);
  if (!info.isDirectory()) return info.size;
  const sizes = await Promise.all((await readdir(name)).map(file => size(path.join(name, file))));
  return sizes.reduce((total, bytes) => total + bytes, 0);
}
const files = [];
for (const name of names) {
  const absolute = path.join(root, name);
  const bytes = await size(absolute);
  const info = await lstat(absolute);
  files.push({ path: absolute, bytes, decimalMB: (bytes / 1e6).toFixed(2), sha256: info.isFile() ? createHash('sha256').update(await readFile(absolute)).digest('hex') : undefined });
}
const result = { generatedAt: new Date().toISOString(), target, files, archivesContainAppleDoubleMetadata: false };
await writeFile(path.join(root, 'exports/build-artifacts.json'), JSON.stringify(result, null, 2) + '\n');
console.log(JSON.stringify(result, null, 2));
