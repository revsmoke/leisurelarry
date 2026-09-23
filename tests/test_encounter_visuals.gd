extends SceneTree
## Presentation contracts only: these checks do not award an encounter, evaluate
## attraction, or establish that a scene is funny. Optional native frame captures
## let a reviewer inspect the real pixels independently of these assertions.
const Encounter = preload("res://scripts/encounter_cutscene.gd")
const Travel = preload("res://scripts/travel_cutscene.gd")
var assertions := 0
var failures: Array[String] = []

func _init() -> void:
	_run.call_deferred()

func check(value: bool, title: String) -> void:
	assertions += 1
	if not value:
		failures.append(title)
		printerr("FAIL: " + title)

func _run() -> void:
	var scene := Encounter.new()
	root.add_child(scene)
	var signals := {"finished": 0}
	scene.finished.connect(func(): signals.finished += 1)
	for character in ["larry", "lisa"]:
		for partner in ["eve", "adam", "Chase", "Velvet"]:
			var profile := {"character": character, "name": character.capitalize(), "orientation": "bisexual"}
			var invitation := {"partner": partner, "name": partner.capitalize(), "gender": "male" if partner in ["adam", "Chase"] else "female", "finale": partner in ["eve", "adam"]}
			for reduced in [false, true]:
				scene.play(profile, invitation, reduced)
				check(scene.active and scene.player_actor.role == character, "Selected player appears")
				check(scene.partner_actor.gender == invitation.gender, "Selected partner gender appears")
				check(scene.duration == (1.8 if reduced else 5.4), "Bounded duration for selected motion preference")
				check(not scene.caption_label.text.is_empty(), "Invitation or outcome caption is present")
				for progress in [0.0, 0.2, 0.4, 0.6, 0.83]:
					scene.elapsed = progress * scene.duration
					scene._update_scene()
					check(scene.player_actor.position.is_finite() and scene.partner_actor.position.is_finite(), "Finite actor positions")
					if reduced:
						check(not scene.player_actor.visible and not scene.partner_actor.visible and not scene.player_actor.walking, "Reduced-motion aftermath remains still")
				var before := int(signals.finished)
				scene.skip_button.pressed.emit()
				scene.finish()
				check(not scene.active and signals.finished == before + 1, "Skip emits exactly one completion")
				check(not scene.player_actor.is_processing() and not scene.partner_actor.is_processing(), "Finished actors stop processing")
	var last_children := scene.get_child_count()
	for repeat in range(8):
		scene.play({"character": "lisa"}, {"partner": "eve", "name": "Adam", "gender": "male", "finale": true})
		check(scene.partner_actor.role == "adam", "Stable rooftop ID resolves to selected male host art")
		check(scene.get_child_count() == last_children, "Replay does not accumulate UI children")
		var before := int(signals.finished)
		scene._process(scene.duration + 10.0)
		check(not scene.active and signals.finished == before + 1, "Natural completion is bounded and emits once")
	for character in ["larry", "lisa"]:
		for orientation in ["heterosexual", "homosexual", "bisexual"]:
			var expected_host := "Eve" if (character == "lisa") == (orientation == "homosexual") else "Adam"
			var words: String = Travel.caption_for("penthouse", "rooftop", 2, {"character": character, "orientation": orientation})
			check(words.contains(expected_host), "Correct finale host in travel caption for %s/%s" % [character, orientation])
	check(Travel.caption_for("street", "bar", 0, {"character": "lisa"}).contains("Lisa makes an entrance. Her"), "Lisa travel pronouns are personalized")
	# Map routes can go directly from the lower garden to the rooftop. The
	# narrator must use the same floor direction as the drawn elevator indicator.
	for lower in ["hotel", "garden"]:
		for upper in ["penthouse", "rooftop"]:
			check(Travel.mode_for(lower, upper) == "elevator" and Travel.caption_for(lower, upper, 0, {"character": "lisa"}).begins_with("Going up?"), "Ascending %s → %s has upward narration" % [lower, upper])
			check(Travel.caption_for(upper, lower, 0, {"character": "lisa"}).begins_with("Lisa comes down to earth."), "Descending %s → %s has downward narration" % [upper, lower])
	var caller_profile := {"character": "lisa", "name": "Lisa"}
	var long_caption := "Lisa and Adam got laid. " + "The narrator politely keeps the details to himself. ".repeat(10)
	var caller_invitation := {"partner": "eve", "name": "Adam", "gender": "male", "finale": true, "caption": long_caption}
	scene.play(caller_profile, caller_invitation, true)
	caller_profile.clear()
	caller_invitation.clear()
	check(scene.profile.character == "lisa" and scene.encounter.name == "Adam", "Presentation owns isolated profile and invitation snapshots")
	check(scene.caption_label.text == long_caption, "Full authored aftermath is preserved")
	check(scene.caption_label.get_parent() is ScrollContainer and not scene.caption_label.clip_text, "Long aftermath can scroll instead of clipping")
	scene.finish()
	if "--capture-camp" in OS.get_cmdline_user_args():
		await _capture(scene)
	scene.queue_free()
	await process_frame
	print("Encounter visuals: %d assertions, %d failures." % [assertions, failures.size()])
	quit(0 if failures.is_empty() else 1)

func _capture(scene: Control) -> void:
	root.size = Vector2i(1000, 700)
	root.content_scale_size = Vector2i(1000, 700)
	DirAccess.make_dir_recursive_absolute("res://exports/camp-captures")
	for character in ["larry", "lisa"]:
		var partner := "Eve" if character == "larry" else "Adam"
		scene.play({"character": character}, {"partner": "eve", "name": partner, "gender": "female" if partner == "Eve" else "male", "title": "Paradise: strictly a private performance", "finale": true})
		scene.set_process(false)
		for progress in [0.2, 0.85]:
			scene.elapsed = progress * scene.duration
			scene._update_scene()
			for actor in [scene.player_actor, scene.partner_actor]: actor.set_process(false)
			await process_frame
			await RenderingServer.frame_post_draw
			root.get_texture().get_image().save_png("res://exports/camp-captures/%s-%d.png" % [character, int(progress * 100)])
		scene.finish()
