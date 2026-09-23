# Camp, character, and visual reference

Research date: 2026-09-22. This is a reference note for the Larry/Lisa update, not a claim that the originals support selectable orientation. Existing production illustrations remain the visual baseline. No historical assets were added to production or downloaded during this review.

## Versions and primary evidence

“First two versions” can mean the first two numbered games or the original and remake of the first game. This review covers both: **Larry 1 (1987), Larry 2 (1988; viewed through its 1989 Atari ST release), and Larry 1 VGA (1991)**. Softporn is the text-game predecessor, not an illustrated version.

The Blue Sky Software Apple II manual describes an unnamed vacationer trying to seduce three women. Sierra’s first Larry manual gives Larry one night to pursue his dream woman. Its costume description specifies a white polyester suit, conspicuous chains, elevated shoes, and a disco-inspired hairstyle. These establish a frank adult pursuit and dated self-presentation as core ingredients. [Softporn manual, PDF pages 2 and 4](https://www.mocagh.org/sierra/softporn-alt.pdf), [Larry manual, PDF pages 3–4](https://www.mocagh.org/sierra/lsl-manual.pdf). See also [the repository’s objective research](original-objective-research.md).

Al Lowe’s creator account explicitly says the update made fun of the outdated lifestyle, used the narrator to puncture Larry’s pretensions, and added many inspection responses while keeping clues clear. This supports comedy delivered through interaction, not just decorative adult branding. It is a first-person retrospective, not a contemporaneous production log. [Al Lowe, First, Softporn](https://allowe.com/games/larry/inside-stories/softporn.html).

## Screens actually viewed

The visual descriptions below are direct observations of game images, distinct from the host’s editorial claims. The existing [reference gallery](../reference/index.html) and [source catalog](references.json) contain additional first-game captures.

| Image and provenance | Observed visual devices | Adaptation use |
|---|---|---|
| [1987 upstairs room](https://www.filfre.net/wp-content/uploads/2015/08/ll_012.png), viewed from the existing local archival copy | Cracked cyan walls, a dangling light, a cramped bed, and a large black CENSORED sign create comic obstruction in an otherwise broad, sparse stage. | Use framing, interruptions, closed doors, and boastful captions to create a knowing gag. The scene can communicate its outcome without explicit anatomy. |
| [1987 rooftop close-up](https://www.filfre.net/wp-content/uploads/2015/08/ll_021.png), existing local copy | Strong black hair silhouette, high-contrast face, pool bubbles across the lower frame, and a drink prop establish the setting with few shapes. | Maintain readable silhouettes and atmospheric props; keep equivalent visual attention for Eve and Adam. |
| [1987 disco close-up](https://www.filfre.net/wp-content/uploads/2015/08/ll_019.png), existing local copy | Saturated pink costume, huge hair silhouette, black background, and an intrusive text box provide the visual joke’s timing. | Give dialogue room to carry the joke; a reaction beat can do more than adding detail. |
| [Larry 2 Atari ST gallery](https://www.atarimania.com/games/atari-st-games-leisure-suit-larry-ii-goes-looking-for-love-in-several-wrong-places-9819), viewed live in the browser | The home exterior uses a tiny white-suited Larry against a large house and street. The villain-room frame has bold blue floor, red walls, a raised central platform, and theatrically posed figures. The cover uses broad caricature and flamboyant display lettering. | Retain the small overconfident protagonist in a scene that is larger than their ego; use bold blocking and readable silhouettes. |
| [1991 VGA Lefty’s interior](https://www.classicgaming.cc/pc/leisure-suit-larry/images/screenshots/screenshot-lslvga-leftys-bar-inside.jpg), viewed live from the [version-separated gallery](https://www.classicgaming.cc/pc/leisure-suit-larry/screenshots) | Crooked room perspective, blue walls, red bar, pink stools, a comic moose trophy, and contrasting patrons surround the little white suit. | Preserve the current colorful stage design. Add a few original environmental jokes and expressive character details instead of repainting every background. |

The [user-supplied Digital Antiquarian article](https://www.filfre.net/2015/08/leisure-suit-larry-in-the-land-of-the-lounge-lizards/) supplies the first-game screenshot context. Its historical interpretations are secondary; the manuals and creator account above anchor the objective and intended parody. The Sierra founders’ [Larry 2 archive](https://www.sierragamers.com/leisure-suit-larry-2/) identifies the sequel and its 1988 release. Its linked plot synopsis is credited there to MobyGames, so it is not treated as creator testimony. The Larry 2 PDF did not render in the in-app browser and Sierra Chest presented a security check; Atarimania provided the inspected sequel frames.

## Direction for this update

These are new design choices inferred from the references and the user’s brief:

- Make the starting ambition plain: **get laid before sunrise**, with Eve or Adam as the final pursuit. Communicate mutual interest through character dialogue and choices rather than a hidden entitlement meter.
- Give Larry and Lisa the same glorious lack of self-awareness: loud polyester, improbable confidence, theatrical poses, and a narrator with impeccable timing. A gender or orientation choice changes attraction and presentation, not competence, moral worth, rewards, or the quality of the joke.
- Use original signs, kitschy furnishings, oversized lapels, nightclub posters, affectionate banter, and amusing interruptions. Maintain the current palette and art readability. Keep intimate action offscreen; aftermath and implication can carry the farce.
- Make optional encounters discoverable through ordinary room clues and character needs. A completed favor should open a conversation and voluntary invitation; it should not silently turn into an encounter or consume the final story goal.
- Keep refusal and friendship graceful, with continued puzzle progress and a clear way back to the main objective. The protagonist’s ego and assumptions are the targets of the joke, not anybody’s orientation.

## Current TypeSafe guidance for QA

Read live during this task: [documentation index](https://docs.typesafe.ai/llms.txt), [State](https://docs.typesafe.ai/concepts/state), [Function calling cookbook](https://docs.typesafe.ai/cookbooks/function_calling), and [Confidence](https://docs.typesafe.ai/confidence). Markdown URLs failed for two pages; their ordinary documentation pages were available.

The cookbook maps natural-language decisions to known functions and closed argument sets. For this project, keep each gameplay candidate tied to a real visible control and let deterministic code validate and execute it. Candidate coverage matters: a model cannot choose a control omitted from its observation. The example model name in the cookbook is an example, not evidence of the model version used by a new experiment.

State documentation says Jev accepts text, not images, audio, or video. Supply the selected identity, orientation label, visible character names, visible objective, room text, learned clues, and available actions as named observation fields. Do not expose quest flags, hidden compatibility decisions, or solution knowledge in an unaided run. Independent questions in one request cannot depend on each other’s answers.

Confidence describes the answer distribution, not correctness or enjoyment. Record the exact observed input and candidate set, returned model version and confidence, resulting UI action, and subsequent visible outcome. Test all six identity/orientation combinations deterministically; text-driven model runs can then find unclear labels or loops, while actual browser inspection must check the visual presentation. This research does not change the API integration or claim that a successful model playthrough proves the comedy is enjoyable.
