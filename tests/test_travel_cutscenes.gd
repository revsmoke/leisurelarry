extends SceneTree
## Travel presentation exercised through real visible controls and parser signals.
## Test-only animation forcing keeps legacy headless route checks instantaneous.
## Isolated save paths and overrides preserve all of the player's local data.
const GameState = preload("res://scripts/game_state.gd")
const TravelCutscene = preload("res://scripts/travel_cutscene.gd")
const QABridge = preload("res://scripts/qa_bridge.gd")

class IsolatedState:
	extends "res://scripts/game_state.gd"
	var scratch_path := "user://cutscene-test-%s.json" % OS.get_process_id()
	func save_game(_path: String = "user://savegame.json") -> String:
		return super.save_game(scratch_path)
	func load_game(_path: String = "user://savegame.json") -> String:
		return super.load_game(scratch_path)

class TestMain:
	extends "res://scripts/main.gd"
	var saved_snapshots: Array[Dictionary] = []
	var render_calls := 0
	var say_calls := 0
	func _autosave() -> void:
		saved_snapshots.append({"room": game.room, "inventory": game.inventory.duplicate(), "flags": game.flags.duplicate(true), "cash": game.cash, "score": game.score, "turns": game.turns, "completed": game.completed, "journal": game.journal.duplicate()})
	func _render() -> void:
		render_calls += 1
		super._render()
	func _say(who: String, text: String) -> void:
		say_calls += 1
		super._say(who, text)
	func _start_music() -> void: pass
	func _automation() -> void: pass
	func _load_preferences() -> void: pass
	func _save_preferences() -> void: pass
	func clear_counts() -> void:
		saved_snapshots.clear()
		render_calls = 0
		say_calls = 0

var app: Control
var assertions := 0
var failures: Array[String] = []
var component_finishes := 0
var bridge_result: Dictionary = {}

func _init() -> void:
	_run.call_deferred()

func _check(ok: bool, message: String) -> void:
	assertions += 1
	if not ok:
		failures.append(message)
		printerr("FAIL: " + message)

func _state(game: RefCounted) -> Dictionary:
	return {"room": game.room, "inventory": game.inventory.duplicate(), "flags": game.flags.duplicate(true), "cash": game.cash, "score": game.score, "turns": game.turns, "completed": game.completed, "journal": game.journal.duplicate()}

func _clone(game: RefCounted) -> RefCounted:
	var result := GameState.new()
	for key in _state(game): result.set(key, _state(game)[key])
	return result

func _button(parent: Node, text: String) -> Button:
	if not is_instance_valid(parent): return null
	for child in parent.get_children():
		if child is Button and child.text == text: return child
		var nested := _button(child, text)
		if nested != null: return nested
	return null

func _meta(parent: Node, key: String, value: String) -> Button:
	for child in parent.get_children():
		if child is Button and str(child.get_meta(key, "")) == value: return child
		var nested := _meta(child, key, value)
		if nested != null: return nested
	return null

func _press(parent: Node, text: String) -> void:
	var button := _button(parent, text)
	_check(button != null and not button.disabled, "Available visible control: " + text)
	if button != null and not button.disabled: button.pressed.emit()

func _exit(destination: String) -> Button:
	for exit in app.game.get_room().exits:
		if exit.id == destination: return _button(app.exit_box, str(exit.label) + "  →")
	return null

func _go(destination: String) -> void:
	var button := _exit(destination)
	_check(button != null, "Actual exit exists for " + destination)
	if button != null: button.pressed.emit()

func _key(code: Key) -> void:
	var event := InputEventKey.new()
	event.pressed = true
	event.keycode = code
	app._unhandled_key_input(event)

func _submit(text: String) -> void:
	app.parser.text = text
	app.parser.text_submitted.emit(text)

func _settle() -> void:
	await process_frame
	await process_frame
	await process_frame

func _skip() -> void:
	_check(app.is_travelling() and is_instance_valid(app.travel_cutscene), "Transition is active before its visible skip control")
	if app.is_travelling(): app.travel_cutscene.skip_button.pressed.emit()
	await _settle()
	_check(not app.is_travelling() and not is_instance_valid(app.modal), "Skip settles arrival and removes travel overlay")

func _await_arrival(limit: float = 6.0) -> void:
	var start := Time.get_ticks_msec()
	while app.is_travelling() and Time.get_ticks_msec() - start < limit * 1000.0:
		await process_frame
	await _settle()
	_check(not app.is_travelling(), "Travel naturally settles within its bounded duration")

func _complete_bridge_request(bridge: Node, message: Dictionary) -> void:
	bridge_result = await bridge.request(message)

func _bridge_checks() -> void:
	var bridge := QABridge.new()
	root.add_child(bridge)
	await bridge.start(app, false)
	var observation: Dictionary = bridge.observation()
	var id := ""
	for candidate in observation.actions:
		if candidate.label == "Travel via city map to The Lucky Chip": id = candidate.id
	_check(not id.is_empty(), "QA publishes actual map travel as a closed-set action")
	bridge_result.clear()
	_complete_bridge_request.call_deferred(bridge, {"type": "larry-qa-action", "requestId": "travel-callback-test", "revision": observation.revision, "action": id})
	await _settle()
	_check(bridge.busy and app.is_travelling() and bridge_result.is_empty(), "QA action remains pending while the actual cinematic is active")
	_check(app.game.room == "casino" and app.current_render_room != "casino", "QA does not fake a rendered arrival ahead of the visual callback")
	var repeated: Dictionary = await bridge.request({"type": "larry-qa-action", "requestId": "duplicate", "revision": observation.revision, "action": id})
	_check(repeated.get("error", "") == "busy", "An in-flight cinematic rejects concurrent model actions")
	app.travel_cutscene.skip_button.pressed.emit()
	await _settle()
	_check(not bridge.busy and not bridge_result.is_empty() and not bridge_result.has("error"), "Actual skip callback releases the QA request only after arrival")
	if not bridge_result.is_empty() and bridge_result.has("observation"):
		var arrived: Dictionary = bridge_result.observation
		_check(arrived.room.id == "casino" and arrived.room.title == "The Lucky Chip", "QA returns matching destination model and rendered room title")
		_check(arrived.overlay.is_empty() and arrived.dialogue.speaker != "ON THE MOVE", "QA observation excludes an unfinished movie and its transient caption")
		_check(arrived.revision == observation.revision + 1, "Completed cinematic advances one model action revision")
	bridge.queue_free()
	await _settle()

func _taxi_checks() -> void:
	for parser_input in [false, true]:
		app._new_game()
		if parser_input:
			_submit("use taxi")
		else:
			app.verbs.use.pressed.emit()
			var stand := _meta(app.hotspots, "hotspot_id", "taxi")
			_check(stand != null, "Street exposes its usable taxi stand")
			if stand != null: stand.pressed.emit()
		_check(is_instance_valid(app.modal) and not app.is_travelling(), "Taxi %s opens the actual destination map" % ("parser command" if parser_input else "hotspot"))
		_check(app.game.cash == 80 and app.game.room == "street", "Opening taxi destinations costs nothing and does not move Larry")
		var locked := _button(app.modal, "+  Eve's Rooftop")
		_check(locked != null and locked.disabled, "Courtesy taxi keeps the rooftop puzzle gate disabled")
		var expected := _clone(app.game)
		expected.travel("casino")
		app.clear_counts()
		_press(app.modal, ">  The Lucky Chip")
		_check(app.is_travelling() and app.travel_cutscene.mode == "taxi", "Choosing a taxi destination starts the ride vignette")
		_check(_state(app.game) == _state(expected), "Courtesy ride retains ordinary route moves and no fare")
		await _skip()
		_check(app.saved_snapshots.size() == 1 and app.render_calls == 1, "Taxi destination uses one accepted save and one arrival render")
	app._new_game()

func _component_checks() -> void:
	for sample in [
		["street", "bar", "door"], ["bar", "bathroom", "door"], ["bar", "backroom", "door"],
		["street", "casino", "taxi"], ["street", "disco", "taxi"], ["street", "hotel", "taxi"],
		["hotel", "penthouse", "elevator"], ["backroom", "balcony", "rope"],
		["penthouse", "rooftop", "terrace"], ["hotel", "garden", "terrace"],
		["street", "shop", "walk"], ["street", "alley", "walk"],
		["bar", "hotel", "taxi"], ["bathroom", "casino", "taxi"],
		["garden", "rooftop", "elevator"], ["casino", "hotel", "walk"]
	]:
		_check(TravelCutscene.mode_for(sample[0], sample[1]) == sample[2], "Context-specific travel mode: %s → %s" % [sample[0], sample[1]])
		_check(TravelCutscene.mode_for(sample[1], sample[0]) == sample[2], "Return trip keeps appropriate travel mode: %s → %s" % [sample[1], sample[0]])
	var model := GameState.new()
	for id in model.rooms:
		for route in model.get_room(id).exits:
			for variant in [0, 1, 2]:
				_check(not TravelCutscene.caption_for(id, route.id, variant).strip_edges().is_empty(), "Authored caption exists for %s → %s, variant %d" % [id, route.id, variant])
	var texture := GradientTexture2D.new()
	texture.gradient = Gradient.new()
	for sample in [["street", "bar", false], ["street", "shop", false], ["street", "casino", false], ["hotel", "penthouse", false], ["backroom", "balcony", false], ["penthouse", "rooftop", false], ["hotel", "garden", true]]:
		var reduced: bool = sample[2]
		var scene = TravelCutscene.new()
		scene.size = Vector2(800, 480)
		root.add_child(scene)
		scene.finished.connect(func(): component_finishes += 1)
		var before := component_finishes
		scene.play(sample[0], sample[1], model.get_room(sample[0]), model.get_room(sample[1]), texture, texture, reduced, 0)
		_check(scene.active and scene.mode == TravelCutscene.mode_for(sample[0], sample[1]), "Component activates with its selected transport mode")
		_check(scene.duration > 0.0 and scene.duration <= (1.5 if reduced else 5.0), "Component has a bounded duration for reduced motion=%s" % reduced)
		_check(not scene.caption_label.text.is_empty() and is_instance_valid(scene.skip_button), "Component exposes readable caption and real skip button")
		if reduced:
			var position: Vector2 = scene.actor.position
			scene._process(minf(0.25, scene.duration / 2.0))
			_check(scene.actor.position == position and not scene.actor.walking, "Reduced-motion card leaves Larry still")
		else:
			for progress in [0.1, 0.35, 0.6, 0.9]:
				scene._process(maxf(0, scene.duration * progress - scene.elapsed))
				_check(scene.active and scene.actor.position.is_finite(), "Animated %s phase %.2f retains a finite actor position" % [scene.mode, progress])
		scene._process(scene.duration + 1.0)
		_check(not scene.active and component_finishes == before + 1, "Time completion emits exactly one finished signal")
		scene.finish()
		scene.skip_button.pressed.emit()
		scene._process(10.0)
		_check(component_finishes == before + 1, "Repeated skip and late processing cannot duplicate completion")
		var child_count: int = scene.get_child_count()
		scene.play(sample[0], sample[1], model.get_room(sample[0]), model.get_room(sample[1]), texture, texture, reduced, 1)
		_check(scene.active and scene.elapsed == 0 and scene.get_child_count() == child_count, "Replaying a vignette replaces its old presentation children")
		scene.skip_button.pressed.emit()
		_check(component_finishes == before + 2 and not scene.active, "Replayed vignette has one independent completion")
		var ref: WeakRef = weakref(scene)
		scene.queue_free()
		await _settle()
		_check(ref.get_ref() == null, "Finished component and owned resources leave the scene tree")

func _run() -> void:
	var originals: Dictionary = {}
	for path in ["user://savegame.json", "user://autosave.json", "user://preferences.cfg"]:
		originals[path] = FileAccess.get_file_as_bytes(path) if FileAccess.file_exists(path) else null
	await _component_checks()
	app = TestMain.new()
	app.game = IsolatedState.new()
	app.size = Vector2(1440, 960)
	app.animate_travel_in_tests = true
	root.add_child(app)
	await _settle()
	_check(not app.is_travelling(), "A fresh evening does not create a travel cutscene")
	var source_hotspot := _meta(app.hotspots, "hotspot_id", "newsbox")
	app.verbs.take.pressed.emit()
	source_hotspot.pressed.emit()
	var source_item := _meta(app.inventory_box, "inventory_id", "newspaper")
	var source_exit := _exit("casino")
	var expected := _clone(app.game)
	expected.travel("bar")
	app.clear_counts()
	_go("bar")
	_check(app.is_travelling() and app.game.room == "bar", "Accepted exit commits the destination while showing travel")
	_check(app.current_render_room == "street", "Arrival is not rendered underneath an unfinished cutscene")
	_check(app.travel_cutscene.mode == "door", "Entering Lefty's from the strip shows a doorway scene")
	_check(app.saved_snapshots.size() == 1 and app.saved_snapshots[0] == _state(expected), "Closing the browser mid-travel would retain exactly one complete accepted destination snapshot")
	_check(_state(app.game) == _state(expected), "Presentation adds no fare, rewards, inventory changes, or extra move")
	var moving_state := _state(app.game)
	var moving_scene: Control = app.travel_cutscene
	var narration: String = app.last_message
	# Retained controls represent events queued immediately before the modal opens.
	source_hotspot.pressed.emit()
	source_item.pressed.emit()
	source_exit.pressed.emit()
	app.verbs.talk.pressed.emit()
	var right_click := InputEventMouseButton.new()
	right_click.button_index = MOUSE_BUTTON_RIGHT
	right_click.pressed = true
	source_hotspot.gui_input.emit(right_click)
	source_item.gui_input.emit(right_click)
	_submit("go street")
	for label in ["City map", "Options", "New evening"]:
		var control := _button(app.canvas, label)
		_check(control != null, "Stale toolbar callback exists: " + label)
		if control != null: control.pressed.emit()
	for key in [KEY_1, KEY_M, KEY_J, KEY_O, KEY_T, KEY_F5, KEY_F9]: _key(key)
	_check(_state(app.game) == moving_state, "Source-room, inventory, parser, toolbar, and keyboard inputs cannot act during travel")
	_check(app.travel_cutscene == moving_scene and app.is_travelling(), "Queued controls cannot replace the active travel modal")
	_check(app.last_message == narration and app.render_calls == 0 and app.say_calls == 1, "Blocked inputs cannot narrate or render a false arrival")
	_check(app.saved_snapshots.size() == 1, "Blocked inputs do not trigger another autosave")
	var scene_ref: WeakRef = weakref(moving_scene)
	_key(KEY_SPACE)
	_check(not app.is_travelling() and app.game.room == "bar", "Space skips to the already validated destination")
	_check(app.current_render_room == "bar" and app.room_title.text == "Lefty's Bar", "Skip renders the destination's real scene and title")
	_check(app.render_calls == 1 and app.say_calls == 2 and app.saved_snapshots.size() == 1, "Skip renders arrival once, adds its narration after the travel caption, and never saves again")
	app._skip_travel()
	app._finish_travel()
	_check(app.render_calls == 1 and app.say_calls == 2 and app.saved_snapshots.size() == 1, "Duplicate completion callbacks are harmless")
	await _settle()
	_check(scene_ref.get_ref() == null, "Arrival frees the previous cutscene")
	# Locked, invalid, and same-room actions retain model rules and never animate.
	app.clear_counts()
	_go("backroom")
	_check(not app.is_travelling() and app.game.room == "bar" and app.last_message.contains("password"), "Locked exit reports its gate without playing entry animation")
	app._map()
	_press(app.modal, "Lefty's Bar")
	_check(not app.is_travelling() and app.game.room == "bar", "Selecting the current map location has no cutscene")
	_submit("go rooftop")
	_check(not app.is_travelling() and app.game.room == "bar", "Invalid nonadjacent parser travel does not animate")
	# Alias parser travel follows the same animation pipeline.
	app.clear_counts()
	_submit("enter bathroom")
	_check(app.is_travelling() and app.game.room == "bathroom" and app.parser.text.is_empty(), "Parser ENTER starts the same accepted doorway animation and consumes input")
	_key(KEY_ESCAPE)
	await _settle()
	_check(not app.is_travelling() and app.current_render_room == "bathroom", "Escape completes parser travel at the intended room")
	_check(app.saved_snapshots.size() == 1 and app.say_calls == 2 and app.render_calls == 1, "Parser and Escape retain single save/render/narration semantics")
	# A multi-hop map request produces one cinematic but retains every model hop.
	expected = _clone(app.game)
	for id in ["bar", "street", "hotel"]: expected.travel(id)
	app._map()
	app.clear_counts()
	_press(app.modal, ">  The Come-On Inn")
	_check(app.is_travelling() and app.game.room == "hotel", "Map starts one presentation for its multi-room route")
	_check(_state(app.game) == _state(expected), "Map retains all actual route observations and move counts")
	_check(app.saved_snapshots.size() == 1 and app.saved_snapshots[0] == _state(expected), "Map saves only its complete validated destination")
	await _skip()
	_check(app.render_calls == 1 and app.say_calls == 2, "Multi-hop map arrival renders and narrates once")
	# Reduced motion is a brief static card and still completes automatically.
	app.reduced_motion = true
	app.clear_counts()
	_go("garden")
	_check(app.is_travelling() and app.travel_cutscene.reduced_motion and app.travel_cutscene.duration <= 1.5, "Reduced motion keeps a brief transition card")
	await _await_arrival(2.5)
	_check(app.current_render_room == "garden" and app.render_calls == 1 and app.say_calls == 2 and app.saved_snapshots.size() == 1, "Reduced-motion natural completion reaches the real room exactly once")
	app.reduced_motion = false
	_go("hotel")
	await _skip()
	app.clear_counts()
	_go("casino")
	await _await_arrival()
	_check(app.current_render_room == "casino" and app.render_calls == 1 and app.say_calls == 2 and app.saved_snapshots.size() == 1, "Animated natural completion follows the same single-arrival contract")
	# Manual and parser LOAD restore a saved room immediately rather than inventing travel.
	app.game.save_game()
	_go("street")
	await _skip()
	app._load()
	_check(app.game.room == "casino" and not app.is_travelling() and app.current_render_room == "casino", "Manual Load restores a different room without a cinematic")
	_go("street")
	await _skip()
	_submit("load")
	_check(app.game.room == "casino" and not app.is_travelling() and app.current_render_room == "casino", "Parser Load is a restore, never mistaken for a room-change journey")
	app._new_game()
	_check(app.game.room == "street" and not app.is_travelling() and app.game.turns == 0, "New evening resets directly without a cutscene")
	# A hotspot may change rooms through model.interact, not only through an exit.
	# This deterministic fixture isolates an unlocked elevator; no model-run grant.
	_go("hotel")
	await _skip()
	app.game.flags["penthouse_access"] = true
	app._render()
	app.verbs.use.pressed.emit()
	expected = _clone(app.game)
	expected.interact("elevator", "use")
	app.clear_counts()
	var elevator := _meta(app.hotspots, "hotspot_id", "elevator")
	_check(elevator != null, "Hotel exposes its actual elevator hotspot")
	if elevator != null: elevator.pressed.emit()
	_check(app.is_travelling() and app.game.room == "penthouse", "USE elevator triggers a journey when interact changes rooms")
	if app.is_travelling():
		_check(app.travel_cutscene.mode == "elevator", "Hotel elevator hotspot selects the lift vignette")
	_check(_state(app.game) == _state(expected), "Elevator vignette preserves the existing model interaction and travel counts")
	await _skip()
	_check(app.render_calls == 1 and app.say_calls == 2 and app.saved_snapshots.size() == 1, "Elevator hotspot shares one save and one arrival rendering")
	app._new_game()
	await _taxi_checks()
	# Repeated visible transitions leave no orphaned scenes or duplicate completion.
	await _settle()
	var baseline_nodes := app.get_child_count()
	var baseline_canvas_nodes: int = app.canvas.get_child_count()
	for i in range(12):
		var destination := "bar" if app.game.room == "street" else "street"
		app.clear_counts()
		_go(destination)
		var travel_ref: WeakRef = weakref(app.travel_cutscene)
		app._close_modal()
		await _settle()
		_check(not app.is_travelling() and app.current_render_room == destination, "Close-dialog completes repeated travel %d" % i)
		_check(app.render_calls == 1 and app.say_calls == 2 and app.saved_snapshots.size() == 1, "Repeated trip %d has a single persistence and arrival event" % i)
		_check(travel_ref.get_ref() == null and app.get_child_count() == baseline_nodes and app.canvas.get_child_count() == baseline_canvas_nodes, "Repeated trip %d releases its cutscene without growing root or canvas nodes" % i)
	await _bridge_checks()
	# Legacy checks and automation use deterministic instant travel when not forced.
	app.animate_travel_in_tests = false
	_go("street")
	_check(not app.is_travelling() and app.current_render_room == "street", "Ordinary headless checks retain synchronous travel")
	var scratch: String = app.game.scratch_path
	app.queue_free()
	await _settle()
	if FileAccess.file_exists(scratch): DirAccess.remove_absolute(ProjectSettings.globalize_path(scratch))
	for path in originals:
		var current: Variant = FileAccess.get_file_as_bytes(path) if FileAccess.file_exists(path) else null
		_check(current == originals[path], "Cutscene tests preserve user file: " + path)
	print("Travel cutscene tests: %d assertions, %d failures." % [assertions, failures.size()])
	quit(0 if failures.is_empty() else 1)
