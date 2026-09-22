import assert from 'node:assert/strict';
import { execFileSync, spawnSync } from 'node:child_process';
import { writeFile } from 'node:fs/promises';
import path from 'node:path';
import { fileURLToPath } from 'node:url';

const root = path.resolve(path.dirname(fileURLToPath(import.meta.url)), '..');
const app = path.join(root, 'exports/macos/Last Call in Lost Wages.app');
execFileSync('/usr/bin/codesign', ['--verify', '--deep', '--strict', app]);
const executable = execFileSync('/usr/libexec/PlistBuddy', ['-c', 'Print :CFBundleExecutable', path.join(app, 'Contents/Info.plist')], { encoding: 'utf8' }).trim();
const run = spawnSync(path.join(app, 'Contents/MacOS', executable), ['--headless', '--quit-after', '30'], { encoding: 'utf8', timeout: 30000 });
if (run.error) throw run.error;
const output = `${run.stdout}\n${run.stderr}`;
assert.equal(run.status, 0, output);
assert.ok(!/(?:^|\n)(?:SCRIPT ERROR|ERROR):/.test(output), output);
const report = { passed: true, exportedApp: path.relative(root, app), signatureValid: true, frames: 30, exitCode: run.status, output: output.trim() };
await writeFile(path.join(root, 'exports/native-smoke-result.json'), JSON.stringify(report, null, 2) + '\n');
console.log(JSON.stringify(report, null, 2));
