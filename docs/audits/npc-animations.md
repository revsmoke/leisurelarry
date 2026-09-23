# NPC hover and interaction animation — September 23, 2026

NPCs now animate when the pointer enters either their body or their hotspot. Each role cycles through three gestures: hosts and romantic guests wave, preen and wink; Lefty polishes, nods and waves; the bouncer folds his arms, raises an eyebrow and shrugs. Other characters have appropriate variations. No story randomness or API calls choose these performances.

Look raises an eyebrow, Talk gestures and animates the mouth, Take produces a comic hands-off recoil, and Use reaches toward the player. These acknowledge an attempted action; narration still explains whether it succeeded. Lefty's purchase offer uses a service gesture. Body clicks, hotspot clicks, inventory use, keyboard buttons and parser interactions share the existing deterministic actions. A matching animated actor appears alongside conversation replies, including replies to topic choices.

Actors survive same-room interface refreshes so gestures are not cut off by changing verbs or displaying a result. Room changes discard them. Active action reactions take priority over hover; moving between a body and its label cannot restart an active gesture. All gestures expire and disable processing at idle. Reduced motion holds one expressive pose, then returns to idle. The label avoidance envelope includes the raised arms.

## Live browser checks

Assistant-operated normal Web export at `http://127.0.0.1:8766/`, viewport 884 × 882, using the existing completed Lisa/bisexual evening. The saved progress, score and wallet remained available. Test interactions used the actual scene and text/keyboard controls; no inventory or quest flags were injected. This was a focused feature check, not another beginning-to-end playthrough or human enjoyment study.

- Adam's body hover produced a [wave](npc-animation-evidence/01-adam-body-hover.png), then [returned to idle](npc-animation-evidence/02-adam-idle.png). Entering his hotspot later produced a [different grooming gesture](npc-animation-evidence/03-adam-hotspot-hover.png). Full browser frames were sampled across 2.3 seconds to inspect the motion.
- Clicking Adam's body with Take invoked the normal refusal. The regular's [Use gesture](npc-animation-evidence/09-regular-use.png) and [Take gesture](npc-animation-evidence/10-regular-take.png) were visibly distinct, with their normal game responses.
- Lefty's [conversation portrait](npc-animation-evidence/06-lefty-conversation.png) gestured alongside readable text. Choosing a topic produced the correct [new reply](npc-animation-evidence/07-lefty-topic-reply.png) and kept the buttons usable.
- [Reduced motion](npc-animation-evidence/08-reduced-motion-conversation.png) displayed still staging; the original OFF setting was restored afterward. Compact hotspots retained readable names in the keyboard surface; full labels were restored.

The first browser pass found that Godot's duplicate name tooltip covered Adam's face during a hover animation. NPCs now use the visible name and hover line without that extra tooltip; compact keyboard controls retain their name through explicit metadata. The final browser pass confirmed the face stays visible. Cropped browser captures did not reliably show the canvas, so the evidence uses full visible-browser screenshots. Short capture latency also missed some early action frames; the final Use/Take evidence comes from the keyboard companion's real callbacks.

## Automated verification and builds

The dedicated [NPC suite](../../tests/test_npc_animations.gd) passes **340 checks**. It forwards actual mouse events through [Godot's viewport input dispatcher](https://docs.godotengine.org/en/stable/classes/class_viewport.html#class-viewport-method-push-input), checking body hit testing, hover variety, no game-state changes on hover, action priority, exactly-once execution, right-click Look, parser parity, conversation portraits, reduced motion, actor lifetime, and both casts across all rooms. It also checks that repeated refreshes do not duplicate actors and that names clear the gesture envelope. Its first draft attempted a locked journey from an artificially staged rooftop; that invalid fixture was corrected to exercise room cleanup directly.

The final build passed **4,420 Godot assertions across 15 suites and 34 Node tests**. This includes the 333 label placement checks, complete interface route, QA isolation, Web companion, responsive/modal layout, six player profiles, travel/finale scenes, and repeated native lifecycle checks. The lifecycle test measured a final/static-baseline memory ratio of about **1.020** after 10 cycles and two warmups; it is not a browser FPS or long-running soak measurement. See [results and exact source hashes](npc-code-checks.json) and the [lifecycle sample](npc-memory-lifecycle.json).

Normal Web, macOS, and Web QA exports were rebuilt. Export-content checks, packaging, native signing and a 30-frame native launch smoke check passed. See the [build manifest](npc-builds.json). No TypeSafe integration changed or live Jev campaign was run; text-driven action choices would not establish whether these rendered gestures are visible or appealing.

Reproduce the feature checks with:

```sh
./tools/godot --headless --path . --script tests/test_npc_animations.gd
./tools/godot --headless --path . --script tests/test_hotspot_labels.gd
./tools/godot --headless --path . --script tests/test_interface.gd
./tools/godot --headless --path . --script tests/test_qa_bridge.gd
./tools/godot --headless --path . --script tests/test_web_companion.gd
```
