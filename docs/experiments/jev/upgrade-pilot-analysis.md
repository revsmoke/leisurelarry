# Upgrade gameplay pilots, 2026-09-22 UTC

These exploratory pilots led to the separate [final 100-run analysis](upgrade-100-analysis.md): 86 completed evenings, with all failures retained. Do not pool the different builds or the excluded canceled batch into that result.

The first upgraded live-browser pilot **did not complete either evening**. Its new social branches worked through the hotel, but both players lost the seed-source lead during gardening. The preserved failures distinguish a clue weakness from a model planning weakness; there is no evidence of a failed UI dispatch in these traces.

Evidence: [batch summary](2026-09-22T02-54-06-602Z/2d59625e-7feb-4cf2-8e4a-a5a7b6c91a1b/summary.json), [aggregate](2026-09-22T02-54-06-602Z/2d59625e-7feb-4cf2-8e4a-a5a7b6c91a1b/aggregate.json), [objective-led trace](2026-09-22T02-54-06-602Z/2d59625e-7feb-4cf2-8e4a-a5a7b6c91a1b/2d59625e-7feb-4cf2-8e4a-a5a7b6c91a1b-001-goal.jsonl.gz), [curious trace](2026-09-22T02-54-06-602Z/2d59625e-7feb-4cf2-8e4a-a5a7b6c91a1b/2d59625e-7feb-4cf2-8e4a-a5a7b6c91a1b-002-curious.jsonl.gz). Use `gunzip -c` to inspect exact requests, distributions and observations. All step numbers below count executed UI actions starting at one.

## Measured results

| Policy | Result | Key progress |
| --- | --- | --- |
| Objective-led | 74 actions, 32 points; model abstained on request 75 | Matched the bowling promotion, completed rehearsal, got the hotel introduction, met Eve, read the paper and collected the pitcher. |
| Curious | 87 actions, 36 points; deterministic repeated-action cycle stop | Completed the same social route, sampled Didi's performance, learned all initial Eve topics and read the paper. |

The 160-action allowance was not exhausted. There were 162 successful API requests, no reported API errors, 992,681 input tokens and approximately **$0.04169** in input cost at the published rate. Both answered as `jev-1.13.0`. API latency was p50 200 ms / p95 331 ms. Completion was 0/2; cycle-stop rate was 1/2. These are two exploratory policies, not population estimates.

The old score is an exploration score. A new social route can reach the rooftop at 24 points while bypassing many optional caper awards. Thus comparing these 32/36-point runs directly with the old 64/76-point linear route would misrepresent progress. Neither lower scores nor successfully reaching the roof changes the fact that neither player finished.

## Findings

1. **The new social hotel route bypasses the old mandatory alley visit, exposing a missing seed-source clue.** Goal step 39 examined the planter, 42 read the newspaper, and 56 operated the planter. All said seeds plus water; none explained where seeds might come from. This player never visited the alley, so its observed memory could not legitimately supply that location. It eventually collected the pitcher (62) and was told to plant seeds first (64). The final abstention had only 0.15 confidence / 0.18 selected probability, indicating uncertainty rather than proof that no action was possible. A normal authored clue about extracting apple seeds from a discarded core would address the game design gap without teaching the model a hidden solution.

2. **The curious player had the needed object location but failed to make the semantic connection.** It had previously visited the alley and retained the `Apple core` hotspot in observed memory. Nevertheless it tried the stool and knife on the planter (69–70), then newspaper on planter (78). This is model planning weakness as well as weak clue linkage. All the relevant map destinations and available actions were present. No evidence supports calling it a driver blockage.

3. **Eve gives a misleading exhausted-conversation reply.** Curious chose her garden topic, missed dinner, personal follow-up, cultivar name and Larry's story (59–63). Later TALK still repeated the original introduction and said to choose a topic despite `dialogueOptions` being empty (81, 83, 85–87). This stale invitation encourages repeating a finished conversation. A state-aware reply should acknowledge the earlier conversation and point back to the unresolved garden interest. The cycle detector correctly stopped after the final three identical non-progressing TALK actions instead of presenting them as successful testing.

4. **The observation omitted available controls from independent critic questions.** Action labels existed only in `next_action.criteria`. TypeSafe questions are evaluated independently; clarity/strategy cannot read another question's criteria. The runner now repeats those same player-visible labels in shared `visible.available_actions`, giving the critics control context without adding hidden knowledge. Action selection already had the candidates, so this omission does not explain away its failed gardening choices. Subsequent batches must be reported as a different runner condition. Runner source hashes are now recorded alongside game-pack hashes.

No automated restart, hidden flag, item grant, exact-solution hint, post-hoc outcome relabeling or threshold change was used to rescue these runs.

## Critic calibration

[The preserved 60-request calibration](critic-calibration-2026-09-22T02-54-22.494Z.json) used 20 developer-authored stale/current pairs (40 dialogue cases) and 20 clue cases. At the predeclared 0.5 contradiction threshold, it had 18 true positives, 20 true negatives, no false positives and two false negatives: **precision 1.00, recall 0.90** on this small set. It still missed the required TV-before-password regression (0.43), and the completed wine trade (0.46).

Clarity at the predeclared ≥2/3 threshold had nine true positives, ten true negatives, no false positives and one false negative: **precision 1.00, recall 0.90**. The missed clue was the cabaret rehearsal offer. These synthetic pairs are related examples, not held-out human labels. A mandatory regression still failing is sufficient reason to keep critics as advisory evidence rather than automatic release gates. The shared-control observation change has not retroactively changed this result; another run is needed to measure it.

## Performance observations and limits

Across the two visible dashboard iframes, 2,541 of 2,603 sampled requestAnimationFrame intervals after the two-second warmup were within 20 ms (**97.62%**); each worker's p95 histogram upper bound was 19 ms. Initial ready times were 818 and 822 ms, with uncontrolled browser cache state. These measurements concern this two-worker dashboard, not a full-size 1440×960 standalone game or GPU rendering duration.

The initial Web engine static-memory monitor returned zero. This is unavailable monitoring, not a zero-byte game; the bridge now represents it as null. Browser JS heap values were available but may be shared and exclude total Godot/WASM allocation. Recreating iframes per run does not establish the proposed ten-reset memory-growth gate. Confidence, critic scores and frame diagnostics do not measure enjoyment.

## Follow-up pilot: four concurrent players

The corrected-clue [four-player batch](2026-09-22T02-58-34-237Z/f48b0b64-dd90-41c8-baad-19130da5d72e/summary.json) completed **2/4** evenings: objective-led in 84 actions/48 exploration points, curious in 85/52. The other two abstained at 24 and 38 actions; neither reported an API or UI execution error. This combines changed game clues and runner observations, so it does not isolate which change caused the improvement.

Both abstentions happened inside conversations. The unguided player had completed Lefty's promotion, bought whiskey and asked for its callback; the other objective-led player had just completed the rehearsal and had an explicit objective to call the wall telephone. Their currently available controls were conversation topics plus `Press ×`; room controls required closing the dialog. Their abstention confidences were only 0.08 and 0.22.

This exposed an affordance-description weakness, not missing action coverage or proof of a game dead end. The adapter now describes the same × control as closing the dialog and returning to the room, while Stop explicitly ends the entire playtest. General control instructions explain the distinction. The ordinary conversation UI also gained a visible **Back to the room** button. These changes add no hidden locations, quest flags or walkthrough knowledge; subsequent experiments use a new build/runner condition and must retain the two earlier abstentions.

## Native lifecycle check

[The native/headless lifecycle report](native-memory-lifecycle.json) records ten measured scene create/reset/free cycles after two warmups, using real map, inventory, dialogue, casino-opening and reset callbacks plus 140 submitted LOOK commands per cycle. The 120-entry transcript remained bounded; all scenes freed; node count returned to one and orphan count to zero. All **336 checks passed**, including unchanged manual/autosave/preferences files.

The final-source rerun on 2026-09-22T03:29:35Z (separate from these pilots) increased Godot static memory from 32,154,732 warmed baseline bytes to 33,021,788 bytes after the final free: **+2.70%**, within the provisional 15% native check. This measures allocator-reported static memory for this exercised scene lifecycle. It is not a whole-route ten-reset browser-memory result, nor a GPU-residency measurement. Reproduce with `./tools/godot --headless --path . --script tests/test_memory_lifecycle.gd`.


## Follow-up pilot: eight concurrent players

The [eight-player batch](2026-09-22T03-03-25-328Z/8a939298-c77c-4f25-8d97-a27180338e4d/summary.json) completed **6/8** evenings with no API or UI dispatch errors: all three objective-led players and all three curious players. Both players without objective text stopped after 24 consecutive actions without a newly observed item, clue, topic, object or score increase. There were no model abstentions. [The aggregate](2026-09-22T03-03-25-328Z/8a939298-c77c-4f25-8d97-a27180338e4d/aggregate.json) preserves per-worker timing and outcomes.

| Policy | Completed / attempted | Actions and final exploration points |
| --- | --- | --- |
| Objective-led | 3/3 | 89/64, 97/48, 91/64 |
| Curious | 3/3 | 116/68, 144/68, 128/68 |
| Without objective text | 0/2 | 94/28 and 88/32; both no-observed-progress stops |

The 847 successful requests used 5,652,448 input tokens, approximately **$0.23740** at the published input rate; all answered as `jev-1.13.0`. API latency was p50 189 ms / p95 258 ms. The experiment used eight workers, 160 actions per run, a 2,000-request cap, 12-million observed-input-token threshold, $0.60 estimated-cost threshold, observed memory enabled and seed 1. It is a 75% completion / 25% stall-stop result on eight model runs, not a population estimate or enjoyment measure. The game and runner hashes are recorded in the aggregate; the game includes the corrected seed clue and clearer conversation exit.

### The two remaining stalls

Both unguided players solved the earlier seed-source connection promptly, planting seeds by actions eight or nine. They later repeated exploration across the Strip, alley, garden, shop, bar and backroom without entering the casino or disco. The casino map action was genuinely offered in 78 and 73 decision requests respectively. This rules out missing map candidates as the explanation for these traces.

The [first failure](2026-09-22T03-03-25-328Z/8a939298-c77c-4f25-8d97-a27180338e4d/8a939298-c77c-4f25-8d97-a27180338e4d-003-unguided.jsonl.gz) made its last novel discovery around the busker at action 70, then exhausted the 24-action stall allowance. The [second](2026-09-22T03-03-25-328Z/8a939298-c77c-4f25-8d97-a27180338e4d/8a939298-c77c-4f25-8d97-a27180338e4d-006-unguided.jsonl.gz) last progressed with the wine-for-knife trade at action 64 and stopped at 88. Both repeatedly attempted unsuitable inventory combinations on the railing and revisited known conversations instead of trying the still-unvisited casino. These are concrete model planning failures; the bounded strategy judgment and observed memory did not prevent them.

There is also an actionable game-design weakness for a later iteration: the backstage poster's comic slogan does little to connect an unguided player to Didi at Studio 69 or the casino's free admission pass. A stronger in-world lead could make the next chapter less dependent on HUD objective text. That proposal is an inference from these two failed routes, not proof that all human players need it. A smaller copy defect remains: operating the planter after planting seeds, without the water pitcher, repeats the generic seeds-then-water instruction; examining it correctly acknowledges the planted seeds. Neither issue was silently changed during this fixed-build pilot.

### Eight-worker load

Visible requestAnimationFrame intervals within 20 ms were **12,341/13,728 (89.90%)**, below the proposed 95% target at this load. Per-worker p95 histogram upper bounds were 34–35 ms. Initial ready times ranged from 1,114 to 3,141 ms with uncontrolled cache state. UI callbacks had per-worker p95 values of 33–34 ms; callback-to-settled-frame p95 values were 88–113 ms, and browser dispatch acknowledgement p95 values were 128–172 ms. Model/network time is measured separately.

Eight simultaneous Godot iframes stress the workstation; these measurements do not establish standalone full-resolution game performance. Four workers were selected for the larger batch after the earlier four-worker pilot had better frame intervals. The first attempted large batch was canceled because a dashboard lifecycle bug invalidated its configured concurrency, as documented below.

## Excluded large-batch attempt and harness correction

[Batch 32abdb9c-6dad-4804-b29d-b682ed303b0e](2026-09-22T03-03-25-328Z/32abdb9c-6dad-4804-b29d-b682ed303b0e/summary.json) requested 100 runs with four workers immediately after the eight-worker pilot. The dashboard replaced only worker slots zero through three; finished iframes in slots four through seven remained alive and rendering. Thus configured four-worker performance was contaminated by four additional game instances. This is a QA harness defect, not a game dead end.

The operator stopped the attempt after 306 dispatched requests. Preserved observations account for 1,883,806 input tokens and about **$0.07912** in known input cost; three canceled requests have unknown provider usage. One unguided player had already stopped without progress; four started runs were stopped, and 95 never started. These are not 100 gameplay results. The entire attempt is excluded from configured four-worker performance and completion-rate comparisons, while exact traces, cancellation errors and costs remain available.

New-batch setup now unregisters and disposes **every** previous iframe, card and pending callback before registering fresh workers. It also sets the running guard before awaiting batch registration, preventing rapid double submissions. Regression checks cover switching eight finished workers to four and a delayed registration double-submit against the actual dashboard event handler. All 34 Node QA tests passed after the correction; the clean larger experiment must use a freshly loaded dashboard and a new recorded runner hash.
