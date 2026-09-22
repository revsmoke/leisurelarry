const config = await fetch('/config').then(r=>r.json());
const profiles = {goal:['Objective-led','Follows the displayed plan and learned clues.'],curious:['Curious','Inspects and talks before acting.'],unguided:['Without the plan','Uses the same game with its objective text withheld from Jev.']};
const players = new Map(); let stopped=false; let running=false;
const ui = (tag, text, cls) => {const e=document.createElement(tag);if(text)e.textContent=text;if(cls)e.className=cls;return e;};
for (const [id,[title,description]] of Object.entries(profiles)) {
  const card=ui('article',null,'card'); const heading=ui('section');heading.append(ui('h2',title),ui('p',description));const status=ui('div','Loading…','status');heading.append(status);
  const frame=document.createElement('iframe');frame.title=`${title} Godot game`;frame.src=`/game/index.html?qa=1&instance=${id}`;frame.allow='autoplay';
  const content=ui('section');const metrics=ui('div',null,'metrics');const score=ui('div');const scoreValue=ui('strong','0/100');score.append(scoreValue,ui('span','score'));const steps=ui('div');const stepsValue=ui('strong','0');steps.append(stepsValue,ui('span','actions'));metrics.append(score,steps);
  const current=ui('p','Waiting for game observations.');const log=ui('ol',null,'log');const detail=ui('details');detail.append(ui('summary','Current player-visible observation'));const view=ui('pre');detail.append(view);content.append(metrics,current,log,detail);card.append(heading,frame,content);document.querySelector('#players').append(card);
  players.set(id,{id,frame,status,scoreValue,stepsValue,current,log,view,observation:null,history:[],memory:{},step:0,pending:null,stalls:0,errors:0,timings:[]});
}
function remember(p,o){if(!config.memoryEnabled)return;const key=o.room.id;const previous=p.memory[key]||{dialogue:[]};const line=o.dialogue.text;const dialogue=[...previous.dialogue.filter(t=>t!==line),line].slice(-5);p.memory[key]={room:o.room.title,hotspots:o.hotspots.map(h=>h.name),dialogue};}
function render(p){const o=p.observation;if(!o)return;p.scoreValue.textContent=`${o.score}/100`;p.stepsValue.textContent=p.step;p.current.textContent=typeof o.dialogue==='string'?o.dialogue:`${o.dialogue?.speaker || ''}: ${o.dialogue?.text || ''}`;p.view.textContent=JSON.stringify(o,null,2);}
window.addEventListener('message',event=>{
  if(event.origin!==location.origin)return;
  const p=[...players.values()].find(p=>p.frame.contentWindow===event.source);if(!p)return;
  const message=event.data;if(!['larry-qa-ready','larry-qa-observation'].includes(message?.type))return;
  p.observation=message.observation;remember(p,p.observation);render(p);
  if(message.type==='larry-qa-ready'){p.status.textContent='Ready · isolated save state';if([...players.values()].every(p=>p.observation)){document.querySelector('#start').disabled=false;document.querySelector('#overall').textContent=`All three game instances ready · ${config.memoryEnabled?'observed room memory':'recent history only'}.`;}}
  if(p.pending&&p.pending.id===message.requestId){clearTimeout(p.pending.timer);const {resolve,reject}=p.pending;p.pending=null;message.error?reject(Error(message.error)):resolve(message.observation);}
});
async function post(route,data){const response=await fetch(route,{method:'POST',headers:{'Content-Type':'application/json','X-QA-Token':config.token},body:JSON.stringify(data)});const result=await response.json();if(!response.ok)throw Error(result.error||`HTTP ${response.status}`);return result;}
function execute(p,action){return new Promise((resolve,reject)=>{const id=crypto.randomUUID();const timer=setTimeout(()=>{p.pending=null;reject(Error('Godot did not acknowledge the action within 15 seconds'));},15000);p.pending={id,resolve,reject,timer};p.frame.contentWindow.postMessage({type:'larry-qa-action',requestId:id,revision:p.observation.revision,action},location.origin);});}
const sameProgress=(a,b)=>JSON.stringify([a.room,a.score,a.money,a.inventory,a.objective,a.dialogue,a.notebook])===JSON.stringify([b.room,b.score,b.money,b.inventory,b.objective,b.dialogue,b.notebook]);
async function run(p){let reason='action_budget';const started=performance.now();
  try{while(p.step<config.maxSteps&&!stopped){if(p.observation.completed){reason='completed';break;}
    p.status.textContent='Jev is choosing…';const before=p.observation;
    const decision=await post('/decide',{runId:p.id,persona:p.id,observation:before,history:p.history,memory:config.memoryEnabled?p.memory:undefined,step:p.step});
    const answer=decision.result.answers.next_action;if(['abstain','decline'].includes(answer.choice)){reason='model_abstained';break;}
    const candidate=before.actions.find(a=>a.id===answer.choice);if(!candidate)throw Error('Action no longer available');
    p.status.textContent=`${candidate.label} · ${decision.apiMs} ms API`;
    const actionStart=performance.now();const after=await execute(p,answer.choice);p.timings.push(Math.round(performance.now()-actionStart));p.step++;
    p.stalls=sameProgress(before,after)?p.stalls+1:0;
    p.history.push({action:candidate.label,room:after.room,dialogue:after.dialogue,score:after.score,objective:after.objective});
    p.log.prepend(ui('li',`${p.step}. ${candidate.label} → ${after.score}/100 (confidence ${Number(answer.confidence).toFixed(2)})`));render(p);
    await post('/result',{runId:p.id,status:'running',steps:p.step,score:after.score,room:after.room,money:after.money,completed:after.completed,observation:after,lastAction:candidate.label,apiMs:decision.apiMs,actionMs:p.timings.at(-1),clarity:decision.result.answers.clarity,contradiction:decision.result.answers.contradiction});
    if(answer.choice==='decline'){reason='model_abstained';break;}
    if(p.stalls>=4){reason='repeated_unchanged_state';break;}
  }}catch(error){p.errors++;reason='error';p.current.textContent=error.message;p.status.classList.add('error');}
  if(stopped&&reason==='action_budget')reason='user_stopped';
  if(p.observation?.completed)reason='completed';
  p.status.textContent=`Finished · ${reason.replaceAll('_',' ')}`;
  await post('/result',{runId:p.id,status:'finished',reason,steps:p.step,score:p.observation?.score,money:p.observation?.money,room:p.observation?.room,completed:!!p.observation?.completed,elapsedMs:Math.round(performance.now()-started),actionTimesMs:p.timings,errors:p.errors,history:p.history,observation:p.observation,memoryEnabled:config.memoryEnabled});
}
document.querySelector('#start').addEventListener('click',async()=>{if(running)return;running=true;stopped=false;document.querySelector('#start').disabled=true;document.querySelector('#stop').disabled=false;document.querySelector('#overall').textContent='Three Jev players running concurrently…';await Promise.all([...players.values()].map(run));document.querySelector('#stop').disabled=true;const status=await fetch('/status').then(r=>r.json());document.querySelector('#overall').textContent=`Finished · ${status.budget.requests} API requests · ${status.budget.inputTokens.toLocaleString()} input tokens · evidence saved`;});
document.querySelector('#stop').addEventListener('click',()=>{stopped=true;document.querySelector('#stop').disabled=true;});
