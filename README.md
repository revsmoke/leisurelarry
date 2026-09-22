# Leisure Suit Larry: Last Call in Lost Wages

A complete, compact **Godot 4.7.2** point-and-click comedy adventure: thirteen illustrated rooms, a connected puzzle story, and a rooftop ending. An unofficial modern reimagining of *Softporn Adventure* and *Leisure Suit Larry 1*, with newly created art, dialogue, pixel characters and lounge music.

![The Neon Strip](docs/audits/browser-evidence/03-1.jpg)

## Play

- **Native Mac:** open `exports/macos/Last Call in Lost Wages.app`, or double-click `Play.command` to play from source.
- **Browser:** while the preview server runs, visit **http://127.0.0.1:8766**. Start it again with `node tools/serve-web.mjs`. Browser saves belong to that browser/site; native saves are separate.
- **Editor:** open `project.godot` in Godot, or run `./tools/godot --editor --path .`.
- **Portable builds:** `exports/Last Call in Lost Wages-macOS.zip` and `exports/Last Call in Lost Wages-Web.zip`. The Mac build is locally ad-hoc signed, not notarized. Serve the extracted Web files over HTTP; opening index.html directly is unsupported.

The game runs locally and needs no account, API key or network after loading. All game currency is imaginary.

## Controls

Click a scene target after choosing **Look, Talk, Take, or Use**. Select an inventory item, then click a target to use it. Selecting or right-clicking a pocket item also examines it; double-clicking uses it on itself. Click the scenery to move Larry. **Take** collects loose objects; **Use** operates machines and activities. To buy whiskey, choose **Use** and click **Lefty**, or type `buy whiskey`.

| Input | Action |
|---|---|
| 1 / 2 / 3 / 4 | Look / Talk / Take / Use |
| Right-click target | Examine |
| M / J / H | City map / notebook / hotspot labels |
| F5 / F9 | Manual save / load |
| F11 | Toggle full screen |
| Enter or command field | Type a parser command |
| Escape | Close overlay or clear selection |

Use the map to follow connected routes automatically. Locked rooms open through puzzles. **Show next step** gives an explicit solution hint with spoilers; the notebook preserves discoveries and completed favors. Use slots or blackjack at the casino to open the optional games; `play slots` and `play blackjack` work there too. Unfinished blackjack bets are refunded when closing the table.

Manual Save and Load use one slot. Progress also autosaves after actions. When an autosave exists, the next launch offers **Continue evening**; **? → Restore autosave** restores the same separate slot. New evening does not overwrite the manual save. Scroll within Help to read its complete instructions. Native data is in Godot's user-data folder for this project (`~/Library/Application Support/Godot/app_userdata/Leisure Suit Larry — Last Call in Lost Wages/` on this Mac).

## Included

- 13 distinct neon/pixel-textured backgrounds, independently animated pixel characters, a dance animation, and a garden tree that grows and loses its apple when harvested.
- 18 inventory items, 25 scoring milestones, a 100-point completion route, original narrator humor and flirtatious dialogue.
- Point-and-click and parser input, persistent gates, contextual objectives, clues, hints, manual saves and autosave.
- State-aware descriptions, an optional Didi follow-up, and a rooftop conversation that unfolds over three **Talk** actions after the final gift.
- Animated slots and blackjack, with a casino recovery mechanic that prevents money from blocking the adventure.
- Original 32-second lounge loop and music toggle.
- **46 historical reference images**: 44 screenshots and two manual scans, with provenance. Open [the searchable reference gallery](reference/index.html).
- Installed Godot, verified macOS/Web export templates, local Godot MCP configuration and an installed GDScript patterns skill.

The adaptation keeps the bar/remote/password, disco gifts, phone/rope, hotel favor and grown-apple chain. It changes motivations and condenses the route. It is **not a scene-for-scene reproduction** of either original: original commercial art/dialogue/music, several bedroom/chapel branches, death timer, taxi simulation, voice acting and full NPC animation are not included. Romance remains suggestive and non-explicit. [Design and scope](docs/design.md) explains the choices.

## Playtest and verification

**845 automated assertions pass across six suites.** The game was also played from beginning to end twice through the actual browser UI without hints: the baseline finished at **100/100, 97 moves, $48**; the rebuilt game finished at **100/100, 85 moves, $43**. The second run visibly confirmed the three-part Eve conversation, readable ending, garden tree, and fruit removal after harvesting.

The tester knew the implementation, so these are informed playtests, not blind novice tests or proof that everyone will find the game fun. See the [browser playthrough and issues](docs/audits/browser-playthrough.md) and [verification evidence and limits](docs/verification.md).

## Jev development playtesting

TypeSafe is installed for Codex at `.agents/skills/typesafe-ai/`; `AGENTS.md` records the project workflow. A separate local lab runs three isolated Godot Web instances with Jev choosing actions from player-visible text. The API key stays in the ignored `.env` and the server; the normal game still needs no network or account.

- [Run the playtest lab](tools/jev-qa/README.md)
- [Measured experiments and limitations](docs/jev-experiments.md)
- [Prioritized gameplay upgrade plan](docs/gameplay-upgrade-plan.md)
- [Applicable TypeSafe cookbooks](docs/typesafe-research.md)

Generated exports and installed dependencies are excluded from Git; the source, art, music, tests, research and experiment evidence are included. Rebuild with `./tools/package.sh all`.

## Research and development

- [Cited research and version differences](docs/research.md)
- [Source/image manifest](docs/references.json)
- [Complete walkthrough — spoilers](docs/walkthrough.md)
- [Godot, MCP and skill setup](docs/tooling.md)
- [Art prompts, asset origins and credits](docs/art.md)
- [Original music and reproduction](docs/audio.md)
- [Verification results](docs/verification.md)

```sh
./tools/godot --headless --path . --script tests/test_game.gd
./tools/godot --headless --path . --script tests/test_casino.gd
./tools/godot --headless --path . --script tests/test_interface.gd
./tools/godot --headless --path . --script tests/test_narrative.gd
./tools/godot --headless --path . --script tests/test_modal_layout.gd
./tools/godot --headless --path . --script tests/test_action_intent.gd
./tools/godot --headless --path . -- --smoke-ui
node tools/mcp-smoke.mjs
./tools/package.sh all
```

`game_state.gd` owns the independent model; `main.gd` renders it; `actor.gd` draws the actors; `world_effects.gd` draws the planted seeds and growing tree; `casino_panel.gd` owns the casino tables. `docs/`, `reference/`, development tools and tests are excluded from released game packs. No historical game binaries or original game assets are shipped in the builds.

The supplied walkthrough is retained untouched at the project root. This is an unofficial fan project; the original game names and characters belong to their respective owners.
