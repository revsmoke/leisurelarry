# Browser playthrough — 2026-09-21

Status: **two complete browser playthroughs finished**, before and after fixes. The baseline reached **100/100 in 97 recorded moves, $48 remaining**; the rebuilt game reached **100/100 in 85 recorded moves, $43 remaining**. Both visited all 13 rooms and used ordinary game controls without the hint button, state injection, or a route script. No progression blocker was encountered on either route.

Evidence comes from the actual in-app browser at http://127.0.0.1:8766/, viewport 884×886, through screenshot-grounded clicks. The tester knew the implementation, so this is **not a blind novice test** and the shorter second run is not evidence of improved completion time. The second run omitted the baseline's blackjack hand, which explains the wallet difference. Automated assertions are separate evidence.

**Assessment:** the game is playable and clearer after these repairs. The atmosphere and narrator jokes are its strongest features. It is still a short, linear chain of errands with limited player agency and uneven visual reactions. Finishing it successfully does not establish that it is a satisfying, fully developed adventure.

Evidence: [76 baseline screenshots](browser-evidence/index.md), [44 replay screenshots](browser-retest/index.md), [baseline ending](browser-evidence/51-2.jpg), [rebuilt ending](browser-retest/33-1.jpg). These are unmodified captures from the browser tool, not simulated game-state renders. Independent [source/story review](story-review.md) helped locate fixes but is not presented as browser evidence.

## Baseline action log

1. Opening street (0/100, $80). Read Help. **Help footer overlaps final instructions.** Opening says big night; notebook supplies 'find a little connection.' Controls explain verbs, inventory, map, parser. Took and read newspaper; bought flowers using Use; entered Lefty's.
2. Lefty's (8→28 points). Talked to regular and Lefty; bought whiskey, traded for remote. Talked again: **regular still offers the already-completed remote trade**. Bouncer/password clues were clear. Read restroom graffiti, took ring, supplied password by Talk, used remote on TV. **TV still tells me to provide the already-accepted password.** Objective changes correctly but **four-line objectives overflow into POCKETS**.
3. Backstage (32). Took promotional candy. Description establishes rope/fire-escape puzzle. Notebook and map work. Objective reveals casino/disco pass without an encountered story clue; convenient but feels like an omniscient walkthrough.
4. Casino (40). Took pass. Played a slot round ($60→55; +4 points). Slots openly repeat payouts rather than chance: functional but little suspense. Played $5 blackjack, stood on20, dealer busted24 ($55→60). Wallet/result UI consistent. No actual-money transactions; this is local game currency.
5. Disco (64). Talked to Didi, Used dance floor, supplied flowers/ring/candy, called stage manager using phone. **Dance is a line of prose without a dance animation or choice.** Ring/flower responses repeat same joke. Didi gives number, manager authorizes rope and requests message about a dance at opening; talking to Didi repeats number without acknowledging call/message. The rope instruction is clear, but there is no next clue for where to obtain a knife yet.

6. Shop/alley (68→76). Clerk explains voucher/coffee; busker explains wine-for-knife. Took core and mallet; core's description correctly explains self-use, double click extracts seeds. Bought wine and completed trade. TAKE rope automatically cuts it using carried knife; forgiving but inconsistent with the explicit item-use tutorial. Inventory scroll works but newly acquired items can be below the fold without an obvious arrival cue.
7. Fire escape (80). Tied rope, opened window. **Objective says redeem voucher before voucher has been taken.** Followed objective to shop, failed redemption, returned to take it, then redeemed successfully. Actual wasted backtracking caused by guidance. Window's label/description still say sticking after it was opened.
8. Hotel/rooftop (84). Coffee invitation works. **Objective immediately says grow apple before meeting Eve or hearing her request.** Deliberately visited roof first; Eve's fresh-food request supplies the missing motivation. Pool USE only gives generic refusal. Eve sprite is mostly obscured by her own label/pool placement.
9. Garden/penthouse (88→96). Planted seeds, took stool, placed it below cabinet, took pitcher, filled it, watered planter. These actions work. **No tree visually grows; new tree label appears over fountain away from planter.** Stool still painted on ground after taking. After growth objective again skips pickup and says offer apple, though narrator does say take it. Took apple successfully.
10. Ending (100/100, 97 recorded moves, $48). Gave Eve apple and TALK once triggers ending. **No actual back-and-forth conversation; no personal detail about Eve; subplot payoff for Didi absent.** Ending's score overlaps prose. Stayed longer and returned to Lefty's; TAKE bartender produces purchase response (duplicate protected after prior purchase).

Baseline result: start-to-finish route completed through browser, all13rooms visited, no hint button used and no save/state injection. No progression blocker encountered. The test is informed by prior implementation knowledge, so it cannot establish novice discoverability or objectively prove fun. It does demonstrate the difference between a solvable dependency chain and a responsive adventure.

## Baseline design judgment

Atmosphere and short narrator jokes are strengths; the item clues generally permit progress. Low frustration (no timer/deaths/consumed wrong combinations), map travel, and optional parser help. The major weakness is agency and payoff: obvious delivery tasks, static scenes despite described actions, almost no character memory, and an ending awarded at the moment a conversation begins. Art is stronger than the interaction density. Several polished-looking props are decorative or stay painted after removal. This remains a compact adventure rather than a fully developed remake.

## Repairs and actual browser retest

The baseline export stayed unchanged until the first playthrough was finished. Source repairs were then packaged for both Web and macOS. The second browser run started a fresh evening in that rebuilt Web export and replayed the entire route.

| Priority | Observed problem | Change and replay evidence |
| --- | --- | --- |
| High | The voucher objective sent the player to the shop before collecting the voucher, causing actual wasted travel. The apple objective also skipped collection. | Objectives distinguish exposing, taking, redeeming, and delivering items. [Voucher pickup prompt](browser-retest/19-1.jpg); [apple pickup prompt and visible fruit](browser-retest/26-1.jpg). |
| High | Help instructions, long objectives, and ending text overlapped other UI. | Scrollable Help, larger objective panel, and separated ending text/score/buttons. Verified [Help top](browser-retest/03-1.jpg), [Help bottom](browser-retest/03-2.jpg), and [ending](browser-retest/33-1.jpg). |
| High | TAKE on a person could perform a transaction or advance an unrelated interaction. | TAKE now refuses people without spending money or advancing the story. [Lefty refusal](browser-retest/05-1.jpg) followed by an ordinary purchase. Wrong actions are also covered by regression checks. |
| Medium | Characters forgot completed trades; TV dialogue contradicted the accepted password. | Responses now reflect progress. Replayed [regular's acknowledgement](browser-retest/06-1.jpg), [TV/password chain](browser-retest/07-1.jpg), and [busker trade](browser-retest/18-1.jpg). |
| Medium | Didi repeated her phone number after the call; the stage manager's message had no acknowledgement. | Didi acknowledges the completed call/message; remaining-prop requests update as deliveries arrive. [Subplot acknowledgement](browser-retest/13-1.jpg). This is a short closure, not a staged cabaret performance. |
| Medium | Important spoken clues were easy to lose. | Notebook retains ordinary clue-bearing conversations without repeated copies. [Busker request in notebook](browser-retest/15-1.jpg). |
| Medium | The objective prescribed gardening before meeting Eve, removing the story motivation. | Invitation now leads to meeting Eve first. [Introduction objective](browser-retest/22-1.jpg), then [her request](browser-retest/22-2.jpg). |
| Medium | Dance and tree growth were prose-only; the apple label appeared over the fountain. | Larry visibly dances. A tree grows at the planter; taking the apple removes its fruit and keeps the tree. [Dance](browser-retest/11-1.jpg), [grown tree](browser-retest/26-1.jpg), [picked tree](browser-retest/26-2.jpg). |
| Medium | One TALK immediately ended the game, without an actual conversation. | Three TALK beats now share Larry's night, reveal Eve's gardening work, and lead to the invitation. Score stays at 96 through the first two beats, then reaches 100. [Larry's story](browser-retest/31-1.jpg), [Eve's story](browser-retest/32-1.jpg), [ending](browser-retest/33-1.jpg). |
| Medium | Reload appeared to erase progress; the restore action was buried in Help. | A visible Continue evening prompt appears on startup. Verified both restoration of the baseline save and, after the second ending, restoration of the new rooftop state with 100/100 and $43. [Prompt](browser-retest/34-1.jpg), [restored game](browser-retest/35-1.jpg). |
| Low | NPC labels covered faces; the hint button did not clearly advertise a full solution. | Raised person labels and renamed the button “Show next step.” Eve is visible in the [replayed conversation](browser-retest/31-1.jpg). Neither full playthrough used that button. |

## Journey health after the replay

1. **Opening and controls — usable, with caveats.** Help is readable and verbs/map/inventory work. At this narrow viewport the fixed game canvas makes text small. Selecting an inventory item sets up item use; clicking Use again retains it, which can surprise a player expecting bare Use. Look or another verb clears it.
2. **Bar and password — clear.** The trade, restroom clue, password, and TV chain all progress, and repeat conversation acknowledges the trade.
3. **Backstage and casino — functional, thin.** Access, candy, pass, and optional game score work. The objective panel often supplies a destination before the player discovers a reason. Slots openly use a repeating payout sequence and offer little suspense.
4. **Didi and the phone — more coherent.** The prop request changes, dancing has a visible reaction, and the call gets acknowledgement. Choices and comic variation remain limited.
5. **Shop, alley, and rope — understandable.** Item descriptions and retained dialogue explain the trades and seed extraction. Some interactions automatically use a carried tool, making the distinction between Take and Use inconsistent.
6. **Window and voucher — repaired.** Following the displayed objective now collects the voucher before the shop trip. The painting still depicts a closed window even after opening it.
7. **Hotel and Eve introduction — repaired.** Coffee earns the invitation, and the objective now sends the player to meet Eve before gardening.
8. **Garden and pitcher — functional, with better payoff.** Seeds, stool, cabinet, pitcher, water, tree, and apple all work. The tree responds visually; other collected props remain baked into the background art.
9. **Final conversation — improved but brief.** There is now an exchange with a callback and personal detail. Repeated TALK advances a fixed script; it is not a branching dialogue system.
10. **Completion and continuation — verified.** The ending is readable, continued exploration works, and browser reload restores the completed state through an obvious prompt.

## Remaining work that would improve the game

1. **Give the player meaningful choices.** The central loop is mostly “collect the requested thing and deliver it.” Add alternate approaches to a few puzzles, optional dialogue topics, and consequences or callbacks for those choices. This is the largest remaining design weakness.
2. **Make important actions visibly change the scene.** Separate collectible/interactable props from the background: remove the stool/core/pitcher when taken, open the window, and let completed character activities change the room. More generic scenery responses will not provide that payoff.
3. **Improve inventory and clue pacing.** New items can arrive below the inventory fold without an arrival cue, and spent-purpose items clutter it. The objective panel often reveals solutions too directly. A graduated hint system and clearer item selection would preserve discoverability without forcing guessing.
4. **Develop the comedy and character scenes.** Didi's acknowledgement closes the implemented errand, but there is no performance to attend. Eve's extra dialogue repairs the abrupt ending but remains short. More situational responses and optional conversations would make the characters feel less like task dispensers.
5. **Run a fresh-player test.** A tester who has not read the code should attempt the opening, rope puzzle, and garden sequence without help. Observe confusion and enjoyment directly. This audit cannot substitute for that evidence.

## Validation boundaries

- Actual browser evidence: two start-to-finish plays; all 13 rooms; map, notebook, inventory, Help, wrong-action examples, optional slots, one baseline blackjack hand, ending, continued exploration, and autosave restoration. The walkthrough was not injected or automated as a route.
- Parser input was exercised during the baseline. The browser driver's bulk text entry delivered only the first character into Godot's input surface; individual key entry worked. This is recorded as an automation limitation, not asserted to be an ordinary keyboard bug. Exhaustive parser synonym coverage is outside this UI audit.
- Six automated suites additionally passed **845 assertions**: game 198, interface 182, modal layout 330, narrative 56, action intent 39, casino 40. The layout suite checks three viewport sizes, but this does not establish responsive usability or accessibility at those sizes.
- The browser exposes the game as a canvas with no meaningful control tree. Screen-reader accessibility is therefore a remaining issue, not a passed check. Audio quality, every optional action, every save migration, and every browser/platform combination were not manually retested here.
- Web and macOS packages were rebuilt after the repairs. This audit played the Web package; native packaging/smoke checks are separate evidence in [verification.md](../verification.md).
- The rebuilt Web ZIP SHA-256 at replay was `1c0e69123849c9806df5bbc95098081a9717df4a5f107cb9476bd95c5e927c5e`. Screenshot evidence is excluded from game imports/exports via `docs/audits/.gdignore` and the export filters.
