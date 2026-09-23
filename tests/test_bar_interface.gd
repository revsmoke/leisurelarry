extends SceneTree
## Real UI callbacks and viewport pointer input; isolated from player saves.
const Bar = preload("res://scripts/bar_regulars.gd")
class TestMain:
	extends "res://scripts/main.gd"
	var saves := 0
	func _autosave() -> void: saves += 1
	func _start_music() -> void: pass
	func _automation() -> void: pass
	func _load_preferences() -> void: pass
	func _save_preferences() -> void: pass

var checks := 0
var failures: Array[String] = []
var app: Control
func _init() -> void: _run.call_deferred()
func check(value: bool, message: String) -> void:
	checks += 1
	if not value:
		failures.append(message)
		printerr("FAIL: " + message)
func settle() -> void:
	await process_frame
	await process_frame
func label_for(id: String) -> Button:
	for button in app.hotspots.get_children():
		if button.get_meta("hotspot_id", "") == id: return button
	return null
func choose(id: String, action: String) -> void:
	var key := "bar|" + id + "|" + action
	var button: Button = app.dialogue_choice_buttons.get(key)
	check(is_instance_valid(button) and not button.disabled, "Real dialogue button: " + key)
	if is_instance_valid(button): button.pressed.emit()
func click_body(actor: Control) -> void:
	var point := actor.get_global_transform() * Vector2(0, -136)
	for pressed in [true, false]:
		var event := InputEventMouseButton.new()
		event.button_index = MOUSE_BUTTON_LEFT
		event.position = point
		event.global_position = point
		event.pressed = pressed
		root.push_input(event, true)

func _run() -> void:
	root.size = Vector2i(1440, 960)
	app = TestMain.new()
	root.add_child(app)
	await settle()
	root.notify_mouse_entered()
	for character in ["larry", "lisa"]:
		for orientation in ["heterosexual", "homosexual", "bisexual"]:
			app.game.new_game(0)
			app.game.configure_profile(character, orientation)
			app.game.room = "bar"
			app._render()
			await settle()
			check(app.actors.get_child_count() == 8, "Five new patrons coexist with three original bar NPCs")
			for label in app.hotspots.get_children():
				var text_width: float = label.get_theme_font("font").get_string_size(label.text, HORIZONTAL_ALIGNMENT_LEFT, -1, label.get_theme_font_size("font_size")).x
				check(label.size.x >= text_width + 32, "Bar label fits its text and both 16px style margins: " + label.text)
			for id in Bar.IDS:
				var actor: Control = app._npc_actor(id)
				check(actor.seated and actor.role == app.game.actor_profile(id).role, "Seated role matches " + id)
				var body_bounds: Rect2 = actor.get_transform() * actor.label_obstacle()
				check(label_for(id).get_rect().end.y <= body_bounds.position.y, "Patron label stays above the entire animated silhouette: " + id)
				app._set_verb("talk")
				click_body(actor)
				await settle()
				check(app.game.get_dialogue_target() == id and is_instance_valid(app.modal), "Body click opens this patron's real conversation")
				var portrait: Control = app.modal.find_child("ConversationActor", true, false) if is_instance_valid(app.modal) else null
				check(is_instance_valid(portrait) and portrait.role == actor.role and portrait.gender == actor.gender and portrait.skin == actor.skin and not portrait.seated, "Conversation stands the matching patron up without a stool")
				app._close_modal()
				app._command("use " + app.game.actor_profile(id).name)
				check(is_instance_valid(app.modal) and app.game.get_dialogue_target() == id and not app.dialogue_choice_buttons.is_empty(), "Parser USE exposes the same choices as pointer USE")
				app._close_modal()
	# The UI resolves an actual puzzle and invitation before presenting each actor.
	for id in Bar.IDS:
		app.game.new_game(2)
		app.game.configure_profile("lisa", "bisexual")
		app.game.room = "bar"
		app._render()
		app._command("talk " + app.game.actor_profile(id).name)
		if id == "bar_kit": choose(id, "clue")
		else:
			app._close_modal()
			var source: Array = {"bar_rox": ["hotel", "guestbook"], "bar_bo": ["shop", "magazines"], "bar_jazz": ["alley", "busker"], "bar_red": ["street", "newsbox"]}[id]
			app._map_travel(source[0])
			app._command("look " + source[1])
			app._map_travel("bar")
			app._command("talk " + app.game.actor_profile(id).name)
		for pick in Bar.PUZZLES[id][int(app.game.bar_regulars.night.variants[id])].answer:
			choose(id, "pick_" + str(pick))
		# Inject completion only for a headless after-party regression, never a model run.
		app.game.completed = true
		app.game.flags.encounter_eve = true
		app.ending_shown = true
		choose(id, "flirt")
		var before: int = app.saves
		app.animate_travel_in_tests = true
		choose(id, "accept")
		check(app.is_cinematic(), "Accepted bar encounter starts the actual cutscene")
		if is_instance_valid(app.encounter_cutscene):
			var partner: Control = app.encounter_cutscene.partner_actor
			check(partner.role == app.game.actor_profile(id).role and partner.skin == Color(app.game.actor_profile(id).skin) and not partner.seated, "Cutscene preserves distinctive partner art and skin")
			check(app.saves == before + 1, "Acceptance saves once before the movie")
			check(app.encounter_result.contains("already complete") and not app.encounter_result.contains("goal is still"), "After-party text acknowledges the completed rooftop ending")
			app.encounter_cutscene.finish()
			check(not app.is_cinematic() and app.game.completed, "Skipping returns to play and retains the prior ending")
		app.animate_travel_in_tests = false
		await settle()
	app.queue_free()
	await process_frame
	print("Bar interface checks: %d passed, %d failed" % [checks - failures.size(), failures.size()])
	quit(0 if failures.is_empty() else 1)
