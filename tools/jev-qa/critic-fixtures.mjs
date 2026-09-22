// Developer-authored evaluation set, not independent human ratings or live runs.
// The first pair preserves the confirmed bowling-before-password regression.
const pairs=[
 ['tv-before-password','The television is now showing bowling. The bouncer turns toward it.','Find the remote and put bowling on. I still need the password.','Bowling is on. Now I only need the password.'],
 ['whiskey-traded','You hand the whiskey to the regular. He hands over the TV remote.','Bring me whiskey and I will give you the remote.','Thanks for that whiskey. Enjoy the remote.'],
 ['candy-delivered','Didi accepts the promotional candy for the show.','I still need the promotional candy.','The candy is ready. I still need flowers.'],
 ['flowers-delivered','Didi puts the flowers in the stage vase.','Please bring me flowers for this empty vase.','The flowers look great; the ring is still missing.'],
 ['ring-delivered','Didi accepts the costume ring as a stage prop.','You have not brought me the costume ring.','Your ring will be perfect for the stage bit.'],
 ['dance-finished','Didi and Larry finish their rehearsal dance.','We have not rehearsed the dance yet.','That dance was gloriously ridiculous.'],
 ['phone-called','The stage manager answers the phone and confirms the introduction.','You still need to call the stage manager.','The stage manager is expecting your visit.'],
 ['wine-traded','The busker accepts the wine and hands over his pocket knife.','Bring me wine and I will lend you my knife.','Thanks for the wine; that knife is yours to borrow.'],
 ['rope-released','You cut the spare stage rope free with the pocket knife.','The rope is still tied down and cannot be carried.','You now have a usable length of stage rope.'],
 ['rope-secured','You secure the rope to the safety railing.','The safety railing has no rope attached.','The rope at the railing is secure.'],
 ['window-open','You tap the stuck frame and the service window opens.','The service window is still stuck shut.','The service window is open; take a look inside.'],
 ['voucher-collected','You pick up the espresso voucher from the sill.','The espresso voucher is still waiting on the sill.','You have the voucher; the machine can redeem it.'],
 ['voucher-redeemed','The espresso machine accepts the voucher and dispenses coffee.','You still have an unused espresso voucher.','Your voucher paid for that steaming espresso.'],
 ['coffee-delivered','The receptionist accepts the espresso and gives you an invitation.','You have not brought the receptionist her coffee.','Thank you for the coffee. Take the invitation upstairs.'],
 ['stool-placed','You set the folding stool under the cabinet.','No stool has been placed under the high cabinet.','The stool is in position under the cabinet.'],
 ['pitcher-collected','You take the water pitcher from the cabinet.','The water pitcher is still inside the cabinet.','The cabinet is empty now; you took the pitcher.'],
 ['pitcher-filled','You fill the pitcher at the kitchenette sink.','Your pitcher is still empty.','The pitcher is full and ready for watering.'],
 ['seeds-planted','You plant the apple seeds in the experimental planter.','The planter has no seeds in it yet.','The seeds are planted; they need water.'],
 ['apple-picked','You pick the ripe apple from the miniature tree.','The ripe apple is still hanging on that branch.','You have the apple; the picked tree remains.'],
 ['eve-gift','Eve accepts the apple and takes a bite.','You have not offered Eve the apple yet.','That apple hit the spot. Stay and talk.']
];
const clues=[
 ['remote','The regular says: bring me a whiskey from Lefty and I will give you my remote.','Use Lefty · whiskey $10'],
 ['ring','Didi needs a costume ring. Your notebook records a costume ring in the restroom dish.','Travel via city map to The Restroom'],
 ['flowers','Didi wants stage flowers. The flower cart is on this street and costs $10.','Take Flower cart · $10'],
 ['wine','The busker asks for wine. The shop clerk advertises a bottle for $12.','Take Wine · $12'],
 ['phone','Didi says the stage manager can be reached with the wall telephone here.','Use Wall telephone'],
 ['water','The planted seeds need water. You are holding a full water pitcher.','Use Pitcher of water with Experimental planter'],
 ['pitcher','The receptionist points out the pitcher in the open cabinet beside you.','Take Water pitcher'],
 ['apple','Eve has missed dinner. You are holding the ripe apple she asked about.','Use Perfect apple with Eve · rooftop host'],
 ['cabaret','Didi says: choose the rehearsal role if you would rather help without stage props.','Press Volunteer for the rehearsal'],
 ['ending','Eve offers a friendly conversation or a flirtatious sunrise. Choose which evening you want.','Press Stay for a friendly sunrise']
];
function observation(text,action='Look around the current room'){return {revision:1,room:{id:'fixture',title:'Developer fixture'},dialogue:{speaker:'Character',text},inventory:[],notebook:[],score:0,actions:[{id:'inspect',label:action}]};}
export const CRITIC_FIXTURES=[
 ...pairs.flatMap(([id,prior,stale,current])=>[
  {id:id+'-stale',kind:'dialogue',expected:true,observation:observation(stale),history:[{action:'Previous successful interaction',dialogue:{text:prior},score:0}]},
  {id:id+'-current',kind:'dialogue',expected:false,observation:observation(current),history:[{action:'Previous successful interaction',dialogue:{text:prior},score:0}]}
 ]),
 ...clues.flatMap(([id,lead,action])=>[
  {id:id+'-actionable',kind:'clue',expected:true,observation:observation(lead,action),history:[]},
  {id:id+'-atmosphere',kind:'clue',expected:false,observation:observation('The room glows with neon. Somewhere a saxophone owes someone money. No one mentions a task, a useful object, or where to go.',action),history:[]}
 ])
];
export function criticMetrics(records){
 return Object.fromEntries(['dialogue','clue'].map(kind=>{
  const group=records.filter(r=>r.kind===kind);const cells={truePositive:0,falsePositive:0,trueNegative:0,falseNegative:0};
  for(const r of group){const predicted=kind==='dialogue'?r.result.answers.contradiction.noul>=.5:r.result.answers.clarity.score>=2;cells[predicted?(r.expected?'truePositive':'falsePositive'):(r.expected?'falseNegative':'trueNegative')]++;}
  return [kind,{sampleSize:group.length,threshold:kind==='dialogue'?0.5:2,...cells,precision:cells.truePositive+cells.falsePositive?cells.truePositive/(cells.truePositive+cells.falsePositive):null,recall:cells.truePositive+cells.falseNegative?cells.truePositive/(cells.truePositive+cells.falseNegative):null,misses:group.filter(r=>r.expected&&(kind==='dialogue'?r.result.answers.contradiction.noul<.5:r.result.answers.clarity.score<2)).map(r=>r.id),falseAlarms:group.filter(r=>!r.expected&&(kind==='dialogue'?r.result.answers.contradiction.noul>=.5:r.result.answers.clarity.score>=2)).map(r=>r.id)}];
 }));
}
