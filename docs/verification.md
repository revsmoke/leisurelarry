# Verification — browser playtest follow-up

Verified with Godot **4.7.2.stable.official.ed1daf0bf** on Apple Silicon macOS. This report separates automated assertions, actual browser playthroughs, and earlier release checks. The detailed action log and visual evidence are in [Browser playthrough](audits/browser-playthrough.md).

## Current automated checks

| Suite | Result | Evidence |
|---|---|---|
| Adventure model | **198 assertions, 0 failures** | `tests/test_game.gd` |
| Actual scene/interface route | **182 assertions, 0 failures** | `tests/test_interface.gd` |
| Modal and objective layout | **330 assertions, 0 failures** | `tests/test_modal_layout.gd` |
| Narrative state and clues | **56 assertions, 0 failures** | `tests/test_narrative.gd` |
| Action intent and visual feedback | **39 assertions, 0 failures** | `tests/test_action_intent.gd` |
| Casino rules and settlements | **40 assertions, 0 failures** | `tests/test_casino.gd` |

**Six suites pass: 845 assertions, 0 failures.** These automated checks complement the browser playthroughs below; they are not a substitute for playing the visible game.

The interface suite instantiates the actual main scene, emits toolbar/hotspot/inventory/map/parser signals, operates the animated slots button, reaches the 100-point ending, and checks New Game → Restore autosave. It preserves/restores prior autosave bytes and leaves the manual save slot untouched. The model suite covers the complete route, room gates, inventory trades, score idempotence, cash recovery, parser aliases, saves, resets, and malformed-save rejection.

The new regression suites check modal/footer collisions and every staged objective at three viewport sizes, NPC memory and notebook deduplication, missing-item pickup instructions, TAKE refusing unintended purchases or interactions, and UI-driven dance/tree/harvest state. Casino tests cover aces, blackjack, pushes, busts, settlements, repeated clicks, and unfinished-hand refunds.

## Two complete browser playthroughs

Both runs played from the beginning through completion in the actual in-app browser at `http://127.0.0.1:8766/`, using the visible game interface. Neither used the hint button.

| Browser run | Final score | Recorded moves | Final wallet | Purpose |
|---|---|---|---|---|
| Original baseline | **100 / 100** | **97** | **$48** | Find real interaction, guidance, presentation, and story problems |
| Rebuilt game | **100 / 100** | **85** | **$43** | Replay the complete route after fixes and inspect their visible results |

The baseline exposed Help and objective text overflow, stale dialogue after completed favors, objectives that skipped voucher/apple collection, weak motivation for the gardening errand, missing visible tree growth, an unresolved Didi follow-up, and a one-click ending whose score overlapped its prose. It established that the original route was finishable while documenting why its play experience needed work.

The rebuilt replay visibly confirmed **three separate Eve conversation beats**, a **readable ending**, a **visible garden tree**, and **fruit disappearing from the tree after pickup**. Its full route reached the ending without hints. Reloading then displayed Continue evening and restored the completed rooftop state, 100/100 score, and $43 wallet. The [browser audit](audits/browser-playthrough.md) records the action-level observations and screenshots; the [source review](audits/story-review.md) preserves the earlier narrative findings and their implementation follow-up.

**Test limitation:** the tester knew the implementation and had played the baseline route. These were informed functional and qualitative playtests, **not blind novice tests**. The second run's lower move count does not establish improved novice discoverability, and neither a full score nor passing assertions objectively proves the game is fun. A new player's unassisted session remains useful for evaluating whether clues, pacing, and the ending work without prior knowledge. Wallet differences reflect the actions and optional casino play in each run; the currency is fictional.

## Earlier release checks — historical evidence

The initial release report recorded **409 automated assertions**: 196 model, 173 interface, and 40 casino. Those counts are superseded by the current six-suite results above. The following earlier observations remain historical evidence; they are not claims that every check was rerun during this playtest follow-up:

- All-room UI smoke passed without engine errors (`--smoke-ui`, `exports/ui-smoke.log`). Godot MCP passed six protocol checks (`node tools/mcp-smoke.mjs`).
- Native rendering used the Apple M4 Pro compatibility renderer. Captures of all 13 rooms and both casino overlays were saved in `exports/screenshots/`; the street, casino/blackjack, fonts, room labels, and actors were inspected.
- Initial browser checks covered WebAssembly/WebGL startup, keyboard verbs, mouse pickup, inventory examination, map travel, parser key events, blackjack, unfinished-hand refunds, and manual Save → reload → Load restoring location and wallet. The initial Mac app was launched and its opening screen inspected.
- The inline city-map visualization was checked at desktop and 360px width, with all 13 selections and its spoiler toggle working and no JavaScript errors or horizontal overflow.

Browser automated bulk text insertion did not emulate Godot's IME key events correctly in the initial tooling checks; explicit key events worked. This is a test-driver observation, not a claim of broad IME or localization support.

## Packaged artifacts

`./tools/package.sh all` imports resources, exports macOS and Web, verifies the actual PCK directory, checks the native signature, and runs the exported native binary for 30 frames. The saved rebuilt export report, `exports/export-verification-all.json`, records **passed: true**, with **58 resources in each pack**, all **13 backgrounds**, **three fonts and their licenses**, music, the main scene, and compiled runtime scripts. This includes the dormant QA bridge and supersedes the earlier 53- and 55-resource counts. Normal builds do not enable its qa_playtest feature.

Research, documentation, development tools, tests, `.agents/`, `.codex/`, archival screenshots, the supplied walkthrough, and raw `.gd` source are excluded from the game packs. The saved packaging evidence includes:

- `exports/export-verification-all.json`: actual pack inventories and hashes.
- `exports/native-smoke-result.json`: native launch result.
- `exports/build-artifacts.json`: artifact sizes and SHA-256 values.
- `tools/cache/package-typesafe-integration.log`: rebuilt packaging log for this browser audit.

The Mac build has an ad-hoc signature for local use. No Developer ID notarization, App Store submission, public hosting, Windows/Linux packaging, or remote device certification was performed. The Web preview binds only to loopback. Touch-specific layout, controller input, voice acting, localization, full screen-reader accessibility, and original-game branch parity remain outside this build's scope.

## TypeSafe integration follow-up

The later Jev testing integration adds 179 passing Godot bridge assertions and nine passing Node client tests. The existing 182 interface and 39 action-intent checks were rerun after the integration. Six live Web runs performed 480 Jev-selected actions, with no reported API/action errors; none finished within its 80-action budget. API calibration added six calls. These outcomes and their limitations are documented in [Jev experiments](jev-experiments.md). They do not supersede the earlier actual Browser completion runs or establish human enjoyment.

Production Web and macOS were rebuilt and verified after the QA guards were integrated; the QA export is separate. The latest compact packaging record is [production-build.json](experiments/jev/production-build.json).
