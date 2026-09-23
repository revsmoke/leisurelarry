// PCK structure follows Godot 4.7.2 core/io/file_access_pack.cpp.
import assert from 'node:assert/strict';
import { createHash } from 'node:crypto';
import { readFile, readdir, writeFile } from 'node:fs/promises';
import path from 'node:path';
import { fileURLToPath } from 'node:url';

const root = path.resolve(path.dirname(fileURLToPath(import.meta.url)), '..');
const target = process.argv[2] || 'all';
assert.ok(['all', 'macos', 'web'].includes(target));
async function walk(directory) {
  const entries = await readdir(directory, { withFileTypes: true });
  const paths = await Promise.all(entries.map(entry => entry.isDirectory() ? walk(path.join(directory, entry.name)) : path.join(directory, entry.name)));
  return paths.flat();
}

function readPack(buffer) {
  assert.equal(buffer.toString('ascii', 0, 4), 'GDPC', 'Expected a standalone Godot pack');
  const version = buffer.readUInt32LE(4);
  assert.ok([2, 3, 4].includes(version), `Unsupported pack version ${version}`);
  const flags = buffer.readUInt32LE(20);
  assert.equal(flags & 1, 0, 'Pack directory is unexpectedly encrypted');
  let position = version === 2 ? 96 : Number(buffer.readBigUInt64LE(32));
  const count = buffer.readUInt32LE(position); position += 4;
  assert.ok(count > 0 && count < 10000, `Unexpected file count ${count}`);
  const files = [];
  for (let index = 0; index < count; index++) {
    const size = buffer.readUInt32LE(position); position += 4;
    assert.ok(size < 8192 && position + size + 36 <= buffer.length, 'Invalid pack directory');
    const name = buffer.toString('utf8', position, position + size).replace(/\0+$/, '');
    position += size;
    const bytes = Number(buffer.readBigUInt64LE(position + 8));
    position += 36;
    files.push({ path: name, bytes });
  }
  return { formatVersion: version, files };
}

const references = await readdir(path.join(root, 'reference/screenshots')).catch(() => []);
const referenceStems = references.filter(name => !name.startsWith('.')).map(name => path.parse(name).name);
const backgrounds = ['alley', 'backroom', 'balcony', 'bar', 'bathroom', 'casino', 'disco', 'garden', 'hotel', 'penthouse', 'rooftop', 'shop', 'street', 'garden-clean', 'penthouse-clean', 'backroom-clean', 'alley-clean', 'balcony-clean', 'balcony-open'];
const fonts = ['Outfit', 'SpaceGrotesk', 'NotoSansSymbols2'];
const fontLicenses = ['OFL.txt', 'SpaceGrotesk-OFL.txt', 'NotoSansSymbols2-OFL.txt'];
const packs = [];
if (target !== 'web') {
  packs.push(...(await walk(path.join(root, 'exports/macos'))).filter(name => name.endsWith('.pck')));
  assert.equal(packs.length, 1, 'Expected exactly one native game pack');
}
if (target !== 'macos') packs.push(path.join(root, 'exports/web/index.pck'));
const reports = [];
for (const file of packs) {
  const buffer = await readFile(file);
  const { files, formatVersion } = readPack(buffer);
  const names = files.map(entry => entry.path.replace(/^res:\/\//, ''));
  const forbidden = names.filter(name => /^(?:docs|reference|tools|tests|\.agents|\.codex|exports)\//.test(name)
    || /(?:^|\/)\.env(?:\.|$)/.test(name)
    || /softporn_adventure_walkthrought_snippet/.test(name)
    || /\.(?:py|mjs|sh|toml|md|gd)$/.test(name)
    || referenceStems.some(stem => name.includes(stem)));
  assert.deepEqual(forbidden, [], `Development/research/source files leaked into ${file}`);
  assert.ok(names.some(name => name === 'project.binary'), 'Missing project settings');
  assert.ok(names.some(name => /main\.(?:tscn|scn|tscn\.remap)$/.test(name)), 'Missing main scene');
  assert.ok(names.some(name => /last_call\.wav.*(?:sample|import)$/.test(name)), 'Missing music');
  assert.ok(names.some(name => /scripts\/main\.gd\.remap/.test(name)), 'Missing main script remap');
  assert.ok(names.includes('scripts/casino_panel.gdc'), 'Missing compiled casino panel');
  assert.ok(names.includes('scripts/travel_cutscene.gdc'), 'Missing compiled travel cutscenes');
  assert.ok(names.includes('scripts/encounter_cutscene.gdc'), 'Missing compiled encounter cutscenes');
  assert.ok(names.includes('scripts/hotspot_layout.gdc'), 'Missing compiled hotspot layout');
  assert.ok(names.includes('scripts/casino_panel.gd.remap'), 'Missing casino script remap');
  for (const background of backgrounds) {
    assert.ok(names.includes(`assets/backgrounds/${background}.png.import`), `Missing ${background} import`);
    assert.ok(names.some(name => name.startsWith(`.godot/imported/${background}.png-`) && name.endsWith('.ctex')), `Missing ${background} texture`);
  }
  for (const font of fonts) {
    assert.ok(names.includes(`assets/fonts/${font}.ttf.import`), `Missing ${font} import`);
    assert.ok(names.some(name => name.startsWith(`.godot/imported/${font}.ttf-`) && name.endsWith('.fontdata')), `Missing ${font} data`);
  }
  for (const license of fontLicenses) assert.ok(names.includes(`assets/fonts/${license}`), `Missing font license ${license}`);
  reports.push({
    file: path.relative(root, file), bytes: buffer.length,
    sha256: createHash('sha256').update(buffer).digest('hex'), formatVersion,
    fileCount: files.length, excludedResearchAndTooling: true,
    backgroundCount: backgrounds.length, fontCount: fonts.length,
    fontLicenses: fontLicenses.length, casinoCompiled: true, resources: files,
  });
}
const report = { verifiedAt: new Date().toISOString(), passed: true, target, packs: reports };
await writeFile(path.join(root, `exports/export-verification-${target}.json`), JSON.stringify(report, null, 2) + '\n');
console.log(JSON.stringify({ ...report, packs: reports.map(({ resources, ...summary }) => summary) }, null, 2));
