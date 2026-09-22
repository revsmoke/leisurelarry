// TypeSafe HTTP contract: https://docs.typesafe.ai/api.md
export const ENDPOINT = 'https://api.typesafe.ai/v1/systemone';
export const MODEL = 'jev-latest';
export const PERSONAS = {
  goal: 'Follow the displayed objective and try to finish the evening. Prefer a direct action supported by acquired clues. Examine or talk when evidence is missing.',
  curious: 'Try to finish the evening while exploring the comedy. Talk to new people and inspect unfamiliar objects, then use learned clues. Avoid revisiting resolved interactions.',
  unguided: 'Try to finish the evening using descriptions, dialogue and acquired clues. The objective panel is deliberately withheld in this experiment. Discover character requests and act on them.'
};
export function buildRequest({persona, observation, history = [], memory}) {
  if (!Object.hasOwn(PERSONAS, persona)) throw Error('Unknown player profile');
  if (!Array.isArray(observation.actions) || observation.actions.length < 1 || observation.actions.length > 255) throw Error('Invalid action coverage');
  const ids = new Set();
  for (const action of observation.actions) {
    if (typeof action.id !== 'string' || !action.id || action.id.length > 128 || ids.has(action.id) || typeof action.label !== 'string' || !action.label || action.label.length > 500) throw Error('Invalid or duplicate action');
    ids.add(action.id);
  }
  const criteria = Object.fromEntries(observation.actions.map(a => [a.id, a.label]));
  if (!ids.has('decline')) criteria.abstain = 'None of these actions is supported, or the player is stuck and needs a human review.';
  if (Object.keys(criteria).length > 255) throw Error('Invalid action coverage');
  const {actions, diagnostics, ...visible} = observation;
  if (persona === 'unguided') delete visible.objective;
  return {
    model: MODEL,
    state: {
      player: PERSONAS[persona],
      controls: 'Look examines; Talk converses; Take collects; Use operates. An inventory item can be used on a target or itself. Map travels. Avoid repeating an action that just failed or already fulfilled its purpose. Read the recent outcomes before selecting.',
      visible,
      ...(memory ? {observed_memory: memory, memory_guidance: 'These are previously observed locations and dialogue, not hidden knowledge. Find missing objects by comparing the current goal or character request to observed hotspots in other rooms. A remembered statement may be outdated; the current visible state wins.'} : {}),
      recent_actions: history.slice(-12).map(({action, room, dialogue, score, objective}) => ({action, room, dialogue, score, ...(persona === 'unguided' ? {} : {objective})}))
    },
    questions: {
      next_action: {
        type: 'choice',
        instructions: 'Which single available action should this player take next? Use the player style, current visible evidence and recent outcomes. Make progress toward a complete evening. Do not repeat a completed trade or failed action without changed circumstances. Criteria describe available controls, not facts that the actions will succeed.',
        criteria
      },
      clarity: {
        type: 'score',
        instructions: 'How clearly does the visible evidence establish a useful next step for a new player? Judge the displayed clues, not your own prior knowledge of this game.',
        criteria: [
          'No identifiable purpose or useful lead is provided by the displayed evidence.',
          'A purpose exists, but the next lead or relevant interaction is missing.',
          'A useful next lead is inferable from the displayed evidence, with some interpretation.',
          'A specific next interaction or destination is explicitly explained in the displayed evidence.'
        ]
      },
      contradiction: {
        type: 'noul',
        instructions: 'Does the current dialogue or objective contradict a completed action recorded in recent_actions? Count a concrete inconsistency such as still requesting an item already delivered. Do not count comic exaggeration, a new request, or a failed action.',
        criteria: {'true': 'A concrete contradiction is supported by these observations.', 'false': 'No concrete contradiction is supported.'}
      }
    }
  };
}
export async function evaluate(request, {apiKey, fetchImpl = fetch, timeoutMs = 30000} = {}) {
  if (!apiKey) throw Error('TYPESAFE_API_KEY is missing');
  const started = performance.now();
  // No automatic retries: ambiguous timeouts may already have incurred usage.
  const response = await fetchImpl(ENDPOINT, {
    method: 'POST', headers: {'Content-Type': 'application/json', Authorization: `Bearer ${apiKey}`},
    body: JSON.stringify(request), signal: AbortSignal.timeout(timeoutMs)
  });
  if (!response.ok) throw Error(`TypeSafe HTTP ${response.status}; request stopped without an automatic retry`);
  const result = await response.json();
  const selected = result.answers?.next_action;
  if (request.questions.next_action && (!selected || !Object.hasOwn(request.questions.next_action.criteria, selected.choice))) throw Error('TypeSafe returned an unsupported choice');
  if (typeof result.model !== 'string' || !result.model || !result.usage || !result.answers) throw Error('Incomplete TypeSafe response');
  if (!['input_tokens','output_tokens'].every(k=>Number.isSafeInteger(result.usage[k]) && result.usage[k]>=0)) throw Error('Invalid TypeSafe usage');
  for (const [key, question] of Object.entries(request.questions)) {
    const answer = result.answers[key];
    if (!answer || answer.type !== question.type) throw Error('Missing or invalid TypeSafe answer');
    const unit = n => Number.isFinite(n) && n>=0 && n<=1;
    if (question.type === 'noul' && !unit(answer.noul)) throw Error('Invalid TypeSafe probability');
    if (question.type !== 'noul' && !unit(answer.confidence)) throw Error('Invalid TypeSafe confidence');
    if (question.type === 'score' && !(Number.isFinite(answer.score) && answer.score>=0 && answer.score<=question.criteria.length-1)) throw Error('Invalid TypeSafe score');
    if (question.type !== 'noul' && (!answer.probabilities || !Object.values(answer.probabilities).every(unit))) throw Error('Invalid TypeSafe distribution');
  }
  return {result, apiMs: Math.round(performance.now() - started)};
}
