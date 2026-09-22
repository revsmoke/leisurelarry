# Working on Last Call in Lost Wages

Read `README.md`, `docs/design.md`, and the relevant tests before changing the game.
Use `.agents/skills/godot-gdscript-patterns/SKILL.md` for Godot implementation.

Use `.agents/skills/typesafe-ai/SKILL.md` when working on this project. Read the
current TypeSafe docs and relevant cookbooks before adding or changing a TypeSafe
integration. Keep deterministic game rules and execution in code; use Jev for
bounded semantic judgments over explicitly described observations. Keep the
resulting confidence, model version, input, candidate set, and observed outcome
when reporting experiments. A typed answer or confident choice is not proof of
correctness, good design, or player enjoyment.

## Credentials and build boundaries

- Read `TYPESAFE_API_KEY` from the local `.env` on the server only. Never print it,
  commit it, send it to the browser, or include it in an export or result artifact.
- Keep `.env` and `.env.*` excluded from Git and Godot exports. A placeholder
  example is fine if it contains no credential.
- Browser QA runs on `http://127.0.0.1:8767` with the `Web QA` export's
  `qa_playtest` feature. The normal Web/native game must not activate the bridge.
- Preserve QA session isolation: fresh games, no shared manual/autosave access,
  no music, origin/source validation, revision checks, and closed-set actions.
  Use the real UI callbacks; never grant items or set quest flags for a model run.
- Jev observations contain player-visible text and learned clues. Do not supply
  hidden quest flags, walkthroughs, hint-function results, or source-derived
  solution knowledge to a run described as unaided gameplay.

## Verification and reporting

Run checks appropriate to the change. For bridge/UI isolation changes, run:

```sh
./tools/godot --headless --path . --script tests/test_qa_bridge.gd
./tools/godot --headless --path . --script tests/test_interface.gd
```

Keep reproducible experiment artifacts and document failures as well as wins.
Distinguish headless model tests, UI callback tests, live Web runtime experiments,
and actual human browser playthroughs. Text-driven Jev runs do not test visual
perception or prove that a game is fun. Report measured sample sizes, budgets,
completion/loop rates, and timing conditions without treating estimates as facts.
Do not turn desired outcomes such as “award-winning” into verification claims.

Keep the comic tone adult, playful, and character-driven. Romance remains
consensual and suggestive; strong punchlines, player agency, clear feedback, and
satisfying consequences matter more than explicitness or repetitive rewards.
