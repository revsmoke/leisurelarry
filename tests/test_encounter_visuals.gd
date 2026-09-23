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
				var expected_duration := (3.0 if reduced else 12.0) if invitation.finale else (1.8 if reduced else 5.4)
				check(scene.duration == expected_duration, "Bounded duration for selected movie and motion preference")
				check(not scene.caption_label.text.is_empty(), "Invitation or outcome caption is present")
				for progress in [0.0, 0.2, 0.4, 0.6, 0.83]:
					scene.elapsed = progress * scene.duration
					scene._update_scene()
					check(scene.player_actor.position.is_finite() and scene.partner_actor.position.is_finite(), "Finite actor positions")
					if reduced:
						check(scene.player_actor.visible == invitation.finale and scene.partner_actor.visible == invitation.finale and not scene.player_actor.walking and not scene.partner_actor.walking, "Reduced-motion finale retains both actors; optional scenes retain their still card")
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
			var partner_gender := ("female" if character == "lisa" else "male") if orientation == "homosexual" else ("male" if character == "lisa" else "female")
			var partner_name := "Adam" if partner_gender == "male" else "Eve"
			var player_profile := {"character": character, "orientation": orientation, "name": character.capitalize()}
			var event := {"partner": "eve", "name": partner_name, "gender": partner_gender, "finale": true}
			scene.play(player_profile, event)
			check(scene.is_finale and scene.duration == 12.0, "Winning encounter uses the extended finale for %s/%s" % [character, orientation])
			check(scene.player_actor.role == character and scene.partner_actor.role == partner_name.to_lower(), "Finale casts both chosen characters")
			for act in [[0.1, "invitation"], [0.3, "together"], [0.54, "privacy"], [0.9, "sunrise"]]:
				scene.elapsed = scene.duration * act[0]
				scene._update_scene()
				check(scene.phase == act[1], "Finale advances through authored act: " + str(act[1]))
				check(scene.player_actor.visible == (act[1] != "privacy") and scene.partner_actor.visible == (act[1] != "privacy"), "Both actors are visible outside the private curtain interlude")
			check(scene.player_actor.modulate.a == 1.0 and scene.partner_actor.modulate.a == 1.0 and not scene.player_actor.walking and not scene.partner_actor.walking, "Victory tableau shows both actors at full opacity, standing together")
			check(scene._name_label.text.contains(character.capitalize()) and scene._name_label.text.contains(partner_name), "Victory names match both visible characters")
			check(scene.caption_label.text.contains("got laid"), "Finale states the achieved goal")
			check(player_profile == {"character": character, "orientation": orientation, "name": character.capitalize()} and event == {"partner": "eve", "name": partner_name, "gender": partner_gender, "finale": true}, "Finale presentation does not mutate caller state")
			scene.finish()
			scene.play(player_profile, event, true)
			var player_position: Vector2 = scene.player_actor.position
			var partner_position: Vector2 = scene.partner_actor.position
			check(scene.phase == "sunrise" and scene.player_actor.visible and scene.partner_actor.visible, "Reduced motion starts on the complete pair tableau")
			scene._process(1.0)
			check(scene.player_actor.position == player_position and scene.partner_actor.position == partner_position and scene.active, "Reduced motion holds a still tableau for reading")
			var before := int(signals.finished)
			scene._process(2.0)
			scene.finish()
			check(not scene.active and signals.finished == before + 1, "Reduced finale ends once after its three-second hold")
	for progress in [0.08, 0.32, 0.54, 0.9]:
		scene.play({"character": "larry"}, {"partner": "eve", "name": "Adam", "gender": "male", "finale": true})
		scene.elapsed = progress * scene.duration
		scene._update_scene()
		var act: String = scene.phase
		var before := int(signals.finished)
		scene.skip_button.pressed.emit()
		scene._process(scene.duration)
		scene.finish()
		check(not scene.active and signals.finished == before + 1 and not scene.is_processing(), "Skip during %s completes once, even with a late frame" % act)
		check(not scene.player_actor.is_processing() and not scene.partner_actor.is_processing(), "Skip during %s stops both actors" % act)
	var announced: Array[Dictionary] = []
	var listener := func(): announced.append({"phase": scene.phase, "label": scene._phase_label.text, "caption": scene.caption_label.text, "player_visible": scene.player_actor.visible, "partner_visible": scene.partner_actor.visible})
	scene.phase_changed.connect(listener)
	scene.play({"character": "lisa"}, {"partner": "eve", "name": "Eve", "gender": "female", "finale": true})
	check(announced.size() == 1 and announced[0].phase == "invitation" and announced[0].label.begins_with("01") and announced[0].player_visible, "Initial phase notification follows complete labels and pose")
	for progress in [0.1, 0.2, 0.3, 0.32, 0.35, 0.5, 0.54, 0.6, 0.8, 0.9, 0.95]:
		scene.elapsed = progress * scene.duration
		scene._update_scene()
	check(announced.size() == 4, "Many rendered frames emit only four phase notifications")
	check(announced.map(func(value): return value.phase) == ["invitation", "together", "privacy", "sunrise"], "Phase notifications follow story order")
	check(announced[2].label.begins_with("03") and not announced[2].player_visible and not announced[2].partner_visible, "Privacy notification observes completed hidden-actor pose")
	check(announced[3].label.begins_with("04") and announced[3].caption.contains("got laid") and announced[3].player_visible and announced[3].partner_visible, "Sunrise notification includes outcome and both visible characters")
	scene.finish()
	announced.clear()
	scene.play({"character": "larry"}, {"partner": "eve", "name": "Adam", "gender": "male", "finale": true}, true)
	scene._process(0.5)
	scene._process(0.5)
	check(announced.size() == 1 and announced[0].phase == "sunrise", "Reduced motion announces its still final tableau once")
	scene.finish()
	scene.phase_changed.disconnect(listener)
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
		for partner in ["Eve", "Adam"]:
			scene.play({"character": character}, {"partner": "eve", "name": partner, "gender": "female" if partner == "Eve" else "male", "title": "Paradise: strictly a private performance", "finale": true})
			scene.set_process(false)
			for progress in [0.12, 0.32, 0.54, 0.90]:
				scene.elapsed = progress * scene.duration
				scene._update_scene()
				for actor in [scene.player_actor, scene.partner_actor]: actor.set_process(false)
				await process_frame
				await RenderingServer.frame_post_draw
				root.get_texture().get_image().save_png("res://exports/camp-captures/finale-%s-%s-%d.png" % [character, partner.to_lower(), int(progress * 100)])
			scene.finish()
