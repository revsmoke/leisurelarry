extends SceneTree
## Real profile controls and cinematic lifecycle, isolated from player saves.
const EncounterCutscene = preload("res://scripts/encounter_cutscene.gd")
const QABridge = preload("res://scripts/qa_bridge.gd")
class TestMain:
	extends "res://scripts/main.gd"
	var saves := 0
	func _autosave() -> void: saves += 1
	func _start_music() -> void: pass
	func _automation() -> void: pass
	func _load_preferences() -> void: pass
	func _save_preferences() -> void: pass

class ScratchState:
	extends "res://scripts/game_state.gd"
	var scratch_path := "user://profile-startup-%s.json" % OS.get_process_id()
	func save_game(_path: String = "user://savegame.json") -> String:
		return super.save_game(scratch_path)
	func load_game(_path: String = "user://savegame.json") -> String:
		return super.load_game(scratch_path)

class ResumeMain:
	extends TestMain
	func _autosave() -> void:
		saves += 1
		game.save_game()

var checks := 0
var failures: Array[String] = []
var app: Control
var finishes := 0
var bridge_result: Dictionary = {}

func _init() -> void: _run.call_deferred()
func _check(ok: bool, message: String) -> void:
	checks += 1
	if not ok:
		failures.append(message)
		printerr("FAIL: " + message)
func _button(node: Node, label: String) -> Button:
	if not is_instance_valid(node): return null
	for child in node.get_children():
		if child is Button and child.text.trim_prefix("✓ ") == label and child.visible: return child
		var found := _button(child, label)
		if found != null: return found
	return null
func _press(label: String) -> void:
	var button := _button(app.modal, label)
	_check(button != null and not button.disabled, "Visible actionable " + label)
	if button != null and not button.disabled: button.pressed.emit()
func _texts(node: Node) -> String:
	var result := ""
	for child in node.get_children():
		if child is Label: result += child.text + "\n"
		result += _texts(child)
	return result
func _key(code: Key) -> void:
	var event := InputEventKey.new()
	event.pressed = true
	event.keycode = code
	app._unhandled_key_input(event)

func _request(bridge: Node, message: Dictionary) -> void:
	bridge_result = await bridge.request(message)

func _run() -> void:
	app = TestMain.new()
	root.add_child(app)
	await process_frame
	_check(app.game.profile.orientation == "bisexual", "New model defaults to bisexual")
	for character in ["larry", "lisa"]:
		for orientation in ["heterosexual", "homosexual", "bisexual"]:
			var old_profile: Dictionary = app.game.profile.duplicate()
			var old_cash: int = app.game.cash
			var saves_before: int = app.saves
			app._character_setup(false)
			_check(app.setup_open and app.draft_orientation == "bisexual", "Setup starts with bisexual selected")
			_key(KEY_ESCAPE)
			_check(app.setup_open and is_instance_valid(app.modal), "Required fresh setup cannot be bypassed with Escape")
			_press("Play as " + character.capitalize())
			_press(orientation.capitalize())
			var partner := "Adam" if (character == "larry" and orientation == "homosexual") or (character == "lisa" and orientation != "homosexual") else "Eve"
			_check(_texts(app.modal).contains("Tonight's dream date: " + partner), "Setup clearly previews matching finale")
			_check(app.game.profile == old_profile and app.game.cash == old_cash and app.saves == saves_before, "Draft choices do not mutate or save current evening")
			_press("Start evening as " + character.capitalize())
			_check(not app.setup_open and not is_instance_valid(app.modal), "Start closes setup")
			_check(app.game.profile.character == character and app.game.profile.orientation == orientation, "Start commits selected identity and orientation")
			_check(app.game.finale_name() == partner, "Correct finale for all six configurations")
			_check(app.logo_label.text == character.to_upper() and app.larry.role == character, "Header and visible avatar match chosen identity")
			_check(app.last_message.contains("get laid with " + partner), "Opening states explicit goal and chosen partner")
			_check(app.saves == saves_before + 1, "New profile persists exactly once on Start")
			_check(app.game.turns == 0 and app.game.cash == 80, "Profile choices spend no moves or money")
	app.game.cash = 53
	var retained: Dictionary = app.game.profile.duplicate()
	var before: int = app.saves
	app._character_setup(true)
	_press("Play as Larry")
	_press("Keep this evening")
	_check(app.game.profile == retained and app.game.cash == 53 and app.saves == before, "Cancel setup preserves ongoing identity and progress")
	await _startup_cancel_checks()
	# Render all six adult pairings through the standalone movie component.
	for player_gender in ["male", "female"]:
		for partner_gender in ["male", "female"]:
			var movie := EncounterCutscene.new()
			root.add_child(movie)
			var name := "Larry" if player_gender == "male" else "Lisa"
			movie.play({"name": name, "character": name.to_lower(), "gender": player_gender}, {"partner": "test", "name": "Robin", "gender": partner_gender, "title": "The velvet curtain", "caption": "A consensual detour. The narrator waits outside.", "finale": false}, false)
			_check(movie.active and movie.player_actor.role == name.to_lower(), "Movie uses selected player avatar")
			_check(movie.partner_actor.gender == partner_gender, "Movie uses selected partner presentation")
			movie.finished.connect(func(): finishes += 1)
			var prior := finishes
			movie.finish()
			movie.finish()
			_check(not movie.active and finishes == prior + 1 and not movie.is_processing(), "Movie skip is idempotent and stops processing")
			movie.queue_free()
			await process_frame
	# Main integration blocks stale controls, persists before the movie, then releases.
	app.animate_travel_in_tests = true
	app._character_setup(false)
	_press("Play as Lisa")
	_press("Homosexual")
	_press("Start evening as Lisa")
	var state_before := {"room": app.game.room, "cash": app.game.cash, "turns": app.game.turns, "score": app.game.score}
	before = app.saves
	app._present_encounter({"partner": "eve", "name": "Eve", "gender": "female", "title": "Some privacy", "caption": "The curtain gets the last word.", "finale": false})
	_check(app.is_cinematic() and not app.is_travelling(), "Encounter is modal cinematic, not travel")
	_check(app.saves == before + 1, "Encounter persists accepted model state before playback")
	app._command("go bar")
	app._map_travel("casino")
	app._new_game()
	_check(app.game.room == state_before.room and app.game.cash == state_before.cash and app.game.turns == state_before.turns, "Stale commands, travel and restart cannot alter active encounter")
	_key(KEY_SPACE)
	_check(not app.is_cinematic() and not is_instance_valid(app.modal), "Space skips actual encounter control")
	_check(app.last_message == "The curtain gets the last word." and app.game.score == state_before.score, "Skipping narrates aftermath without awarding duplicate progress")
	app.reduced_motion = true
	app._present_encounter({"partner": "eve", "name": "Eve", "gender": "female", "title": "Some privacy", "caption": "Still a very good evening.", "finale": false})
	_check(app.encounter_cutscene.reduced_motion and not app.encounter_cutscene.player_actor.walking, "Reduced motion freezes player presentation")
	_key(KEY_ESCAPE)
	_check(not app.is_cinematic(), "Escape dismisses reduced-motion scene")
	# The QA adapter executes an actual invitation button and waits for the movie.
	app.reduced_motion = false
	app.animate_travel_in_tests = false
	app._new_game()
	app._command("go casino")
	app._command("talk casino_date")
	app._close_modal()
	app._command("look lucky_napkin")
	app._command("talk casino_date")
	app._choose_dialogue("date_solve_casino_date")
	app._choose_dialogue("date_flirt_casino_date")
	_check(app.dialogue_choice_buttons.has("date_accept_casino_date"), "Real clue and dialogue route produces optional invitation")
	app.animate_travel_in_tests = true
	var bridge := QABridge.new()
	root.add_child(bridge)
	await bridge.start(app, false)
	var observation: Dictionary = bridge.observation()
	var choice_id := ""
	for choice in observation.actions:
		if choice.label.contains("Yes") and (choice.label.contains("fling") or choice.label.contains("laid")): choice_id = choice.id
	_check(not choice_id.is_empty(), "QA sees actual accepted-fling choice")
	before = app.saves
	_request.call_deferred(bridge, {"type": "larry-qa-action", "requestId": "encounter-check", "revision": observation.revision, "action": choice_id})
	await process_frame
	await process_frame
	_check(app.is_cinematic() and bridge.busy and bridge_result.is_empty(), "QA waits while actual encounter movie plays")
	_check(app.game.flags.get("encounter_casino_date", false) and not app.game.completed, "Accepted optional fling persists independently of winning goal")
	_check(app.saves == before + 1, "Real invitation path autosaves only once")
	var duplicate: Dictionary = await bridge.request({"type": "larry-qa-action", "requestId": "duplicate", "revision": observation.revision, "action": choice_id})
	_check(duplicate.get("error") == "busy", "Concurrent QA action rejected during movie")
	if is_instance_valid(app.encounter_cutscene): app.encounter_cutscene.skip_button.pressed.emit()
	for i in range(6): await process_frame
	_check(not bridge.busy and not bridge_result.is_empty() and not bridge_result.has("error"), "Movie skip releases QA only after visible aftermath")
	_check(not app.is_cinematic() and not app.game.completed and app.game.room == "casino", "Optional encounter returns to same room without finishing story")
	bridge.queue_free()
	await process_frame
	await _finale_replay_checks()
	app.queue_free()
	await process_frame
	print("Profile interface tests: %d assertions, %d failures." % [checks, failures.size()])
	quit(0 if failures.is_empty() else 1)

func _finale_replay_checks() -> void:
	app._close_modal()
	app.game.new_game()
	app._render()
	app._replay_finale()
	_check(not app.is_cinematic() and not app.finale_replay_button.visible, "Unfinished evenings cannot replay an unearned finale")
	# Completed-save fixtures exercise presentation only, not unaided gameplay.
	for character in ["larry", "lisa"]:
		for orientation in ["heterosexual", "homosexual", "bisexual"]:
			app.game.new_game()
			app.game.configure_profile(character, orientation)
			app.game.completed = true
			app.game.flags["encounter_eve"] = true
			app.game.flags["ending_flirt"] = true
			app.game.room = "rooftop"
			app.game.score = 48
			app.game.turns = 84
			app.ending_shown = true
			app.reduced_motion = false
			app._render()
			var before_saves: int = app.saves
			var before_flags: Dictionary = app.game.flags.duplicate(true)
			_check(app.finale_replay_button.visible, "Loaded completed profile offers replay")
			app.finale_replay_button.pressed.emit()
			_check(app.is_cinematic() and app.encounter_cutscene.player_actor.role == character and app.encounter_cutscene.partner_actor.gender == app.game.finale_gender(), "Replay stars the saved player and compatible finale partner")
			var current: Control = app.encounter_cutscene
			app._replay_finale()
			_check(app.encounter_cutscene == current, "Repeated replay request cannot replace the active scene")
			_key(KEY_SPACE)
			await process_frame
			_check(not app.is_cinematic() and _button(app.modal, "Replay finale") != null, "Skipping returns to the ending with a replay control")
			_check(app.game.flags == before_flags and app.game.score == 48 and app.game.turns == 84 and app.saves == before_saves, "Replay changes no progress, points, turns, or autosave")
			app._close_modal()
	# Let one actual 12-second finale finish through the QA callback. This catches
	# the former 8-second bridge deadline without skipping/accelerating the movie.
	var prior_size: Vector2 = app.size
	app.size = Vector2(884, 886)
	app._fit()
	_check(app.finale_replay_button.get_rect().end.x <= app.canvas.size.x, "Replay control fits the compact layout")
	app.size = Vector2(1440, 960)
	app._fit()
	_check(not app.status.visible and app.finale_replay_button.visible, "Wide resize does not overlap the replay control with status text")
	app.size = prior_size
	app._fit()
	var finale_bridge := QABridge.new()
	app.add_child(finale_bridge)
	await finale_bridge.start(app, false)
	var observation: Dictionary = finale_bridge.observation()
	var action_id := ""
	for action in observation.actions:
		if action.label == "Press Replay finale": action_id = action.id
	_check(not action_id.is_empty(), "QA sees the same replay button as the player")
	var saves_before: int = app.saves
	var started := Time.get_ticks_msec()
	var result: Dictionary = await finale_bridge.request({"type": "larry-qa-action", "requestId": "finale-natural", "revision": observation.revision, "action": action_id})
	_check(not result.has("error") and not finale_bridge.busy and not app.is_cinematic(), "QA waits through the longer finale to its actual ending")
	_check(Time.get_ticks_msec() - started >= 11500, "Natural finale was watched through its full duration")
	_check(app.saves == saves_before and app.game.completed and app.game.score == 48, "QA replay also preserves the completed save")
	finale_bridge.queue_free()
	app._close_modal()
	await process_frame

func _startup_cancel_checks() -> void:
	var previous_app: Control = app
	app = ResumeMain.new()
	app.game = ScratchState.new()
	root.add_child(app)
	await process_frame
	app.game.configure_profile("lisa", "homosexual")
	app.game.room = "casino"
	app.game.cash = 53
	app.game.turns = 12
	app.game.inventory.assign(["pass"])
	app.game.flags["taken_pass"] = true
	app.game.save_game()
	var path: String = app.game.scratch_path
	var saved_bytes := FileAccess.get_file_as_bytes(path)
	for cancel in ["Keep this evening", "×", "Escape"]:
		# Same startup state as _ready(): model still fresh, old evening on disk.
		app.game.new_game()
		app._render()
		app._resume_prompt()
		_press("Start a new evening")
		_press("Play as Lisa")
		_press("Heterosexual")
		if cancel == "Escape": _key(KEY_ESCAPE)
		else: _press(cancel)
		_check(not app.setup_open and is_instance_valid(app.modal) and _button(app.modal, "Continue evening") != null, "Startup %s returns to the resume prompt" % cancel)
		_check(FileAccess.get_file_as_bytes(path) == saved_bytes and app.saves == 0, "Startup %s leaves autosave bytes unchanged" % cancel)
		_check(_button(app.modal, "×") == null, "Startup resume cannot expose an unloaded evening through Close")
		_key(KEY_ESCAPE)
		app._close_modal()
		app._command("go bar")
		_check(app.resume_pending and is_instance_valid(app.modal) and _button(app.modal, "Continue evening") != null and app.game.room == "street", "Resume remains required after Escape, direct close, or underlying parser submission")
		_check(FileAccess.get_file_as_bytes(path) == saved_bytes and app.saves == 0, "Blocked startup dismissals preserve saved bytes")
		_press("Continue evening")
		_check(app.game.profile == {"character": "lisa", "orientation": "homosexual"} and app.game.room == "casino" and app.game.cash == 53 and app.game.turns == 12 and app.game.inventory.has("pass"), "Continue after %s restores the stored identity and progress" % cancel)
		_check(FileAccess.get_file_as_bytes(path) == saved_bytes and not is_instance_valid(app.modal) and not app.resume_pending, "Restore after %s does not rewrite the saved evening" % cancel)
	# Committing a new draft intentionally replaces the autosave and must not
	# accidentally return to the prior evening's resume prompt.
	app.game.new_game()
	app._render()
	app._resume_prompt()
	_press("Start a new evening")
	_press("Play as Lisa")
	_press("Heterosexual")
	_press("Start evening as Lisa")
	_check(not is_instance_valid(app.modal) and not app.setup_return_to_resume and app.game.profile == {"character": "lisa", "orientation": "heterosexual"}, "Starting from resume commits the chosen profile without reopening Continue")
	_check(app.saves == 1 and FileAccess.get_file_as_bytes(path) != saved_bytes, "Explicit Start replaces only the isolated autosave once")
	DirAccess.remove_absolute(path)
	app.queue_free()
	await process_frame
	app = previous_app
