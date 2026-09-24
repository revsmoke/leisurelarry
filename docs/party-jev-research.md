# Party opponents with Jev

The optional local service in [`tools/party-jev.mjs`](../tools/party-jev.mjs) makes two bounded decisions: a five-card-draw opponent's exchange policy, and a lounge host's authored response to a fictional “Never Have I Ever” answer. Godot retains dealing, hand ranking, shot physics, accessory counters, consent, quest progress and outcomes. Pool needs no inference: the player's aim and power determine the shot.

## Sources and design

Read on September 23, 2026 (local time), starting with the [live documentation index](https://docs.typesafe.ai/llms.txt). The `.md` endpoints failed in the research browser; their normal pages loaded.

- The [HTTP API](https://docs.typesafe.ai/api) defines the `state`, `model`, and typed `questions` request, and returns the model version, answers and token usage. This service uses `jev-latest` through the existing HTTP helper with no automatic retries.
- [Choice](https://docs.typesafe.ai/primitives/choice) fits a finite move or reply menu. [State](https://docs.typesafe.ai/concepts/state) supports named structured observations. Poker input includes only the opponent's own five cards and the public player discard count. The server computes readable card names, rank/suit counts and the current hand category before asking for a strategy; it never sends the player's private hand or the remaining deck.
- The [function-calling cookbook](https://docs.typesafe.ai/cookbooks/function_calling) separates closed choices from deterministic execution. Here a choice selects one of four local draw policies. It cannot create a move, declare a winner or change a wallet.
- The [pre-parsed value cookbook](https://docs.typesafe.ai/cookbooks/pre_parsed_value_extraction_cookbook) suggests selecting existing content instead of generating it. Here 24 authored scenarios and eight reviewed quips supply the text. A non-pass answer offers seven quips to Jev; the pass-only response is excluded mechanically. Pass itself resolves locally without inference. No free-form personal disclosure enters this workflow.
- [Confidence](https://docs.typesafe.ai/confidence) reflects concentration among alternatives. We retain it without treating a confident choice as proof of a good strategy or joke. No model result establishes consent or human enjoyment.

An OpenAI text-generation or agent integration was unnecessary for these bounded party games.

## Local contract

Mount `createPartyJudge({origin: 'http://127.0.0.1:8766'}).handle(request, response)` before the preview server's static-file handler. It returns `true` only for `/api/party-judge`. The key is read from the server's ignored `.env`; no credential is sent to the game or included in exports.

`POST /api/party-judge` accepts exactly:

```js
{
  request_id: "evening:game:revision",
  mode: "poker", // or "never"
  observation: {
    own_cards: [12, 25, 0, 18, 33],
    player_discard_count: 2,
    round: 1,
    persona: "playful_sharp"
  },
  candidates: [/* all legal {id, label} pairs */]
}
```

Never's observation is `{scenario_id: 'n01'…'n24', player_response: 'have'|'never'|'pass', round: 1…5, persona: 'party_host'}`. The client strips model-side `description` fields. The server accepts only known IDs and exact observation fields and rebuilds all upstream wording from its reviewed catalog. A parity test compares that catalog with Godot's authored constants.

The reply is `{request_id, choice, source: 'jev'|'fallback', confidence, model}`. Fallback has null confidence/model. The caller must compare the echoed request ID with the current game revision before applying a result. Reusing an ID with changed input returns HTTP 409; identical retries share the first result without another API call.

Only the configured loopback Host and Origin are accepted. Bodies are limited to 8 KiB. Per server process: at most 120 upstream requests, 20 per minute, two concurrent requests, and a 250,000 observed-input-token stop threshold. Each call has a 1.5-second hard deadline; cancellation, no key, exhaustion, malformed provider results, and provider errors produce an immediate legal local fallback. The threshold stops later dispatches and is not a prepaid token ceiling. Unknown failed-call usage is counted separately. Static exports and native play retain local behavior when the optional server is unavailable.

## Live experiments and observed failures

Reproduce the fixed 12-case batch with `node tools/party-jev.mjs --experiment`. It makes at most 12 requests, writes exact inputs, model questions, eligible criteria, full probabilities, confidence, model version, selected move, observed outcome and source hashes. Credentials and provider headers are never recorded.

Both batches used `jev-1.13.0`, six poker fixtures and six fictional party replies, sequential requests, a 1.5-second timeout and no retries:

| Measurement | Original encoded-card input | Readable facts and eligible quips |
|---|---:|---:|
| Valid responses / requests | 12 / 12 | 12 / 12 |
| API errors or fallbacks | 0 | 0 |
| Poker choices agreeing with authored strategy expectation | 4 / 6 | 5 / 6 |
| Pass-only quips incorrectly selected for “Never” answers | 3 / 3 | 0 / 3 |
| Input / output tokens | 8,536 / 828 | 8,865 / 776 |
| API latency p50 / p95 | 224 / 715 ms | 200 / 378 ms |

The [initial record](experiments/party-jev/2026-09-24T01-19-16-039Z/summary.json) includes two poor poker choices: breaking four matching ranks and overlooking a four-card flush draw. It also confused answering “Never” with declining to answer. Readable, code-computed facts and a mechanically eligible response set addressed those specific issues in the [follow-up record](experiments/party-jev/2026-09-24T01-20-29-812Z/summary.json). One low-confidence high-card strategy still differed from the authored heuristic. The six follow-up party replies used only two distinct quips, so this sample does **not** demonstrate rich response variety.

The full traces are in each folder's `requests.jsonl`. These are isolated API decision experiments, not live rendered browser playthroughs. The tiny, repeated fixture set is not a poker benchmark; a legal strategy may still be a poor strategy, and a plausible joke may still be repetitive. Godot and browser checks are separate evidence.

`node --test tests/test_party_jev.mjs` passes 22 tests covering validation, secret isolation, service mounting, fallback, timeout, cancellation, stale IDs, complete candidate sets and budgets. The initial HTTP Host test exposed a test-harness issue: Node fetch ignored a custom Host header. The test now uses a real raw HTTP request and verifies rejection of a foreign Host.
