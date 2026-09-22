import {validateConfig,runPool,remember,ProgressTracker,acceptsMessage,disposeWorkers} from './runner.mjs';
const config=await fetch('/config').then(r=>r.json());
const profiles={goal:'Objective-led',curious:'Curious',unguided:'Without objectives'};
const players=new Map();let stopped=false,running=false,batch,finished=0;
const ui=(tag,text,cls)=>{const e=document.createElement(tag);if(text)e.textContent=text;if(cls)e.className=cls;return e;};
for(const [key,value] of Object.entries(config.defaults)){const input=document.querySelector(`[name="${key}"]`);if(input)input.type==='checkbox'?input.checked=value:input.value=value;}
async function post(route,data){const response=await fetch(route,{method:'POST',headers:{'Content-Type':'application/json','X-QA-Token':config.token},body:JSON.stringify(data),signal:AbortSignal.timeout(45000)});const result=await response.json();if(!response.ok)throw Error(result.error||`HTTP ${response.status}`);return result;}
function render(p){const o=p.observation;if(!o)return;p.scoreValue.textContent=`${o.score}/100`;p.stepsValue.textContent=p.step;p.current.textContent=typeof o.dialogue==='string'?o.dialogue:`${o.dialogue?.speaker||''}: ${o.dialogue?.text||''}`;p.view.textContent=JSON.stringify(o,null,2);}
window.addEventListener('message',event=>{
  const p=[...players.values()].find(p=>p.frame.contentWindow===event.source);if(!p||!acceptsMessage(event,location.origin,p.frame.contentWindow,p.pending?.id))return;
  const message=event.data;if(!message.observation)return;
  p.observation=message.observation;remember(p.memory,p.observation);render(p);
  if(message.type==='larry-qa-ready'&&p.ready){clearTimeout(p.ready.timer);p.ready.resolve();p.ready=null;p.status.textContent='Ready · isolated save state';}
  if(p.pending&&message.requestId===p.pending.id){clearTimeout(p.pending.timer);const {resolve,reject}=p.pending;p.pending=null;message.error?reject(Error(message.error)):resolve(message.observation);}
});
function makePlayer(run,worker){
  players.get(worker)?.card.remove();
  const card=ui('article',null,'card'),heading=ui('section');heading.append(ui('h2',`Worker ${worker+1} · ${profiles[run.persona]}`),ui('p',`Run ${run.index+1} of ${batch.config.runCount}`));const status=ui('div','Loading a fresh game…','status');heading.append(status);
  const frame=document.createElement('iframe');frame.title=`Run ${run.index+1}: ${profiles[run.persona]} Godot game`;frame.allow='autoplay';
  const content=ui('section'),metrics=ui('div',null,'metrics'),score=ui('div'),scoreValue=ui('strong','0/100'),steps=ui('div'),stepsValue=ui('strong','0');score.append(scoreValue,ui('span','score'));steps.append(stepsValue,ui('span','actions'));metrics.append(score,steps);
  const current=ui('p','Waiting for player-visible observations.'),log=ui('ol',null,'log'),detail=ui('details'),view=ui('pre');detail.append(ui('summary','Current observation'),view);content.append(metrics,current,log,detail);card.append(heading,frame,content);
  const p={...run,card,frame,status,scoreValue,stepsValue,current,log,view,observation:null,history:[],memory:{},step:0,pending:null,errors:0,timings:[],tracker:new ProgressTracker(),strategy:null};
  p.readyPromise=new Promise((resolve,reject)=>{p.ready={resolve,reject,timer:setTimeout(()=>{p.ready=null;reject(Error('Godot initial load exceeded 90 seconds'));},90000)};});
  // Register handlers before navigation or insertion: fast cached loads cannot race readiness.
  players.set(worker,p);frame.src=`/game/index.html?qa=1&instance=${run.id}`;document.querySelector('#players').append(card);return p;
}
function execute(p,action){return new Promise((resolve,reject)=>{const id=crypto.randomUUID();const timer=setTimeout(()=>{p.pending=null;reject(Error('Godot acknowledgement exceeded 20 seconds'));},20000);p.pending={id,resolve,reject,timer};p.frame.contentWindow.postMessage({type:'larry-qa-action',requestId:id,revision:p.observation.revision,action},location.origin);});}
async function stop(){stopped=true;document.querySelector('#stop').disabled=true;await post('/stop',{});for(const p of players.values()){if(p.ready){clearTimeout(p.ready.timer);p.ready.reject(Error('batch_cancelled'));p.ready=null;}if(p.pending){clearTimeout(p.pending.timer);p.pending.reject(Error('batch_cancelled'));p.pending=null;}}}
async function run(runInfo,worker){const started=performance.now();const p=makePlayer(runInfo,worker);let reason='action_budget',cycle=null,coldLoadMs=null;
  try{
    await p.readyPromise;coldLoadMs=Math.round(performance.now()-started);p.tracker.update(p.observation);
    while(p.step<batch.config.maxSteps&&!stopped){
      if(p.observation.completed){reason='completed';break;}if(p.observation.error)throw Error(p.observation.error);
      p.status.textContent='Jev is choosing…';const before=p.observation;const decisionStarted=performance.now();
      const decision=await post('/decide',{runId:p.id,persona:p.persona,observation:before,history:p.history,memory:batch.config.memoryEnabled?p.memory:undefined,strategy:p.strategy,step:p.step});
      const decisionRoundTripMs=Math.round(performance.now()-decisionStarted);
      if(stopped){reason='user_stopped';break;}
      const answer=decision.result.answers.next_action;p.strategy=decision.result.answers.strategy;
      if(['abstain','decline'].includes(answer.choice)){reason='model_abstained';break;}
      const candidate=before.actions.find(a=>a.id===answer.choice);if(!candidate)throw Error('Action no longer available');
      p.status.textContent=`${candidate.label} · ${decision.apiMs} ms API`;const actionStart=performance.now();const after=await execute(p,answer.choice);p.timings.push(Math.round(performance.now()-actionStart));p.step++;
      cycle=p.tracker.update(after,candidate.label);p.history.push({action:candidate.label,room:after.room,dialogue:after.dialogue,score:after.score,objective:after.objective});
      p.log.prepend(ui('li',`${p.step}. ${candidate.label} → ${after.score}/100 (confidence ${Number(answer.confidence).toFixed(2)})`));while(p.log.children.length>30)p.log.lastChild.remove();render(p);
      await post('/result',{runId:p.id,status:'running',steps:p.step,score:after.score,room:after.room,money:after.money,completed:after.completed,observation:after,lastAction:candidate.label,apiMs:decision.apiMs,decisionRoundTripMs,actionMs:p.timings.at(-1),clarity:decision.result.answers.clarity,contradiction:decision.result.answers.contradiction,strategy:p.strategy,cycle,visibility:document.visibilityState});
      if(cycle.stop){reason=cycle.reason;break;}
    }
  }catch(error){p.errors++;reason=stopped?'user_stopped':'error';p.current.textContent=error.message;p.status.classList.add('error');if(/budget|threshold|concurrency_limit/.test(error.message)){reason=error.message;await stop();}}
  if(stopped&&reason==='action_budget')reason='user_stopped';if(p.observation?.completed)reason='completed';
  p.status.textContent=`Finished · ${reason.replaceAll('_',' ')}`;
  // A queued run stopped while loading is already terminal on the server.
  try{await post('/result',{runId:p.id,status:'finished',reason,steps:p.step,score:p.observation?.score,money:p.observation?.money,room:p.observation?.room,completed:!!p.observation?.completed,elapsedMs:Math.round(performance.now()-started),coldLoadMs,actionTimesMs:p.timings,errors:p.errors,cycle,history:p.history,observation:p.observation,memoryEnabled:batch.config.memoryEnabled,visibility:document.visibilityState});}catch(error){if(!stopped)throw error;}
  finished++;const row=ui('tr');for(const text of [runInfo.index+1,profiles[p.persona],p.step,p.observation?.score??'—',reason])row.append(ui('td',String(text)));document.querySelector('#results').append(row);
  document.querySelector('#overall').textContent=`${finished}/${batch.config.runCount} runs finished · ${batch.config.workers} workers · ${batch.batchId}`;return {reason,steps:p.step};
}
document.querySelector('#settings').addEventListener('submit',async event=>{
  event.preventDefault();if(running)return;running=true;document.querySelector('#start').disabled=true;
  try{const values=Object.fromEntries(new FormData(event.currentTarget));for(const key of Object.keys(values))if(key!=='memoryEnabled')values[key]=Number(values[key]);values.memoryEnabled=!!values.memoryEnabled;const selected=validateConfig(values);disposeWorkers(players);document.querySelector('#players').replaceChildren();batch=await post('/batch',selected);stopped=false;running=true;finished=0;document.querySelector('#results').replaceChildren();document.querySelector('#start').disabled=true;document.querySelector('#stop').disabled=false;document.querySelector('#overall').textContent='Starting isolated workers…';
    await runPool(batch.runs.length,batch.config.workers,(i,w)=>run(batch.runs[i],w),()=>stopped);
    document.querySelector('#overall').textContent=`Batch ${stopped?'stopped':'complete'}: ${finished}/${batch.config.runCount} runs executed. Exact traces and summary saved on the server.`;
  }catch(error){if(running&&!stopped){try{await stop();}catch{stopped=true;}}document.querySelector('#overall').textContent=error.message;}finally{running=false;document.querySelector('#start').disabled=false;document.querySelector('#stop').disabled=true;}
});
document.querySelector('#stop').addEventListener('click',()=>stop().catch(error=>document.querySelector('#overall').textContent=error.message));
document.querySelector('#overall').textContent=`Ready to configure · build ${config.buildId.slice(0,12)} · no API requests until Start.`;
