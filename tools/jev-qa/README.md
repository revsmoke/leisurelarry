# Jev live browser playtests

The development lab runs **2, 4 or 8 actual Godot Web instances** with **up to 100 fresh runs in waves**. Jev selects a closed-set action using player-visible text, observed locations and learned notebook clues. The adapter invokes real UI callbacks and waits for rendered frames. It never grants items, changes quest flags or supplies a walkthrough. This does **not** test pixel recognition, pointer hitboxes, screen readers or human enjoyment.

The production game stays offline. The API credential is read only from the ignored root `.env` by Node. Follow the installed [TypeSafe skill](../../.agents/skills/typesafe-ai/SKILL.md) and [project guidance](../../AGENTS.md).

## Run

Requires Node 24 and Godot with Web templates; no npm dependencies.

```sh
mkdir -p exports/qa
./tools/godot --headless --path . --export-release 'Web QA' exports/qa/index.html
node tools/jev-qa/server.mjs
```

Open **http://127.0.0.1:8767/**. Set concurrent workers, run count, actions per run, request cap, observed token/cost thresholds, memory and candidate-order seed. Press **Start bounded batch**. No API request occurs before Start. Defaults are 2 runs, 2 workers, 160 actions each, 1,000 attempts, 12M observed input tokens and a $0.60 estimated-input-cost threshold. Up to 100 runs / 200 actions / 20,000 attempts are accepted. Begin with a small pilot; 100 is capacity, not a claim that 100 runs have been performed.

The hard request cap is reserved before dispatch. Token and dollar thresholds use **reported usage**: in-flight requests can exceed them, and timeouts/malformed responses may have unreported charges. These are not provider-enforced spending limits. Price is $0.042/M input tokens, as documented at [TypeSafe models](https://docs.typesafe.ai/models). API calls time out at 30 seconds and are never automatically retried. Stop cancels pending inference locally and starts no further runs; the provider may still bill dispatched work.

The page reuses worker slots by destroying each finished iframe and loading a fresh instance for the next run. Starting another batch retires every previous worker, including extra slots when switching from eight to four; Start is locked while registration is pending. Unique run IDs, source/origin checks, request IDs, observation revision checks, duplicate-step rejection and server-side registration prevent old responses crossing sessions. Production Web/native builds cannot activate the bridge. QA games do not read/write manual or autosaves, and do not play music.

## Player policy and stopping rules

Policies rotate objective-led, curious and objective-withheld. Candidate order is reproducibly shuffled using the recorded seed, run index and step. All policies receive acquired notebook clues and up to 12 recent outcomes; persistent observed-room memory keeps labels seen at each room and its latest eight distinct dialogue lines. Historical labels are distinguished from current labels. The objective-withheld condition removes objectives from current state and history.

Each inference batches four **independent** judgments: an action Choice, a tentative strategic-intention Choice for the following turn, a 0–3 clue-clarity Score and a dialogue-contradiction Noul. A strategy is an inference, not observed truth. Confidence and critics are retained as review signals; they do not establish correctness or fun. The strategy experiment has not been assumed to improve performance.

Code detects cycles of 1–6 actions repeated three times with no new observed progress, plus a 24-action no-progress limit. New inventory items, notebook clues, hotspot/topic labels and score increases reset it. Travel and wallet oscillations alone do not. A cycle explicitly stops and escalates for review: it is not counted as completion, nor proof of a game defect. Other stop reasons include actual completion, model abstention, action/request budget, provider/driver error or cancellation.

## Evidence

Each server creates `docs/experiments/jev/<UTC session>/<unique batch>/`:

- `summary.json`: configuration, QA pack and runner-source SHA-256 hashes, requested/returned model, budgets, outcomes, API p50/p95 and server RSS diagnostics, atomically published.
- `<run-id>.jsonl.gz`: exact request/candidate set, response distributions, confidence, usage, latency and resulting UI observations. Appended gzip members preserve every record while keeping files comfortably below GitHub's per-file limit. `gunzip -c` reads them normally.
- `latest.json` in the session directory points to the latest batch.

Failures retain their inputs, stop reasons and traces. Summarize a session or batch with:

```sh
node tools/jev-qa/summarize.mjs docs/experiments/jev/<session>
```

This writes `aggregate.json` with completion, loop-stop and other outcome counts, per-policy actions, timing and sampled FPS. API time includes network overhead. Action time is inference-end to settled-frame acknowledgment, not full input-to-photon time. Cold load is iframe creation to first observation; cache state is not forced. Page visibility is recorded. The bridge also records requestAnimationFrame intervals for visible documents after a two-second warmup, the exact fraction within 20 ms, and p50/p95 upper bounds from 1 ms histogram bins (overflow at 1,000 ms). These are callback intervals, not GPU render duration. Browser JS heap is recorded only when supported; it may be shared and does not represent all Godot/WASM memory. Godot static-memory monitoring is separate and null when the engine cannot provide it. Server RSS excludes browser/Godot memory. Synchronous game callback time, settled-frame time, HTTP decision round-trip, and end-to-end action acknowledgement stay separate. Do not claim the release performance gate from sampled FPS alone.

## Critic calibration and tests

```sh
node --test tests/test_jev_client.mjs
./tools/godot --headless --path . --script tests/test_qa_bridge.gd
./tools/godot --headless --path . --script tests/test_interface.gd
./tools/godot --headless --path . --script tests/test_memory_lifecycle.gd
```

The Node suite mocks 100 scheduled runs, eight workers, budget/cancellation/timeout failures, stale messages and malformed provider responses; this is **not** a paid or live gameplay run.

`node tools/jev-qa/calibrate.mjs --critic` makes **60 paid requests**, two at a time: 20 developer-labeled stale/current dialogue pairs (40 cases), plus 20 actionable/non-actionable clue cases. The first pair reproduces the old TV/bouncer contradiction. Fixed thresholds are contradiction probability ≥0.5 and clarity score ≥2/3. The uniquely named result includes exact fixtures/requests/answers, precision, recall, missed defects and false alarms. These small synthetic, related examples are not held-out human labels and do not justify automatic quality gating. Without `--critic`, the older six-call action-selection sanity check remains available.

Current API, Choice, confidence, function-calling, parallel-questions and citation-check cookbook docs were reread for this update. Their useful pattern is bounded semantic selection plus deterministic execution, with independent editorial questions batched over the same visible observation. No runtime game-AI dependency was added.
