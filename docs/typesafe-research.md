# TypeSafe research for Jev game testing

Researched 2026-09-21 America/Detroit (2026-09-22 UTC) against live first-party documentation. The installed [TypeSafe skill](../.agents/skills/typesafe-ai/SKILL.md) was read and applied. This document records capabilities and an experiment design; measured project results belong in the experiment report, not in cookbook claims.

## Recommendation

Use Jev as a **bounded player and semantic reviewer**, with the browser executing its selected actions. Supply only player-observable text, available controls, and that run's prior observations. Keep game rules, counters, action execution, save isolation, and performance measurement in code. This follows TypeSafe's separation between application control and typed judgments. [Building guide](https://docs.typesafe.ai/concepts/how-to-build-with-system-one)

Jev currently accepts **text only**, so it cannot inspect the rendered game, judge animation quality from screenshots, or detect text overlap visually. A Godot Web observation bridge can expose the same words, inventory labels, and controls available to a player. Such a run is a live browser test with an instrumented text observation surface, not a screenshot-only or human playtest. Use screenshot review and fresh human players alongside it. [State](https://docs.typesafe.ai/concepts/state), [Models](https://docs.typesafe.ai/models)

This matters here: the [previous browser audit](audits/browser-playthrough.md) found both semantic defects (misleading objectives, stale conversations) and visual defects (overlap, invisible world reactions). Jev can help identify the former from text; it must not be credited with inspecting the latter.

## Verified API contract

Use `POST https://api.typesafe.ai/v1/systemone`, a Bearer API key, and JSON with `model`, `state`, and a `questions` map. State accepts a string, object, or array. Each question has a type and instructions. Choice criteria map option IDs to descriptions; Score criteria are ordered descriptions; Noul optionally defines true/false criteria. Question IDs are response keys and do not communicate meaning to the model. [HTTP API](https://docs.typesafe.ai/api)

```json
{
  "model": "jev-1.13.0",
  "state": {
    "room": "Lefty's Bar",
    "visible_objective": "The words currently displayed to the player",
    "inventory": [],
    "recent_observations": [],
    "controls": ["Look at Lefty", "Talk to Lefty", "Leave the bar"]
  },
  "questions": {
    "next_action": {
      "type": "choice",
      "instructions": "Choose the next available action for a curious first-time player using only the supplied observations.",
      "criteria": {
        "look_lefty": "Look at Lefty",
        "talk_lefty": "Talk to Lefty",
        "leave_bar": "Leave the bar",
        "stop_unclear": "No supplied action is intelligible from the observations"
      }
    }
  }
}
```

The returned `answers.next_action` contains `type`, `choice`, `probabilities`, and `confidence`. Score returns `score`, `legend`, `probabilities`, and `confidence`; Noul returns `noul` without a confidence field. Top-level `model` identifies the answering version; `usage` contains `input_tokens` and `output_tokens`. Choice permits at most 255 options; Score supports 2–10 levels. Handle 401/422 as configuration or request failures, and back off on 429/529. [HTTP API](https://docs.typesafe.ai/api)

The Node SDK requires Node 20+ and is installed as `@typesafe-ai/sdk`; its `TypeSafeClient.systemOne()` supplies typed results. Direct HTTP is also documented and does not require installing a second client. The JavaScript SDK's documented default retry policy is two retries, initial 500 ms exponential backoff capped at 5 seconds with jitter, and support for `Retry-After`/`retry-after-ms`. Custom runners should explicitly bound attempts and deadlines. [JavaScript SDK](https://docs.typesafe.ai/sdk/javascript), [Retry policy](https://docs.typesafe.ai/sdk/javascript/api/interfaces/RetryPolicy)

## Current model, price, and limits

At retrieval, `jev-latest` and `jev-preview` both resolve to **`jev-1.13.0`**. Pin the version for comparative experiments and log the response's actual model. Current published price is **$0.042 per million input tokens**, with output tokens free. Published throughput limits are **1,200 requests/minute** and **250,000 tokens/second**, explicitly subject to dynamic changes. Requests have a 64k aggregate token budget and a 32k budget for state plus the longest question. These are provider limits, not a guarantee that this account or laptop can sustain that throughput. [Models](https://docs.typesafe.ai/models)

Calculate estimated inference cost from returned input-token usage in code. For scale only, 100 runs × 100 decisions × 4,000 input tokens would be 40 million input tokens, approximately **$1.68** at the published rate. This is a workload illustration, not a measured run or an invoice estimate; retries, account terms, and changed pricing can alter it. Browser memory/CPU may constrain concurrency before API throughput does.

## Applicable cookbooks and patterns

The supplied [console cookbook URL](https://console.typesafe.ai/docs/cookbooks) redirected an unauthenticated request to login. The [public documentation index](https://docs.typesafe.ai/llms.txt) exposes first-party cookbook pages. No dedicated Godot, browser-game player, or game-loop cookbook appeared in that index; the following are adaptations.

| Cookbook or pattern | Verified technique | Application to this game |
| --- | --- | --- |
| [Function calling](https://docs.typesafe.ai/cookbooks/function_calling) | Select a known function and closed-set arguments; optional-argument presence is evaluated separately. | Offer enumerated UI actions or verb/target/item combinations. Code validates the selected ID and executes it. Never ask Jev to invent parser commands or coordinates. |
| [Parallel questions](https://docs.typesafe.ai/cookbooks/parallel_questions) | Evaluate independent questions in one request over shared state. The published example measures both batching strategies repeatedly. | Ask next action, objective clarity, and suspected contradiction together for the same observation. Log request latency/tokens. The example's speed and cost ratios are not predictions for this game. |
| [Speculative fan-out](https://docs.typesafe.ai/patterns/fan-out) | Ask branch questions together, then consume only those relevant to the selected route. | Select a verb and speculative targets in one request when a flat action set gets too large. Each question must explicitly state its premise. Ignore unused answers. |
| [Self-consistency: choices](https://docs.typesafe.ai/cookbooks/consistency_choice_cookbook) | Repeat fixed cases, retain distributions, and report uncertainty/automatic-action coverage separately. | Repeat tricky room observations and reorder candidate options. Measure action flips and loops rather than assuming confidence means correctness. |
| [Self-consistency: nouls](https://docs.typesafe.ai/cookbooks/consistency_noul_cookbook) | Preserve raw yes-probabilities and route uncertain cases for review. | Flag possible stale dialogue or missing motivation without automatically rewriting the story from a borderline result. |
| [Composite scoring](https://docs.typesafe.ai/patterns/composite-scoring) | Score dimensions separately; application code owns weighting. | Keep clue clarity, character agency, comic payoff, and repetition separate. A high comedy score must not compensate for a progression blocker. |
| [Autoresearch feature discovery](https://docs.typesafe.ai/cookbooks/autoresearch_feature_discovery) | Improve questions against labeled development data, reserve held-out cases, and keep raw probabilities. Its implementation uses bounded concurrent requests. | After collecting human judgments, learn which scene signals predict confusion or enjoyment. Do not optimize solely against Jev's own ratings or claim that its score establishes fun. |

Several worked cookbooks use older model versions, including `jev-1.12`. Their architecture is useful; copy the current API contract and use measured results for the pinned current version rather than transplanting historical benchmarks.

## Proposed experiment matrix

These are proposed configurations, not claims of execution.

| Experiment | Purpose | Evidence to retain |
| --- | --- | --- |
| Two independent fresh browser runs with identical starting conditions | Establish that Jev can act through the real browser and expose basic loops. | Build hash, model, observation, action candidates, selected action, probabilities, result text, score changes, screenshot checkpoints, errors. |
| Guided player versus exploration player | Compare current explicit objectives with investigation driven by room/NPC clues. | Completion rate, turns, hint use, repeated actions, newly discovered clues, and distinct routes. Persona is a test condition, not a claim that Jev models human demographics. |
| Candidate-order permutations on frozen observations | Detect selection artifacts and missing options before scaling. | Exact permutations, answer distributions, action agreement, chosen-option validity. |
| 2, then 4, then 8 isolated browser workers | Find local resource limits separately from API limits. | Browser readiness/command latency, frame-time samples, process memory when measurable, load failures, API latency, retry count, token use. |
| At least 100 bounded runs in waves after the pilot | Seek rare state/interaction failures without making every request simultaneous. | Unique state/action coverage, invariant failures, reproducible failing traces, per-run outcome and stop reason. |
| Scene-text variants on a frozen test set | Compare revised clues or dialogue fairly. | Same starts/personas/action policy, human-labeled examples, held-out scores, and differences with uncertainty. |

Keep three evidence tracks distinct: deterministic engine tests establish exact rules; live browser runs exercise loading, input, rendering and persistence; semantic judgments rank suspicious text or action choices. No one track substitutes for the others.

## Player observation and execution design

The current game separates state in `scripts/game_state.gd` from UI callbacks in `scripts/main.gd`, and the local Web server serves `exports/web`. That provides a practical seam for an opt-in test bridge. The bridge should export rendered room/title/objective/narration, inventory labels, visited notes, and visible actionable labels, without exposing flags, undiscovered rooms, future solutions, dependency graphs, or scoring keys.

For each worker, retain its own browser storage and observed history. Give each observation a revision number. Reject an action whose revision is stale or whose option ID no longer exists. Execute via the same UI path used by ordinary play; a state-method-only test should be labeled as an engine test. Keep diagnostics separately so hidden facts can explain failures after a run without informing the model's decisions.

Use a concise recent-observation history plus durable player-discovered clues. Do not upload the entire repository, walkthrough, or complete save state. Supply legitimate unproductive actions as well as useful ones; pruning to only winning actions would conceal the discoverability problem. Include a stop/unclear option. Measure coverage across the supplied candidate set, since a chooser cannot select an omitted interaction. [Choice](https://docs.typesafe.ai/primitives/choice), [State](https://docs.typesafe.ai/concepts/state)

Stop a run on victory, a bounded turn budget, repeated no-progress cycles, a browser failure, or an API budget/deadline. Save the final trace before stopping. Changing a prompt or implementing a deterministic loop escape changes the player policy: report that explicitly rather than treating the new result as an identical repeat.

## Semantic judgments worth trying

- **Clue sufficiency:** Do the observations explain a plausible next step without knowledge of future states? Use a Score with concrete levels from no motivation through a specific motivated action.
- **Dialogue memory:** Does the latest line contradict a completed event visible in this player's history? Use a Noul; review the supporting text before filing a bug.
- **Action feedback:** Does the response acknowledge the attempted action, explain refusal, or communicate a change? Score the text; verify actual state changes deterministically.
- **Character agency:** Does a scene give the other adult character a preference, a boundary, or an initiative beyond receiving items? Rate this separately from flirtatious tone.
- **Comic payoff:** Does a later scene visibly refer back to an earlier setup? Compare the two text excerpts; do not infer audience laughter from a number.
- **Choice quality:** Do offered choices express meaningfully different intentions or approaches? Preserve the actual consequences for a separate deterministic review.

These judgments address the previous audit's specific shortcomings: errands without agency, weak character closure, omniscient objectives, and repeated generic reactions. They can prioritize writing and puzzle changes, while people decide whether the resulting adult comedy is enjoyable.

## Limitations and validation

Jev's published 1.13 limitations include literal interpretation, weak multi-step indirection and arithmetic, distraction from irrelevant context, and unreliable structural identities across separately phrased questions. It does not generate free-form dialogue or explanations. Keep arithmetic and invariants in code, keep questions direct, and use authored text or a separate writing process for content. [Jev 1.13 limitations](https://docs.typesafe.ai/model-jaggedness/jev-1.13)

Choice/Score confidence summarizes the concentration of returned probabilities. It is not a calibrated guarantee that a player will progress or that an editorial judgment is correct. A Noul near 0.5 expresses uncertainty about yes/no, not medium intensity. Calibrate review thresholds on this game's labeled cases; cookbook thresholds are examples. [Confidence](https://docs.typesafe.ai/confidence), [Noul](https://docs.typesafe.ai/primitives/noul)

No documentation establishes a universal action-selection success rate, game-playing ability, human-fun correlation, screenshot capability, or guaranteed account throughput. Those require measurements. Keep `TYPESAFE_API_KEY` in the local/server runner, outside exports and committed artifacts. Test logs should contain request content needed for reproduction and usage, but never authorization headers or credentials.
