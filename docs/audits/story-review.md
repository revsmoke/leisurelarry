# Narrative and puzzle-design source review

Reviewed 22 September 2026. This is a complementary source review of the **baseline** game model and interface, **not evidence of a browser playthrough**. References below describe the source at the time of that review; the original line numbers have moved as fixes were implemented. Judgments about enjoyment are design judgments to compare with an actual playthrough.

## Follow-up status

The source now includes fixes for the principal findings below: guidance introduces Eve before the apple errand; descriptions and dialogue reflect completed favors; Eve's final exchange has three conversation beats; Didi acknowledges the stage manager's message and the completed show preparations; TAKE refuses people and immovable machines; learned ordinary conversation clues are recorded once. The direct-solution hint remains, but its button is now honestly labeled **Show next step** and its response announces spoilers. A graduated hint ladder and broader dialogue choices remain possible later improvements.

Related interface fixes give Help a scrolling reading area, enlarge the objective and ending text areas, and offer **Continue evening** when an autosave exists. Source also includes a dance animation and visible garden growth/harvest feedback. The **rebuilt game has now completed an actual browser retest at 100/100, 85 moves, and $43, without hints**, following the baseline browser run at 100/100, 97 moves, and $48. The retest visibly confirmed all three Eve conversation beats, a readable ending, the garden tree, and fruit removal after harvesting. The [browser playthrough audit](browser-playthrough.md) owns those observations and visual evidence; this report remains the complementary source review. The tester knew the implementation, so the replay is not a blind novice test or proof of general player enjoyment. The findings below are retained as the baseline record rather than silently rewritten as if the original problems never existed.

The baseline route was mechanically connected and its objects usually explained their intended use. Its larger weakness was that the city often behaved like a list of exchanges: the objective supplied the player's motivation, characters forgot completed favors, and the ending asserted a personal connection without letting the player participate in that conversation.

## Findings

### P2 — The final gardening task is assigned before its story motivation

**Evidence:** `scripts/game_state.gd:602–616` changes the objective directly from bringing coffee to growing an apple, then finally introducing Larry to Eve. `hint():652–665` likewise postpones meeting Eve until after the apple is grown and collected. But `scripts/game_state.gd:421–428` contains the actual reason to find fresh food in Eve's first conversation. That conversation can be visited earlier, yet the primary guidance directs the player away from it.

**Player consequence:** A player following “The Plan” does a multi-room horticulture errand before knowing who it is for. Eve's eventual request then becomes a formality completed with an object already in hand. This weakens the intended change from generic seduction to listening and thoughtfulness.

**Suggested fix:** After the receptionist grants access, make the immediate objective “Join the rooftop gathering and introduce yourself.” Let Eve's first conversation establish the fresh-food request, then guide the apple puzzle. Keep early exploration and early apple collection valid so this remains guidance rather than a new hard gate. Update the objective immediately after each discovery.

**Acceptance check:** On a fresh route, follow only the objective after receiving the invitation. The first recommended destination should be the rooftop; meeting Eve should be the event that changes the objective to finding fresh food.

### P2 — Characters and scenery forget completed interactions

**Evidence:** The regular's LOOK and TALK always describe holding the remote and ask for a whiskey trade (`scripts/game_state.gd:358`, `403`), even though the completed exchange records `whiskey_given` and removes the whiskey (`455–461`). The busker keeps requesting wine and promising the knife (`381`, `417`) after `wine_given` is set (`476–482`). Didi repeats the full three-prop shopping list after partial deliveries (`408–415`), although each delivered prop has its own flag (`468–475`). The source descriptions remain static for the stolen-from dish, emptied ashtray, unstuck window, emptied cabinet, and picked tree (`365`, `372`, `386`, `388–389`). Room descriptions likewise remain unchanged; `get_room()` only changes hotspot visibility and exit locks (`115–136`).

**Player consequence:** Revisiting people and rooms does not acknowledge what the player did. A player can reasonably think a trade failed or that a second item exists, and repeated conversations give little pleasure or useful updated information.

**Suggested fix:** Branch LOOK, TALK, and relevant room descriptions on existing completion flags. Have Didi thank the player for delivered props and name only missing ones. After a trade, use a new short joke and an onward clue instead of repeating the initial offer. Describe the window as open, the cabinet as empty, and the tree as picked after those changes.

**Acceptance check:** Revisit each exchange immediately afterward and after an unrelated room visit. No dialogue should still claim the NPC owns an object now in the player's pockets or ask for an already completed favor.

### P2 — The final “honest conversation” is skipped by the game

**Evidence:** After the apple is given, Eve says “Tell me something interesting” and asks the player to TALK (`scripts/game_state.gd:539–544`). The very next TALK sets `completed = true` and narrates the sunrise invitation (`421–426`). There is no actual story told by Larry, question answered by Eve, choice of conversation, or callback to the player's evening. The ending panel is a static paragraph about Larry listening (`scripts/main.gd:579–585`). The current objective expressly promises an “honest conversation” (`scripts/game_state.gd:616`).

**Player consequence:** The reward arrives at the moment the game finally seems to offer a social interaction. A click completes it without showing that interaction. This is a weak payoff for an entire evening of item delivery and undercuts the claimed narrative theme.

**Suggested fix:** Add a short, non-failable two- or three-beat conversation. Let Larry tell one concrete story from the evening, give Eve a distinctive response, and let her ask or reveal something of her own before the invitation. A small set of dialogue topics can offer personality without creating branching endings. At minimum, write the actual exchange as separate steps rather than asserting that it happened.

**Acceptance check:** The player should be able to identify one thing Eve learns about Larry and one thing Larry learns about Eve before the end screen. The final interaction should acknowledge an earlier event the player experienced.

### P2 — Didi's central subplot has no closure after the prop delivery

**Evidence:** Didi's introduction establishes a cabaret opening and a personal dance (`scripts/game_state.gd:408–415`). Delivering the final prop resolves only to a telephone number (`436–440`, `468–475`). Every later successful TALK returns the same number. The stage manager asks for a dance at the opening (`582`), but there is no show-start, show-status, follow-up dance, updated poster, or other resolution in the content. The cabaret poster is permanently the same joke (`368`). The ending acknowledges only Eve and the apple (`scripts/main.gd:579–585`).

**Player consequence:** Helping the strongest mid-game character feels like paying a toll to obtain an unrelated rope. The player never sees how the favors mattered to Didi or receives a clear goodbye before the story moves to Eve.

**Suggested fix:** After the props are complete, provide an explicit thank-you and invitation/clear goodbye; after the phone call, replace repeated number dialogue with an update on the show. A small closing callback in the cabaret poster, stage sound, notebook, or ending would pay off the work without requiring a new scene. If the opening will not be playable, avoid dialogue that sounds like a new outstanding quest.

**Acceptance check:** After finishing Didi's requests, talk to her again. Her response should acknowledge success and make clear whether there is anything further to do with her. The end should include at least a brief payoff for the show the player helped.

### P2 — The four-verb interface silently treats distinct intentions as the same action

**Evidence:** `interact()` handles LOOK and TALK specially, but all other accepted verbs enter the same target switch (`scripts/game_state.gd:255–342`). Thus TAKE Didi can start a dance, TAKE regular starts a conversation, and TAKE bartender buys whiskey. USE on a puzzle target automatically uses the appropriate carried object (`306–339`) while a wrong item produces one generic rejection (`545`).

**Player consequence:** A player cannot form a reliable mental model of the selected verb. Many puzzles collapse to repeatedly using targets until the model chooses the intended action. Useful forgiving behavior is mixed with surprising purchases and actions that do not match the player's request.

**Suggested fix:** Preserve explicit USE convenience where intentional, but make TAKE act on collectible/purchasable objects and refuse people with a specific funny response. Either introduce contextual action labels (“Buy whiskey,” “Dance,” “Call”) or honor the four shown verbs consistently. Avoid charging money for a verb that does not clearly indicate buying.

**Acceptance check:** Try LOOK, TALK, TAKE, and USE on Didi, Lefty, the regular, and the dance floor. Each response should either carry out the stated intent or explain a sensible alternative. Merely taking a person should not advance a dance or spend cash.

### P3 — “A little nudge” provides complete solutions and ignores local curiosity

**Evidence:** The UI calls the hint button “A little nudge” (`scripts/main.gd:154`), but `hint()` reveals exact items, verbs, prices, and destinations (`scripts/game_state.gd:619–666`). The visible objective also often names the solution, including the tool for the window (`612`). The direct-hint behavior is documented intentionally in `docs/design.md`; it is not a mismatch with that document.

**Player consequence:** The player chooses between following a checklist and receiving the entire next solution. There is no intermediate help for a player who understands a situation but wants a clue rather than an answer. This makes the game accessible, but reduces discovery and inference.

**Suggested fix:** Separate a gentle situational hint from an explicit “Tell me exactly what to do.” At minimum rename the current button “Show next step” so the spoiler level is honest. Keep the notebook focused on facts the player learned and the objective focused on goals, not every tool needed to achieve them.

**Acceptance check:** First hint should describe a need or point of interest; a subsequent explicit request may reveal the exact combination. A player should not lose a puzzle's solution merely by asking for a nudge.

### P3 — Ordinary exploratory dialogue is not retained in the notebook

**Evidence:** `_say()` overwrites the single dialogue display (`scripts/main.gd:409–413`). The notebook shows only `game.journal` (`531–548`); journal entries are mainly added by scoring events. Several concrete clues from ordinary LOOK/TALK — notably the busker's trade and receptionist's coffee request — do not record themselves (`scripts/game_state.gd:381`, `417–420`).

**Player consequence:** The help says “Your notebook keeps the clues” (`scripts/main.gd:552`), but ordinary conversations can be overwritten by the next click without any retained wording. Players exploring several locations before acting must remember those clues or consult the linear spoiler hint.

**Suggested fix:** Record discovered requests and actionable observations once when heard, then mark them completed or move them into a completed section. Alternatively add a separate recent-dialogue log. Keep entries short and distinguish actual discoveries from objective guidance.

**Acceptance check:** Talk to the busker or receptionist, leave the room without fulfilling the request, then open the notebook. The discovered favor and where it came from should be recoverable.

## What already works

- Failed item combinations do not consume items, which supports experimentation (`scripts/game_state.gd:453–545`).
- Most puzzle objects have usable prose clues and direct right-click examination (`scripts/game_state.gd:345–397`, `scripts/main.gd:326–338`).
- The receptionist has a post-favor response (`scripts/game_state.gd:419`) that demonstrates the small state-dependent dialogue changes needed elsewhere.
- The independent puzzle model makes these content changes practical to regression-test without making a new rendering architecture.

## Suggested implementation order

1. Correct stale dialogue/descriptions and record heard requests.
2. Put the rooftop introduction before the guided gardening task.
3. Add an actual finale conversation and a clear Didi follow-up.
4. Resolve verb semantics, then improve the hint ladder.

These findings do not imply that the existing route is impossible to finish. They explain why completing its dependency chain is weaker evidence than finding the game understandable, responsive, and satisfying during an actual playthrough.
