import {existsSync} from 'node:fs';
import {mkdir,writeFile} from 'node:fs/promises';
import {buildRequest,evaluate} from './client.mjs';
if(existsSync('.env'))process.loadEnvFile('.env');
const fixtures=[
 {name:'trade_request',expected:'buy',observation:{revision:1,room:{id:'bar',title:"Lefty's Bar"},objective:'Make a useful trade at Lefty\'s.',dialogue:{speaker:'Regular',text:'Bring me a whiskey from Lefty and this TV remote is yours.'},inventory:[],score:0,money:80,actions:[{id:'buy',label:'Use Lefty: whiskey $10'},{id:'take',label:'Take the thirsty regular'},{id:'leave',label:'Travel to hotel'}]}},
 {name:'completed_trade',expected:'television',observation:{revision:2,room:{id:'bar',title:"Lefty's Bar"},objective:'Use the remote on the television to distract the bouncer.',dialogue:{speaker:'Regular',text:'Thanks for the whiskey. The remote is yours.'},inventory:['TV remote'],score:12,money:70,actions:[{id:'buy',label:'Use Lefty: whiskey $10'},{id:'television',label:'Use TV remote on television'},{id:'leave',label:'Travel to hotel'}]}}
];
const records=[];
for(const fixture of fixtures){const group=await Promise.all(Array.from({length:3},async(_,repeat)=>{const request=buildRequest({persona:'goal',observation:fixture.observation});const answer=await evaluate(request,{apiKey:process.env.TYPESAFE_API_KEY});return{fixture:fixture.name,repeat,expected:fixture.expected,matched:answer.result.answers.next_action.choice===fixture.expected,request,...answer};}));records.push(...group);}
const output='docs/experiments/jev/calibration.json';await mkdir('docs/experiments/jev',{recursive:true});await writeFile(output,JSON.stringify({generatedAt:new Date().toISOString(),purpose:'Six simple API/closed-choice sanity checks; not a blind game completion test',records},null,2)+'\n');
console.log(JSON.stringify({file:output,matched:records.filter(r=>r.matched).length,total:records.length,models:[...new Set(records.map(r=>r.result.model))],inputTokens:records.reduce((n,r)=>n+r.result.usage.input_tokens,0),apiMs:records.map(r=>r.apiMs)}));
