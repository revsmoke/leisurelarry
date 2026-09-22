import {readdir,readFile,writeFile} from 'node:fs/promises';
import path from 'node:path';
const root='docs/experiments/jev';
const quantile=(values,p)=>{const sorted=[...values].sort((a,b)=>a-b);return sorted[Math.floor((sorted.length-1)*p)]??null;};
const all=[];
for(const entry of (await readdir(root,{withFileTypes:true})).filter(e=>e.isDirectory()).sort((a,b)=>a.name.localeCompare(b.name))){
 const dir=path.join(root,entry.name);let summary;try{summary=JSON.parse(await readFile(path.join(dir,'summary.json'),'utf8'));}catch{continue;}
 const decisions=(await readFile(path.join(dir,'decisions.jsonl'),'utf8')).trim().split('\n').filter(Boolean).map(JSON.parse);
 const events=(await readFile(path.join(dir,'events.jsonl'),'utf8')).trim().split('\n').filter(Boolean).map(JSON.parse);
 const players={};for(const [id,run]of Object.entries(summary.runs)){
  const steps=events.filter(e=>e.runId===id&&e.status==='running');const qs=decisions.filter(d=>d.runId===id);
  const actions=steps.map(s=>s.lastAction);let noScoreStreak=0,maxNoScoreStreak=0,previous=0;
  for(const s of steps){noScoreStreak=s.score===previous?noScoreStreak+1:0;previous=s.score;maxNoScoreStreak=Math.max(maxNoScoreStreak,noScoreStreak);}
  const frequencies={};for(const label of actions)frequencies[label]=(frequencies[label]||0)+1;
  players[id]={score:run.score,completed:run.completed,steps:run.steps,reason:run.reason,errors:run.errors,rooms:[...new Set(steps.map(s=>s.room?.id))],uniqueActions:new Set(actions).size,maxConsecutiveActionsWithoutScore:maxNoScoreStreak,mostRepeated:Object.entries(frequencies).sort((a,b)=>b[1]-a[1]).slice(0,3),actionMs:{p50:quantile(steps.map(s=>s.actionMs),.5),p95:quantile(steps.map(s=>s.actionMs),.95)},sampledFps:{min:Math.min(...steps.map(s=>s.observation.diagnostics.fps)),p50:quantile(steps.map(s=>s.observation.diagnostics.fps),.5)},choiceConfidence:{p50:quantile(qs.map(d=>d.result.answers.next_action.confidence),.5)},averageClarity:qs.reduce((n,d)=>n+d.result.answers.clarity.score,0)/qs.length};
 }
 all.push({session:entry.name,memoryEnabled:decisions.some(d=>d.request.state.observed_memory),requests:summary.budget.requests,inputTokens:summary.budget.inputTokens,outputTokens:summary.budget.outputTokens,apiErrors:summary.budget.errors,models:[...new Set(decisions.map(d=>d.result.model))],apiLatencyMs:summary.apiLatencyMs,estimatedInputCostUSD:summary.estimatedInputCostUSD,players});
}
const calibration=JSON.parse(await readFile(path.join(root,'calibration.json'),'utf8'));
const inputs=all.reduce((n,r)=>n+r.inputTokens,0)+calibration.records.reduce((n,r)=>n+r.result.usage.input_tokens,0);
const result={generatedAt:new Date().toISOString(),runs:all,calibration:{requests:calibration.records.length,matched:calibration.records.filter(r=>r.matched).length},totals:{liveRequests:all.reduce((n,r)=>n+r.requests,0),requestsIncludingCalibration:all.reduce((n,r)=>n+r.requests,0)+calibration.records.length,inputTokens:inputs,estimatedInputCostUSD:inputs*.042/1e6},limits:'One run per policy/condition; no human subjects. Sampled FPS is not a frame-time benchmark. Max no-score streak can include useful non-scoring clues. Cost is estimated from published rate, not a billing receipt.'};
await writeFile(path.join(root,'comparison.json'),JSON.stringify(result,null,2)+'\n');console.log(JSON.stringify(result,null,2));
