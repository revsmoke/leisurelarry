import assert from 'node:assert/strict';
import { mkdtemp, readFile, writeFile, rm, mkdir } from 'node:fs/promises';
import path from 'node:path';
import { fileURLToPath } from 'node:url';
import { Client } from './godot-mcp/node_modules/@modelcontextprotocol/sdk/dist/esm/client/index.js';
import { StdioClientTransport } from './godot-mcp/node_modules/@modelcontextprotocol/sdk/dist/esm/client/stdio.js';

const toolsDir = path.dirname(fileURLToPath(import.meta.url));
await mkdir(path.join(toolsDir, 'cache'), { recursive: true });
const fixture = await mkdtemp(path.join(toolsDir, 'cache/mcp-smoke-'));
await writeFile(path.join(fixture, 'project.godot'), `config_version=5\n[application]\nconfig/name="MCP Smoke Fixture"\n[rendering]\nrenderer/rendering_method="gl_compatibility"\n`);
const transport = new StdioClientTransport({
  command: process.execPath,
  args: [path.join(toolsDir, 'godot-mcp/build/index.js')],
  env: { ...process.env, GODOT_PATH: process.env.GODOT_PATH || '/Applications/Godot.app/Contents/MacOS/Godot', DEBUG: 'false', GODOT_DEBUG: 'false' },
  stderr: 'pipe',
});
const client = new Client({ name: 'leisuresuitlarry-tooling-smoke', version: '1.0.0' });
const outcomes = [];
try {
  await client.connect(transport);
  const { tools } = await client.listTools();
  assert.equal(tools.length, 14);
  outcomes.push({ check: 'MCP initialize + tools/list', passed: true, toolCount: tools.length });
  async function call(name, args = {}) {
    const result = await client.callTool({ name, arguments: args });
    assert.ok(!result.isError, `${name}: ${JSON.stringify(result)}`);
    const text = result.content.filter(part => part.type === 'text').map(part => part.text).join('\n');
    outcomes.push({ check: name, passed: true });
    return text;
  }
  const version = await call('get_godot_version');
  assert.match(version, /4\.7\.2/);
  outcomes.at(-1).version = version.trim();
  const projects = JSON.parse(await call('list_projects', { directory: fixture, recursive: false }));
  assert.ok(projects.some(project => project.path === fixture));
  const info = JSON.parse(await call('get_project_info', { projectPath: fixture }));
  assert.equal(info.name, 'MCP Smoke Fixture');
  await call('create_scene', { projectPath: fixture, scenePath: 'smoke.tscn', rootNodeType: 'Node2D' });
  assert.match(await readFile(path.join(fixture, 'smoke.tscn'), 'utf8'), /type="Node2D"/);
  await call('add_node', { projectPath: fixture, scenePath: 'smoke.tscn', nodeType: 'Label', nodeName: 'SmokeLabel', properties: { text: 'MCP verified' } });
  assert.match(await readFile(path.join(fixture, 'smoke.tscn'), 'utf8'), /MCP verified/);
  console.log(JSON.stringify({ passed: true, checks: outcomes }, null, 2));
} finally {
  await client.close();
  await rm(fixture, { recursive: true, force: true });
}
