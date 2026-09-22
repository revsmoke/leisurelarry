# Last Call in Lost Wages — gameplay upgrade plan

Drafted 2026-09-21. This is a proposed shipping sequence, not a list of features already implemented. It combines the [actual browser audit](audits/browser-playthrough.md), [current design](design.md), and [TypeSafe research](typesafe-research.md). The ambition is a memorable adult comedy adventure with a finish worth reaching and alternate choices worth replaying. Awards and enjoyment are outcomes to earn through player response, not promises.

## Experiment findings — both live conditions complete

Confirmed calibration: [six API calls](experiments/jev/calibration.json), comprising two simple fixtures repeated three times each, selected the expected action in 6/6 responses from `jev-1.13.0`. This verifies the narrow request/response setup; it is not six different game scenarios, a completion test, or proof of general playing ability.

First live condition: three concurrent Web/Godot instances, one player policy per instance, each stopped at its 80-turn budget. All 240 API decisions returned without reported API errors; `jev-1.13.0` answered. API latency was p50 177 ms / p95 251 ms. Usage was 905,027 input tokens, approximately $0.038 at the published rate. This is API latency, not browser frame time or full action latency. [Run summary](experiments/jev/2026-09-22T02-15-53-649Z/summary.json), [decisions](experiments/jev/2026-09-22T02-15-53-649Z/decisions.jsonl), [resulting browser observations](experiments/jev/2026-09-22T02-15-53-649Z/events.jsonl)

| First live condition | Turns and outcome | Observed behavior | Interpretation |
| --- | --- | --- | --- |
| Objective-led player | 80 turns; 36/100; incomplete | Solved bar access and delivered candy/danced, then repeatedly traveled between the shop and disco. Those two travel actions were selected 27 times each over the run. | Strong evidence of a policy loop. A limited recent-action memory loses useful earlier observations; this does not prove a progression blocker. |
| Curious player | 80 turns; 44/100; incomplete | Explored more, completed wine/knife trade, talked to Didi 11 times, and tried applying the newspaper to the planter. | Broad exploration did not produce a complete plan. Missing ring/flowers remained an unresolved lead despite visiting their locations earlier. |
| HUD objective withheld | 80 turns; 28/100; incomplete | Explored garden and trades, then tried several ineffective item combinations at the railing and planter. | Without the explicit objective, local clues did not lead this player to the full route. This warrants a human clue-discoverability test, not an assertion that humans cannot solve it. |

The traces expose **one confirmed stale dialogue defect** independently of the model's choices: objective-led step 6 tunes the TV to bowling, but step 7's bouncer line still asks someone to find the remote. It repeats in the curious and unguided runs. The missing password is legitimate; the remote request is obsolete. Relevant evidence is in `events.jsonl` lines 17/20, 38/41, and 85/88, and `_talk("bouncer")` in `scripts/game_state.gd` checks password knowledge without acknowledging an already-tuned TV. This needs a state-aware response and a regression covering the TV-before-password order.

A second, less severe guidance problem is visible after the objective-led player's successful dance: the HUD still tells Larry to meet Didi and dance, while the actual remaining request is ring and flowers. Update the objective by outstanding subtask. The repeated shop/disco travel cannot be attributed solely to this stale checklist; it also exposes the player's weak planning and memory. Give the notebook a durable record of observed item locations so ordinary players and instrumented test players can recover earlier leads without an omniscient solution.

**The semantic critic also needs calibration.** On four requests that included both the obsolete bouncer line and the earlier successful TV action, contradiction probabilities were 0.21, 0.51, 0.34, and 0.40 (`decisions.jsonl` lines 23, 44, 91, and 94). A hypothetical 0.5 review cutoff would flag only one; that is an illustrative comparison, not a chosen production threshold. During the objective-led player's 54 decisions at zero-based steps 26–79, mean clarity was 2.40 on a 0–3 rubric, median 2.44, despite continued travel loops. These ratings do not establish progress or enjoyment. Add the stale-dialogue cases to a human-labeled critic set, distinguish readable instructions from an actionable new lead, and detect repeated state/action cycles in code. Preserve low-confidence choices rather than reporting only their chosen labels.

**Second live condition — complete:** the same three policies and 80-action budget, with durable player-observed room/clue memory, finished at **64/100 objective-led, 76/100 curious, and 16/100 objective-withheld**. All 240 calls succeeded; none of the three runs completed within budget. The curious player visited every room, increased unique actions from 44 to 58, and reduced its longest no-score stretch from 26 to 11 actions. Memory helped two runs and hurt the third; with one run per condition this is an exploratory result, not a universal improvement claim. The second batch used 1,154,456 input tokens, API p50 177 ms/p95 239 ms, and approximately $0.0485. See the [full experiment report](jev-experiments.md) and [comparison data](experiments/jev/comparison.json). Across both batches plus calibration, 486 requests cost an estimated $0.0867 at the published rate. Keep the proposed notebook improvement, but add deterministic cycle detection and a higher-level planning step before large batches; do not treat the critic as an automatic quality gate.

An 80-turn cutoff is a budget stop, not automatically a game defect. These runs use a Godot text observation bridge and real UI actions: they are instrumented browser play, not screenshot-reading Jev. No hidden flags or prescribed route were supplied. Preserve the exact build and runner configuration, and distinguish missing candidate coverage, model mistakes, browser-driver failures, and game problems in the final experiment report. Sampled FPS alone does not establish a performance pass.

## Product direction

Keep the compact 13-room city and retro theatrical framing. Replace a few compulsory errands with small social mysteries and authored alternatives. Each short sequence should offer a reason to investigate, an amusing attempt, a visible consequence, and a later callback. Complexity belongs in the relationships between these moments, not in an oversized map or dozens more inventory objects.

Larry is an adult whose overconfidence and dated lounge-lizard instincts keep colliding with other adults' actual interests. The narrator punctures his self-image; the characters can flirt, refuse, tease back, initiate, and change the subject. Use double meanings, awkward bravado, nightlife satire, wardrobe mishaps, and offscreen implication. Preserve character agency and mutual interest without turning every exchange into a lecture. An item can create a conversation; it does not purchase affection.

Replay should come from comic alternatives, unexpected callbacks, and different evenings. No real-time punishment, streak pressure, mandatory gambling, or reward grind is needed. Keep convenient saves, pausing, direct travel, and a complete offline Godot game. TypeSafe first serves development and testing; runtime inference is not required for any story route.

## Phase 1 — make the player's intentions and clues reliable

Ship a focused usability update before adding branches. Use the live traces to reproduce the highest-impact confusion in the current route. Preserve the tested beginning-to-end route while correcting interaction ambiguity.

- Make the current verb/item explicit: “Use pocket knife on…” beside the cursor or action line, with one-click cancel. Distinguish a person conversation from a purchase through a short labeled offer; a basic verb should not hide a transaction.
- Scroll or focus to a newly acquired inventory item and show a brief arrival cue. Add a tidy pocket view for items with no remaining use, without destroying them or concealing optional jokes. Give spent-purpose objects an accurate examination response.
- Turn the notebook into player-discovered leads: “Didi mentioned a spare rope,” not an instruction invented from a hidden quest flag. Keep destination names consistent across dialogue, map, and exits.
- Record observed useful item locations, such as the costume-ring dish, so a later request can be connected to an earlier discovery. Refresh completed subgoals in the objective, and make the bouncer acknowledge bowling when the TV is handled before the password.
- Replace the single solution button with three deliberate hint levels: remind me of the relevant clue, narrow the next action, then reveal the exact solution. No unsolicited solution spoilers. The current direct solution remains the final level.
- Standardize Take/Use conventions and parser aliases. When a carried tool supplies an automatic convenience, say which tool was used and apply the same behavior across mouse and parser actions.

**Acceptance:** all existing deterministic suites pass; each live-run defect gains a reproducible regression; item selection/cancellation and every hint level are tested through the browser. In a five-person fresh-player pilot, at least four players can explain their current goal and complete the bar sequence without the exact-solution hint. Record where they hesitate; failing that target means revise the opening before Phase 2. This small pilot is a design gate, not a population estimate.

## Phase 2 — prove a better adventure in the bar-to-cabaret slice

Build one strong slice, ending with a short Didi performance, before multiplying choices across the whole city. Introduce visible dialogue topics, with the player choosing an intention rather than repeatedly clicking TALK to exhaust a script. Keep authored dialogue and deterministic consequences.

**First alternate puzzle:** backstage access has two coherent approaches. The existing graffiti/password/TV route remains a comic caper. A new legitimate approach lets Larry help Lefty prepare a bowling-night promotion by finding the advertised prize and matching it to the customer who won it. Lefty then vouches for him. Both open backstage; the bouncer and narrator remember which approach he used. Avoid replacing one fetch quest with three new ones: make the alternate route a small observation-and-conversation puzzle using existing room props.

**Didi's scene:** replace the three mandatory gifts with a rehearsal problem she explains in her own words. The collected ring/flowers/candy can support an elaborate cabaret bit; Larry can instead volunteer for a deliberately ridiculous rehearsal role, using stage marks and a call-and-response cue. Both demonstrate useful help and earn the stage-manager introduction. Didi chooses how she uses the help, and her show changes accordingly.

The performance should pay off at least two earlier actions: the regular's bowling obsession becomes an interruption, or Larry's costume ring becomes a prop with the wrong romantic implication. Stage the reaction using characters, props, sound, and timing. Let the player attend immediately or return later. Skipping the show must not block progression.

**Acceptance:** both access approaches and both rehearsal approaches independently work from a clean save; all four combinations reach the same next chapter without duplicate rewards or stranded objects. Every selected dialogue intention receives a distinct response, and at least one later response reflects it. At least four of five fresh slice testers can describe one choice they made and its consequence; at least three spontaneously mention a specific funny moment during recall. If the scene is merely clear but not enjoyable, rewrite it before expanding the branch system.

## Phase 3 — connect the whole night and give the ending earned alternatives

Extend the proven slice through the hotel and rooftop, keeping branches short enough to test thoroughly.

- **Rope/window route:** keep the knife, secured line, and mallet as an optional slapstick service-access caper. Foreshadow the stuck window and the voucher before committing the trip. Opening it visibly changes the room. The busker is borrowing a bottle for an absurd song-prop gag, with a callback after the trade, rather than a silent knife dispenser.
- **Second hotel approach:** the stage manager can introduce Larry to the receptionist as a last-minute cabaret helper if the player discusses the show's setup and follows through. This offers a social route to the rooftop invitation alongside the espresso-voucher route. Coffee remains a thoughtful optional favor and later callback; neither branch makes kindness a mechanical romance purchase.
- **Eve's conversation:** offer authored topics about the gardens, her missed dinner, Larry's evening, and his exaggerated self-description. Eve asks questions too. A boast can become an amusing admission; listening opens a more personal follow-up. Maintain visible choices so the player understands the social turn being taken.
- **Gardening payoff:** preserve the absurd instant-fruit machine as a signature puzzle with a clear clue chain and visible transformation. The tree's appearance and Eve's reaction can reflect a harmless earlier choice, such as naming the cultivar. The player may offer the apple or keep chatting first; no hidden affection score makes one line a trap.
- **Three closing tones:** a mutually flirtatious sunrise, a companionable “good company is enough” rooftop conversation, and a comic return to Didi's after-show gathering. Each ends a complete evening, with a brief city epilogue reflecting two or more actual choices. The player can understand why that ending occurred and can continue exploring afterward.

Keep three principal binary route choices for the first upgrade: backstage access, Didi's rehearsal, and hotel invitation. Test all eight combinations; avoid an uncontrolled tree of unique global states. Ending tone follows explicit dialogue choices rather than a concealed score. Retain the 100-point exploration system if useful, but separate “evening complete” from “every optional gag found.”

**Acceptance:** all eight route combinations reach a valid ending; every ending has a reproducible browser test and save/reload check. No essential item becomes irretrievable; declining flirtation preserves a full ending; wrong item use cannot consume a unique required prop. A first-time player can summarize Didi's goal and Eve's interest without describing them only as requested-item lists. No new branch requires gambling or knowledge from a different playthrough.

## Phase 4 — make the world respond and the interface fit

Raise presentation quality through a bounded prop and staging pass, rather than replacing all thirteen backgrounds.

- Separate the stool, core, pitcher, ring, candy, voucher, rope, and service window into state-driven layers. Remove collected props from the scene; show rope placement, cupboard access, the open window, and used stage props in their correct positions.
- Give the important interactions short readable reactions: Lefty producing a drink, the bouncer turning toward the TV, Didi's rehearsal and show, the receptionist noticing coffee, and Eve handling the apple. Keep Larry and each speaker visible beneath labels.
- Improve the dance from a generic shuffle to a short player-directed comic choice, with “confident,” “careful,” and “copy Didi” gestures. Timing should add expression without demanding twitch precision. Provide reduced-motion and skip controls.
- Rework the current single scaled canvas layout for the supported desktop widths. Keep dialogue and inventory legible, avoid tiny text in a tall narrow browser window, and expose keyboard focus and action labels. Add a readable transcript and an accessible HTML companion surface for the Web build if Godot's canvas cannot supply meaningful controls to assistive technology.
- Add restrained sound cues for item arrival, refused action, scene changes, and punchline reactions. Separate music and effects volume, retain mute, and ensure every required cue also has a visible equivalent.

**Acceptance:** each listed prop has before/after screenshots at its relevant states. Verify at least 884×886, 1280×720, and 1440×960; no clipped objective, dialogue, or modal text. The complete route can be played with keyboard controls and visible focus. Reduced motion preserves puzzle information; muted play loses no clues. Do not claim screen-reader support until the actual browser control surface has been tested with a screen reader.

## Phase 5 — validate, tune, and ship a release candidate

Use Jev to increase coverage and discover suspicious interactions, then use people to judge the comedy and experience. Keep the testing harness out of production play unless explicitly enabled.

**Automated development loop:** run deterministic route/invariant tests first; then isolated live browser runs at concurrency 2, 4, and 8 while measuring local resources. Scale to at least 100 bounded runs in waves only after the pilot is stable. Vary the declared player policy, supplied objective, and candidate order; repeating the same near-deterministic policy is not broad behavioral coverage. Preserve raw decisions and failure traces. Report completion separately from budget stops and model abstentions. Use batched TypeSafe judgments for clue clarity, repeated dialogue, and action feedback; keep exact state correctness and arithmetic in code. Evaluate the critic on at least 20 labeled stale/current dialogue pairs and 20 actionable/non-actionable clue cases before using its threshold to prioritize defects automatically. Report missed defects and false alarms, with the bouncer case reserved as a required regression.

**Fresh-player loop:** recruit ten adults who have not seen the walkthrough or code. Observe the first session with minimal intervention; ask for enjoyment and confusion feedback afterward, not during every joke. Capture their own words and behavioral evidence. Compare revised clues on a held-out subset so the game does not merely become easier for the existing model prompt.

**Provisional release gates:**

- Zero known progression blockers, unrecoverable saves, cross-session save leakage, duplicate milestone rewards, or required purchases that can permanently bankrupt a run.
- At least eight of ten fresh players finish an intended route with no moderator instruction; use of player-requested graduated hints is recorded separately. At least eight can state why their ending happened.
- At least seven of ten rate the evening 4/5 or better, and at least six can name a different choice or scene they would voluntarily revisit. These are directional product targets, not statistical proof of universal appeal.
- Every major authored scene has one identifiable setup/payoff pair and one optional character response. Human reviewers prefer the revised version over the old scene for clarity and comedy; Jev's score alone cannot pass this gate.
- On the documented reference Mac/browser at 1440×960, target 60 fps with at least 95% of post-load sampled frames within 20 ms and local action feedback p95 under 100 ms, measured separately from inference latency. Record cold-load time, bundle size, memory, and concurrency effects. Investigate memory growth above 15% across ten repeat route/reset cycles after warmup. If these targets prove inappropriate, revise them with recorded baselines rather than silently claiming a pass.
- Export and smoke-test native macOS and Web builds, verify save migration from the currently shipped version, and retain reproducible build IDs, test outputs, and browser evidence. API outages must never affect normal offline play.

## Scope and working rules

Implement one phase at a time and ship reviewable builds. Phase 2 is the quality checkpoint: if the small slice is not noticeably more engaging to fresh players, revise its writing and choices instead of adding more rooms. Keep large expansions, voice acting, generated live NPC dialogue, procedural mysteries, and a fully open natural-language parser outside this first upgrade.

Use the installed TypeSafe skill for future integrations. The practical cookbook sequence is [Function calling](https://docs.typesafe.ai/cookbooks/function_calling) for bounded player actions, [Parallel questions](https://docs.typesafe.ai/cookbooks/parallel_questions) for shared-observation judgments, [Self-consistency choices](https://docs.typesafe.ai/cookbooks/consistency_choice_cookbook) for policy stability, and [Composite scoring](https://docs.typesafe.ai/patterns/composite-scoring) for separate editorial dimensions. Consider [feature discovery](https://docs.typesafe.ai/cookbooks/autoresearch_feature_discovery) only after collecting enough human-labeled sessions to justify it. No runtime AI dependency is currently justified by these needs.


## Implementation status — 2026-09-22

The proposal above is preserved as the design brief. This status distinguishes delivered code from its acceptance criteria. The [upgrade validation report](audits/gameplay-upgrade-validation.md) is the source for the final tested build, run counts, measured outcomes, browser evidence, and remaining defects. Deterministic suites, exported builds, and live model/browser checks are recorded there; the fresh-player and full performance gates below remain open.

### Phase 1: intentions and clues

- [x] Explicit selected-item action line, one-click cancel, inventory arrival cue and focus, and a reversible Tidy view for used souvenirs.
- [x] Labeled purchase offer for Lefty's whiskey rather than an unannounced transaction on a person.
- [x] Player-discovered notebook leads, useful observed item locations, current outstanding objectives, and state-aware bowling/bouncer feedback.
- [x] Three deliberate hint levels: clue reminder, narrower suggestion, and requested exact solution.
- [x] Updated action and parser behavior with regressions for misleading purchase/selection cases.
- [ ] Five-person fresh-player opening pilot and its stated comprehension target. No such recruitment study has been performed by the implementation agents.

### Phase 2: the bar and cabaret slice

- [x] Password/TV backstage route retained; Lefty's bowling-prize observation and conversation route added.
- [x] Didi's elaborate ring/flowers/candy routine retained as one approach; a volunteer rehearsal with stage marks and a call-and-response cue added as the alternative.
- [x] Visible authored dialogue topics, three dance intentions, a player-paced performance with route-specific callbacks, and a curtain-call skip that preserves progression.
- [x] Route and conversation regression coverage authored; current execution results belong in the validation report.
- [ ] Fresh slice testing and independent comedy recall/preferences. The developer playthrough is informed, not a blind player study.

### Phase 3: connected routes and endings

- [x] Rope/window/espresso caper retained; stage-manager introduction provides the second hotel approach. Coffee remains an optional favor after social admission.
- [x] Busker callback, Eve's garden/dinner/story/boast/follow-up topics, and the optional Midlife Crisps cultivar naming callback.
- [x] Three explicit ending choices: flirtatious sunrise, companionable rooftop friendship, and the after-show gathering with Eve. Epilogues reflect actual choices.
- [x] Eight principal route combinations are represented in deterministic route coverage. Completion is separate from collecting every optional exploration point.
- [ ] Final live-browser route/ending/save coverage is reported separately; a passing model test alone does not establish every ending's usability.

### Phase 4: responsive presentation

- [x] Six targeted image edits create clean background plates and a real open-window variant; thirteen rooms remain. Independent collectible layers replace the baked stool, core, mallet, pitcher, candy, and voucher. Ring, rope, cabinet, stage props, tree/fruit, coffee, and character reactions have state-driven presentation.
- [x] Confident/careful/copy-Didi dances; reduced motion preserves puzzle information; idle actors stop unnecessary redraw processing.
- [x] Desktop and narrower-window layouts, visible focus, selected-action labels, transcript, and a readable HTML companion for normal Web play. Companion actions use the real visible UI controls and are excluded from the QA export.
- [x] Separate music/effects levels and mute behavior; short original offline item, refusal, transition, and punchline cues.
- [x] Native before/after prop fixtures inspected; visual-state and companion-control assertions added. [Art provenance and capture commands](art-upgrade.md).
- [x] Live-browser layout checks at all three supported sizes, keyboard activation/focus, muted-play preferences and visual clues are documented in the validation report. A complete keyboard-only replay remains unverified.
- [ ] Actual screen-reader testing. Standard HTML controls are implemented; complete assistive-technology compatibility is not claimed.

### Phase 5: testing and release work

- [x] Jev lab supports isolated workers at concurrency 2, 4, and 8, up to 100 fresh runs in bounded waves, varied policies and candidate order, budgets, cancellation, stale-action rejection, cycle detection, and reproducible raw traces.
- [x] Narrow Jev judgments and independent critics remain development tools. Deterministic code owns gameplay and execution; the ordinary Web/native game remains offline and has no Jev/API dependency.
- [x] Critic calibration fixtures and a repeatable command exist, including the old TV/bouncer contradiction; measured calibration performance is documented with the experiment evidence rather than presumed from confidence.
- [x] Final deterministic suites (3,893 Godot assertions and 34 Node tests), exported-build smoke checks, the 100-run and final 12-run Jev campaigns, and informed browser replays are recorded in [the validation report](audits/gameplay-upgrade-validation.md). Failures and incomplete release gates remain explicit.
- [ ] Ten-person fresh-player usability/enjoyment study, its completion/replay targets, and independent comedy review.
- [ ] The full frame-time, latency, cold-load, bundle, and repeat-reset memory gates under documented conditions. Partial measurements must retain their scope and limitations.

The update implements the authored adventure and testing infrastructure. “Award-winning” remains a creative ambition, not a test result; genuine player enjoyment needs evidence from people who did not build the game.
