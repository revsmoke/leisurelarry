# Gameplay upgrade: implementation and validation

The update is implemented as a complete, offline Godot adventure with eight combinations of puzzle approaches and three authored endings. The 13-room city now has dialogue choices, a player-paced cabaret performance with earlier-action callbacks, clearer inventory actions, graduated hints, changing scene props, separate sound controls, and a readable browser control surface. It preserves the original route and saves while allowing a successful evening without mandatory gambling or buying every gift.

This report separates deterministic checks, text-driven Jev actions in live browser instances, and the assistant's informed visual browser playthroughs. No fresh-human enjoyment study or screen-reader certification was performed. The design's human and full standalone performance gates remain open; “award-winning” is an ambition, not a measured result.

## What shipped

- Backstage access through the password/TV caper or Lefty's bowling promotion; Didi's scene through gifts or a rehearsal role; hotel access through the rope/window/coffee caper or a stage-manager introduction. All eight combinations have three explicit ending choices.
- Wrong dialogue answers recover with character responses. Dance intentions, stage callbacks, Eve's conversation, and the morning-after epilogue acknowledge choices. Watching or skipping the show does not strand the player.
- Explicit purchase offers, selected-item labels and cancellation, inventory arrivals and tidying, an ordinary button for using an item by itself, discovered clues in the notebook, and three deliberate hint levels.
- Six edited background plates plus independently changing props, an open window, dance styles, and reduced-motion support. See [art provenance](../art-upgrade.md).
- Compact and desktop layouts, persistent music/effects settings, a bounded transcript, keyboard focus, and normal-Web HTML controls that activate the actual visible Godot controls.
- An isolated development-only Jev lab with bounded budgets, shuffled candidate order, observed-room memory, independent semantic questions, loop detection, cancellation, complete traces and build hashes. Production play has no API dependency or credential.

Implementation was committed and pushed in `ce783d3`. Final source corrections are committed in `47d1bfd`; the following evidence commit contains this report and the retained experiments. The authoritative final source fingerprints and artifact hashes are in [code checks](upgrade-code-checks.json) and [build verification](upgrade-builds.json).

## Ordinary code and exported-build verification

**All 3,893 Godot assertions and 34 Node tests passed on the final source.** The 13 Godot suites ran sequentially to preserve save-test isolation; the check manifest includes their exact summaries and source hashes. The actual-window resize test has 136 checks and demonstrably fails when the former fixed viewport mode is reproduced inside the isolated test process. Coverage includes all 24 route/ending combinations, old-save compatibility, duplicate reward prevention, wrong-answer recovery, actual modal callbacks, stale controls, session isolation, inventory behavior, audio preferences, visual state, and Web companion dispatch. Tests do not substitute for seeing the running game.

The normal Web and native macOS exports passed resource verification: 19 background resources for 13 rooms, fonts/licenses, compiled game resources, and exclusion of `.env`, research and development tooling. The exported macOS application passed its native 30-frame smoke check and signature validation. It has not been notarized for third-party distribution. Local distributables are in `exports/`; the committed manifest records their sizes and hashes.

The native lifecycle fixture measures ten create/reset/free cycles after warmup, with bounded transcript and node counts. Its warmed static allocation grew from 32,154,732 to 33,021,788 bytes (+2.70%), with no remaining orphan nodes. Its result concerns native scene lifecycle memory, not a whole-route browser/WASM leak assessment.

## Own live browser playthroughs

The assistant played the actual normal Web build through Browser, using its canvas targets and the visible HTML companion. These were informed tests by an implementer, not blind first-player trials. The first route continued across pilot fixes through ordinary autosave restoration; the second was a fresh run on the main implementation before the final small feedback/layout patches. Final-build reload and settings/layout checks followed, then a fresh complete final-build run in Chrome reached the flirt ending. The first two used the in-app Browser; the third used Chrome through native Computer controls because the testing agent had no enabled browser automation surface. No save flags or inventory were injected.

| Route | Observed ending | Result |
| --- | --- | --- |
| Bowling promotion → volunteer rehearsal → manager introduction → garden | After-show gathering | 52 points, $80 remaining, 67 moves |
| Password/TV → gift performance → rope/window/coffee → garden | Friendship | 96 points, $48 remaining, 78 moves |
| Final build: bowling promotion → volunteer rehearsal → manager introduction → garden | Flirt / A little connection | 52 points, $80 remaining, 66 moves |

The first evening deliberately tried a wrong bowling answer and a wrong rehearsal response before recovering. The full show paid off the bowling route; the second evening exercised the prop version and curtain-call skip. The classic run turned the TV on before obtaining the password, inspected the corrected bouncer response, opened the actual window, exchanged the voucher for coffee, and finished without gambling. Both solved the seed/stool/pitcher/fruit sequence. Collecting the pitcher removed its prop, placing the stool changed the scene, and the opened window visibly replaced the closed one. A lower exploration score did not prevent an ending.

The final fresh replay used visible HTML companion and canvas controls, played every show beat, and selected optional Eve topics before choosing flirt. It specifically checked the corrected dance-floor introduction, phone text before and after dialing, and the manager discussion. Eve's exhausted dialogue still supplied the core/extraction lead; using the planted tray requested water and named the pitcher/stool lead. The item self-use button worked without a double-click. No hint was requested, no interaction blocked progress, and no contradictory story reply was observed in this informed replay.

Additional checks exercised the tidied inventory, item self-use, normal save restoration, explicit purchase dialog, conversation exits, keyboard activation/focus, reduced motion, and muted settings persistence. Required clues remained visible while muted. This was not a complete keyboard-only replay or a screen-reader test.

Real browser testing found issues the original headless layout fixture missed. Godot's `canvas_items` stretch mode kept the root at its logical base size, preventing the compact breakpoint from activating. The project now lets its existing layout code scale the canvas itself. Long fixed-size labels were allowed to expand before wrapping; those labels now stay within their rectangles, while zero-height container labels retain their growing scrollable content. The Options modal, objective, and transcript were visually rechecked at the required sizes: 884×886, 1280×720, and 1440×960. Browser reload also exposed a stale Music header after restoring a muted preference; one preference-application path now updates both sound state and header.

Browser evidence:

- [Collected pitcher and placed stool](upgrade-browser-evidence/01-pitcher-collected.png)
- [After-show ending](upgrade-browser-evidence/02-after-show-ending.png)
- [Opened window](upgrade-browser-evidence/03-open-window.png)
- [Friendship ending](upgrade-browser-evidence/04-friends-ending.png)
- [Before-fix compact Options failure](upgrade-browser-evidence/05-options-884x886.png)
- [Corrected compact Options](upgrade-browser-evidence/06-options-compact-fixed.png)
- [Laptop-size Options](upgrade-browser-evidence/07-options-1280x720.png)
- [Final-build flirt ending in Chrome](upgrade-browser-evidence/08-final-flirt-ending.png)

## Live Jev evidence and fixes

Jev chose bounded actions from displayed text and available UI controls; the adapter executed the real callbacks in separate running Godot Web instances. It received no hidden flags, source-derived route or hint-function output. Requested model was `jev-latest`; returned model was `jev-1.13.0`. These tests exercise authored behavior and text discovery, not visual perception or human enjoyment.

| Experiment | Concurrency | Completion | What it revealed |
| --- | --- | --- | --- |
| First revised pilot | 2 | 0/2 | Social routes could skip the alley, leaving the seed source poorly explained. Added ordinary newspaper, planter and Eve clues. |
| Second pilot | 4 | 2/4 | Closing a conversation was confused with ending a run. Added an explicit back-to-room button and accurate close semantics. |
| Third pilot | 8 | 6/8 | Objective-withheld players lacked a strong next-chapter lead. Lefty and the poster now connect backstage to Didi and the free casino pass. |
| Main bounded campaign | 4 | 86/100 | Stable broad completion plus model loops, one provider failure, and two contradictory dialogue openings. |
| Final patch campaign | 4 | 8/12 | Final game source; four model planning failures, zero API/dispatch errors. |

See [pilot analysis](../experiments/jev/upgrade-pilot-analysis.md), [100-run analysis](../experiments/jev/upgrade-100-analysis.md), and [final 12-run analysis](../experiments/jev/upgrade-final-12-analysis.md). These were successive debugging conditions with changed game/runner code; improvements are not a controlled causal comparison. A canceled 100-run attempt retained obsolete iframe workers after a previous eight-worker pilot. It was excluded, its traces retained, and dashboard teardown plus double-start handling were corrected before the clean campaign.

The clean 100-run result was **86/100 endings**: objective-led 33/34, curious 32/33, objective-withheld 21/33. Six players abstained, six stopped after no observed progress, one repeated a two-action loop, and one received HTTP 529 from TypeSafe. There were 8,934 request attempts, 8,933 responses and 8,927 executed game actions. Known input usage was 59,834,619 tokens, approximately **$2.513054** at the documented rate; the failed request's usage is unknown. It was not retried or reclassified as a game failure.

The traces also exposed real feedback defects: the dance-floor and phone interactions could open valid choices while saying there was no conversational opening, and repeat calls sounded dismissive while a manager introduction remained available. Final source now gives state-appropriate replies. A held knife now makes the objective point to cutting the rope. Valid unused actions still existed in the stalled model runs; no deterministic progression blocker was demonstrated by those stops.

The final campaign on QA pack `ab88e50d7cf6c922d000532a6a5d6958e37141950b1fe7a9bafd8b6802f2c38a` completed **8/12**: objective-led 3/4, curious 3/4, objective-withheld 2/4. Two players made no progress, one repeated a two-action cycle, and one abstained; none had an API or dispatch error. All 1,006 requests returned, with 1,005 executed actions and 6,618,076 known input tokens (about **$0.277959**). The corrected dance-floor reply appeared in an actual run; the phone reminder appeared in both a stalled and a successful run. The wording correction did not eliminate the model planning weakness. This smaller result uses a different seed and build and must not be pooled with the 100-run sample or presented as an improvement in completion.

The independent critic calibration used 20 developer-labeled stale/current dialogue pairs and 20 clue cases. Dialogue detection had 18 true positives, 2 misses, no false positives and 20 true negatives; clue detection had 9 true positives, 1 miss, no false positives and 10 true negatives. The critic missed the old bouncer contradiction at its fixed threshold. This is a small synthetic fixture, not held-out human validation, and the critic is not a release gate. [Exact calibration evidence](../experiments/jev/critic-calibration-2026-09-22T02-54-22.494Z.json).

## Performance and remaining validation

The clean four-worker 100-run campaign measured 93.88% of visible post-warmup animation-frame intervals within 20 ms, below the proposed 95% target. Callback p95 was 36 ms; settled game feedback p95 was 90 ms; browser acknowledgement p95 was 112 ms; successful API latency p95 was 282 ms. These scopes are different. Small concurrent iframes, uncontrolled cache state, and concurrent local work do not establish the proposed standalone 1440×960 release gate. Browser JS heap sampling omits or shares relevant allocations and is not a WASM leak test. The final 12-run lab measured 94.94% of frames within 20 ms, callback p95 36 ms, settled feedback p95 89 ms, acknowledgement p95 109 ms and API p95 349 ms; it also misses the 95% frame target.

Remaining work is explicit: recruit fresh adult players for comprehension/comedy/replay feedback; conduct a complete keyboard-only and real screen-reader study; measure standalone cold load, rendering and full-route reset memory under controlled reference conditions. The current update is a tested playable release candidate, not evidence that all human or performance targets have passed.
