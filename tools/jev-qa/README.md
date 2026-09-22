# Jev live browser playtests

This development-only harness runs **three actual Godot Web instances** and lets Jev choose a closed-set action from player-visible text. It invokes the game's real UI callbacks and waits for rendered frames. It does **not** test pixel recognition, pointer hitboxes, screen-reader usability, or whether humans enjoy the jokes. No solution route, hidden quest flags, or state injection is given to Jev. Map labels, current inventory and acquired notebook clues are conveniently available together, so it is not an exact simulation of a novice's attention.

The normal game remains offline. TypeSafe is used only by the local testing server. Follow the installed [TypeSafe skill](../../.agents/skills/typesafe-ai/SKILL.md) and [project guidance](../../AGENTS.md).

## Run

Requires Godot with Web export templates and Node 24 (built-in fetch, dotenv loading, and node:test; no extra npm dependencies).

1. Put the real credential in the ignored root `.env` as `TYPESAFE_API_KEY=...`. Never put it in an HTML file, browser script, Godot resource, or result artifact.
2. Export the separate QA preset:

   ```sh
   mkdir -p exports/qa
   ./tools/godot --headless --path . --export-release 'Web QA' exports/qa/index.html
   ```

3. Start **one** server. For the recent-history condition:

   ```sh
   node tools/jev-qa/server.mjs
   ```

   For persistent observed-room memory instead:

   ```sh
   JEV_QA_MEMORY=1 node tools/jev-qa/server.mjs
   ```

4. Open `http://127.0.0.1:8767/`, wait for all three instances, and press **Start three players**. Watch the actual games and visible traces. Use **Stop after current actions** to end early. Restart the server and reload the dashboard for a separately recorded batch.

Each player has an 80-action budget. The server allows at most three concurrent API requests and 300 attempts per server session, with a 2M **observed** input-token threshold. In-flight requests can exceed that token threshold; timeouts or malformed responses may incur usage that is not counted. This is not a provider-enforced dollar cap. Requests time out after 30 seconds with no automatic retry. Closing/stopping the page does not retroactively cancel an already dispatched inference. The dashboard starts no new batch automatically.

The test export requires `qa_playtest`, Web, and the exact origin above. It starts fresh, disables all manual/autosave access and music, and validates parent origin/source, observation revision and candidate ID before invoking controls. A human changing the game while Jev thinks invalidates that decision. Production Web and native builds do not activate this bridge. Credentials stay in Node; the test page receives only a separate per-server anti-CSRF token.

## What the two conditions mean

Three policies run in each batch: objective-led, curious, and objective text withheld. All receive current visible scene text, inventory, map availability, learned notebook clues, available actions and the last 12 outcomes. The memory condition also retains observed hotspot labels and the latest five distinct dialogue lines per visited room. It adds a reminder to consult those observations; it does not supply undiscovered object locations. This is a player-policy comparison with one run per cell, not a controlled population study.

Choice selects an action; independent Score and Noul questions rate clue clarity and possible dialogue contradiction in the same request. Their values are review signals, not truth. Low Choice confidence is retained; it does not block harmless test actions. Repeated identical observed states stop after four attempts, but alternating room cycles may run until the budget. The current report explicitly recommends a stronger cycle detector before large batches.

## Evidence and checks

Each server writes a dated folder under `docs/experiments/jev/`:

- `decisions.jsonl`: exact textual request, candidate set, returned distributions, model, token usage, and API duration.
- `events.jsonl`: resulting UI observations, selected actions, render/acknowledgement duration, final history and stop reasons.
- `summary.json`: atomically written outcomes, budgets, p50/p95 API latency, and estimated cost at the documented rate.

Timestamps use UTC. No authorization headers or credentials are written. API duration includes network overhead. Action duration starts after inference and measures dispatch-to-settled-render acknowledgement; it is not a full input-to-photon or frame-time benchmark. Sampled Godot FPS is diagnostic only, especially when browser visibility/throttling changes. Preserve traces from failures as well as successes.

```sh
node --test tests/test_jev_client.mjs
./tools/godot --headless --path . --script tests/test_qa_bridge.gd
./tools/godot --headless --path . --script tests/test_interface.gd
```

`node tools/jev-qa/calibrate.mjs` is an optional **six paid API requests** sanity check over two simple fixtures, three repetitions each. It is separate from live gameplay. Raw results and limitations are in [the experiment report](../../docs/jev-experiments.md); planned game changes are in [the upgrade plan](../../docs/gameplay-upgrade-plan.md).
