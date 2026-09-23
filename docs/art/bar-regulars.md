# Lefty's five regulars — art notes

The five original pixel actors reinterpret the silhouettes in the seven screenshots supplied by the user on September 23, 2026. No historical sprite pixels were extracted into the game.

| Reference cue | Cast role | Presentation |
|---|---|---|
| Tall blond quiff, white shirt, blue trousers | Kit / Kitty | Jukebox flirt; raised glass and exaggerated collar |
| Brown curls, purple satin, crossed legs | Roxanne / Rex | Independent escort; direct smile and own terms |
| Broad blond cook, white shirt, blue trousers | Bo / Bonnie | Midnight cook; apron-free night out |
| Black hat, turquoise shirt, purple trousers | Jax / Jazz | Session musician; hat-tip and rhythmic gestures |
| Red hair and blue club vest | Red / Reddie | Rally captain; visible face and club crest |

`scripts/bar_actor_art.gd` draws seated and standing versions. Each uses the existing actor's head, mouth and arm animation system. World poses include pink stools; dialogue and encounter poses stand up without a stool. Skin and role persist into the encounter. Gender presentation follows the selected player orientation.

Larry's new right-facing profile has a large nose, receding black pompadour and determined chin, inspired by the supplied lower-left side view. Lisa's existing design remains available.

## Background plate

- Final project asset: [bar-social.png](../../assets/backgrounds/bar-social.png).
- Original project plate retained: [bar.png](../../assets/backgrounds/bar.png).
- Mode: built-in image generation tool, edit of the existing project plate.
- Output copied from the tool's generated-images directory into the project.
- The revised counter leaves an empty apron for five code-drawn stools and patrons. No people are baked into the background. The WC, staff curtain, television and burgundy booth remain.
- Godot maps this plate through `WorldEffects.background_path_for("bar")`. The production export checker now requires it.

## Final image prompt

Use case: precise-object-edit. Asset type: production background plate for a Godot retro comedy adventure, wide 16:9. Edit target: the attached existing Lefty's Bar background. Preserve its richly illustrated pixel-textured style, warm dark wood, bottles, aged brass, magenta/cyan neon, burgundy upholstery and late-night mood. Re-stage the room for five seated interactive pixel characters that will be drawn separately by the game: make a long mostly frontal bar counter across the left 78 percent of the picture at about 49 percent image height, with a clear uncluttered apron below it and plenty of empty standing floor at the bottom. No stools or chairs in front of this counter: five pink stools will be rendered by code together with the characters, evenly spaced across the counter. Leave visible standing space behind the counter for a bartender at horizontal 36 percent. Keep a WC door and curtained staff entrance toward the right of the room, a television high on the right, and a small rightmost burgundy booth. Keep 'Lefty's' neon lettering on the upper left. Avoid other legible text. No people, no silhouettes, no faces painted into the background. No UI or labels. This is a warm, inviting and slightly seedy adult nightlife set; the room must read immediately as the same bar, with a wider stage for its cast.

## Staging

Five shuffled seat anchors use the same row and scale. Lefty stands higher behind them; the original thirsty regular and bouncer remain at the right. All five labels fit above their animated silhouettes. Labels include both style margins in their text width, avoiding clipped names. The illustrated plate is a sibling asset, preserving the prior art.
