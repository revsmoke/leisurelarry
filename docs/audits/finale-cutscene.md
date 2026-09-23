# Four-act finale

The winning invitation now plays a dedicated **12-second animated finale with both selected characters**. Larry/Lisa and Eve/Adam share a rooftop invitation, move together, disappear behind the comic privacy curtain, and return side by side for a sunrise victory tableau. Warm skyline lighting, palms, champagne, a heart, confetti, their names, and the **YOU GOT LAID** title give the ending a distinct payoff. Optional encounters retain their existing shorter scenes. Intimacy stays offscreen.

Reduced motion shows both characters in a static three-second sunrise tableau. All phases can be skipped. The HTML text/keyboard surface receives complete act updates, not a per-frame stream. Completed evenings offer **Replay finale** in the room and ending panel. Replay works with existing version-2 completed saves and changes no points, money, turns, flags, inventory, or saves. It returns to the ending panel; an unfinished evening cannot replay an unearned finale.

## Verification

**1,892 assertions across eight relevant Godot suites and 34 Node tests passed.** [Exact checks and source hashes](finale-code-checks.json). The selected suites cover character pairings, all cinematic phases, skip idempotence, reduced motion, real UI replay controls, save preservation, compact/wide layout, HTML companion, and QA isolation. One callback test watches the actual full twelve seconds naturally, catching the former eight-second QA deadline. The bridge now allows sixteen seconds, within the existing browser driver's twenty-second deadline. The full seventeen-suite campaign from the preceding update was not repeated for this presentation change.

[Build evidence](finale-builds.json) records rebuilt Web/macOS packages, export-content verification, a native launch smoke check, and the separate QA pack hash. The native smoke check is not a full native playthrough.

The assistant watched the normal Web build at `127.0.0.1:8766` using the restored completed Lisa/bisexual evening. The visible replay button launched Lisa and Adam together. All four acts were observed through both the rendered scene and changing HTML act text. The movie finished naturally into the ending panel. A second replay was skipped using Space. A third used reduced motion and showed both characters, the victory title, and names. The ending remained at **52/100, $80, 83 moves**. Reduced motion was restored to OFF afterward, matching the original preference.

| Browser evidence | What it shows |
| --- | --- |
| [Invitation](finale-browser-evidence/01-invitation.png) | Both named participants arrive on the rooftop |
| [Together](finale-browser-evidence/02-together.png) | The pair approaches before the privacy gag |
| [Curtain](finale-browser-evidence/03-curtain.png) | Offscreen interlude and narrator punchline |
| [Sunrise transition](finale-browser-evidence/04-sunrise.png) | Both characters return as the lighting warms |
| [Reduced-motion final tableau](finale-browser-evidence/05-reduced-motion.png) | Static pair, names, victory title, and visual punchline |

The same-gender pairings and Larry/Eve were checked by component assertions and native render captures; this browser pass used Lisa/Adam. The browser test replayed a legitimately completed saved evening rather than repeating the complete puzzle route. Existing interface tests still verify the ordinary route and earned ending. No new Jev API campaign was run: its text-only observations cannot judge the animation. Current [TypeSafe State guidance](https://docs.typesafe.ai/concepts/state) and the [function-calling cookbook](https://docs.typesafe.ai/cookbooks/function_calling) were reviewed; the closed-set UI execution and server-only credential boundary are preserved.

Review caught and corrected three integration problems before verification: headless bridge startup needed its explicit test mode, the nonmodal QA candidate list needed the visible replay button, and wide-window resizing could restore a status label over that button. An early local test was interrupted while the new phase signal was still being added; the completed-source checks above all passed. No model enjoyment or performance claim is made by this visual update.
