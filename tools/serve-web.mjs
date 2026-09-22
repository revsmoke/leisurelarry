import { createServer } from 'node:http';
import { createReadStream } from 'node:fs';
import { stat } from 'node:fs/promises';
import path from 'node:path';
import { fileURLToPath } from 'node:url';

const webRoot = path.resolve(path.dirname(fileURLToPath(import.meta.url)), '../exports/web');
const port = Number(process.argv[2] || 8766);
if (!Number.isInteger(port) || port < 1024 || port > 65535) throw new Error('Choose a port between 1024 and 65535.');
const types = { '.html': 'text/html; charset=utf-8', '.js': 'application/javascript', '.wasm': 'application/wasm', '.json': 'application/json', '.css': 'text/css', '.svg': 'image/svg+xml', '.png': 'image/png', '.ico': 'image/x-icon', '.pck': 'application/octet-stream' };
createServer(async (request, response) => {
  if (!['GET', 'HEAD'].includes(request.method)) { response.writeHead(405); response.end(); return; }
  let filename;
  try {
    const pathname = decodeURIComponent(new URL(request.url, 'http://localhost').pathname);
    filename = path.resolve(webRoot, `.${pathname === '/' ? '/index.html' : pathname}`);
    if (!filename.startsWith(webRoot + path.sep)) throw new Error('Outside export directory');
    const info = await stat(filename);
    if (!info.isFile()) throw new Error('Not a file');
    response.writeHead(200, { 'Content-Type': types[path.extname(filename)] || 'application/octet-stream', 'Content-Length': info.size, 'Cache-Control': 'no-store' });
  } catch {
    response.writeHead(404, { 'Content-Type': 'text/plain' }); response.end('Export file not found. Run tools/package.sh web first.'); return;
  }
  if (request.method === 'HEAD') { response.end(); return; }
  const stream = createReadStream(filename);
  stream.on('error', () => response.destroy());
  stream.pipe(response);
}).listen(port, '127.0.0.1', () => console.log(`Last Call web build: http://127.0.0.1:${port}`));
