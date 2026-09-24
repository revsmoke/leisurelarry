extends SceneTree
## Deterministic UI regression, not an unaided model or visual playthrough.
## Pool tests intentionally use the model's target angles/power to exercise UI.
## No network, real player saves, quest-item grants or live API requests.
const Hosts = preload("res://scripts/party_hosts.gd")

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
var context := ""

func _init() -> void: _run.call_deferred()

func check(value: bool, message: String) -> void:
	checks += 1
	if not value:
		failures.append(context + ": " + message)
		printerr("FAIL: " + context + ": " + message)

func settle() -> void:
	await process_frame
	await process_frame

func label_for(id: String) -> Button:
	for button in app.hotspots.get_children():
		if button.get_meta("hotspot_id", "") == id: return button
	return null

func click_body(actor: Control) -> void:
	var point := actor.get_global_transform() * Vector2(0, -136)
	for pressed in [true, false]:
		var event := InputEventMouseButton.new()
		event.button_index = MOUSE_BUTTON_LEFT
		event.position = point
		event.global_position = point
		event.pressed = pressed
		root.push_input(event, true)

func choose(id: String, action: String) -> void:
	var key := "party|" + id + "|" + action
	var button: Button = app.dialogue_choice_buttons.get(key)
	check(is_instance_valid(button) and not button.disabled, "Enabled dialogue choice " + action)
	if is_instance_valid(button): button.pressed.emit()

func table_press(panel: Control, action: String) -> Button:
	var button: Button = panel.action_buttons.get(action)
	check(is_instance_valid(button) and not button.disabled, "Enabled table action " + action)
	if is_instance_valid(button): button.pressed.emit()
	return button

func skip_interlude(panel: Control) -> void:
	if panel.interlude_left <= 0: return
	check(panel.table.interlude, "Settled round stages an actual wardrobe interlude")
	if panel.action_buttons.has("skip"): table_press(panel, "skip")
	else: panel._skip_interlude()
	check(panel.interlude_left == 0 and not panel.table.interlude, "Skip ends the wardrobe interlude")

func snapshot_adventure() -> Dictionary:
	var adventure_flags: Dictionary = {}
	for key in app.game.flags:
		if not str(key).begins_with("party_"): adventure_flags[key] = app.game.flags[key]
	return {"cash": app.game.cash, "score": app.game.score, "completed": app.game.completed, "inventory": app.game.inventory.duplicate(), "finale": app.game.finale_name(), "room": app.game.room, "flags": adventure_flags}

func played_entries(id: String) -> int:
	var count := 0
	var prefix: String = "Played " + Hosts.TITLES[Hosts.mode_for(id)] + " with " + app.game.actor_profile(id).name + ". "
	for entry in app.game.journal:
		if str(entry).begins_with(prefix): count += 1
	return count

func check_table_layout(panel: Control) -> void:
	check(panel.rules.get_rect().end.y <= panel.score.position.y, "Rules end above the score after text layout")
	check(panel.score.get_rect().end.y <= panel.table.position.y, "Score ends above the table stage")
	check(panel.table.get_rect().end.y <= panel.detail.position.y, "Table stage ends above the scrolling result")
	check(panel.detail.get_rect().end.y <= panel.visual_text.position.y, "Result scroll area leaves visual instructions clear")
	check(panel.visual_text.get_rect().end.y <= panel.controls.position.y, "Visual instructions end above the game controls")
	check(panel.controls.get_rect().end.y <= panel.footer.position.y, "Game controls do not overlap the fixed footer")
	check(Rect2(Vector2.ZERO, panel.size).encloses(panel.footer.get_rect()), "Footer stays inside the table panel")
	for button in panel.controls.get_children():
		check(Rect2(Vector2.ZERO, panel.controls.size).encloses(button.get_rect()), "Action button fits its flow container: " + button.text)
	for button in panel.footer.get_children():
		check(Rect2(Vector2.ZERO, panel.footer.size).encloses(button.get_rect()), "Footer button stays inside its container: " + button.text)

func play_session(panel: Control, answer_style: int = 0) -> void:
	var mode: String = Hosts.mode_for(panel.host_id)
	var guard := 0
	var final_button: Button
	while not panel.model.view().finished and guard < 160:
		guard += 1
		skip_interlude(panel)
		await settle()
		check_table_layout(panel)
		var view: Dictionary = panel.model.view()
		if panel.action_buttons.has("next"):
			table_press(panel, "next")
			continue
		match mode:
			"poker":
				if view.round == 1:
					for slot in [0, 1, 2]: table_press(panel, "toggle_" + str(slot))
					check(not panel.action_buttons.has("toggle_3"), "A fourth discard is unavailable")
					table_press(panel, "toggle_0")
					check(panel.action_buttons.has("toggle_3"), "Keeping a card restores legal discard choices")
				final_button = table_press(panel, "draw")
			"never":
				var answer: String = ["pass", "have", "never"][answer_style % 3]
				final_button = table_press(panel, answer)
				if answer == "pass":
					check(panel.model.view().player_losses == 0, "Pass never removes player clothing")
					check(str(panel.model.view().status).contains("No explanation"), "Pass has a pressure-free response")
			"pool":
				var target: Dictionary = view.visuals
				# Target values are deliberate deterministic fixtures, not a player's
				# unaided observations and never inputs to the external QA player.
				while int(panel.model.view().visuals.angle) < int(target.target_angle): table_press(panel, "angle_plus")
				while int(panel.model.view().visuals.angle) > int(target.target_angle): table_press(panel, "angle_minus")
				while int(panel.model.view().visuals.power) < int(target.target_power): table_press(panel, "power_plus")
				while int(panel.model.view().visuals.power) > int(target.target_power): table_press(panel, "power_minus")
				final_button = table_press(panel, "shoot")
				check(panel.model.view().visuals.success, "The actual aim/power/Shoot controls pot the intended ball")
		var after: Dictionary = panel.model.view()
		check(panel.player_actor.party_loss == mini(3, after.player_losses), "Player wardrobe reflects settled losses")
		check(panel.host_actor.party_loss == mini(3, after.npc_losses), "Host wardrobe reflects settled losses")
		check(not panel.pending, "Headless offline play settles without a network wait")
		if after.finished and is_instance_valid(final_button):
			var saves: int = app.saves
			# A second press during the same event frame must not record twice.
			final_button.pressed.emit()
			check(app.saves == saves, "A stale final-round button cannot record completion twice")
	check(guard < 160 and panel.model.view().finished, "All rounds finish through real buttons")
	skip_interlude(panel)
	await settle()
	check_table_layout(panel)
	check(panel.action_buttons.has("rematch") and panel.action_buttons.has("chat"), "Finished games offer a rematch and optional conversation")

func _run() -> void:
	root.size = Vector2i(1440, 960)
	app = TestMain.new()
	root.add_child(app)
	await settle()
	root.notify_mouse_entered()
	var profile_index := 0
	for character in ["larry", "lisa"]:
		for orientation in ["heterosexual", "homosexual", "bisexual"]:
			for id in Hosts.IDS:
				context = character + "/" + orientation + "/" + id
				app.game.new_game(41 + profile_index)
				app.game.configure_profile(character, orientation)
				app.game.room = Hosts.ROOMS[id]
				app.ending_shown = false
				app.reduced_motion = profile_index % 2 == 1
				app._render()
				await settle()
				var person: Dictionary = app.game.actor_profile(id)
				var actor: Control = app._npc_actor(id)
				check(is_instance_valid(actor) and actor.role == id and actor.gender == person.gender and actor.skin == Color(person.skin), "World actor matches the chosen host/profile")
				check(actor.party_loss == 0 and not actor.seated, "World host has the normal clothed pose")
				check(app.game.is_eligible_partner(id), "Host is a compatible adult optional date")
				var label := label_for(id)
				check(is_instance_valid(label), "World host has a clickable label")
				if is_instance_valid(label):
					var body_bounds: Rect2 = actor.get_transform() * actor.label_obstacle()
					check(not label.get_rect().intersects(body_bounds), "Name label leaves the host's face and silhouette unobscured")
					check(Rect2(0, 0, 1140, 506).encloses(label.get_rect()), "Name label stays inside the scene")
					var text_width: float = label.get_theme_font("font").get_string_size(label.text, HORIZONTAL_ALIGNMENT_LEFT, -1, label.get_theme_font_size("font_size")).x
					check(label.size.x >= text_width + 32, "Full label fits both style margins")
				app._set_verb("talk")
				click_body(actor)
				await settle()
				check(app.game.get_dialogue_target() == id and is_instance_valid(app.modal), "Body click opens this host's conversation")
				if app.reduced_motion:
					# Reduced motion applies the final approach position immediately.
					var player_bounds: Rect2 = app.larry.get_global_transform() * app.larry.label_obstacle()
					var host_bounds: Rect2 = actor.get_global_transform() * actor.label_obstacle()
					check(not player_bounds.intersects(host_bounds), "Player stops beside the host without covering the host's face or body")
				var portrait: Control = app.modal.find_child("ConversationActor", true, false) if is_instance_valid(app.modal) else null
				check(is_instance_valid(portrait) and portrait.role == actor.role and portrait.gender == actor.gender and portrait.skin == actor.skin, "Conversation portrait preserves the host's identity")
				check(not app.dialogue_choice_buttons.has("party|" + id + "|flirt"), "Flirting is a separate option after playing")
				app._close_modal()
				app._command("use " + person.name)
				check(is_instance_valid(app.modal) and app.game.get_dialogue_target() == id and app.dialogue_choice_buttons.has("party|" + id + "|play"), "Parser USE opens the same playable invitation")
				var adventure := snapshot_adventure()
				choose(id, "play")
				var panel: Control = app.party_panel
				check(is_instance_valid(panel), "Real Play dialogue callback opens the party table")
				if not is_instance_valid(panel): continue
				# Seed only the isolated table's random fixture for reproducible rounds.
				panel.model.setup(Hosts.mode_for(id), 100 + profile_index)
				panel._refresh()
				check(not panel.network_available and not panel.pending, "Headless game table never calls a network service")
				check(panel.host_actor.role == id and panel.host_actor.gender == person.gender and panel.host_actor.skin == Color(person.skin), "Table uses the same host")
				check(panel.player_actor.role == "party_player" and panel.player_actor.gender == app.game.player_gender(), "Table uses the selected protagonist")
				check(str(panel.detail.text).begins_with(person.name), "Intro names the actual orientation-aware host")
				check(panel.reduced_motion == app.reduced_motion and panel.host_actor.reduced_motion == app.reduced_motion, "Table and actors honor reduced motion")
				if app.reduced_motion:
					check(panel.interlude_duration <= 0.45 and panel.table.motion == 1.0, "Reduced-motion intro is a short still pose")
				await settle()
				check_table_layout(panel)
				table_press(panel, "start")
				check(not panel.intro and panel.interlude_left == 0, "Start leaves the intro and enables real gameplay")
				var saves_before: int = app.saves
				await play_session(panel, profile_index)
				check(snapshot_adventure() == adventure, "Party game changes no adventure cash, score, inventory or ending")
				check(app.game.flags.get("party_played_" + id, false), "Completion callback records the earned party visit")
				check(played_entries(id) == 1 and app.saves == saves_before + 1, "Completed session adds one journal memory and saves once")
				check(not app.game.flags.get("party_encounter_" + id, false), "Finishing a game does not imply consent to an encounter")
				table_press(panel, "chat")
				check(not is_instance_valid(app.party_panel) and app.dialogue_choice_buttons.has("party|" + id + "|flirt"), "After-game chat returns to a separate optional flirtation")
				choose(id, "flirt")
				check(not app.game.flags.get("party_encounter_" + id, false), "Flirting still requires a separate invitation acceptance")
				choose(id, "decline")
				check(not app.game.flags.get("party_encounter_" + id, false) and app.dialogue_choice_buttons.has("party|" + id + "|flirt"), "Declining is recoverable and keeps the game friendly")
				choose(id, "flirt")
				app.animate_travel_in_tests = true
				var before_accept: int = app.saves
				choose(id, "accept")
				check(app.is_cinematic(), "Accepted invitation starts the actual private-scene cutscene")
				if is_instance_valid(app.encounter_cutscene):
					var partner: Control = app.encounter_cutscene.partner_actor
					check(partner.role == id and partner.gender == person.gender and partner.skin == Color(person.skin), "Encounter cutscene keeps the correct host appearance")
					check(partner.party_loss == 0, "Private scene restores the host's ordinary outfit")
					check(app.encounter_cutscene.reduced_motion == app.reduced_motion, "Private scene honors the current motion preference")
					check(app.saves == before_accept + 1, "Acceptance is saved once before the cutscene")
					app.encounter_cutscene.finish()
				check(app.game.flags.get("party_encounter_" + id, false) and not app.is_cinematic(), "Skip preserves the accepted optional encounter")
				check(snapshot_adventure() == adventure, "Optional encounter preserves the main route and finances")
				app.animate_travel_in_tests = false
				app._close_modal()
				await settle()
			profile_index += 1
	await _close_and_rematch_checks()
	await _absent_host_commands()
	app.queue_free()
	await process_frame
	print("Party interface checks: %d passed, %d failed" % [checks - failures.size(), failures.size()])
	quit(0 if failures.is_empty() else 1)

func _close_and_rematch_checks() -> void:
	for id in Hosts.IDS:
		context = "lifecycle/" + id
		app.game.new_game(72)
		app.game.room = Hosts.ROOMS[id]
		# A completed-evening fixture verifies after-party preservation. This is
		# deterministic test setup, never a state supplied to a model player.
		app.game.completed = true
		app.game.flags.encounter_eve = true
		app.ending_shown = true
		app.reduced_motion = true
		app._render()
		await settle()
		var adventure := snapshot_adventure()
		app._command("play " + Hosts.mode_for(id))
		var panel: Control = app.party_panel
		check(is_instance_valid(panel), "Parser PLAY opens the host's real table")
		if not is_instance_valid(panel): continue
		panel.model.setup(Hosts.mode_for(id), 200)
		panel._refresh()
		table_press(panel, "start")
		var first_action: String = {"poker": "toggle_0", "never": "pass", "pool": "angle_plus"}[Hosts.mode_for(id)]
		table_press(panel, first_action)
		var leave: Button = panel.footer.get_child(0)
		check(leave.text.begins_with("Leave table"), "A leave control is always present mid-session")
		leave.pressed.emit()
		check(not panel.active and not panel.pending and panel.timeout_timer.is_stopped(), "Closing stops processing and any pending request")
		check(not is_instance_valid(app.party_panel) and not app.game.flags.get("party_played_" + id, false), "Abandoned rounds do not earn completion")
		check(snapshot_adventure() == adventure and played_entries(id) == 0, "Leaving mid-session has no adventure or journal penalty")
		await settle()
		app._command("play " + Hosts.mode_for(id))
		panel = app.party_panel
		check(is_instance_valid(panel) and panel.intro and panel.model.view().round == 1 and panel.model.view().player_losses == 0 and panel.model.view().npc_losses == 0, "Reopening begins a fresh fully dressed session")
		if not is_instance_valid(panel): continue
		panel.model.setup(Hosts.mode_for(id), 201)
		panel._refresh()
		table_press(panel, "start")
		await play_session(panel)
		var memories: int = played_entries(id)
		var saves: int = app.saves
		table_press(panel, "rematch")
		check(panel.intro and panel.model.view().round == 1 and panel.model.view().player_losses == 0 and panel.model.view().npc_losses == 0, "Rematch resets rounds, cards and costume losses")
		check(not panel.completed_sent and panel.last_ai.is_empty(), "Rematch resets completion/AI transient state")
		check(played_entries(id) == memories and app.saves == saves, "Starting a rematch does not repeat a completion reward")
		table_press(panel, "start")
		check(not panel.model.view().finished, "Fresh rematch is playable")
		app._close_modal()
		check(snapshot_adventure() == adventure, "Rematch and exit preserve the adventure")
		app._command("talk " + app.game.actor_profile(id).name)
		choose(id, "flirt")
		app.animate_travel_in_tests = true
		choose(id, "accept")
		check(app.is_cinematic() and app.encounter_result.contains("already complete"), "After-party invitation recognizes the earned ending")
		if is_instance_valid(app.encounter_cutscene):
			check(app.encounter_cutscene.reduced_motion and app.encounter_cutscene.duration <= 1.8, "Reduced-motion after-party uses the brief still scene")
			app.encounter_cutscene.finish()
		app.animate_travel_in_tests = false
		check(snapshot_adventure() == adventure and app.game.completed, "After-party romance preserves the complete main ending")
		app._close_modal()
		await settle()

func _absent_host_commands() -> void:
	for character in ["larry", "lisa"]:
		for orientation in ["heterosexual", "homosexual", "bisexual"]:
			app.game.new_game(88)
			app.game.configure_profile(character, orientation)
			app.ending_shown = false
			for index in range(Hosts.IDS.size()):
				var id: String = Hosts.IDS[index]
				var elsewhere: String = Hosts.ROOMS[Hosts.IDS[(index + 1) % Hosts.IDS.size()]]
				for room in [elsewhere, "bar"]:
					app._close_modal()
					app.game.room = room
					app._render()
					await settle()
					for target in [app.game.actor_profile(id).name, id]:
						context = "absent host/" + character + "/" + orientation + "/" + room + "/" + target
						var adventure := snapshot_adventure()
						var turns: int = app.game.turns
						app._command("use " + target)
						check(app.last_message.contains("cannot see that here"), "Absent host USE reports the ordinary unavailable-target message")
						check(not is_instance_valid(app.modal) and not is_instance_valid(app.party_panel), "Absent host USE opens no remote invitation or party table")
						check(snapshot_adventure() == adventure and app.game.turns == turns, "Absent host USE preserves adventure progress and turn count")
