# Animated travel and entrance scenes

Implemented on 2026-09-22. Every accepted location change now presents a short, authored travel scene, whether chosen from an exit, the City map, a parser command, or the hotel elevator hotspot. The ordinary game remains offline. Routing, gates, money, inventory and scoring stay in the deterministic game model.

## Presentation

Six visual treatments cover the thirteen locations:

- Doorway: Larry approaches a hinged door, enters, and emerges in the destination. The Neon Strip/Lefty's entrance aligns the doorway with the bar exterior.
- Walking: a short walk joins nearby locations.
- Taxi: Larry boards at an exterior curb, rides past a scrolling neon skyline, and leaves the cab before the destination interior appears. Cross-building map jumps use the appropriate district; courtesy rides charge no money.
- Elevator: Larry enters, doors close, the floor indicator moves in the correct direction, and the doors reveal the destination.
- Rope: Larry carefully crosses the secured line to or from the fire escape. The existing rope gate still controls access.
- Terrace: doors and planted edges frame garden/rooftop travel.

Normal durations are 3.5–4.4 seconds. Each scene has a visible Skip travel button; Space, Enter or Escape arrives immediately. The browser text-control drawer honors those keys through the same visible Skip button. Reduced motion presents a one-second departure/arrival still card, with no walking, panning or flashing. Audio cues use the existing effects volume/mute preference. Narrator lines rotate across repeat journeys within an evening, using newly written innuendo and jokes about Larry's confidence, cologne and trousers.

The accepted destination autosaves at departure, before animation. Skip does not spend another move, charge a fare, award points or repeat an action. Input from the room underneath is blocked during travel, including stale retained buttons. Loading an evening does not replay its entrance. Multi-room map travel still follows connected unlocked exits, but shows one montage instead of one movie per intermediate room. USE the taxi stand now opens the ordinary City map with its existing locked destinations.

## Code and builds

**4,245 Godot assertions and 34 Node tests passed.** [Per-suite results and source hashes](travel-code-checks.json). This includes 334 new travel assertions covering all six modes, natural completion, repeated play/free cycles, idempotent skipping, stale actions, accepted-save semantics, map/exit/parser/elevator/taxi input paths, reduced motion, restoring saves, and the QA bridge waiting for actual arrival. Existing full adventure, save, UI, modal, route, visual, companion and responsive suites also passed. The audio test was updated to cover six new travel cues in addition to the four existing cues.

Both normal Web and macOS exports were rebuilt and passed resource verification. The verifier now requires the compiled travel component. The exported macOS application passed its native smoke check. [Artifact hashes and sizes](travel-builds.json); [native scene lifecycle sample](travel-memory-lifecycle.json). The latter is a headless lifecycle measurement, not a browser/WASM or full-route memory guarantee.

## Actual browser checks

The assistant tested the real normal Web build using the in-app Browser and its visible canvas/HTML controls. This used the existing completed classic-route save to access gated destinations; no state was injected. It was an informed targeted transition review, not a fresh-player study or another complete manual story replay.

Observed terrace travel from Eve's roof to the penthouse, elevator descent to the hotel, taxi travel to the Strip, entry into Lefty's, backstage-to-fire-escape rope travel, and walking between the Strip and shop. The final taxi correction was then checked on a map journey from backstage to the hotel: boarding was outdoors and arrival returned to the correct hotel room. Cash remained $48 and exploration score 96 through these movements.

The first browser pass caught a taxi appearing in the hotel lobby during boarding. The final version uses an opaque exterior city/road throughout boarding and transit, removes the taxi before the interior reveal, and labels the curb with its origin. Unit/callback testing also caught a typed-array caption failure and the elevator hotspot bypassing the travel presentation; both were fixed before the Jev batch. Final browser checks verified reduced-motion stills, then restored the prior motion preference. Music remained muted as found.

The HTML keyboard control's Space shortcut skipped a 4.4-second hotel-to-Strip ride and visibly reached the Strip in 394 ms in one observed check. Escape was also exercised. A reload issued while Lefty's entrance scene was still visible restored directly inside Lefty's with the existing money/progress, confirming real browser persistence for that interrupted journey.

Screenshots from the live browser at its existing compact viewport:

- [Hotel elevator](travel-browser-evidence/01-elevator.png)
- [Lefty's entrance](travel-browser-evidence/02-leftys-entrance.png)
- [Secured rope crossing](travel-browser-evidence/03-rope-crossing.png)
- [Corrected exterior taxi boarding](travel-browser-evidence/04-taxi-exterior-fixed.png)
- [Reduced-motion departure and arrival](travel-browser-evidence/05-reduced-motion.png)
- [Walking](travel-browser-evidence/06-walking.png)

The component was additionally inspected through native rendered fixtures for all six visual modes, including taxi departure/arrival frames. Those fixtures are visual review, distinct from player-driven Browser travel.

## Live Jev integration regression

Two fresh isolated Web workers both completed an evening with animations enabled: 78 and 110 executed actions. Their 48 room-changing actions waited 3.54–4.47 seconds for the actual movies and returned settled destination controls. There were 188 model requests and no API, bridge or travel-timeout errors. Known input cost was approximately $0.05462. [Exact conditions, model/version, decisions, confidence, costs and limitations](travel-jev-analysis.md).

This batch ran before the final exterior-taxi visual correction and browser-drawer shortcut patch; its recorded pack hash is preserved. Final ordinary code checks and actual Browser observations cover those later changes. The final rebuilt QA pack has its own hash in the artifact manifest. No earlier experiment was relabeled as testing a later binary.

These two text-driven model players verify sequencing and reachable endings under their recorded conditions. They cannot judge the animation pixels, sexiness, joke quality or human tolerance for repeated travel scenes. The skip control and reduced-motion option keep those scenes optional. No new human enjoyment or standalone performance certification is claimed.
