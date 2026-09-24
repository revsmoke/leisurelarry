# Production art and credits

All thirteen background paintings were newly generated with the built-in image generation tool for this project. Historical screenshots in `reference/` are research only and are excluded from game exports. Backgrounds are detailed modern illustrations with visible pixel texture; they are not extracted original Sierra sprites.

## Shared generation direction

Finished production background for a 16:9 point-and-click retro comedy adventure; fixed wide camera; deliberate pixel clusters; cinematic purple and teal neon with peach/gold light; late-1980s setting; clear foreground walking space; no people, UI or watermark. Requested size 1536×864. Delivered images are 1672×941 and imported directly by Godot.

## Scene prompts

- **street.png**: Two-storey salmon-stucco Lefty's dive bar, amber windows, blue awning, neon LEFTY'S and martini signs, alley left, broad sidewalk, yellow taxi right, palms and distant art-deco casino skyline, crescent moon, wet reflective asphalt.

- **bar.png**: Interior of Lefty's shabby lounge bar. A curved dark wooden bar on the left with red leather stools and amber bottle shelves, center open walkable parquet floor, booth on right, small TV high on right wall, door at rear marked WC and curtained backroom entrance. An abandoned bouquet and folded newspaper on a small side table. No people.

- **casino.png**: A glamorous tacky casino lobby. Neon slot machines down left, curved green blackjack table on right, monumental gold elevator doors center rear, huge pink neon CASINO sign, starburst carpet, potted palms, brass ashtray stand near elevators. Open walkable floor at front. No people.

- **disco.png**: A 1987 disco nightclub interior. Glowing magenta and cyan checkerboard dance floor center, big mirror ball overhead, teal booth seats down left and right, stylish cocktail bar at rear, velvet rope at door, gold art deco trim. Warm romantic and comic, no people.

- **hotel.png**: A luxurious but tacky 1980s casino hotel interior. Burgundy carpet, palm plants, dramatic golden elevator to left, reception desk and brass bell center right, enormous moonlit picture window and balcony door on far right. Pink and teal accent lights. No people.

- **rooftop.png**: A moonlit casino rooftop terrace with a turquoise circular hot tub in the center right, lush potted palms left, a peach and teal art deco cabana and wicker chairs with towels, tiny cocktail table, neon Las Vegas skyline beyond, crescent moon. Romantic comedy atmosphere. No people, no nudity.

- **bathroom.png**: Shabby but charming cartoon dive bar bathroom. Cracked checkerboard tiles, porcelain sink with mirror on left, brass ring near sink drain, toilet stall on right, cheeky illegible graffiti on wall, paper towel dispenser. Teal tile and muted pink neon ambience. No people.

- **garden.png**: A small surreal casino courtyard garden at night. Enormous potted palms, raised planter with empty soil center left, ornamental fountain center right, low stool and watering pitcher, tiny mushroom, lush monstera, stucco wall and starry desert sky. Purple turquoise and gold lights. No people.

- **backroom.png**: An intimate shabby dive-bar back room converted into a cabaret dressing lounge: red velvet curtain, tiny low stage, colorful dressing table with bulb-framed mirror on left, comedy props and a box of chocolates on a side table center right, bulky CRT television and a door out, patterned carpet, no people.

- **shop.png**: A tiny charming 1987 Las Vegas 24-hour convenience store interior at night: teal counter and cash register at right, bottles of wine on left, rack of magazines, coffee machine and red coffee cups, packs of mints, fridge with cold drinks, grimy tiled floor, window with reversed neon OPEN sign; no people.

- **alley.png**: A comic sleazy 1987 Las Vegas back alley at night: peach stucco building at left, fire escape and balcony high overhead, dumpster with apple core nearby, small toolbox containing a hammer beside crates, scruffy busker's guitar against brick wall at right, purple and cyan neon light spill and wet pavement; no people.

- **balcony.png**: A narrow first-floor exterior motel balcony above a neon Las Vegas alley. Railing across foreground with thick rope tied to it, stuck old wood-framed window on right with glowing amber light inside, a small cafe table with coupon on it, shabby teal stucco walls, palm shadows and distant magenta casinos at left; no people.

- **penthouse.png**: Interior of a comically decadent 1980s Las Vegas penthouse suite: peach semicircular sofa at left, cocktail table, huge broad-leaf plants, gold-accented cabinet and high shelf with watering pitcher on right, kitchen sink at back right, sliding glass doors center looking onto moonlit rooftop, gold and teal lighting, no people.

The store image's first generation failed. Its final prompt was:

> Create an empty 1980s neighborhood convenience store interior as a wide 16:9 pixel-art adventure-game background. Small cashier counter on right, espresso coffee machine behind counter, colorful soda bottles on shelves left, newspaper stand, snack shelves, a cooler, tiled floor, pink and turquoise neon reflected in front windows. Warm cozy light, richly detailed deliberate pixel clusters, retro video-game environment illustration, no people, no interface, no watermark. Clear walkable space in front. 1536x864.

## Other original assets

- `scripts/actor.gd`: original procedural pixel characters and walking animation.
- `scripts/party_actor_art.gd`: original cabbie, lounge-host and pool-regular pixel silhouettes, in both gender presentations, plus table outfits for Larry/Lisa. Four wardrobe stages share the existing hover/action pose system. `scripts/party_table.gd` draws the cards, felt, pool guide and curtains; no new raster assets or copied commercial sprites are used for the party games.
- `assets/icon.svg`: original martini-glass application icon.
- `assets/audio/last_call.wav`: original deterministic synthesis; see [audio.md](audio.md).
- Outfit, Space Grotesk, and Noto Sans Symbols 2: Google Fonts, SIL Open Font License. Copies of all three licenses are included under `assets/fonts/`.

Fonts source: [Outfit](https://github.com/google/fonts/tree/main/ofl/outfit), [Space Grotesk](https://github.com/google/fonts/tree/main/ofl/spacegrotesk), [Noto Sans Symbols 2](https://github.com/google/fonts/tree/main/ofl/notosanssymbols2). Engine: [Godot MIT license](https://godotengine.org/license/). Adventure lineage and original creators: [research notes](research.md).

This is an unofficial fan adaptation. The original game names and characters belong to their respective owners; no affiliation or commercial distribution rights are implied.
