import { readFileSync } from 'node:fs';
import { mkdir, writeFile } from 'node:fs/promises';
import { parseEnv } from 'node:util';
import { fileURLToPath } from 'node:url';
import path from 'node:path';
import {createHash} from 'node:crypto';
import { evaluate, MODEL } from './jev-qa/client.mjs';

const ROOT = fileURLToPath(new URL('../', import.meta.url));
export const PARTY_PATH = '/api/party-judge';
export const MAX_BODY_BYTES = 8192;
export const POKER_CHOICES = Object.freeze({
  "keep_all": "Stand pat: keep all five cards.",
  "keep_pairs": "Keep a made hand, or matching ranks and high kickers; replace up to three other cards.",
  "chase_flush": "Keep the most common suit and replace up to three other cards.",
  "draw_three": "Keep the two highest cards and draw three. A bold high-card gamble."
});
// These texts match the authored game catalog; a parity check prevents silent drift.
export const NEVER_SCENARIOS = Object.freeze([
  {
    "id": "n01",
    "text": "Never have I ever sent a love note to the wrong hotel room."
  },
  {
    "id": "n02",
    "text": "Never have I ever rehearsed a pickup line in a mirror."
  },
  {
    "id": "n03",
    "text": "Never have I ever mistaken a coat check ticket for a phone number."
  },
  {
    "id": "n04",
    "text": "Never have I ever worn sunglasses indoors to seem mysterious."
  },
  {
    "id": "n05",
    "text": "Never have I ever dated someone because of their record collection."
  },
  {
    "id": "n06",
    "text": "Never have I ever proposed strip charades and regretted the word octopus."
  },
  {
    "id": "n07",
    "text": "Never have I ever called a taxi just to impress a date."
  },
  {
    "id": "n08",
    "text": "Never have I ever left a party wearing somebody else's feather boa."
  },
  {
    "id": "n09",
    "text": "Never have I ever practiced a seductive entrance and hit a screen door."
  },
  {
    "id": "n10",
    "text": "Never have I ever used a hotel ice bucket as a champagne cooler."
  },
  {
    "id": "n11",
    "text": "Never have I ever named a dance move after my own pants."
  },
  {
    "id": "n12",
    "text": "Never have I ever flirted while wearing a borrowed mustache."
  },
  {
    "id": "n13",
    "text": "Never have I ever read a romance horoscope out loud to a willing date."
  },
  {
    "id": "n14",
    "text": "Never have I ever confused a waterbed showroom with a singles mixer."
  },
  {
    "id": "n15",
    "text": "Never have I ever kept a souvenir matchbook from a very good date."
  },
  {
    "id": "n16",
    "text": "Never have I ever said 'my place or yours' before checking for roommates."
  },
  {
    "id": "n17",
    "text": "Never have I ever lost an accessory playing a suspiciously named party game."
  },
  {
    "id": "n18",
    "text": "Never have I ever worn satin because an advertisement called it irresistible."
  },
  {
    "id": "n19",
    "text": "Never have I ever dedicated a song to a date under the wrong name."
  },
  {
    "id": "n20",
    "text": "Never have I ever tried to look casual while waiting by a pay phone."
  },
  {
    "id": "n21",
    "text": "Never have I ever brought a silk scarf to a picnic just for dramatic effect."
  },
  {
    "id": "n22",
    "text": "Never have I ever suggested a slow dance to a song with a kazoo solo."
  },
  {
    "id": "n23",
    "text": "Never have I ever mistaken a stage curtain for the exit after a flirtation."
  },
  {
    "id": "n24",
    "text": "Never have I ever packed a spare outfit for an optimistic first date."
  }
]);
export const NEVER_REACTIONS = Object.freeze({
  "wink": "The host winks. 'A little mystery goes beautifully with those lapels.'",
  "commiserate": "'We've all had a night when the outfit had better luck than its owner.'",
  "tease_self": "'My autobiography is mostly apologies to coat-check attendants.'",
  "toast": "The host raises a glass of soda. 'To consenting adults and questionable tailoring.'",
  "deadpan": "'Very glamorous. I'll alert the society pages. In very small print.'",
  "wardrobe": "'This town puts strip in front of everything. Even the laundromat has a waiting list.'",
  "mystery": "'An air of mystery! At last, an accessory nobody has to take off.'",
  "gracious": "'Passing is always fine, darling. Your privacy is more interesting than a forced confession.'"
});

export class PartyInputError extends Error {
  constructor(code, status = 400) { super(code); this.code = code; this.status = status; }
}
const fail = (code, status) => { throw new PartyInputError(code, status); };
const plain = value => value !== null && typeof value === 'object' && !Array.isArray(value) && [Object.prototype, null].includes(Object.getPrototypeOf(value));
function exactKeys(value, expected) {
  return plain(value) && Object.keys(value).length === expected.length && expected.every(key => Object.hasOwn(value, key));
}
const integer = (value, lo, hi) => Number.isSafeInteger(value) && value >= lo && value <= hi;
const shortText = (value, length) => typeof value === 'string' && value.length > 0 && value.length <= length && !/[\u0000-\u001f\u007f]/.test(value);

export function validatePartyPayload(input) {
  if (!exactKeys(input, ['request_id', 'mode', 'observation', 'candidates'])) fail('invalid_payload');
  if (!shortText(input.request_id, 96) || !/^[A-Za-z0-9:_-]+$/.test(input.request_id)) fail('invalid_request_id');
  const state = input.observation;
  let choices;
  let observation;
  if (input.mode === 'poker') {
    if (!exactKeys(state, ['own_cards', 'player_discard_count', 'round', 'persona']) || state.persona !== 'playful_sharp' || !integer(state.round, 1, 3) || !integer(state.player_discard_count, 0, 3)) fail('invalid_poker_observation');
    if (!Array.isArray(state.own_cards) || state.own_cards.length !== 5 || new Set(state.own_cards).size !== 5 || !state.own_cards.every(card => integer(card, 0, 51))) fail('invalid_own_cards');
    observation = { own_cards: [...state.own_cards], player_discard_count: state.player_discard_count, round: state.round, persona: state.persona };
    choices = POKER_CHOICES;
  } else if (input.mode === 'never') {
    if (!exactKeys(state, ['scenario_id', 'player_response', 'round', 'persona']) || state.persona !== 'party_host' || !integer(state.round, 1, 5) || !['have', 'never', 'pass'].includes(state.player_response) || !NEVER_SCENARIOS.some(scenario => scenario.id === state.scenario_id)) fail('invalid_never_observation');
    observation = { scenario_id: state.scenario_id, player_response: state.player_response, round: state.round, persona: state.persona };
    choices = NEVER_REACTIONS;
  } else fail('invalid_mode');
  const expected = Object.keys(choices);
  if (!Array.isArray(input.candidates) || input.candidates.length !== expected.length) fail('invalid_candidates');
  const ids = new Set();
  for (const candidate of input.candidates) {
    if (!exactKeys(candidate, ['id', 'label']) || !Object.hasOwn(choices, candidate.id) || ids.has(candidate.id) || !shortText(candidate.label, 320)) fail('invalid_candidates');
    ids.add(candidate.id);
  }
  // Client labels are not sent upstream. All model wording comes from this catalog.
  return { request_id: input.request_id, mode: input.mode, observation, candidates: input.candidates.map(({id, label}) => ({id, label})) };
}

function pokerFallback(cards) {
  const ranks = cards.map(card => card % 13 + 2).sort((a, b) => a - b);
  const counts = ranks.map(rank => ranks.filter(other => other === rank).length);
  const flush = cards.every(card => Math.floor(card / 13) === Math.floor(cards[0] / 13));
  const straight = new Set(ranks).size === 5 && (ranks[4] - ranks[0] === 4 || ranks.join(',') === '2,3,4,5,14');
  if (flush || straight || (counts.includes(3) && counts.includes(2)) || counts.includes(4)) return 'keep_all';
  if (counts.some(count => count > 1)) return 'keep_pairs';
  if ([0, 1, 2, 3].some(suit => cards.filter(card => Math.floor(card / 13) === suit).length >= 4)) return 'chase_flush';
  return 'draw_three';
}
function readablePokerFacts(cards) {
  const rankName = rank => ({11:'Jack', 12:'Queen', 13:'King', 14:'Ace'})[rank] || String(rank);
  const suits = ['clubs', 'diamonds', 'hearts', 'spades'];
  const ranks = cards.map(card => card % 13 + 2).sort((a, b) => a - b);
  const rankCounts = Object.fromEntries([...new Set(ranks)].map(rank => [rankName(rank), ranks.filter(value => value === rank).length]));
  const suitCounts = Object.fromEntries(suits.map((suit, index) => [suit, cards.filter(card => Math.floor(card / 13) === index).length]));
  const counts = Object.values(rankCounts).sort((a, b) => b - a);
  const flush = Math.max(...Object.values(suitCounts)) === 5;
  const straight = new Set(ranks).size === 5 && (ranks[4] - ranks[0] === 4 || ranks.join(',') === '2,3,4,5,14');
  const madeHand = straight && flush ? 'straight flush' : counts[0] === 4 ? 'four of a kind' : counts[0] === 3 && counts[1] === 2 ? 'full house' : flush ? 'flush' : straight ? 'straight' : counts[0] === 3 ? 'three of a kind' : counts[0] === 2 && counts[1] === 2 ? 'two pair' : counts[0] === 2 ? 'one pair' : 'high card';
  return {cards: cards.map(card => `${rankName(card % 13 + 2)} of ${suits[Math.floor(card / 13)]}`), rank_counts: rankCounts, suit_counts: suitCounts, made_hand: madeHand};
}
export function fallbackPartyChoice(payload) {
  const valid = validatePartyPayload(payload);
  if (valid.mode === 'poker') return pokerFallback(valid.observation.own_cards);
  const { player_response, round, scenario_id } = valid.observation;
  if (player_response === 'pass') return 'gracious';
  const options = player_response === 'have' ? ['wink', 'commiserate', 'tease_self', 'toast'] : ['deadpan', 'wardrobe', 'mystery', 'toast'];
  return options[(Number(scenario_id.slice(1)) + round) % options.length];
}

export function buildPartyRequest(payload) {
  const valid = validatePartyPayload(payload);
  const poker = valid.mode === 'poker';
  const { request_id: _ignored, candidates: _labels, ...visible } = valid;
  const state = poker ? {
    ...visible,
    observation: {...visible.observation, own_cards: readablePokerFacts(valid.observation.own_cards)},
    character: 'A playful adult card sharp who likes a good contest and a theatrical flourish.',
    rules: 'Five-card draw, one exchange of up to three cards. The readable cards, rank counts, suit counts and made hand are computed by game code for this opponent\'s own cards before the exchange. The only public information about the human-controlled character is the number of cards they chose to exchange. Their cards, deck order and future draws are unknown. Preserve strong made hands, keep valuable groups and consider a four-card flush draw. Game code deals cards, ranks hands and resolves the result.'
  } : {
    ...visible,
    character: 'An adult lounge host who is quick with a warm joke, laughs at their own misadventures, and never shames or pressures a guest.',
    scenario: NEVER_SCENARIOS.find(scenario => scenario.id === valid.observation.scenario_id).text,
    answer_meaning: {have: 'The fictional character says they HAVE done the prompted thing and is sharing in the joke.', never: 'The fictional character says they have NEVER done the prompted thing and is participating in the game. This is an answer, not a Pass.', pass: 'The guest chose not to answer this prompt.'}[valid.observation.player_response],
    rules: 'This is a fictional character party game. The player chooses an authored in-character answer, not a real-life personal disclosure. Choose only the host\'s next quip. Do not infer whether a story is true. No choice changes points, clothing, consent, romance, or game outcomes.'
  };
  return {
    model: MODEL,
    state,
    questions: {
      next_action: {
        type: 'choice',
        instructions: poker
          ? 'Which of the four legal exchange strategies fits this playful opponent and the known cards? Use only this opponent\'s cards and the public discard count. Do not infer hidden player cards or choose a winner. Each option is legal; code performs the chosen exchange.'
          : 'Which authored quip best fits the fictional scenario, the selected in-character answer, and this friendly lounge host? Prefer a topical connection to the scenario over a generic toast when one fits. Pick a coherent playful response without judging the guest, pressuring them, or claiming knowledge of their real life. All text is prewritten and the selected line is used verbatim.',
        criteria: poker ? {...POKER_CHOICES} : Object.fromEntries(Object.entries(NEVER_REACTIONS).filter(([id]) => id !== 'gracious' || valid.observation.player_response === 'pass'))
      }
    }
  };
}

function readLocalKey(envPath) {
  try { return parseEnv(readFileSync(envPath, 'utf8')).TYPESAFE_API_KEY || ''; }
  catch { return ''; }
}
function validOrigin(origin) {
  const url = new URL(origin);
  if (url.protocol !== 'http:' || url.hostname !== '127.0.0.1' || url.origin !== origin || !url.port) throw Error('Party service requires a loopback HTTP origin.');
  return url;
}
function sendJSON(response, status, data) {
  if (response.destroyed || response.writableEnded) return;
  const body = JSON.stringify(data);
  response.writeHead(status, {'Content-Type': 'application/json; charset=utf-8', 'Content-Length': Buffer.byteLength(body), 'Cache-Control': 'no-store', 'X-Content-Type-Options': 'nosniff'});
  response.end(body);
}
async function readBody(request) {
  if (!/^application\/json(?:\s*;\s*charset=utf-8)?$/i.test(request.headers['content-type'] || '')) fail('json_required', 415);
  if (request.headers['content-length'] && (!/^\d+$/.test(request.headers['content-length']) || Number(request.headers['content-length']) > MAX_BODY_BYTES)) fail('body_too_large', 413);
  const chunks = [];
  let size = 0;
  for await (const chunk of request) {
    size += chunk.length;
    if (size > MAX_BODY_BYTES) fail('body_too_large', 413);
    chunks.push(chunk);
  }
  try { return JSON.parse(Buffer.concat(chunks).toString('utf8')); }
  catch { fail('invalid_json'); }
}

/** Mount handle() before static files. The key, provider headers, and raw replies never enter a browser response. */
export function createPartyJudge({
  origin = 'http://127.0.0.1:8766', envPath = new URL('../.env', import.meta.url), apiKey,
  fetchImpl = fetch, timeoutMs = 1500, maxRequests = 120, maxPerMinute = 20,
  maxConcurrent = 2, maxInputTokens = 250000, now = Date.now, onRecord = () => {}
} = {}) {
  const endpointOrigin = validOrigin(origin);
  for (const [value, lo, hi] of [[timeoutMs, 1, 1500], [maxRequests, 1, 120], [maxPerMinute, 1, 20], [maxConcurrent, 1, 2], [maxInputTokens, 1, 250000]]) if (!integer(value, lo, hi)) throw Error('Invalid party service budget.');
  const key = apiKey === undefined ? readLocalKey(envPath) : apiKey;
  if (typeof key !== 'string') throw Error('Invalid server credential.');
  const cache = new Map();
  const recent = [];
  const counters = { requests: 0, active: 0, jev: 0, fallback: 0, input_tokens: 0, output_tokens: 0, usage_unknown: 0 };
  function record(data) { try { onRecord(data); } catch { /* Reporting never interrupts the game. */ } }
  async function decide(payload, signal) {
    const started = performance.now();
    const request = buildPartyRequest(payload);
    const fallback = reason => {
      counters.fallback++;
      const reply = { request_id: payload.request_id, choice: fallbackPartyChoice(payload), source: 'fallback', confidence: null, model: null };
      record({ input: payload, request, reply, reason, elapsed_ms: Math.round(performance.now() - started) });
      return reply;
    };
    if (signal?.aborted) return fallback('cancelled');
    if (payload.mode === 'never' && payload.observation.player_response === 'pass') return fallback('guest_passed');
    if (!key) return fallback('no_server_key');
    if (counters.requests >= maxRequests || counters.input_tokens >= maxInputTokens) return fallback('session_budget');
    while (recent.length && recent[0] <= now() - 60000) recent.shift();
    if (recent.length >= maxPerMinute) return fallback('rate_budget');
    if (counters.active >= maxConcurrent) return fallback('busy');
    counters.requests++; counters.active++; recent.push(now());
    const controller = new AbortController();
    let cancelReason = 'provider_error';
    let rejectAbort;
    const aborted = new Promise((_, reject) => { rejectAbort = reject; });
    const cancel = reason => { cancelReason = reason; controller.abort(); rejectAbort(new Error('Party decision cancelled.')); };
    const abortListener = () => cancel('cancelled');
    signal?.addEventListener('abort', abortListener, {once: true});
    const timer = setTimeout(() => cancel('timeout'), timeoutMs);
    try {
      const { result, apiMs } = await Promise.race([evaluate(request, {apiKey: key, fetchImpl, timeoutMs, signal: controller.signal}), aborted]);
      const selected = result.answers.next_action;
      if (!payload.candidates.some(candidate => candidate.id === selected.choice)) throw Error('Unsupported party choice.');
      counters.jev++; counters.input_tokens += result.usage.input_tokens; counters.output_tokens += result.usage.output_tokens;
      const reply = { request_id: payload.request_id, choice: selected.choice, source: 'jev', confidence: selected.confidence, model: result.model };
      record({ input: payload, request, result, reply, api_ms: apiMs, elapsed_ms: Math.round(performance.now() - started), reason: 'selected' });
      return reply;
    } catch {
      counters.usage_unknown++;
      return fallback(cancelReason);
    } finally {
      clearTimeout(timer);
      signal?.removeEventListener('abort', abortListener);
      counters.active--;
    }
  }
  async function judge(input, {signal} = {}) {
    const payload = validatePartyPayload(input);
    const signature = JSON.stringify(payload);
    const previous = cache.get(payload.request_id);
    if (previous) {
      if (previous.signature !== signature) fail('request_id_reused', 409);
      return structuredClone(await previous.promise);
    }
    if (cache.size >= 512) cache.delete(cache.keys().next().value);
    const promise = decide(payload, signal);
    cache.set(payload.request_id, {signature, promise});
    return structuredClone(await promise);
  }
  async function handle(request, response) {
    let url;
    try { url = new URL(request.url, origin); } catch { return false; }
    if (url.pathname !== PARTY_PATH) return false;
    if (request.method !== 'POST') { sendJSON(response, 405, {error: 'post_required'}); return true; }
    if (request.headers.origin !== origin || request.headers.host !== endpointOrigin.host || !['127.0.0.1', '::1', '::ffff:127.0.0.1'].includes(request.socket.remoteAddress) || url.search) {
      request.resume(); sendJSON(response, 403, {error: 'local_origin_required'}); return true;
    }
    const controller = new AbortController();
    const onClose = () => { if (!response.writableEnded) controller.abort(); };
    response.on('close', onClose);
    try { sendJSON(response, 200, await judge(await readBody(request), {signal: controller.signal})); }
    catch (error) {
      request.resume();
      sendJSON(response, error instanceof PartyInputError ? error.status : 400, {error: error instanceof PartyInputError ? error.code : 'invalid_request'});
    } finally { response.off('close', onClose); }
    return true;
  }
  return {handle, judge, stats: () => ({...counters, enabled: Boolean(key)})};
}

// A fixed, small evaluation batch; direct execution never starts an unbounded loop.
export async function runPartyExperiment(fixtures, output) {
  if (!Array.isArray(fixtures) || fixtures.length < 1 || fixtures.length > 12) throw Error('Use 1 to 12 fixed party fixtures.');
  for (const fixture of fixtures) validatePartyPayload(fixture.input);
  if (new Set(fixtures.map(fixture => fixture.input.request_id)).size !== fixtures.length) throw Error('Experiment request IDs must be unique.');
  const records = [];
  const judge = createPartyJudge({maxRequests: 12, maxPerMinute: 12, onRecord: entry => records.push(entry)});
  if (!judge.stats().enabled) throw Error('A local TypeSafe credential is required for the experiment.');
  const started = new Date().toISOString();
  for (const fixture of fixtures) {
    const reply = await judge.judge(fixture.input);
    records[records.length - 1].observed_outcome = {
      legal_choice: fixture.input.candidates.some(candidate => candidate.id === reply.choice),
      ...(fixture.expected ? {expected: fixture.expected, agrees_with_authored_expectation: fixture.expected.includes(reply.choice)} : {}),
      scope: fixture.scope || 'Isolated opponent decision; no rendered gameplay or enjoyment measurement.'
    };
  }
  const times = records.filter(entry => entry.reply.source === 'jev').map(entry => entry.api_ms).sort((a, b) => a - b);
  const quantile = p => times.length ? times[Math.min(times.length - 1, Math.ceil(times.length * p) - 1)] : null;
  const sha256 = file => createHash('sha256').update(readFileSync(path.join(ROOT, file))).digest('hex');
  const summary = {started, finished: new Date().toISOString(), fixtures: fixtures.length, budgets: {max_requests: 12, timeout_ms: 1500, automatic_retries: 0}, stats: judge.stats(), models: [...new Set(records.map(entry => entry.reply.model).filter(Boolean))], api_ms: {p50: quantile(.5), p95: quantile(.95)}, source_sha256: Object.fromEntries(['tools/party-jev.mjs', 'scripts/party_games.gd'].map(file => [file, sha256(file)])), limits: 'Small authored-fixture experiment. Legal choices and expectation agreement do not demonstrate good poker strategy, visual usability, player enjoyment, or a full gameplay pass.'};
  await mkdir(output, {recursive: true});
  await writeFile(path.join(output, 'requests.jsonl'), records.map(entry => JSON.stringify(entry)).join('\n') + '\n');
  await writeFile(path.join(output, 'summary.json'), JSON.stringify(summary, null, 2) + '\n');
  return summary;
}

export function partyExperimentFixtures() {
  const pokerCases = [
    {cards: [8, 9, 10, 11, 12], expected: ['keep_all', 'keep_pairs'], note: 'An already complete straight flush should remain intact.'},
    {cards: [0, 13, 26, 9, 22], expected: ['keep_all', 'keep_pairs'], note: 'An already complete full house should remain intact.'},
    {cards: [12, 25, 0, 18, 33], expected: ['keep_pairs'], note: 'Keep a pair of aces while improving the three unrelated cards.'},
    {cards: [0, 2, 5, 9, 25], expected: ['chase_flush'], note: 'Four clubs offer a one-card flush draw.'},
    {cards: [0, 15, 31, 49, 12], expected: ['draw_three', 'keep_pairs'], note: 'A scattered high-card hand can improve by keeping the best two cards.'},
    {cards: [5, 18, 31, 44, 10], expected: ['keep_all', 'keep_pairs'], note: 'Four matching ranks should stay together.'}
  ];
  const choices = catalog => Object.entries(catalog).map(([id, label]) => ({id, label}));
  return [
    ...pokerCases.map((fixture, i) => ({input: {request_id: `experiment:poker:${i}`, mode: 'poker', observation: {own_cards: fixture.cards, player_discard_count: i % 4, round: i % 3 + 1, persona: 'playful_sharp'}, candidates: choices(POKER_CHOICES)}, expected: fixture.expected, scope: fixture.note + ' This checks a bounded strategy choice, not the result of a dealt hand.'})),
    ...[['n01', 'have'], ['n08', 'have'], ['n17', 'never'], ['n21', 'never'], ['n24', 'have'], ['n06', 'never']].map(([scenario_id, player_response], i) => ({input: {request_id: `experiment:never:${i}`, mode: 'never', observation: {scenario_id, player_response, round: i % 5 + 1, persona: 'party_host'}, candidates: choices(NEVER_REACTIONS)}, scope: 'Authored quip selection after a fictional character answer. Outcome is legal catalog membership; humorous quality needs human review.'}))
  ];
}

if (process.argv[1] && path.resolve(process.argv[1]) === fileURLToPath(import.meta.url)) {
  if (process.argv.slice(2).join(' ') !== '--experiment') throw Error('Usage: node tools/party-jev.mjs --experiment');
  const output = path.join(ROOT, 'docs/experiments/party-jev', new Date().toISOString().replaceAll(':', '-').replaceAll('.', '-'));
  const summary = await runPartyExperiment(partyExperimentFixtures(), output);
  console.log(JSON.stringify({output, ...summary}, null, 2));
}
