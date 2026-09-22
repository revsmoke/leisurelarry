import {createServer} from 'node:http';
import {createReadStream, existsSync} from 'node:fs';
import {mkdir, stat, appendFile, writeFile, rename,readFile} from 'node:fs/promises';
import {randomUUID,createHash} from 'node:crypto';
import {gzipSync} from 'node:zlib';
import path from 'node:path';
import {fileURLToPath} from 'node:url';
import {buildRequest, evaluate, PERSONAS,MODEL} from './client.mjs';
import {DEFAULTS,validateConfig,Budget,orderCandidates} from './runner.mjs';
const root = path.resolve(path.dirname(fileURLToPath(import.meta.url)), '../..');
export const ORIGIN='http://127.0.0.1:8767';
export async function createLab({apiKey,output,origin=ORIGIN,evaluateFn=evaluate,buildId='test-fixture',runnerId='test-fixture'}={}) {
  if(!apiKey)throw Error('Set TYPESAFE_API_KEY in the local .env file');
  const token=randomUUID();const session=path.basename(output);await mkdir(output,{recursive:true});
  let batch=null;let persistQueue=Promise.resolve();
  const json=(res,status,data)=>{res.writeHead(status,{'Content-Type':'application/json','Cache-Control':'no-store'});res.end(JSON.stringify(data));};
  async function body(req){let text='';for await(const chunk of req){text+=chunk;if(text.length>500000)throw Error('Request too large');}return JSON.parse(text);}
  async function trace(run,event){await appendFile(path.join(output,batch.id,run.id+'.jsonl.gz'),gzipSync(JSON.stringify({at:new Date().toISOString(),...event})+'\n'));}
  function snapshot(){if(!batch)return {session,buildId,runnerId,batch:null};const values=[...batch.latencies].sort((a,b)=>a-b);return {session,buildId,runnerId,generatedAt:new Date().toISOString(),batchId:batch.id,config:batch.config,modelRequested:MODEL,budget:batch.budget.snapshot(),apiLatencyMs:{p50:values[Math.floor(values.length*.5)]??null,p95:values[Math.floor(values.length*.95)]??null},serverMemory:{peakRssBytes:batch.peakRssBytes,currentRssBytes:process.memoryUsage().rss},budgetNotes:{requests:'Hard attempts cap, reserved before dispatch. No automatic retry.',usage:'Input and estimated cost are observed thresholds. Concurrent or timed-out requests may exceed them; unknown usage is not free. Not a provider-enforced dollar cap.',latency:'API includes network. UI acknowledgement includes rendered frames. Server RSS excludes browser/Godot workers.'},priceSource:'https://docs.typesafe.ai/models',estimatedInputCostUSD:batch.budget.snapshot().estimatedInputCostUSD,runs:Object.fromEntries([...batch.runs].map(([id,r])=>[id,{...r,controller:undefined,inFlight:undefined}]))};}
  function persist(){const value=JSON.stringify(snapshot(),null,2)+'\n';const directory=path.join(output,batch.id);persistQueue=persistQueue.catch(()=>{}).then(async()=>{const tmp=path.join(directory,'summary.json.tmp');await writeFile(tmp,value);await rename(tmp,path.join(directory,'summary.json'));await writeFile(path.join(output,'latest.json'),JSON.stringify({batchId:batch.id,directory:path.relative(root,directory)},null,2));});return persistQueue;}
  const server=createServer(async(req,res)=>{
    if(req.headers.host!==new URL(origin).host)return json(res,403,{error:'Loopback host required'});
    const pathname=new URL(req.url,origin).pathname;
    try{
      if(req.method==='GET'&&pathname==='/config')return json(res,200,{token,session,buildId,runnerId,profiles:Object.keys(PERSONAS),defaults:DEFAULTS});
      if(req.method==='GET'&&pathname==='/status')return json(res,200,snapshot());
      if(req.method==='POST'){
        if(req.headers.origin!==origin||req.headers['x-qa-token']!==token)return json(res,403,{error:'Local test-page authorization required'});
        const data=await body(req);
        if(pathname==='/batch'){
          if(batch&&([...batch.runs.values()].some(r=>r.status!=='finished')||batch.budget.active))return json(res,409,{error:'Finish or stop the current batch first'});
          const config=validateConfig(data);const id=randomUUID();const budget=new Budget(config);const runs=new Map();const profiles=Object.keys(PERSONAS);
          for(let i=0;i<config.runCount;i++){const persona=profiles[i%profiles.length];const runId=`${id}-${String(i+1).padStart(3,'0')}-${persona}`;runs.set(runId,{id:runId,persona,index:i,status:'queued',decisions:0,steps:0,score:0});}
          batch={id,config,budget,runs,latencies:[],peakRssBytes:process.memoryUsage().rss};await mkdir(path.join(output,id));await persist();return json(res,200,{batchId:id,config,runs:[...runs.values()]});
        }
        if(!batch)return json(res,409,{error:'Create a batch first'});
        if(pathname==='/stop'){
          batch.budget.cancelled=true;
          for(const run of batch.runs.values()){if(run.controller)run.controller.abort();if(run.status==='queued')Object.assign(run,{status:'finished',reason:'cancelled_before_start',completed:false});}
          await persist();return json(res,200,{stopped:true});
        }
        const run=batch.runs.get(data.runId);if(!run)return json(res,400,{error:'Unknown run'});
        if(pathname==='/result'){
          if(!['running','finished'].includes(data.status))return json(res,400,{error:'Invalid run status'});
          if(run.status==='finished')return json(res,409,{error:'Run already finished'});
          const {runId,...outcome}=data;
          for(const key of ['status','reason','steps','score','money','room','completed','elapsedMs','errors','cycle','coldLoadMs','visibility','actionTimesMs'])if(Object.hasOwn(outcome,key))run[key]=outcome[key];
          await trace(run,{type:'outcome',...data});await persist();return json(res,200,{saved:true});
        }
        if(pathname!=='/decide')return json(res,404,{error:'Not found'});
        if(data.persona!==run.persona||data.step!==run.decisions||run.status==='finished'||run.inFlight)return json(res,409,{error:'Invalid or duplicate run step'});
        if(run.decisions>=batch.config.maxSteps)return json(res,429,{error:'action_budget'});
        const observation={...data.observation,actions:orderCandidates(data.observation.actions,batch.config.seed+run.index*1009+data.step)};
        const request=buildRequest({...data,observation,memory:batch.config.memoryEnabled?data.memory:undefined});
        let settle;try{settle=batch.budget.reserve();}catch(error){return json(res,429,{error:error.message});}
        run.inFlight=true;run.status='running';run.decisions++;run.controller=new AbortController();
        try{
          const answer=await evaluateFn(request,{apiKey,signal:run.controller.signal});settle(answer.result.usage);settle=null;
          batch.latencies.push(answer.apiMs);batch.peakRssBytes=Math.max(batch.peakRssBytes,process.memoryUsage().rss);
          await trace(run,{type:'decision',runId:run.id,step:data.step,revision:data.observation.revision,request,...answer});run.model=answer.result.model;
          json(res,200,answer);
        }catch(error){
          if(settle){settle();settle=null;}
          const message=String(error.message).replaceAll(apiKey,'[redacted]');await trace(run,{type:'api_error',runId:run.id,step:data.step,request,message,usageUnknown:true});json(res,502,{error:message});
        }finally{run.inFlight=false;run.controller=null;await persist();}return;
      }
      if(!['GET','HEAD'].includes(req.method))return json(res,405,{error:'Method not allowed'});
      const base=pathname.startsWith('/game/')?path.join(root,'exports/qa'):path.join(root,'tools/jev-qa');
      const relative=pathname.startsWith('/game/')?pathname.slice(6):pathname==='/'?'index.html':pathname.slice(1);
      if(!pathname.startsWith('/game/')&&!['index.html','dashboard.js','runner.mjs'].includes(relative))return json(res,404,{error:'Not found'});
      const filename=path.resolve(base,decodeURIComponent(relative));if(!filename.startsWith(base+path.sep))return json(res,403,{error:'Outside test directory'});
      const info=await stat(filename);if(!info.isFile())throw Error('Not a file');
      const types={'.html':'text/html; charset=utf-8','.js':'application/javascript','.mjs':'application/javascript','.wasm':'application/wasm','.pck':'application/octet-stream','.png':'image/png','.svg':'image/svg+xml','.ico':'image/x-icon'};
      res.writeHead(200,{'Content-Type':types[path.extname(filename)]||'application/octet-stream','Content-Length':info.size,'Cache-Control':'no-store'});if(req.method==='HEAD')return res.end();const stream=createReadStream(filename);stream.on('error',()=>res.destroy());stream.pipe(res);
    }catch(error){if(!res.headersSent)json(res,400,{error:'Invalid request or missing QA export'});else res.end();}
  });
  return {server,token,snapshot,finished:()=>persistQueue};
}
if(process.argv[1]&&path.resolve(process.argv[1])===fileURLToPath(import.meta.url)){
  if(existsSync(path.join(root,'.env')))process.loadEnvFile(path.join(root,'.env'));
  const session=new Date().toISOString().replaceAll(':','-').replaceAll('.','-');const output=path.join(root,'docs/experiments/jev',session);
  const pack=path.join(root,'exports/qa/index.pck');const buildId=existsSync(pack)?createHash('sha256').update(await readFile(pack)).digest('hex'):'missing-qa-export';
  const runnerFiles=['client.mjs','runner.mjs','dashboard.js','server.mjs'];const runnerId=createHash('sha256').update((await Promise.all(runnerFiles.map(file=>readFile(path.join(root,'tools/jev-qa',file),'utf8')))).join('\n')).digest('hex');
  const {server}=await createLab({apiKey:process.env.TYPESAFE_API_KEY,output,buildId,runnerId});server.listen(8767,'127.0.0.1',()=>console.log(`Jev playtest dashboard: ${ORIGIN}\nEvidence: ${path.relative(root,output)}\nConfigure workers, runs and budgets in the dashboard. No requests until Start. Key stays server-side.`));
}
