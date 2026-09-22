import {existsSync} from 'node:fs';
import {mkdir,writeFile,rename} from 'node:fs/promises';
import {buildRequest,evaluate} from './client.mjs';
import {CRITIC_FIXTURES,criticMetrics} from './critic-fixtures.mjs';
import {runPool} from './runner.mjs';
if(existsSync('.env'))process.loadEnvFile('.env');
if(process.argv.includes('--critic')){
 const records=[];const output='docs/experiments/jev/critic-calibration-'+new Date().toISOString().replaceAll(':','-')+'.json';
 await mkdir('docs/experiments/jev',{recursive:true});let queue=Promise.resolve();
 const persist=()=>{const captured=records.filter(Boolean);const successful=captured.filter(r=>r.result);const snapshot=JSON.stringify({generatedAt:new Date().toISOString(),labelSource:'Developer-authored synthetic fixtures; first pair reproduces the observed stale bouncer defect.',limits:'20 stale/current pairs and 20 clue cases, one judgment per case. Thresholds fixed in advance at probability 0.5 and clarity 2/3. Small non-independent examples; no held-out human labels; not proof of enjoyment or readiness for automatic defect prioritization. Maximum60 attempts, concurrency2, no retries; failed responses may have unknown billable usage.',summary:criticMetrics(successful),attempted:captured.length,successful:successful.length,records:captured},null,2)+'\n';queue=queue.then(async()=>{await writeFile(output+'.tmp',snapshot);await rename(output+'.tmp',output);});return queue;};
 let failed=null;
 try{await runPool(CRITIC_FIXTURES.length,2,async index=>{
   const fixture=CRITIC_FIXTURES[index];const request=buildRequest({persona:'goal',observation:fixture.observation,history:fixture.history});delete request.questions.next_action;delete request.questions.strategy;
   try{const answer=await evaluate(request,{apiKey:process.env.TYPESAFE_API_KEY});records[index]={id:fixture.id,kind:fixture.kind,expected:fixture.expected,request,...answer};}
   catch(error){records[index]={id:fixture.id,kind:fixture.kind,expected:fixture.expected,request,error:String(error.message).replaceAll(process.env.TYPESAFE_API_KEY??'not-set','[redacted]'),usageUnknown:true};await persist();throw error;}
   await persist();
 });}catch(error){failed=String(error.message).replaceAll(process.env.TYPESAFE_API_KEY??'not-set','[redacted]');}
 await queue;const successful=records.filter(r=>r?.result);
 console.log(JSON.stringify({file:output,summary:criticMetrics(successful),requests:records.filter(Boolean).length,successful:successful.length,inputTokens:successful.reduce((n,r)=>n+r.result.usage.input_tokens,0),error:failed}));process.exit(failed?1:0);
}
const fixtures=[
 {name:'trade_request',expected:'buy',observation:{revision:1,room:{id:'bar',title:"Lefty's Bar"},objective:'Make a useful trade at Lefty\'s.',dialogue:{speaker:'Regular',text:'Bring me a whiskey from Lefty and this TV remote is yours.'},inventory:[],score:0,money:80,actions:[{id:'buy',label:'Use Lefty: whiskey $10'},{id:'take',label:'Take the thirsty regular'},{id:'leave',label:'Travel to hotel'}]}},
 {name:'completed_trade',expected:'television',observation:{revision:2,room:{id:'bar',title:"Lefty's Bar"},objective:'Use the remote on the television to distract the bouncer.',dialogue:{speaker:'Regular',text:'Thanks for the whiskey. The remote is yours.'},inventory:['TV remote'],score:12,money:70,actions:[{id:'buy',label:'Use Lefty: whiskey $10'},{id:'television',label:'Use TV remote on television'},{id:'leave',label:'Travel to hotel'}]}}
];
const records=[];
for(const fixture of fixtures){const group=await Promise.all(Array.from({length:3},async(_,repeat)=>{const request=buildRequest({persona:'goal',observation:fixture.observation});const answer=await evaluate(request,{apiKey:process.env.TYPESAFE_API_KEY});return{fixture:fixture.name,repeat,expected:fixture.expected,matched:answer.result.answers.next_action.choice===fixture.expected,request,...answer};}));records.push(...group);}
const output='docs/experiments/jev/calibration.json';await mkdir('docs/experiments/jev',{recursive:true});await writeFile(output,JSON.stringify({generatedAt:new Date().toISOString(),purpose:'Six simple API/closed-choice sanity checks; not a blind game completion test',records},null,2)+'\n');
console.log(JSON.stringify({file:output,matched:records.filter(r=>r.matched).length,total:records.length,models:[...new Set(records.map(r=>r.result.model))],inputTokens:records.reduce((n,r)=>n+r.result.usage.input_tokens,0),apiMs:records.map(r=>r.apiMs)}));
