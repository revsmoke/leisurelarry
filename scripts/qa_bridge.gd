extends Node
## QA-only text observation/action adapter. Jev never receives flags or executable code.
## Disabled unless the dedicated Web export is served on the isolated loopback origin.

signal observation_sent(envelope: Dictionary)

const ORIGIN := "http://127.0.0.1:8767"
const MAX_ACTIONS := 255
const MAP_IDS := ["street", "bar", "bathroom", "backroom", "alley", "shop", "casino", "disco", "hotel", "balcony", "garden", "penthouse", "rooftop"]
var app: Control
var revision := 0
var busy := false
var _actions: Dictionary = {}
var _observation: Dictionary = {}
var _visible_signature := ""
var _browser_callback: JavaScriptObject
var _window: JavaScriptObject

static func allowed_context(feature: bool, web: bool, origin: String) -> bool:
	return feature and web and origin == ORIGIN

static func runtime_allowed() -> bool:
	if not OS.has_feature("qa_playtest") or not OS.has_feature("web"):
		return false
	return allowed_context(true, true, str(JavaScriptBridge.eval("window.location.origin")))

func start(owner_app: Control, browser: bool = true) -> void:
	app = owner_app
	if browser:
		if not runtime_allowed():
			return
		_window = JavaScriptBridge.get_interface("window")
		_browser_callback = JavaScriptBridge.create_callback(_on_message)
		# Fixed installation code, never model- or message-supplied JavaScript.
		JavaScriptBridge.eval("""
		window.__larryQaInstall = function(callback) {
		  const listener = function(event) {
		    if (event.origin !== 'http://127.0.0.1:8767' || event.source !== window.parent || window.parent === window) return;
		    if (!event.data || event.data.type !== 'larry-qa-action') return;
		    callback(JSON.stringify(event.data));
		  };
		  window.addEventListener('message', listener);
		  window.__larryQaRemove = () => window.removeEventListener('message', listener);
		};
		""", true)
		_window.__larryQaInstall(_browser_callback)
	await _settle_frames()
	_refresh_observation()
	_send({"type": "larry-qa-ready", "observation": _observation.duplicate(true)})

func _exit_tree() -> void:
	if _window != null:
		_window.__larryQaRemove()
	_browser_callback = null
	_window = null

func _on_message(arguments: Array) -> void:
	if arguments.size() != 1 or not arguments[0] is String or arguments[0].length() > 4096:
		return
	var parsed: Variant = JSON.parse_string(arguments[0])
	if parsed is Dictionary:
		_receive.call_deferred(parsed)

func _receive(message: Dictionary) -> void:
	_send(await request(message))

func _send(envelope: Dictionary) -> void:
	observation_sent.emit(envelope)
	if _window != null:
		var json := JavaScriptBridge.get_interface("JSON")
		_window.parent.postMessage(json.parse(JSON.stringify(envelope)), ORIGIN)

func request(message: Dictionary) -> Dictionary:
	var response := {"type": "larry-qa-observation", "requestId": str(message.get("requestId", "")).left(128)}
	var error := ""
	if message.get("type") != "larry-qa-action": error = "unsupported_message"
	elif busy: error = "busy"
	elif not message.get("revision") is float and not message.get("revision") is int: error = "invalid_revision"
	elif float(message.revision) != float(revision): error = "stale_revision"
	elif not message.get("action") is String or not _actions.has(message.action): error = "unsupported_action"
	elif _signature() != _visible_signature:
		# A human may click while inference is in flight. Rebuild, never apply stale intent.
		revision += 1
		_refresh_observation()
		error = "state_changed"
	if not error.is_empty():
		response.error = error
		response.observation = _observation.duplicate(true)
		return response
	busy = true
	var chosen: Dictionary = _actions[message.action]
	_execute(chosen)
	await _settle_frames()
	# A slot spin has a visible one-second animation; observe its settled result.
	var started := Time.get_ticks_msec()
	while is_instance_valid(app.casino_panel) and app.casino_panel.slot_pending and Time.get_ticks_msec() - started < 4000:
		await get_tree().process_frame
	await _settle_frames()
	revision += 1
	_refresh_observation()
	response.observation = _observation.duplicate(true)
	if chosen.kind == "decline": response.stopped = true
	busy = false
	return response

func _settle_frames() -> void:
	await get_tree().process_frame
	await get_tree().process_frame
	if DisplayServer.get_name() != "headless":
		await RenderingServer.frame_post_draw

func observation() -> Dictionary:
	return _observation.duplicate(true)

func _add(label: String, operation: Dictionary, choices: Array, id: String = "") -> void:
	var key := id if not id.is_empty() else "a%03d" % choices.size()
	_actions[key] = operation
	choices.append({"id": key, "label": label})

func _refresh_observation() -> void:
	_actions.clear()
	var choices: Array = []
	var room: Dictionary = app.game.get_room()
	var spots: Array = []
	for h in room.hotspots:
		spots.append({"name": str(h.label), "kind": str(h.kind)})
	var inventory: Array = []
	for item in app.game.get_inventory(): inventory.append(str(item.name))
	var destinations: Array = []
	for id in MAP_IDS:
		destinations.append({"name": str(app.game.get_room(id).name), "locked": not app.game.is_unlocked(id), "current": id == app.game.room})
	var overlay_text: Array[String] = []
	if is_instance_valid(app.modal):
		_collect_text(app.modal, overlay_text)
		var buttons: Array[Button] = []
		_collect_buttons(app.modal, buttons)
		for button in buttons:
			# Never expose save restoration or new-game controls to the bounded player.
			if button.text in ["Restore autosave", "One more evening", "Start a new evening"]: continue
			_add("Press " + button.text, {"kind": "button", "button": button}, choices)
	else:
		_add("Look around the current room", {"kind": "parser", "command": "look around"}, choices)
		for h in room.hotspots:
			for action in ["look", "talk", "take", "use"]:
				_add(action.capitalize() + " " + str(h.label), {"kind": "hotspot", "verb": action, "target": str(h.id)}, choices)
		for item in app.game.get_inventory():
			_add("Inspect " + str(item.name) + " in inventory", {"kind": "inspect", "item": str(item.id)}, choices)
			_add("Use " + str(item.name) + " on its own", {"kind": "self", "item": str(item.id)}, choices)
			for h in room.hotspots:
				_add("Use " + str(item.name) + " with " + str(h.label), {"kind": "item", "item": str(item.id), "target": str(h.id)}, choices)
		for id in MAP_IDS:
			if id != app.game.room and app.game.is_unlocked(id):
				_add("Travel via city map to " + str(app.game.get_room(id).name), {"kind": "map", "destination": id}, choices)
	_add("Stop: no suitable action", {"kind": "decline"}, choices, "decline")
	_observation = {
		"revision": revision,
		"room": {"id": str(app.game.room), "title": app.room_title.text, "subtitle": app.room_subtitle.text},
		"objective": app.objective_text.text,
		"dialogue": {"speaker": app.speaker.text, "text": app.dialogue.get_parsed_text()},
		"inventory": inventory,
		"notebook": app.game.journal.duplicate(),
		"hotspots": spots,
		"map": destinations,
		"overlay": overlay_text,
		"score": int(app.game.score), "money": int(app.game.cash), "completed": bool(app.game.completed),
		"actions": choices,
		"diagnostics": {"fps": Engine.get_frames_per_second(), "process_seconds": Performance.get_monitor(Performance.TIME_PROCESS), "candidate_count": choices.size()}
	}
	_visible_signature = _signature()
	if choices.size() > MAX_ACTIONS:
		# Fail closed instead of silently dropping a potentially necessary action.
		_actions.clear()
		_observation.actions = []
		_observation["error"] = "candidate_limit_exceeded"

func _signature() -> String:
	var overlay: Array[String] = []
	var modal_buttons: Array[Button] = []
	if is_instance_valid(app.modal):
		_collect_text(app.modal, overlay)
		_collect_buttons(app.modal, modal_buttons)
	for button in modal_buttons: overlay.append(button.text)
	return JSON.stringify([app.game.room, app.objective_text.text, app.speaker.text, app.dialogue.text, app.game.get_inventory(), app.game.journal, app.game.score, app.game.cash, app.game.completed, app.game.get_room().hotspots, overlay])

func _collect_text(node: Node, output: Array[String]) -> void:
	for child in node.get_children():
		if child is Control and not child.is_visible_in_tree(): continue
		if child is Label: output.append(child.text)
		elif child is RichTextLabel: output.append(child.get_parsed_text())
		_collect_text(child, output)

func _collect_buttons(node: Node, output: Array[Button]) -> void:
	for child in node.get_children():
		if child is Control and not child.is_visible_in_tree(): continue
		if child is Button and not child.disabled: output.append(child)
		_collect_buttons(child, output)

func _item_button(id: String) -> Button:
	var index: int = app.game.inventory.find(id)
	if index >= 0 and index < app.inventory_box.get_child_count():
		return app.inventory_box.get_child(index) as Button
	return null

func _target_button(id: String) -> Button:
	var visible: Array = app.game.get_room().hotspots
	for index in range(visible.size()):
		if str(visible[index].id) == id:
			return app.hotspots.get_child(index) as Button
	return null

func _execute(action: Dictionary) -> void:
	match action.kind:
		"hotspot":
			app.verbs.look.pressed.emit()
			app.verbs[action.verb].pressed.emit()
			var button := _target_button(action.target)
			if button != null: button.pressed.emit()
		"inspect", "self":
			var button := _item_button(action.item)
			if button != null:
				var event := InputEventMouseButton.new()
				event.pressed = true
				event.button_index = MOUSE_BUTTON_RIGHT if action.kind == "inspect" else MOUSE_BUTTON_LEFT
				event.double_click = action.kind == "self"
				button.gui_input.emit(event)
		"item":
			app.verbs.look.pressed.emit()
			var item := _item_button(action.item)
			if item != null: item.pressed.emit()
			var target := _target_button(action.target)
			if target != null: target.pressed.emit()
		"map":
			app._map()
			var buttons: Array[Button] = []
			_collect_buttons(app.modal, buttons)
			var destination: String = app.game.get_room(action.destination).name
			for button in buttons:
				if button.text.ends_with(destination):
					button.pressed.emit()
					break
		"parser":
			app.parser.text = action.command
			app.parser.text_submitted.emit(action.command)
		"button":
			if is_instance_valid(action.button) and not action.button.disabled: action.button.pressed.emit()
		"decline": pass
