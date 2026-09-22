# Last Call in Lost Wages — design and scope

This project is a complete, compact Godot adventure with a beginning, a connected inventory-puzzle route, and an ending. It is an **unofficial hybrid reimagining**, not an exact preservation of Softporn Adventure or either commercial version of Leisure Suit Larry 1. Historical evidence and the original puzzle map are in [research.md](research.md); the implemented solution is in [walkthrough.md](walkthrough.md).

## What the adaptation keeps

The player explores a ridiculous nightlife district in a conspicuously optimistic white suit. A knowing narrator turns observation, failure, and improbable object combinations into comedy. The city is small enough to learn, but early discoveries become useful several locations later.

The route retains the predecessor's recognizable chain: drink for remote, bathroom password, television distraction, candy, casino pass, disco gifts and dance, telephone clue, wine for knife, rope and window access, hotel gate, seeds plus water, and an apple at the rooftop finale. These are adapted dependencies with newly written dialogue and motivation. The character, white-suit silhouette, narrator and illustrated-room presentation evoke Larry; BELLYBUTTON, channel six, 555-0987 and the grown-apple puzzle follow the supplied Softporn route.

The setting is an intentionally imagined late-1980s Lost Wages, rather than Softporn's stated year 2020 and Lost Vagueness. The economy starts at $80 and has its own prices. This continuity choice is explicit: historical details from the two games are selected for a new playable version rather than presented as one original release.

## What changes, and why

| Original structural element | This version | Design reason |
|---|---|---|
| Text parser as the principal interface | Four verbs, labeled targets, inventory and optional parser | Preserve experimentation while making available actions discoverable |
| Repeated taxi fees and travel friction | Connected named exits; city overview | Keep the compact city's relationships understandable |
| Repeated random gambling to fund progress | Optional animated slots and playable blackjack; recovery grant | The required shopping costs $32, so the route does not require grinding or lucky outcomes |
| Gifts as a seduction transaction | Didi needs stage props; a dance is a voluntary social moment | Give the NPC a purpose and a voice beyond being a reward |
| Original bedroom/chapel/honeymoon dependencies | Cabaret and stage-manager introduction | Retain the gift/phone/knife/rope chain in a shorter coherent subplot |
| Pills given at the hotel gate | Espresso voucher, machine and receptionist invitation | Preserve the multi-step favor without copying the original drug gate |
| Break-in and dangerous escape | A sticking service window and a secured access route | Preserve rope/tool callbacks and slapstick in the revised story |
| Winning framed as conquest | An introduction, a thoughtful apple, and a conversation | End on connection and a comic change in Larry's behavior |
| Deaths, inventory friction and expiration pressure | Persistent progress with no death timer or inventory limit | Let the player explore jokes and solve puzzles without replaying large sections |

The game remains suggestive adult comedy: nightlife, romantic misreadings, inflated confidence, double meanings, and a narrator who recognizes every bad idea before Larry does. Intimacy stays offscreen. Character interactions should convey willing participation through their own dialogue; repeating explanatory content notes in every scene weakens the joke.

## Implemented content and systems

The current content model contains **13 logical locations**, **18 inventory objects**, and **25 distinct scoring milestones** worth up to **100 points**. These are data-driven locations rendered through one main interface, not thirteen separate hand-authored Godot scenes.

- Exploration with scene targets, four action verbs, movement feedback, room exits, and visible interaction labels. TAKE collects loose objects and refuses people or immovable machines; USE operates activities. Buying whiskey uses USE on Lefty or the BUY WHISKEY command.
- Item collection, purchases, safe unsuccessful combinations, multi-room prerequisites and persistent room gates.
- Optional command input with aliases, including LOOK, TALK, TAKE, USE, BUY, GIVE, GO, DANCE, CALL, inventory, journal, hints, save and load.
- A current objective and a journal that records discoveries, including ordinary conversations about favors, without repeating identical entries. Completed favors change NPC replies and relevant room/object descriptions. Objectives distinguish exposing an item, collecting it, and delivering it. After receiving the rooftop invitation, guidance introduces Eve before proposing her apple; earlier gardening remains valid.
- The **Show next step** button identifies the next outstanding prerequisite and labels its response as containing spoilers. It supplies a direct solution, not a graduated hint system.
- A manual save slot and an autosave file containing location, inventory, progress flags, money, score, action count and journal. A launch with an existing autosave offers **Continue evening**; Help also provides **Restore autosave**. Invalid save data is rejected before replacing live progress.
- Optional animated slots with an inspectable four-spin cycle, and blackjack with a shuffled deck, Hit/Stand, flexible aces and $5/$10/$20 stakes. The dealer stands on 17; a natural blackjack pays 3:2 profit, rounded down to whole dollars. A cashier recovery grant is available below $10.
- An optional Didi follow-up acknowledges the stage manager's message and the completed cabaret props without adding another required exchange or score award.
- A final rooftop conversation over three TALK actions after the apple gift: Larry tells a story, Eve talks about her own work on the gardens, and she invites him to stay for sunrise. Only the conclusion grants the existing ending score. The completion screen allows continued exploration or restart.
- Thirteen new illustrated backgrounds, independent animated geometric pixel actors with a dance animation, visible planted seeds and a growing apple tree, a looping original music bed and a mute control. Harvesting removes the fruit while leaving the tree.

The narrative tracks an action count but does not simulate an expiring night. The displayed clock is atmosphere, not a countdown. Walking supplies visual feedback; it is not a free-roaming physical simulation with navigation obstacles. Accepted travel now plays a 3.5–4.4 second vignette showing departure, transit and arrival. Doors, walks, taxis, elevators, secured rope crossings and terraces receive distinct staging with authored, rotating innuendo. Each scene is skippable; reduced-motion mode uses a one-second still card. The deterministic model validates the route and commits movement once, before animation; saving/reloading never requires replaying the movie, and a blocked or same-room request has no movie. Map travel follows the existing connected route while showing one montage for the chosen destination. Taxi visuals add no fees.

## Visual direction

The backgrounds reinterpret the original game's theatrical room staging with much richer surfaces: saturated magenta and cyan neon, burgundy upholstery, aged brass, emerald tile, violet night skies and wet reflections. The room art is detailed illustration with pixel-like texture, not an attempt to reproduce the original AGI palette or exact pixel grid. Actors are deliberately simple and rendered independently so their movement is readable over the scenery.

The interface has a dark navy frame, warm cream text, mint selected actions and pink narrator accents. The 1440 × 960 design keeps an inventory and journal rail on the left, a large scene on the right, dialogue beneath the image, and verbs/parser/exits along the bottom. The layout scales as one composition to fit the window.

Image generation supplies the setting, but the game-state data remains authoritative for puzzle objects. Small actionable objects must have readable labels or independently drawn props; decorative writing in a background is not a reliable source of a puzzle password or telephone number. Venue signage and room titles should be kept consistent as art receives further polish.

## Background usage by location

Each of the thirteen locations has its own illustration in `assets/backgrounds/`. These backgrounds are newly generated production art; the historical screenshots remain separate research references.

| Location ID | Background | Role |
|---|---|---|
| `street` | `street.png` | Neon district exterior and starting hub; Lefty's and a taxi are painted into the scene |
| `bar` | `bar.png` | Main lounge; bar counter, WC door, curtained staff area and television |
| `bathroom` | `bathroom.png` | Restroom, wall clues and ring discovery |
| `backroom` | `backroom.png` | Cabaret backstage, promotional candy and safety-rope gate |
| `casino` | `casino.png` | Animated slot machine, playable blackjack table, complimentary pass and cashier |
| `disco` | `disco.png` | Dance, Didi, telephone and spare-rope chain |
| `shop` | `shop.png` | Shop interior, wine purchase and espresso-voucher redemption |
| `alley` | `alley.png` | Service alley, busker exchange, apple core and loaner mallet |
| `hotel` | `hotel.png` | Reception and elevator hub |
| `balcony` | `balcony.png` | Fire escape and sticking service window, with espresso voucher reward |
| `garden` | `garden.png` | Planter, loan stool and apple-growth puzzle |
| `penthouse` | `penthouse.png` | Penthouse lounge/kitchen, high cabinet, pitcher and sink |
| `rooftop` | `rooftop.png` | Poolside conversation and finale |

Backgrounds are wide images displayed in a shallower scene viewport. With an aspect-cover display mode, some image area is cropped; hotspot coordinates must be mapped into the same visible image rectangle. Content placement should be checked against the actual picture rather than inferred from the room name. Examples that warrant particular care are the restroom sink on the left, hotel elevator on the left, television at the upper right, taxi at the lower right and rooftop pool right of center.

## Runtime design

`game_state.gd` is a `RefCounted` model that owns the locations, items, gates, rewards, commands and serialization. It can run without the main scene, which makes full-route regression checks possible. `main.gd` owns interface construction, actors, rendering, mouse/keyboard interaction, modals, audio and persistence triggers. `actor.gd` draws and animates the original small characters. `world_effects.gd` renders the garden's planted seeds, tree growth and harvested-fruit state. `casino_panel.gd` supplies the animated slot reels and blackjack table, settles bets against the adventure wallet and refunds an unsettled hand when the panel closes.

UI actions should call the same state methods as parser commands. Merely displaying an item's static description is insufficient when LOOK also records a discovery. Likewise, a map that offers nonadjacent destinations must resolve a valid route through unlocked exits; checking only the destination's lock flag is not enough. These are interface/model integration requirements, not extra puzzle rules.

Historical research material is kept separately in `reference/` and excluded from Godot imports with `.gdignore`. Its screenshot gallery records sources and provenance. Production room art, actor drawings, dialogue, music and game code are newly authored for this project.

## Deferred scope

This build does not claim parity with every mechanism, joke, location or branch from either historical game. In particular, it does not include:

- Exact original dialogue, sprites, music, score system or age-trivia gate.
- The original paid-encounter, wedding, honeymoon, inflatable-doll or mushroom-teleport scenes.
- Blackjack split, double-down or insurance options; simulated taxi service, a dynamic clock or a death system.
- Fully animated character portraits, lip sync, voice acting or long-form cinematic story sequences. Short animated travel vignettes are included.
- A physically navigable city, obstacle-aware pathfinding, gamepad support, localization or touch-specific interface layout.
- A fully open natural-language parser or combinatorial responses for every possible object pair.

These are development opportunities, not hidden prerequisites to reach the current ending. The current acceptance target is a polished, understandable complete adapted route with reliable inventory, room gates, saves, hints and a satisfying finale. Historical research, code-level tests and a successful launch are complementary evidence; none replaces playing the visible interface from the first room through completion.
