# Upgraded game: bounded 100-run browser experiment

**Final: 86 of 100 runs completed the evening.** Six players abstained, six stopped after 24 actions without observed progress, one entered a repeated two-action cycle and one stopped on an HTTP 529 response from TypeSafe. All 100 registered runs reached a terminal result; none exhausted the 160-action allowance. The final summary was generated at `2026-09-22T03:20:33.163Z`. The canceled, contaminated earlier batch is excluded.

Evidence: [batch summary](2026-09-22T03-08-43-757Z/ebe69eac-e40a-436f-af0a-37c6b93753f8/summary.json), [per-run aggregate](2026-09-22T03-08-43-757Z/ebe69eac-e40a-436f-af0a-37c6b93753f8/aggregate.json). The exact candidate lists, observations, response distributions, model versions and executed UI outcomes are retained in the adjacent per-run `.jsonl.gz` files. Action numbers below are one-based executed UI actions; an abstention request makes no game action.

## Fixed experimental condition

Four fresh Godot Web instances ran in waves with 100 registered runs, a 160-action limit per run, 20,000-request hard cap, 80-million observed-input-token threshold and $3 estimated-input-cost threshold. Persistent player-observed memory was enabled; candidate-order seed was 42. Policies rotate objective-led, curious and objective-withheld. The browser uses real UI callbacks; it does not inject inventory or quest flags. The objective-withheld player still receives ordinary dialogue and acquired notebook clues.

- QA game pack SHA-256: `8918a71966d04b7b8f9a894d097a2a3d50aeef64d3de498000d71a30055f23ba`.
- Runner SHA-256: `371cdc4cb20e8fe7fcbde3a3d5d9ed39f1974b440c4e2f3f799a71206d4020f7`.
- Observed responses in the analyzed failures: `jev-1.13.0` (requested alias `jev-latest`).

This is the clean batch after correcting dashboard teardown, with four configured workers and no retained workers from the previous eight-worker pilot. The canceled contaminated attempt remains separately documented and is not pooled here. Later source fixes to the held-knife objective and audio preference UI are not retroactively part of this pack's measured results.

## Final measured outcomes

| Policy | Completed / runs | Completion | Other outcomes |
| --- | --- | --- | --- |
| Objective-led | 33 / 34 | 97.06% | 1 provider HTTP error |
| Curious | 32 / 33 | 96.97% | 1 repeated-action cycle |
| Objective withheld | 21 / 33 | 63.64% | 6 abstentions, 6 no-progress stops |
| Total | 86 / 100 | 86.00% | 14 non-completions |

The server dispatched **8,934 attempts**, retained **8,933 successful model responses**, and observed **8,927 executed game actions**. The six-response difference is the six abstentions. Reported usage was 59,834,619 input tokens and 3,759,330 output tokens; estimated known input cost was **$2.513054** at $0.042/M input tokens. The failed request's usage is unknown, so the estimate is not a bill or a guaranteed total. No automatic retry, item grant, state injection or outcome relabeling rescued it. All returned model versions were `jev-1.13.0`. The first retained decision to last outcome spanned about 11.50 minutes, excluding initial page startup.

The overall loop/stall-stop rate was 7/100; abstention rate 6/100; provider-error stop rate 1/100. The observed provider-error frequency was 1/8,934 attempts. These are measured sample proportions under this condition, not general reliability guarantees.

## Review of the 12 objective-withheld non-successful runs

All 12 failures in this group were objective-withheld. None exhausted the 160-action budget or reported a failed bridge dispatch. The most consistent decision pattern was **closing a valid phone conversation instead of choosing its remaining topic**. Every one of these runs was offered `Discuss Didi's show with the stage manager`; all 18 occurrences across their traces selected the close control. The first phone call explicitly said that discussing the setup could obtain a hotel introduction. The topic and its descriptive lead were available to the model; the adapter did not hide a required action.

| Run suffix | Actions / points | Stop | Main observed pattern |
| --- | --- | --- | --- |
| 009 | 68 / 40 | Abstained, confidence 0.17 | Took the rope, finished the show, repeatedly returned to Didi, then stopped without visiting the hotel or backroom. |
| 015 | 58 / 40 | Abstained, confidence 0.13 | Took the rope, inspected the spent rope hotspot again, then repeated the after-show conversation. |
| 018 | 101 / 36 | No progress for 24 actions | Obtained a knife but did not return to cut the disco rope; looped through coffee/voucher conversations. |
| 021 | 61 / 40 | Abstained, confidence 0.22 | Took the rope, toggled pocket tidying, and repeated Didi's exhausted main greeting. |
| 039 | 56 / 40 | Abstained, confidence 0.11 | Took the rope and finished the show; repeated the after-show topic and greeting. |
| 051 | 92 / 32 | No progress for 24 actions | Used mallet/newspaper on rope, then repeated shop/hotel/bar conversations without obtaining the knife. |
| 054 | 56 / 40 | Abstained, confidence 0.18 | Took the rope and called again; closed the still-available manager topic and stopped. |
| 060 | 73 / 32 | No progress for 24 actions | Left the first phone topic, then followed the coffee lead only as far as repeated shop/hotel/bar visits. |
| 066 | 129 / 48 | No progress for 24 actions | Obtained the knife at action 105, applied it to the safety railing twice, never returned to cut the disco rope. |
| 072 | 100 / 36 | No progress for 24 actions | Reached the rope and understood the need for a cutting tool, but continued trying newspaper and mallet. |
| 081 | 59 / 40 | Abstained, confidence 0.28 | Took the rope and finished the show, then repeated Didi's greeting and stopped. |
| 084 | 111 / 40 | No progress for 24 actions | Obtained and examined the knife, then looped through the coffee lead without cutting the rope or pursuing the manager introduction. |

Each suffix identifies `ebe69eac-e40a-436f-af0a-37c6b93753f8-NNN-unguided.jsonl.gz` in the evidence folder. All six abstentions had low confidence (0.11–0.28), with only 0.13–0.30 probability on the selected decline candidate. Those distributions show uncertainty; they do not establish that no legal progress remained.

### Model planning failures with exact examples

In run 009, action 32 calls the stage manager. Decision 33 has the explicit hotel-introduction lead, the manager discussion button, and both visible exit controls. Jev selects × with confidence 0.47. It later cuts and collects the rope at action 51, finishes the cabaret and circles back to Didi. The hotel map destination was present in 49 decision requests, but the player never visited it. The missing connection was choosing an available new lead, not a blocked destination.

In run 054, a second call at action 55 still exposes the manager discussion topic. Decision 56 closes it with confidence 0.35, followed by abstention. The latest phone reply emphasizes the already-collected rope, but the unresolved topic remains visible. In run 066, the player gets a knife at action 105 after earlier rope text explicitly asked for one. It instead uses the knife on the safety railing at actions 107 and 120. Both return the ordinary failure reply; neither changes inventory. It does not revisit the disco before the stall stop.

The bounded strategy judgment did not cure these errors. In the six abstaining traces, the final three strategic choices repeatedly favored `conclude`; run 081's penultimate strategy had confidence 0.80 even though `completed` remained false and the hotel had not been visited. This is useful evidence for a future controlled planner comparison, not evidence that a stronger-sounding strategy judgment improves gameplay. A future driver experiment could retain explicit unresolved observed topics and encourage testing an unused lead before declaring review, without supplying source-derived solutions.

### Reproducible game feedback defects

**Valid conversations can open with an incorrect refusal.** `Use Dance floor` opens Didi's actual dance/show options while the lead text says “It offers no conversational opening. Larry recognizes the feeling.” This appears in run 009 action 67, 018 action 43, 051 action 65 and 081 action 55. Run 081 still receives `Continue Didi's performance` and `Skip to the curtain call`; selecting the latter at 56 succeeds. Similarly, run 084 action 51 uses `Talk Wall telephone`, gets the same generic refusal, and nevertheless receives the valid manager discussion topic. These are repeatable mismatches between game feedback and actual options, not execution dead ends. They were reported for a final source correction; this experiment's raw observations remain unchanged.

**Repeat phone text weakens the hotel route's signposting.** First-call text explains the introduction, but later calls after collecting the rope sound like a dismissal. Run 054 action 55 says the manager has a show to run while a useful unresolved topic remains available. This is a clarity improvement opportunity, distinct from the model's demonstrated decision to ignore the initially explicit offer. Naming the remaining topic around its purpose, or reminding the player about the introduction on repeat calls, could improve discoverability without advancing state automatically.

**A second act can feel like an ending before the evening is complete.** The six abstaining players all complete Didi's show and have the rope, then repeatedly ask about her after-show gathering. Their current text celebrates completed help, while getting to Eve still requires another lead. A short character-specific reminder toward the hotel introduction or the backstage rope use may help. It should be tested with fresh people; these related model runs do not prove human confusion or enjoyment.

## Two additional non-completions

**[Run 092, curious](2026-09-22T03-08-43-757Z/ebe69eac-e40a-436f-af0a-37c6b93753f8/ebe69eac-e40a-436f-af0a-37c6b93753f8-092-curious.jsonl.gz): a model conversation loop.** It reached Eve at the rooftop and held apple seeds, but attempted seeds on the pool and inspected scenery instead of following through on the apple request. At actions 42/43, 44/45 and 46/47 it alternated TALK Eve and close. The dialogue still had a valid `Tell Eve what actually happened tonight` topic. Choice confidence on the final TALK/close pair was 0.12/0.22. The deterministic detector stopped at action 47, score 28, with a two-action cycle and 14 actions since the last novel observed fact. This is a chosen loop, not an unavailable topic or a bridge failure.

**[Run 094, objective-led](2026-09-22T03-08-43-757Z/ebe69eac-e40a-436f-af0a-37c6b93753f8/ebe69eac-e40a-436f-af0a-37c6b93753f8-094-goal.jsonl.gz): provider failure, cause beyond the status is unknown.** After 46 executed actions and 28 points, its 47th decision request received `TypeSafe HTTP 529` at `2026-09-22T03:19:45.029Z`. The exact input and `usageUnknown: true` error are preserved in its trace. The player had reached Eve, learned about the garden, obtained seeds, and just collected the newspaper. No corresponding action was dispatched because there was no valid model response. It is inappropriate to count this as a game dead end, a model abstention, or a successful completion. The harness deliberately stopped without retrying; the status alone does not identify the provider's underlying failure.

## Four-worker browser timing and memory

| Measurement | Median | p95 | Scope |
| --- | --- | --- | --- |
| Godot UI callback | 4 ms | 36 ms | Synchronous real callback |
| Callback through settled frames | 52 ms | 90 ms | Game-side feedback interval |
| Browser action acknowledgement | 68 ms | 112 ms | Dispatch through settled-frame reply |
| API request | 195 ms | 282 ms | Includes provider/network time |
| Dashboard decision HTTP round trip | 203 ms | 315 ms | Server wrapper plus provider/network time |
| New iframe ready time | 380 ms | 517 ms | Cache state not forced cold |

Callback, settled-frame and acknowledgement percentiles combine all 8,927 executed actions; API percentiles combine 8,933 successful requests. The slowest settled-frame response was 1,119 ms and acknowledgement 1,137 ms. New-iframe ready times ranged from 359 to 1,356 ms. These are empirical order-statistic percentiles, not estimates of input-to-photon or GPU rendering time.

After each iframe's two-second warmup, **126,237 of 134,473 visible requestAnimationFrame intervals were within 20 ms: 93.88%**. Per-run p95 histogram upper bounds ranged from 19 to 34 ms. All recorded outcomes reported a visible document. This four-worker batch **does not meet the proposed ≥95% frame-interval target**; the earlier shorter four-worker pilot's better result must not substitute for it. The 90-ms p95 settled-frame interval and 112-ms p95 end-to-end acknowledgement also have different scopes; neither should be silently substituted for a blanket performance pass. Concurrent small dashboard iframes are not the proposed standalone 1440×960 reference playthrough.

Browser-reported JS heap samples ranged from 185,330,746 to 508,939,595 bytes (median 308,087,795). These readings may be shared across frames and omit total Godot/WASM allocation, so they cannot be summed per worker or treated as a leak assessment. The Web engine's static-memory monitor was unavailable for all actions and is represented as null. Node server peak RSS was 286,736,384 bytes; it excludes browser/Godot memory. The separate [native scene lifecycle test](native-memory-lifecycle.json) measured +2.70% static-memory growth over ten warmed create/reset/free cycles; it does not satisfy a whole-route browser memory gate.

## Interpretation limits

The 100 runs share one model version and three related prompts; shuffled candidate order and fresh sessions do not make them 100 independent human subjects. Successful UI callbacks do not exercise visual perception, pointer hitboxes or accessibility. Repeated text-driven completion is useful route evidence, but it cannot establish humor, consent comprehension, enjoyment or the desired “award-winning” quality. Confidence is retained as model output, never a correctness score.

The batch is complete and the figures above are final for its recorded hashes. Later source corrections require their own fresh-build verification; no game, prompt or runner change was inserted into this fixed batch to rescue individual failures. The earlier 2/4/8 pilots, critic calibration and canceled batch remain separate experiments with their own costs and conditions.
