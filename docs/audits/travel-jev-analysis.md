# Travel cutscenes: bounded live Jev regression

**Both fresh browser runs completed their evenings with the travel animations enabled.** This is a two-run integration regression, not a population completion estimate, visual review, enjoyment study, or controlled performance benchmark. The runs used real Godot Web UI callbacks and waited for each cinematic to arrive before requesting another decision.

Evidence: [final batch summary](../experiments/jev/2026-09-22T18-27-27-369Z/e47830e9-38ef-432e-840b-2f1e2b5fcc7d/summary.json), [aggregate](../experiments/jev/2026-09-22T18-27-27-369Z/aggregate.json), [objective-led trace](../experiments/jev/2026-09-22T18-27-27-369Z/e47830e9-38ef-432e-840b-2f1e2b5fcc7d/e47830e9-38ef-432e-840b-2f1e2b5fcc7d-001-goal.jsonl.gz), [curious trace](../experiments/jev/2026-09-22T18-27-27-369Z/e47830e9-38ef-432e-840b-2f1e2b5fcc7d/e47830e9-38ef-432e-840b-2f1e2b5fcc7d-002-curious.jsonl.gz). Compressed traces retain every exact input, candidate set, typed answer and probability distribution, model version, selected action, and observed result.

## Fixed condition and build boundary

The batch used two concurrent fresh workers, one objective-led policy and one curious policy, a limit of 160 actions per run, a hard cap of 400 API attempts, an observed-input threshold of 3,000,000 tokens, and a $0.15 estimated-input-cost threshold. Observed player memory was enabled and candidate-order seed was 44. Neither policy was the objective-withheld variant. No walkthrough, hidden quest flags, hint-function output, inventory grants, or automatic retries were supplied.

- Session: `2026-09-22T18-27-27-369Z`.
- Batch: `e47830e9-38ef-432e-840b-2f1e2b5fcc7d`.
- QA pack SHA-256: `fb7f538338b5c567850fbfa580e0d821b37679e57410ec606092a2d67c2b04ad`.
- Runner SHA-256: `371cdc4cb20e8fe7fcbde3a3d5d9ed39f1974b440c4e2f3f799a71206d4020f7`.
- Requested model: `jev-latest`; all 188 responses reported `jev-1.13.0`.
- First decision: `2026-09-22T18:28:00.763Z`; last executed outcome: `2026-09-22T18:30:30.955Z`; final summary: `2026-09-22T18:30:30.959Z`.

The QA bridge now waits for the actual travel component to finish, with an eight-second timeout, before publishing the next observation. It does not automatically skip travel. Its observations remain text-driven; Jev does not see the animation pixels. The normal production game remains offline and does not load the QA bridge.

This pack predates a subsequent visual correction to taxi staging: the taxi's exterior background is now opaque from boarding, and the car disappears before the destination interior appears. An upper-floor direction indicator was also corrected for a rooftop destination. Those later visual changes are covered by the separate final code/browser checks; they are not retroactively part of this batch's measured pack.

## Outcomes and budget

| Policy | Result | Executed actions | In-game moves | Points | Final cash | Ending | Elapsed run time |
| --- | --- | ---: | ---: | ---: | ---: | --- | ---: |
| Objective-led | Completed | 78 | 91 | 48 | $80 | Good Company | 110.929 s |
| Curious | Completed | 110 | 123 | 64 | $63 | The After-Show | 151.595 s |

A map action can traverse several connected rooms, while opening or closing an interface can take no game move; executed UI actions and the game's move counter are deliberately different measures. Both runs used the bowling-promotion, rehearsal, and hotel-introduction routes. Neither attempted the rope/fire-escape route.

The server recorded **188 attempts, 188 successful responses, and 188 executed actions**. Reported usage was **1,300,486 input tokens** and **77,164 output tokens**. Estimated known input cost was **$0.054620412**, using the harness's recorded rate of $0.042 per million input tokens ([model/pricing source](https://docs.typesafe.ai/models)); this is an estimate, not a billing statement. The runs stayed below every configured limit. No request was retried or recorded with unknown usage.

Observed terminal failures were **0/2**; loop/stall stops **0/2**; abstentions **0/2**; API errors **0/188 attempts**; bridge/timeout errors **0/188 actions**. These small-sample results do not establish zero failure risk. Action-choice confidence ranged from 0.10 to 1.00, with an empirical median of 0.60 and p95 of 0.98. Confidence is recorded for auditability and is not treated as correctness or enjoyment.

## Evidence that travel waited for real arrival

There were **48 room-changing actions**: 21 in the objective-led run and 27 in the curious run. Forty-six used a map destination and two used the actual hotel elevator hotspot. All 48 returned the destination's rendered room title and arrival narration with an empty overlay; none returned an unfinished `ON THE MOVE` observation. No run selected a `Skip travel` action. The observed full-duration waits are consistent with the bridge waiting for the real cinematic rather than immediately returning the already-committed model destination.

Classifying those observed routes against the authored transport rules gives two doorway transitions, 26 taxi rides, 17 elevator transitions, and three terrace walks. **Walking and rope vignettes were not exercised by these two model runs**; the component/callback suite and separate browser checks cover those modes.

| Travel-only measurement, n = 48 | Minimum | Median | p95 | Maximum |
| --- | ---: | ---: | ---: | ---: |
| Synchronous UI callback | 31 ms | 40 ms | 43 ms | 45 ms |
| Callback through settled arrival | 3,537 ms | 4,435 ms | 4,455 ms | 4,472 ms |
| Browser action acknowledgement | 3,553 ms | 4,446 ms | 4,470 ms | 4,489 ms |

The multi-second settled time is expected presentation duration, not equivalent to a blocked frame or a slow model request. The 140 actions that did not change rooms had a settled-time median of 51 ms, p95 of 54 ms, and maximum of 1,104 ms; the maximum includes another deliberately animated activity. Quantiles use the existing summarizer's sorted sample index `floor((n - 1) * p)`.

Concrete trace examples:

- Objective-led action 1 selects the visible Lefty's map destination with confidence 0.79, then returns Lefty's arrival description after 3,555 ms settled time. Curious action 1 independently arrives after 3,537 ms.
- Objective-led action 27 selects **Use Penthouse elevator**, confidence 0.66, and returns the penthouse after 4,139 ms. Curious action 51 does the same with confidence 0.34 and a 4,156 ms wait. This covers the hotspot path that had originally bypassed the cinematic and was fixed before export.
- Objective-led action 14 travels from Lefty's to the casino, confidence 0.96, waiting 4,456 ms for the ride. The complete candidate set, preceding room text, and resulting casino controls are retained in its trace.

These timing and text records validate action sequencing and completion. They do not establish visual quality; that requires looking at the game, as done in the separate browser review.

## Imperfect decisions retained

Completion did not mean flawless play. The curious player tried the folding stool on the planter at action 89 and seeds on Eve at action 94, receiving ordinary refusal feedback. It then planted the seeds at action 96, collected the pitcher at action 99, attempted to water with an empty pitcher at action 101, returned to fill it, and completed. These mistakes were neither rewritten nor rescued by granting state. The 48 transitions include repeated visits, so the sample also exercised repeated movie creation and arrival.

No new travel blocker or arrival timeout was observed. With only two policies and two successful runs, this cannot rule out other routes, unusual ordering, platform-specific problems, or player frustration from frequent transitions. Skip and reduced-motion behavior have separate actual-callback regressions; browser review is reported separately.

## Timing conditions and limits

The root assistant was simultaneously inspecting the ordinary browser game. Cache state, browser scheduling, and total machine load were not controlled. Across the workers' final samples, 15,223 of 15,308 visible requestAnimationFrame intervals were at most 20 ms after the harness's two-second warmup (99.44%). This is an observed scheduling measure, not GPU render time or a performance release gate. API latency was 199 ms median and 454 ms p95. Server peak RSS was 193,331,200 bytes and excludes the browser and Godot workers.

This regression establishes that these two bounded text-driven players could finish with the travel movies active and properly sequenced. It does not measure the humor, attractiveness, pacing, visual comprehension, or enjoyment of the cutscenes, nor does it replace fresh adult human playtesting.

Regenerate the aggregate without making any API calls:

```sh
node tools/jev-qa/summarize.mjs docs/experiments/jev/2026-09-22T18-27-27-369Z
```
