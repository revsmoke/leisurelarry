# Final build: 12-run browser confirmation

**Final: 8/12 evenings completed, with no API or UI dispatch errors.** Two runs stopped without observed progress, one entered a repeated-action cycle and one abstained. This separate follow-up checks the final source corrections after the [100-run campaign](upgrade-100-analysis.md). It must not be pooled into that campaign's completion or performance rates. The final summary was generated at `2026-09-22T03:29:06.580Z`.

Evidence: [batch summary](2026-09-22T03-27-21-767Z/e75098ae-d775-4868-9c4a-b5167c73671c/summary.json), [aggregate](2026-09-22T03-27-21-767Z/e75098ae-d775-4868-9c4a-b5167c73671c/aggregate.json), with exact per-run requests, response distributions and observed UI outcomes in the adjacent `.jsonl.gz` traces.

## Condition

The experiment uses four simultaneous fresh Godot Web instances, 12 runs, 160 actions per run, a 2,000-request hard cap, 12-million observed-input-token threshold and $0.60 estimated-input-cost threshold. Policies rotate objective-led, curious and objective-withheld, four runs each. Persistent observed memory is enabled; candidate-order seed is 43. The runner uses player-visible text, learned clues and real UI callbacks without state injection.

- QA game pack SHA-256: `ab88e50d7cf6c922d000532a6a5d6958e37141950b1fe7a9bafd8b6802f2c38a`.
- Runner SHA-256: `371cdc4cb20e8fe7fcbde3a3d5d9ed39f1974b440c4e2f3f799a71206d4020f7`.

The pack includes the final dialogue feedback, held-knife objective, audio preference, compact viewport and control-label corrections. The seed and build differ from the 100-run campaign, and this is a small sample; any different completion rate is not a controlled estimate of the patches' causal effect.

## Final outcomes and usage

| Policy | Completed / attempted | Non-completions |
| --- | --- | --- |
| Objective-led | 3/4 | One repeated-action cycle |
| Curious | 3/4 | One no-progress stop |
| Objective withheld | 2/4 | One no-progress stop, one abstention |
| Total | 8/12 (66.67%) | Four retained failures |

All **1,006 API requests succeeded** as `jev-1.13.0`; the runner executed **1,005 game actions** and received one abstention. No run reached its 160-action cap. Reported usage was **6,618,076 input tokens** and 413,414 output tokens, with estimated input cost **$0.277959** at $0.042/M input tokens. This was below each configured threshold and involved no retries or intervention to turn failures into wins. The model/request cost estimate is not a provider bill.

## Verification scope

This QA mode intentionally disables music and bypasses save access. Therefore this batch cannot verify audible music persistence or ordinary player saves. Text-driven decisions do not verify visual layout, pointer hitboxes, visual perception or whether the game is fun. Those claims require the separate deterministic/UI tests and ordinary browser playthrough. Browser timing measures the multi-iframe lab, not standalone 1440×960 rendering, and browser JS heap may be shared and exclude total Godot/WASM memory.

## All four non-completions

- **003, objective withheld: 99 actions / 44 points, no progress for 24 actions.** It closed the stage-manager discussion at decisions 36 and 74 despite the available topic; the second call had the corrected non-dismissive text about hearing Didi's setup. It then revisited the receptionist, Lefty and shop clerk without obtaining the knife or following the social introduction. This is the same observed planning weakness as the larger campaign; the new reminder alone did not prevent it.
- **007, objective-led: 47 actions / 28 points, repeated two-action cycle.** It reached Eve with apple seeds, then repeatedly TALKed and closed at actions 42/43, 44/45 and 46/47. The final conversation offered five substantive topics including telling Eve about the night. The detector stopped the chosen repetition; no missing control or failed dispatch appears in the trace.
- **009, objective withheld: 51 actions / 40 points, model abstention.** It closed the first manager topic, collected rope with the knife at action 45, watched the show and skipped to the curtain call, then declined on decision 52 with confidence 0.27. Travel, phone and other interactions remained available. This repeats the model's tendency to treat the second-act payoff as an ending without completing the evening.

- **011, curious: 81 actions / 36 points, no progress for 24 actions.** Eve explained the seed source and newspaper at action 52; the player collected a core and separated seeds by 57. It returned to the roof and used the seeds on Eve, the pool and finally the skyline instead of visiting the garden. The notebook retained the garden/planter lead, and room travel remained available. At 81 the detector stopped the unproductive attempts.

These are retained failures, not game completions. They do not demonstrate a hard-lock in progression, and they also do not establish that the remaining clue presentation is ideal for a new human player.


## Direct evidence for the corrected feedback

The model selected `Use Dance floor` once: run 011, action 39. It now received Didi's actual scene-aware response about remaining props and valid rehearsal/dance topics; it did **not** receive the former generic “no conversational opening” refusal. Across all 1,005 actions, no observation paired that refusal with nonempty dialogue options. `Talk Wall telephone` was not selected in these 12 traces, so that specific path relies on its separate regression/UI checks rather than this model sample.

The updated repeat-call reminder was exercised. Run 003 received it on action 73 but closed the topic and later stalled. Run 012 received it after collecting rope at action 53, chose the manager discussion at 54, obtained the introduction, and completed the evening at 88. These opposite outcomes are useful confirmation that the topic stays available and works; they do not isolate the reminder's causal effect.

No new progression hard-lock or failed action dispatch was established by these four non-completions. The remaining pattern is model difficulty linking clues across locations and choosing substantive conversation topics. It remains appropriate to pursue fresh-player discoverability testing; lowering the stop threshold or counting those traces as successes would conceal the issue.

## Four-worker timings

Across 1,005 executed actions, UI callback p50/p95 was **4/36 ms**, game-side settled-frame feedback **51/89 ms**, and browser acknowledgement **68/109 ms**. API request latency was **216/349 ms**, separately from local feedback. New-iframe readiness was median 349 ms / p95 956 ms, ranging 334–1,260 ms; cache state was not forced cold.

After the two-second per-frame warmup, **15,779/16,620 visible requestAnimationFrame intervals were within 20 ms (94.94%)**. This remains just below the stated 95% target and is not rounded into a pass. It is a concurrent four-iframe result, not a standalone full-resolution performance certification.

Browser JS heap readings ranged from 201,266,249 to 383,947,453 bytes; they may be shared and exclude total Godot/WASM allocation. Engine static-memory monitoring remained unavailable/null. Node server peak RSS was 239,058,944 bytes, excluding browser/game memory. None of these measurements establishes whole-route browser memory stability or human enjoyment.
