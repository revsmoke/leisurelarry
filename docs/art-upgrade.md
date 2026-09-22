# State-driven prop art, 2026-09-22

The presentation upgrade separates puzzle props from their painted backgrounds. Six targeted background edits were generated with the built-in image-generation tool, then inspected before integration. The original thirteen backgrounds remain unchanged for provenance; `WorldEffects.background_path_for` selects the clean plate for five rooms and the open-window plate after the service-window action. The game has thirteen locations and nineteen background files, including these variants.

| New asset under `assets/backgrounds/` | Edited from | Change |
| --- | --- | --- |
| `garden-clean.png` | `garden.png` | Removes the baked stool and watering can. The real folding stool can now disappear after collection. |
| `penthouse-clean.png` | `penthouse.png` | Removes the top-shelf brass pitcher. A state-driven cabinet holds the collectible pitcher and opens when the stool is placed. |
| `backroom-clean.png` | `backroom.png` | Removes the painted chocolate box. Its independent tray disappears after collection. |
| `alley-clean.png` | `alley.png` | Removes the painted apple core and mallet. Independent props disappear after collection. |
| `balcony-clean.png` | `balcony.png` | Removes the painted coffee voucher. The collectible card appears after the window opens and disappears after collection. |
| `balcony-open.png` | `balcony-clean.png` | Raises the lower window sash, preserving the warm room beyond. |

`world_effects.gd` draws the new props, stage marks, footlights, secured backstage rope, bowling picture, delivered coffee, garden tree, and rooftop response. It uses the same deliberately simple geometric vocabulary as the independent actors. These are state-driven additions, not a replacement of every illustrated object with detailed sprites. `actor.gd` adds three dance styles and static readable reactions. Reduced motion retains all puzzle information. `sound_effects.gd` synthesizes four short original offline cues; every required cue also has visible feedback.

## Exact image prompts

Garden cleanup (single source image `garden.png`):

> Use case: precise-object-edit. Edit the supplied game background as a clean production background plate. Remove only the small gray stool and brass watering can together at the base of the rectangular foreground planter, lower left-center (approximately x=508..745, y=585..725 in the 1672x941 input). Seamlessly continue the planter's existing tiled vertical wall behind them and the pavement underneath. Keep every other detail, camera position, composition, fountain, plants, lighting, neon, color palette, and retro pixel-textured illustration unchanged. Do not add people, furniture, placards, labels, UI, new props, or new writing. Output one complete landscape background, same framing and aspect ratio as the input.

The next four requests used this exact common prefix and suffix, with the per-room instruction inserted between them. Each request supplied only its corresponding original background.

Prefix:

> Use case: precise-object-edit. Edit this retro adventure-game background into a clean production plate.

Per-room instructions:

- Penthouse: “Remove only the brass watering pitcher on the highest upper-right shelf (approximately x1497..1645, y30..140). Reconstruct the empty shelf and wall/foliage behind it. Keep the cabinet doors, kitchenette, books, plants, bottles, and all other props unchanged.”
- Backroom: “Remove only the open red chocolate box with its raised 'Life is Sweeter' lid and all chocolates at the front right table (approximately x1080..1340,y590..740). Reconstruct the wood tabletop behind it. Preserve the neighboring chicken prop, bowler hat, small white note, books, furniture, stage, and every other detail.”
- Alley: “Remove only the tiny red apple core on the ground in front of the green dumpster (x480..511,y685..735), plus the mallet lying in the open red tool box at lower right (roughly x1200..1265,y680..718). Reconstruct wet paving and tool-box lining. Keep all surrounding props, bin, tool box, guitar, and the rest of the scene unchanged.”
- Balcony: “Remove only the small cream FREE COFFEE voucher card on the round table below the window (roughly x1080..1160,y505..552). Reconstruct the round tabletop. Keep the entire closed window, room beyond, rope tied to railing, neon skyline, furniture, architecture, and all other details unchanged.”

Suffix:

> Keep the exact input composition, perspective, crop, aspect ratio, lighting, saturated neon palette, and pixel-textured illustration style. Change nothing outside the specified tiny removed object. No new objects, text, UI, characters, or signs. Return one full landscape background, not a crop or collage.

Open-window variant (single source image `balcony-clean.png`):

> Use case: precise-object-edit. This is the closed-window version of a retro adventure game room. Make an OPEN-WINDOW version: raise the lower half/sash of the large service window at center-right so there is a clearly open rectangular opening at the bottom, with no glass or wooden crossing bars obstructing that lower opening. Keep the warm interior/lamp/furniture behind the opening visible and plausible, and keep the upper sash and surrounding frame. Keep EVERYTHING else exactly unchanged: composition, camera, rope, table (empty of voucher), chairs, skyline, neon, plants, brickwork, all writing, pixel-textured painting style, original aspect ratio and crop. Add no characters, UI, labels, furniture, or extra props. One complete landscape image, not a collage.

## Reproduce presentation checks

```sh
./tools/godot --headless --path . --script tests/test_upgrade_visuals.gd
./tools/godot --path . --script tests/test_upgrade_visuals.gd -- --capture-props
./tools/godot --headless --path . --script tests/test_web_companion.gd
```

The second command writes native renderer fixtures to `exports/prop-captures`. These fixtures deliberately set visual state, so they are presentation checks rather than live gameplay evidence. The actual gameplay browser audit is separate. Automated assertions verify prop-state transitions, reduced motion, non-repeating idle actors, offline muted audio, production/QA separation for the HTML companion, actual control signals, stale-action rejection, and transcript reset. They do not establish aesthetic quality or screen-reader compatibility.
