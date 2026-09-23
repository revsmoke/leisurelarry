# Camp update: four live Jev players

**In the initial batch, three of four fresh Web players reached the new Eve finale. The fourth completed Velvet's optional fling, then stopped after 24 actions without observed progress toward hotel access.** All four independently selected heterosexual Larry in the visible character setup. A subsequent two-run check stopped during setup; a third batch with the setup instruction restored completed 2/2. All three build boundaries and the unsuccessful runs are documented below. The initial batch therefore tests that profile only; it does not establish live model coverage for Lisa, homosexual play, or the bisexual default.

This was a bounded text-driven gameplay experiment using real Godot Web controls, not a simulated model route, visual-perception test, or human enjoyment study. No items or quest flags were granted to rescue a run. Both success and failure remain in the artifacts.

## Evidence and build boundary

- [Final batch summary](../experiments/jev/2026-09-23T03-43-28-452Z/76ef6d98-817c-41df-b1a1-516dea8604e9/summary.json)
- [Run 001: objective-led](../experiments/jev/2026-09-23T03-43-28-452Z/76ef6d98-817c-41df-b1a1-516dea8604e9/76ef6d98-817c-41df-b1a1-516dea8604e9-001-goal.jsonl.gz)
- [Run 002: curious](../experiments/jev/2026-09-23T03-43-28-452Z/76ef6d98-817c-41df-b1a1-516dea8604e9/76ef6d98-817c-41df-b1a1-516dea8604e9-002-curious.jsonl.gz)
- [Run 003: objective withheld](../experiments/jev/2026-09-23T03-43-28-452Z/76ef6d98-817c-41df-b1a1-516dea8604e9/76ef6d98-817c-41df-b1a1-516dea8604e9-003-unguided.jsonl.gz)
- [Run 004: objective-led](../experiments/jev/2026-09-23T03-43-28-452Z/76ef6d98-817c-41df-b1a1-516dea8604e9/76ef6d98-817c-41df-b1a1-516dea8604e9-004-goal.jsonl.gz)

The compressed traces retain exact model input, candidate set, selected action, confidence and full probability distribution, reported model version, and the observed UI outcome. Each trace also includes a terminal outcome without `lastAction`; it is not counted as an extra executed action in this report.

| Reproducibility field | Recorded value |
| --- | --- |
| Session | `2026-09-23T03-43-28-452Z` |
| Batch | `76ef6d98-817c-41df-b1a1-516dea8604e9` |
| QA pack SHA-256 | `2f198143da9978a2ff266b7694ee9f77605f3fff1886b56545a851320afc0ff1` |
| Runner SHA-256 | `371cdc4cb20e8fe7fcbde3a3d5d9ed39f1974b440c4e2f3f799a71206d4020f7` |
| Model requested / returned | `jev-latest` / `jev-1.13.0` on all 432 responses |
| Workers / runs | 4 concurrent fresh workers / 4 runs |
| Budget | 160 actions per run; 800 API attempts; 6,000,000 observed input tokens; $0.30 estimated input-cost threshold |
| Policy | Two objective-led, one curious, one objective-withheld |
| Memory / candidate seed | Observed player memory enabled / 69 |
| First decision / final summary | `2026-09-23T03:43:51.614Z` / `2026-09-23T03:47:03.140Z` |

The objective-withheld policy removed the objective from model-visible state and recent-action summaries; it still received descriptions, dialogue, notebook discoveries, observed memory, and normal visible choices. It was not deprived of the game's spoken initial goal. No hidden flags, walkthrough, source-derived solution, or hint-function output appeared in the model's gameplay state.

**This pack predates subsequent fixes.** The run exposed two misleading state-dependent replies, described below and corrected afterward. Root's separate live browser review also found character-setup copy clipping to correct afterward. Later exports and tests must be identified separately; this batch must not be presented as having played those later binaries.

## Results and actual coverage

| Run | Profile selected | Outcome | UI actions | Points | Cash | Optional content observed | Elapsed run time |
| --- | --- | --- | ---: | ---: | ---: | --- | ---: |
| 001, objective-led | Larry, heterosexual | Eve finale | 82 | 48 | $80 | Solved Flora's lighting puzzle; left flirtation optional | 113.068 s |
| 002, curious | Larry, heterosexual | Eve finale | 152 | 68 | $58 | Solved Ruby's card and Flora's lighting puzzles; no optional fling | 192.949 s |
| 003, objective withheld | Larry, heterosexual | Stopped: no observed progress | 110 | 40 | $70 | Solved Velvet's latch and accepted a private fling | 154.801 s |
| 004, objective-led | Larry, heterosexual | Eve finale | 88 | 48 | $80 | Solved Flora's lighting puzzle; left flirtation optional | 114.585 s |

Every setup sequence was `Play as Larry` → `Heterosexual` → `Get lucky as Larry`. The players changed the default bisexual selection themselves; the runner did not assign these profiles. Eve and the optional female partners were therefore correct for the selected orientation. Coverage of the other five profiles belongs to the separate deterministic suite and separately reported browser checks, not to these four runs.

Completion was **3/4 (75%) in this sample**. The objective-led/curious subset was 3/3; the objective-withheld subset was 0/1. One policy instance does not establish a causal effect of the objective panel or a population completion rate. The batch stopped one run for lack of progress, rather than allowing indefinite wandering. There were no action-budget stops, abstentions, API errors, bridge errors, or cinematic timeouts.

All three successful runs used the bowling-promotion, volunteer-rehearsal, and stage-manager hotel-introduction route. The curious player also explored some prop and wine exchanges. This batch did not finish the rope/fire-escape route, Ruby's or Flora's optional encounter, a decline/reopen invitation, or the friendship/after-party branches.

## Optional encounter worked without satisfying the main goal

The objective-withheld run supplied a useful real-runtime check:

1. At action 58 it guessed the rhinestone latch before examining the clue (choice confidence 0.26). The game refused to solve it and pointed to the dressing-screen tag.
2. It examined the tag at action 61, talked again, and solved the latch at 63 (confidence 0.70). The fix alone did not trigger intimacy.
3. It explicitly chose the flirtation at 68 (confidence 0.44), received Velvet's invitation, and accepted at 69 (confidence 0.42).
4. The browser acknowledgement arrived after 5,487 ms; the bridge recorded 5,471 ms through the settled scene. The resulting narration named Velvet, described the comic aftermath, and reiterated that Eve remained the final goal. Completion remained false.
5. Later visits to Velvet at actions 86 and 101 recalled the completed detour; the game did not offer or award a repeat encounter.

The three Eve acceptances likewise waited for their actual cinematic and returned `A LITTLE LATER…` with the new finale text and completion true. Settled times were 5,438, 5,453, and 5,455 ms. No player selected a skip action. These records verify sequencing and state; they do not verify the scene's appearance or whether its joke lands.

## Why run 003 stalled, and what was actually wrong

At action 33 the player called the stage manager successfully. The outcome explicitly offered **Discuss Didi's show with the stage manager**, and the reply mentioned asking about the show's setup for a hotel introduction. At 34 the model closed that conversation instead (confidence 0.47, with four available choices). It then tried taking the still-bound rope, tried a newspaper on it, and later followed the coffee-voucher lead without acquiring a knife or revisiting the manager's discussion.

After the Velvet detour, it repeatedly visited Lefty's, the shop, the hotel, and backstage. Its last 24 actions added no observed progress. It retained the newspaper, disco pass, and TV remote, with $70; the stage-manager route and the wine-for-knife route remained available. The trace shows a planning failure and a guidance weakness, **not a deterministic deadlock or a requirement to restart**. Repeating already-completed conversations and closing the actionable manager topic were model choices. That does not mean the game's feedback was flawless:

- **Action 35, genuine stale prerequisite reply:** after the phone call, `Take Spare stage rope` still said to call the stage manager, then find a cutting tool. The call was already complete. The later fix now acknowledges clearance and asks only for the missing small knife.
- **Action 53, genuine alternate-route contradiction:** the player already had Lefty's social backstage approval. Turning on the bowling broadcast nevertheless said to provide the password. The gate itself stayed open, and the bouncer correctly acknowledged Lefty's approval on the next action. The later fix makes the TV reply recognize existing social access.

Both fixes change feedback only, preserving gates, costs and rewards. Twelve new assertions cover these states across the six profiles; the updated identity/romance suite passed **879 assertions**, and the narrative suite passed **57** after these fixes. Those are deterministic post-fix checks, not retroactive results for this batch's pack.

Other retained mistakes were recoverable. The objective-led players tried newspaper on the high cabinet and attempted to water with an empty pitcher; the game preserved their items, provided the stool/sink lead, and they recovered. The curious player spent 152 of its 160 available actions, so its successful completion still showed inefficient exploration and little budget headroom.

Jev's ratings must not conceal these problems. During the stalled run's final 24 actions, its self-rated clarity had a median of 2.70/3, while action-choice confidence ranged from 0.12 to 0.92. A confident action or high clarity score did not establish useful progress.

## Usage, timing, and limits

The server recorded **432 API attempts, 432 successful responses, and 432 executed actions**, with zero automatic retries. Reported usage was **3,072,056 input tokens** and **182,026 output tokens**. The harness estimated **$0.129026352 of input cost**, below its $0.30 threshold; this is the recorded estimate, not a billing statement or a provider-enforced spending cap. Concurrent observed-usage thresholds can overshoot; no such threshold ended this batch.

Choice confidence over all 432 decisions ranged from 0.10 to 1.00, with median 0.52 and p95 0.98. Raw distributions remain in the traces and are not treated as proof of correctness or enjoyment.

There were **96 room-changing UI actions**: 19, 32, 26, and 19 by run. Travel's settled-time range was 3,531–4,471 ms, median 4,436 ms and p95 4,459 ms, consistent with deliberately animated travel rather than an immediate hidden room switch. API latency, including network, was 245 ms median and 349 ms p95. Quantiles use sorted sample index `floor((n - 1) * p)`.

Root was playing the ordinary browser build concurrently. Cache conditions, browser scheduling, and machine load were not controlled. Across the final worker snapshots, 33,075 of 33,398 visible requestAnimationFrame intervals were at most 20 ms after the harness warmup (99.03%). This measures browser scheduling, not GPU frame cost or a performance release gate. Server peak RSS was 210,288,640 bytes and excludes the browser/Godot workers.

The practical result is a functioning new finale and an optional encounter through live UI callbacks, one preserved incomplete run, and two concrete feedback fixes. It does not establish visual quality, balanced appeal across orientations, human enjoyment, or that the game is universally easy to finish. A separately identified post-fix campaign and broader profile sampling are needed before claiming those runtime cases have been covered.

## Post-fix two-run check: both players abstained during setup

A separate check on the corrected pack **did not validate gameplay**: each player clicked the already-selected Larry card once, then returned the harness's stop choice on its second decision. These unsuccessful runs are retained; they do not replace or extend the earlier three completions.

- [Post-fix final summary](../experiments/jev/2026-09-23T03-51-36-547Z/4abb8608-32e6-441b-99f1-bc26d7830127/summary.json)
- [Post-fix objective-led trace](../experiments/jev/2026-09-23T03-51-36-547Z/4abb8608-32e6-441b-99f1-bc26d7830127/4abb8608-32e6-441b-99f1-bc26d7830127-001-goal.jsonl.gz)
- [Post-fix curious trace](../experiments/jev/2026-09-23T03-51-36-547Z/4abb8608-32e6-441b-99f1-bc26d7830127/4abb8608-32e6-441b-99f1-bc26d7830127-002-curious.jsonl.gz)

| Field | Recorded value |
| --- | --- |
| Session / batch | `2026-09-23T03-51-36-547Z` / `4abb8608-32e6-441b-99f1-bc26d7830127` |
| QA pack SHA-256 | `e959025d54596d423a534b545e8f89c543d3b292c92804d4efbf0708784d0841` |
| Runner | Same `371cdc4c…d4020f7` hash as the first batch |
| Policies / seed / concurrency | Objective-led + curious / 70 / 2 workers |
| Limits | 160 actions each; 400 attempts; 3,000,000 observed input tokens; $0.15 estimated input-cost threshold |
| Actual result | 0/2 completed; 2/2 model abstentions; 1 UI action each; no travel or encounters |
| API usage | 4 valid responses from `jev-1.13.0`; 8,642 input and 724 output tokens; zero recorded errors |
| Estimated input cost | $0.000362964 |
| Per-run elapsed time | 1.247 s / 1.246 s; each first click acknowledged in 58 ms |

This is **an ordinary typed action selection, not an observed API refusal, malformed schema, or bridge failure**. The model chose the declared `decline` value. The dashboard deliberately stops a run on that choice (`tools/jev-qa/dashboard.js`), so the absence of a second UI action is expected harness behavior. Neither trace contains a provider content-filter reason; attributing these stops to such a policy would be speculation.

The choice distributions show uncertainty rather than a unanimous finding that no action was possible:

| Second decision | Returned choice | Reported confidence | P(stop) | P(heterosexual selection) | P(start current Larry evening) |
| --- | --- | ---: | ---: | ---: | ---: |
| Objective-led | `decline` | 0.22 | 0.33 | 0.24 | 0.17 |
| Curious | `decline` | 0.26 | 0.36 | 0.22 | 0.18 |

All seven candidate IDs and labels matched the corresponding earlier setup decision, including the valid `Get lucky as Larry` button. Question schemas and instructions also matched. The state still showed the setup overlay; selecting an already-selected character had correctly left Larry/bisexual selected. Neither player pressed Start, so these are not completed profile-selection or bisexual-gameplay tests.

The inputs did change in several ways: candidate ordering used seed 70 instead of 69; the setup's clipped instruction sentence had been removed; the adult summary had been shortened; and the previous-strategy distributions differed because they came from new model responses. The earlier screen explicitly said to choose a suit and who catches your eye. This screen retained character/orientation controls and the start button but omitted that instruction sentence. Two samples with multiple changed conditions cannot establish which, if any, caused the abstentions.

A concrete UX follow-up is to retain a short, fitting instruction explaining that character/orientation selection is followed by Start. A selected character card currently produces a no-op action; reviewing that affordance may also help people and model players. These are interface hypotheses, not grounds to remove the model's stop option, suppress failures, or claim a provider restriction was overcome. No automatic retries or altered prompts were used to turn these failures into successes.

The final pack consequently has code/browser verification reported elsewhere, but **no completed Jev gameplay run in this two-run post-fix sample**. The earlier 3/4 result belongs solely to its recorded earlier pack. Across the two different conditions there were six runs, three completions, one gameplay stall, and two setup abstentions; pooling them would hide the important build and exposure differences.

## Follow-up after restoring the setup instruction: two completions

A third, separately authorized batch tested the setup with a concise instruction restored and the focused-button contrast corrected. **Both fresh players started their evenings and completed the Eve finale.** The prior setup abstentions remain above; these runs do not erase them or prove which individual change altered the model's choice.

- [Follow-up final summary](../experiments/jev/2026-09-23T03-56-08-958Z/f9b9ed2d-d80b-413f-91b6-ea8f2cee68a2/summary.json)
- [Follow-up objective-led trace](../experiments/jev/2026-09-23T03-56-08-958Z/f9b9ed2d-d80b-413f-91b6-ea8f2cee68a2/f9b9ed2d-d80b-413f-91b6-ea8f2cee68a2-001-goal.jsonl.gz)
- [Follow-up curious trace](../experiments/jev/2026-09-23T03-56-08-958Z/f9b9ed2d-d80b-413f-91b6-ea8f2cee68a2/f9b9ed2d-d80b-413f-91b6-ea8f2cee68a2-002-curious.jsonl.gz)

| Field | Recorded value |
| --- | --- |
| Session / batch | `2026-09-23T03-56-08-958Z` / `f9b9ed2d-d80b-413f-91b6-ea8f2cee68a2` |
| Played QA pack SHA-256 | `0d91b5b36c26ef492bb8989570399d3a20f26b80e1015fc8d2138d913131c9d4` |
| Runner SHA-256 | `371cdc4cb20e8fe7fcbde3a3d5d9ed39f1974b440c4e2f3f799a71206d4020f7` |
| Policies / seed / concurrency | Objective-led + curious / 69 / 2 workers |
| Limits | 160 actions each; 400 attempts; 3,000,000 observed input tokens; $0.15 estimated input-cost threshold |
| Model requested / returned | `jev-latest` / `jev-1.13.0` on all 204 responses |
| First decision / final summary | `2026-09-23T03:56:34.915Z` / `2026-09-23T03:59:14.752Z` |

The setup now visibly says, **“Choose your suit and orientation, then start your evening.”** The stop candidate remained available, model instructions and question schemas were not altered, and no model choice was overridden. The seed returned to 69, matching the first batch; this and the changed visible copy mean the result is not an isolated A/B experiment of the instruction sentence. The visual focus correction cannot be assessed by a text-only model.

| Policy | Actual selected profile | Result | Actions | Points | Cash | Elapsed run time |
| --- | --- | --- | ---: | ---: | ---: | ---: |
| Objective-led | Larry, bisexual default | Eve finale | 84 | 48 | $80 | 117.053 s |
| Curious | Larry, heterosexual | Eve finale | 120 | 60 | $60 | 160.922 s |

The objective-led player clicked the Larry card, then Start while the visible **✓ Bisexual** selection remained active. It saw male **Ruben** at the casino and female **Flora** and **Eve**, confirming the mixed optional roster in that run's text observations and the opposite-gender bisexual finale. The curious player explicitly selected heterosexual before starting. These are actual selection paths, not assigned profiles inferred from the requested test configuration.

Both players solved Flora's lighting puzzle but chose no optional fling. Both followed the bowling-promotion, rehearsal, and hotel-introduction route and eventually accepted Eve's private invitation. The finale callbacks settled after **5,421 ms** and **5,454 ms**, returned the aftermath text, and set completion true. Their chosen-finale confidence values were 0.92 and 0.74. There were **47 room-changing actions**, 20 and 27 respectively, with settled times 3,535–4,476 ms, median 4,169 ms and p95 4,457 ms. No skips, bridge errors, API errors, cinematic timeouts, abstentions, or loop stops were recorded.

The models still made recoverable mistakes. The bisexual player tried seeds on Eve and the pool, a newspaper on the cabinet, a stool on the planter, and an empty pitcher on the planter. The game preserved items and supplied the relevant refusal or missing-step feedback. Successful completion should not be read as flawless navigation or as proof that repeated trips are enjoyable.

Usage was **204 requests, 204 executed actions, 1,443,212 input tokens, and 87,218 output tokens**. Recorded estimated input cost was **$0.060614904**, below the configured threshold. Choice confidence ranged from 0.10 to 1.00, median 0.63 and p95 0.98. API latency was 250 ms median and 404 ms p95. Browser final samples reported 16,163/16,246 visible requestAnimationFrame intervals within 20 ms (99.49%); peak server RSS was 190,365,696 bytes. The same concurrent manual testing and uncontrolled scheduling/cache limitations apply.

**Later final-export boundary:** after this played pack, review identified a separate existing-autosave startup/cancel risk in the normal game. That startup flow was corrected after the batch and is covered by separate interface checks before the final export, so the final binary hash differs. These fresh QA runs had no access to manual/autosaves and did not exercise that startup case. They support gameplay on the hash above; the later startup fix must be supported by its own deterministic/browser evidence, not attributed to these Jev runs.

Across all three conditions, the retained record contains **eight runs: five completions, one gameplay stall, and two setup abstentions**, with **640 API responses and 638 executed UI actions**. Total reported usage was 4,523,910 input tokens and 269,968 output tokens; total estimated input cost was $0.190004220. Build, policy, setup, and exposure differences are preserved rather than pooled into a single claimed success rate. Live Jev still has no completed Lisa or homosexual run, and only one bisexual run; six-profile deterministic checks and separately documented actual browser play supply different evidence. Human enjoyment and visual quality remain outside what these typed choices can establish.
