// Pure policies shared by the browser dashboard, server and deterministic tests.
export const DEFAULTS = Object.freeze({workers:2,runCount:2,maxSteps:160,maxRequests:1000,maxInputTokens:12000000,maxCostUSD:0.60,memoryEnabled:true,seed:1});
export const INPUT_PRICE = 0.042 / 1e6;
export function validateConfig(value={}) {
  const c=Object.fromEntries(Object.entries(DEFAULTS).map(([key,fallback])=>[key,Object.hasOwn(value,key)?value[key]:fallback]));
  if(![2,4,8].includes(c.workers))throw Error('Choose 2, 4 or 8 workers');
  for(const [k,min,max] of [['runCount',1,100],['maxSteps',1,200],['maxRequests',1,20000],['maxInputTokens',1000,200000000],['seed',0,2147483647]]) if(!Number.isSafeInteger(c[k])||c[k]<min||c[k]>max)throw Error(`Invalid ${k}`);
  if(!Number.isFinite(c.maxCostUSD)||c.maxCostUSD<=0||c.maxCostUSD>10)throw Error('Cost threshold must be above $0 and at most $10');
  if(typeof c.memoryEnabled!=='boolean')throw Error('Invalid memory setting');
  return c;
}
export class Budget {
  constructor(config){this.config=validateConfig(config);this.requests=0;this.inputTokens=0;this.outputTokens=0;this.active=0;this.errors=0;this.cancelled=false;}
  reserve(){
    if(this.cancelled)throw Error('batch_cancelled');
    if(this.requests>=this.config.maxRequests)throw Error('request_budget');
    if(this.inputTokens>=this.config.maxInputTokens)throw Error('input_token_threshold');
    if(this.inputTokens*INPUT_PRICE>=this.config.maxCostUSD)throw Error('estimated_cost_threshold');
    if(this.active>=this.config.workers)throw Error('concurrency_limit');
    this.requests++;this.active++;
    let settled=false;
    return (usage)=>{if(settled)throw Error('Request settled twice');settled=true;this.active--;if(usage){this.inputTokens+=usage.input_tokens;this.outputTokens+=usage.output_tokens;}else this.errors++;};
  }
  snapshot(){return {maxRequests:this.config.maxRequests,maxInputTokens:this.config.maxInputTokens,maxCostUSD:this.config.maxCostUSD,maxConcurrent:this.config.workers,requests:this.requests,inputTokens:this.inputTokens,outputTokens:this.outputTokens,active:this.active,errors:this.errors,cancelled:this.cancelled,estimatedInputCostUSD:this.inputTokens*INPUT_PRICE};}
}
export async function runPool(count,workers,task,shouldStop=()=>false){
  let next=0,failed=false;const results=[];
  const workersDone=await Promise.allSettled(Array.from({length:Math.min(workers,count)},async(_,worker)=>{while(!failed&&!shouldStop()){const index=next++;if(index>=count)return;try{results[index]=await task(index,worker);}catch(error){failed=true;throw error;}}}));
  const failure=workersDone.find(result=>result.status==='rejected');if(failure)throw failure.reason;
  return results;
}
export function remember(memory,observation){
  const key=observation.room.id;const old=memory[key]??{dialogue:[],hotspots:[]};
  const line=typeof observation.dialogue==='string'?observation.dialogue:observation.dialogue?.text;
  memory[key]={room:observation.room.title,hotspots:[...new Set([...old.hotspots,...(observation.hotspots??[]).map(h=>h.name)])],currentHotspots:(observation.hotspots??[]).map(h=>h.name),dialogue:line?[...old.dialogue.filter(d=>d!==line),line].slice(-8):old.dialogue};
  return memory;
}
// Novel discoveries, not room travel or changing wallet values, reset a stall.
export class ProgressTracker {
  constructor(){this.seen=new Set();this.highScore=-1;this.noProgress=0;this.sequence=[];}
  update(o,action='initial'){
    const facts=[...(o.inventory??[]).map(x=>'item:'+x),...(o.notebook??[]).map(x=>'clue:'+x),...(o.hotspots??[]).map(x=>`object:${o.room.id}:${x.name}`),...(o.dialogueOptions??[]).map(x=>`topic:${o.room.id}:${x}`)];
    let progress=o.score>this.highScore;this.highScore=Math.max(this.highScore,o.score??0);
    for(const fact of facts){if(!this.seen.has(fact)){this.seen.add(fact);progress=true;}}
    if(progress){this.noProgress=0;this.sequence=[];}else this.noProgress++;
    const signature=JSON.stringify([o.room.id,o.score,[...(o.inventory??[])].sort(),o.notebook??[],o.overlay??[],action]);
    this.sequence.push(signature);this.sequence=this.sequence.slice(-24);
    let period=0;
    if(!progress)for(let width=1;width<=6;width++){
      if(this.sequence.length<width*3)continue;
      const tail=this.sequence.slice(-width).join('|');
      if(tail===this.sequence.slice(-width*2,-width).join('|')&&tail===this.sequence.slice(-width*3,-width*2).join('|')){period=width;break;}
    }
    return {progress,noProgress:this.noProgress,cyclePeriod:period,stop:period>0||this.noProgress>=24,reason:period?'repeated_action_cycle':this.noProgress>=24?'no_observed_progress':null};
  }
}
export function orderCandidates(actions,seed){
  const result=actions.map(x=>({...x}));let state=(seed>>>0)||1;
  for(let i=result.length-1;i>0;i--){state^=state<<13;state^=state>>>17;state^=state<<5;const j=(state>>>0)%(i+1);[result[i],result[j]]=[result[j],result[i]];}return result;
}
export function acceptsMessage(event,origin,source,pendingId){return event.origin===origin&&event.source===source&&['larry-qa-ready','larry-qa-observation'].includes(event.data?.type)&&(event.data.type==='larry-qa-ready'||event.data.requestId===pendingId);}
// Completed worker iframes keep rendering until removed. Retire every previous
// slot before starting a new batch, including slots above the new worker count.
export function disposeWorkers(players){
  const previous=[...players.values()];players.clear();
  for(const player of previous){
    for(const key of ['ready','pending'])if(player[key]){clearTimeout(player[key].timer);player[key].reject(Error('Worker retired before new batch'));player[key]=null;}
    player.frame.src='about:blank';
    player.frame.remove();
    player.card.remove();
  }
  return previous.length;
}
