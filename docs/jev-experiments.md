# Jev gameplay experiments — 21 September 2026

**Result:** Jev can drive real Godot Web instances cheaply and find useful failure cases, but these pilots do not establish an autonomous completion tester or a judge of fun. Six live runs performed **480 game actions**, three instances at a time. **None completed within its 80-action budget.** Persistent observed-room memory improved two players and worsened the third. The best run visited all 13 rooms and scored 76/100.

The integration, traces, research, and [gameplay upgrade plan](gameplay-upgrade-plan.md) are ready for further development. Gameplay content was kept unchanged between these conditions. New story branches in the plan are proposals, not implemented features.

## Setup and evidence boundary

Installed exactly once using `npx skills add typesafe-ai/skills --skill typesafe-ai --agent codex --yes`; Codex received the project-local skill at `.agents/skills/typesafe-ai/`. `AGENTS.md` preserves that workflow. The local `.env` had `TYPESAFE_API_KY`; its name was corrected to `TYPESAFE_API_KEY` without printing the value. The key is ignored by Git, excluded from exports and loaded only in the Node server.

The model actually returned **jev-1.13.0**, via the documented `jev-latest` alias. Jev is text-only. It received displayed room/dialogue/objective text, inventory names, acquired notebook clues, visible hotspots, map availability, and a closed list of executable UI actions. No walkthrough, hidden flags, dependency graph, future solution or state injection was supplied. Available map entries and clues were exposed together for convenience; this is an instrumented player, not a simulation of a human's visual attention. [TypeSafe state contract](https://docs.typesafe.ai/concepts/state), [Choice contract](https://docs.typesafe.ai/primitives/choice)

The browser loaded three isolated copies of the dedicated Godot Web QA export. Jev selected candidate IDs; the bridge executed real toolbar/hotspot/inventory/map/modal callbacks and acknowledged settled rendered frames. This tests live Web runtime behavior, but bypasses physical pointer hitboxes and does not prove visual correctness. Normal Web/native builds cannot activate the bridge. QA sessions never read or write player saves and remain silent. Screenshots were observed through the Browser tool; Jev did not receive them.

- [First batch screenshot](experiments/jev/baseline-browser.jpg)
- [Memory batch screenshot](experiments/jev/memory-browser.jpg)
- [Machine-readable comparison](experiments/jev/comparison.json)
- [Game/export/harness hashes](experiments/jev/build.json)
- [Run instructions and limits](../tools/jev-qa/README.md)

## Experiments actually run

A six-request calibration repeated two simple local-action fixtures three times. All six selected the expected action. This tests the API contract on easy examples, not six independent scenarios or a game's complete route. [Calibration evidence](experiments/jev/calibration.json)

Each live condition used one run of each policy, with 80 actions per run. Condition A supplied current text and the last 12 outcomes. Condition B added previously observed room/hotspot labels and the latest five distinct dialogue lines per visited room, plus an instruction to consult that memory. No solution was added. The second condition also hardened response validation, stop handling and result persistence; no error/abstention occurred that exercised those differences. This is an exploratory comparison, not a statistically established causal effect.

| Player | Recent history only | Observed-room memory | Main result |
| --- | --- | --- | --- |
| Objective-led | 36/100; 6 rooms after actions | 64/100; 8 rooms after actions | Better progress with memory; still spent many actions revisiting rooms. Initial street is omitted from this after-action room count when the first action immediately left it. |
| Curious | 44/100; 9 rooms | 76/100; all 13 rooms | Unique actions rose from 44 to 58; longest no-score stretch fell from 26 to 11. Useful clues can be non-scoring, so this is only a diagnostic. |
| Objective withheld | 28/100; 7 rooms | 16/100; 5 rooms | More context did not consistently improve planning. Became stuck around the bouncer/password. |

All six stopped at their action budget; none crashed, timed out, chose an unsupported action, or completed. This does not prove a hard progression blocker: the prior informed Browser playthroughs completed the game, and the bridge's separate deterministic route test also completes it. The Jev policy, memory, candidate selection and budget are part of the measured system.

Raw evidence: [condition A summary](experiments/jev/2026-09-22T02-15-53-649Z/summary.json), [A decisions](experiments/jev/2026-09-22T02-15-53-649Z/decisions.jsonl), [A outcomes](experiments/jev/2026-09-22T02-15-53-649Z/events.jsonl); [condition B summary](experiments/jev/2026-09-22T02-19-26-417Z/summary.json), [B decisions](experiments/jev/2026-09-22T02-19-26-417Z/decisions.jsonl), [B outcomes](experiments/jev/2026-09-22T02-19-26-417Z/events.jsonl). Recompute the comparison with `node tools/jev-qa/summarize.mjs`.

## What this found in the game and in the tester

1. **Confirmed game dialogue defect:** when the remote tunes the television before the password is learned, the bouncer still asks someone to find the remote. He should acknowledge bowling and ask only for the missing password. This occurred in all three first-condition policies. The [upgrade plan](gameplay-upgrade-plan.md) identifies exact trace lines and the state-order regression to add.
2. **Stale subgoal guidance:** after dancing, the objective still tells Larry to meet Didi and dance instead of naming the outstanding ring/flowers. Update the displayed task by remaining subgoal. This does not fully explain the AI's failures, but it needlessly weakens guidance.
3. **Persistent clue/location memory is useful:** the first objective-led player selected shop travel and disco travel 27 times each. Remembering discovered item locations reduced the loop and improved two runs. A notebook linking player-observed props to locations could help real players too; it still needs a novice test.
4. **Literal action selection needs a planner:** players tried applying the newspaper to the planter after reading its instructions. They also tried unrelated held objects on the railing. These are model choices, not proof that the game's stated seed/water rule is broken. A next-step system should separate identifying the immediate need, retrieving acquired evidence, choosing a local action, and checking its result.
5. **The model critic is insufficiently calibrated:** for four observations containing the obsolete bouncer line and its contradictory earlier TV action, Noul contradiction probabilities were 0.21, 0.51, 0.34 and 0.40. A hypothetical 0.5 cutoff catches only one of those four observations of the same defect. During the first objective-led player's long travel loop, mean clarity remained 2.40/3. Clear-sounding text is not the same as a useful new lead, and neither is enjoyment.
6. **The harness needs cycle detection beyond identical states:** current protection stops four identical observations. Alternating rooms changes narration, so those cycles survive until the action cap. Detect repeated room/action sequences with no new inventory, milestone or learned clue, then save the failure and stop or explicitly escalate. Do not silently insert winning actions and call the resulting run unaided.

## Performance, reliability and cost

| Metric | Condition A | Condition B |
| --- | --- | --- |
| Live API requests | 240 | 240 |
| Reported API failures | 0 | 0 |
| Input tokens | 905,027 | 1,154,456 |
| API latency p50 / p95 | 177 / 251 ms | 177 / 239 ms |
| Per-player render acknowledgement p50 | 71–83 ms | 71–79 ms |
| Per-player render acknowledgement p95 | 109–120 ms | 104–126 ms |
| Sampled median Godot FPS per instance | 55 | 55–56 |

Measurements came from three concurrently visible IAB instances on this Apple M4 Pro Mac. API duration includes network overhead. Render acknowledgement excludes inference and starts at action dispatch; it is not an input-to-photon benchmark. FPS is a coarse sample taken at actions, not a frame-time distribution, and browser throttling, debug/instrumentation overhead and viewport affect it. This pilot does not establish mobile performance, eight-worker capacity, leak freedom, or a sustained frame-rate target.

Including calibration: **486 requests, 2,064,460 input tokens**, approximately **$0.0867** at the published $0.042/million-input-token rate with free output. This is a price-based estimate, not an account billing receipt. [TypeSafe model/pricing documentation](https://docs.typesafe.ai/models)

No network retries were used. Limits were three in-flight calls, 300 attempted requests per server session, 80 actions per player, and a 2M observed-input-token threshold per session. Observed usage is not a hard spending cap: in-flight or ambiguously failed requests can exceed or escape accounting. The retained traces include the complete response distributions, not just labels.

## Best use of Jev in this project

Use Jev as a fast, bounded decision component inside a test runner whose execution, isolation, budgets, arithmetic and invariants remain ordinary code. Its strongest demonstrated role is selecting a local action from clear evidence. Preserve full observations and uncertain alternatives so a stronger planning/review process can diagnose a stall. Do not presently rely on it alone to certify a full game completion, a contradiction-free script or good comedy.

The [researched cookbook mapping](typesafe-research.md) identifies **Function calling** for action routing, **Parallel questions** for independent judgments over shared state, **Self-consistency choices** for repeatability, **Composite scoring** for separate editorial dimensions, and **Autoresearch feature discovery** for later labeled evaluation. No dedicated Godot gameplay cookbook was found. Their published examples are design patterns, not performance promises for this game.

Next, implement the first phase of the [upgrade plan](gameplay-upgrade-plan.md): state-correct dialogue, explicit remaining subgoals, durable discovered leads and predictable item controls. Add labeled examples for the critic and a deterministic cycle detector. Then measure 2/4/8 worker capacity before running 100 bounded sessions in waves. Use real fresh players to judge whether the revised choices, cabaret scene and rooftop conversations are funny and satisfying.

## Validation performed for the integration

- Nine Node client tests: malformed responses, invalid/duplicate candidates, 255-option boundary, missing judge answers, unknown profile, objective withholding, and no automatic retry on provider failure.
- 179 Godot bridge assertions, including a deterministic complete route, stale/unsupported requests, normal-build gating and save isolation.
- 182 existing interface assertions and 39 action-intent assertions rerun after integration.
- Read-only local-server checks denied `.env`, source-file access, traversal and unauthorized inference requests.
- The local `.env` was never logged or committed. Git/export checks accompany the commit.

These are separate evidence tracks. Passing a deterministic route is not one of the six Jev runs completing, and an agent's earlier Browser audit is not a study with human participants.
