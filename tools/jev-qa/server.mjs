import {createServer} from 'node:http';
import {createReadStream, existsSync} from 'node:fs';
import {mkdir, stat, appendFile, writeFile, rename} from 'node:fs/promises';
import {randomUUID} from 'node:crypto';
import path from 'node:path';
import {fileURLToPath} from 'node:url';
import {buildRequest, evaluate, PERSONAS} from './client.mjs';

const root = path.resolve(path.dirname(fileURLToPath(import.meta.url)), '../..');
if (existsSync(path.join(root, '.env'))) process.loadEnvFile(path.join(root, '.env'));
const apiKey = process.env.TYPESAFE_API_KEY;
if (!apiKey) throw Error('Set TYPESAFE_API_KEY in the local .env file');
const origin = 'http://127.0.0.1:8767';
const token = randomUUID();
const memoryEnabled = process.env.JEV_QA_MEMORY === '1';
const session = new Date().toISOString().replaceAll(':', '-').replaceAll('.', '-');
const output = path.join(root, 'docs/experiments/jev', session);
await mkdir(output, {recursive: true});
const budget = {maxRequests: 300, maxInputTokens: 2000000, maxConcurrent: 3, requests: 0, inputTokens: 0, outputTokens: 0, active: 0, errors: 0};
const runs = {};
const latencies = [];
let persistQueue = Promise.resolve();
const json = (res, status, data) => {res.writeHead(status, {'Content-Type': 'application/json', 'Cache-Control': 'no-store'});res.end(JSON.stringify(data));};
async function body(req) {
  let text = ''; for await (const chunk of req) {text += chunk; if (text.length > 250000) throw Error('Request too large');}
  return JSON.parse(text);
}
function persist() {
  const ordered = [...latencies].sort((a,b)=>a-b);
  // Snapshot at enqueue time; serialize writes so concurrent players cannot
  // truncate each other's summaries. Rename publishes each complete JSON file.
  const snapshot = JSON.stringify({session, generatedAt: new Date().toISOString(), modelRequested: 'jev-latest', budget, budgetNotes: {requests: 'Hard per-server request-count limit; concurrent attempts count before dispatch.', inputTokens: 'Observed usage threshold, not a hard token or spending cap. Requests already in flight can exceed it.', uncertainty: 'Timeouts and invalid or missing provider responses may incur usage that is absent from these totals and the estimated cost.'}, apiLatencyMs: {p50: ordered[Math.floor(ordered.length*.5)] ?? null, p95: ordered[Math.floor(ordered.length*.95)] ?? null}, estimatedInputCostUSD: budget.inputTokens * .042 / 1e6, priceSource: 'https://docs.typesafe.ai/models', runs}, null, 2)+'\n';
  const pending = persistQueue.catch(() => {}).then(async () => {
    const temporary = path.join(output, 'summary.json.tmp');
    await writeFile(temporary, snapshot);
    await rename(temporary, path.join(output, 'summary.json'));
  });
  persistQueue = pending;
  return pending;
}
const server = createServer(async (req, res) => {
  if (req.headers.host !== '127.0.0.1:8767') return json(res, 403, {error: 'Loopback host required'});
  const pathname = new URL(req.url, origin).pathname;
  try {
    if (req.method === 'GET' && pathname === '/config') return json(res, 200, {token, session, memoryEnabled, profiles: Object.keys(PERSONAS), maxSteps: 80, budget});
    if (req.method === 'GET' && pathname === '/status') return json(res, 200, {session, budget, runs});
    if (req.method === 'POST') {
      if (req.headers.origin !== origin || req.headers['x-qa-token'] !== token) return json(res, 403, {error: 'Local test-page authorization required'});
      const data = await body(req);
      if (pathname === '/result') {
        if (!Object.hasOwn(PERSONAS, data.runId)) return json(res, 400, {error:'Unknown run'});
        runs[data.runId] = {...runs[data.runId], ...data};
        await appendFile(path.join(output, 'events.jsonl'), JSON.stringify({at:new Date().toISOString(),type:'result',...data})+'\n');
        await persist(); return json(res, 200, {saved:true});
      }
      if (pathname !== '/decide') return json(res, 404, {error:'Not found'});
      if (!Object.hasOwn(PERSONAS, data.runId) || data.persona !== data.runId) return json(res,400,{error:'Unknown run'});
      if (budget.requests >= budget.maxRequests || budget.inputTokens >= budget.maxInputTokens || budget.active >= budget.maxConcurrent) return json(res,429,{error:'Experiment budget or concurrency limit reached'});
      const request = buildRequest({...data, memory: memoryEnabled ? data.memory : undefined});
      budget.requests++; budget.active++;
      try {
        const answer = await evaluate(request, {apiKey});
        budget.inputTokens += answer.result.usage.input_tokens || 0;
        budget.outputTokens += answer.result.usage.output_tokens || 0;
        latencies.push(answer.apiMs);
        const event = {at:new Date().toISOString(),runId:data.runId,step:data.step,revision:data.observation.revision,request,...answer};
        await appendFile(path.join(output, 'decisions.jsonl'), JSON.stringify(event)+'\n');
        runs[data.runId] = {...runs[data.runId], status:'running', step:data.step, score:data.observation.score, room:data.observation.room, model:answer.result.model};
        json(res,200,answer);
      } catch (error) {
        budget.errors++;
        // Error text contains status only, never request headers or the key.
        const message = String(error.message).replaceAll(apiKey, '[redacted]');
        await appendFile(path.join(output, 'events.jsonl'),JSON.stringify({at:new Date().toISOString(),type:'api_error',runId:data.runId,message})+'\n');
        json(res,502,{error:message});
      } finally {budget.active--;await persist();}
      return;
    }
    if (!['GET','HEAD'].includes(req.method)) return json(res,405,{error:'Method not allowed'});
    const base = pathname.startsWith('/game/') ? path.join(root,'exports/qa') : path.join(root,'tools/jev-qa');
    const relative = pathname.startsWith('/game/') ? pathname.slice(6) : pathname === '/' ? 'index.html' : pathname.slice(1);
    // Only the dashboard and QA export are served; .env and repository paths cannot be requested.
    if (!pathname.startsWith('/game/') && !['index.html','dashboard.js'].includes(relative)) return json(res,404,{error:'Not found'});
    const filename = path.resolve(base, decodeURIComponent(relative));
    if (!filename.startsWith(base+path.sep)) return json(res,403,{error:'Outside test directory'});
    const info = await stat(filename); if(!info.isFile()) throw Error('Not a file');
    const types={'.html':'text/html; charset=utf-8','.js':'application/javascript','.wasm':'application/wasm','.pck':'application/octet-stream','.png':'image/png','.svg':'image/svg+xml','.ico':'image/x-icon'};
    res.writeHead(200,{'Content-Type':types[path.extname(filename)]||'application/octet-stream','Content-Length':info.size,'Cache-Control':'no-store'});
    if(req.method==='HEAD')return res.end();
    const stream=createReadStream(filename);stream.on('error',()=>res.destroy());stream.pipe(res);
  } catch {if(!res.headersSent)json(res,400,{error:'Invalid request or missing QA export'});else res.end();}
});
server.listen(8767,'127.0.0.1',()=>console.log(`Jev playtest dashboard: ${origin}\nEvidence: ${path.relative(root,output)}\nLimits: 3 concurrent, 300 requests, 2M observed input tokens; key stays server-side.`));
