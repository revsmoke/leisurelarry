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
var _last_callback_ms := 0
var _last_settled_ms := 0

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
		  let last = 0, count = 0, within20 = 0, hidden = 0, peak = 0, raf = 0;
		  const bins = new Array(1001).fill(0), start = performance.now();
		  function sample(now) {
		    if (last && now - start > 2000) {
		      const dt = now - last;
		      if (document.visibilityState === 'visible') { count++; if (dt <= 20) within20++; peak = Math.max(peak, dt); bins[Math.min(1000, Math.ceil(dt))]++; }
		      else hidden++;
		    }
		    last = now; raf = requestAnimationFrame(sample);
		  }
		  raf = requestAnimationFrame(sample);
		  window.__larryQaPerformance = () => {
		    function quantile(fraction) { let cumulative = 0; const target = Math.ceil(count * fraction); if (!count) return null; for (let i = 0; i < bins.length; i++) { cumulative += bins[i]; if (cumulative >= target) return i; } return null; }
		    return JSON.stringify({visibleFrameSamples: count, hiddenFrameSamples: hidden, framesWithin20ms: within20, fractionWithin20ms: count ? within20 / count : null, rafP50UpperMs: quantile(0.5), rafP95UpperMs: quantile(0.95), maxRafMs: peak, warmupExcludedMs: 2000, histogramBinMs: 1, histogramOverflowMs: 1000, jsHeapUsedBytes: performance.memory ? performance.memory.usedJSHeapSize : null, jsHeapLimitBytes: performance.memory ? performance.memory.jsHeapSizeLimit : null, heapScope: 'Browser-reported JS heap; may be shared and excludes total Godot/WASM memory', visibility: document.visibilityState});
		  };
		  window.__larryQaRemove = () => { window.removeEventListener('message', listener); cancelAnimationFrame(raf); delete window.__larryQaPerformance; };
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
	elif not _button_is_current(_actions[message.action]):
		revision += 1
		_refresh_observation()
		error = "stale_control"
	if not error.is_empty():
		response.error = error
		response.observation = _observation.duplicate(true)
		return response
	busy = true
	var chosen: Dictionary = _actions[message.action]
	var action_started := Time.get_ticks_msec()
	_execute(chosen)
	_last_callback_ms = Time.get_ticks_msec() - action_started
	await _settle_frames()
	# Wait for actual travel/encounter movies, including the 12-second finale.
	# The 16-second bound stays inside the browser driver's 20-second deadline.
	var travel_started := Time.get_ticks_msec()
	while app.is_cinematic() and Time.get_ticks_msec() - travel_started < 16000:
		await get_tree().process_frame
	if app.is_cinematic():
		busy = false
		response.error = "travel_timeout"
		return response
	# A slot spin has a visible one-second animation; observe its settled result.
	var started := Time.get_ticks_msec()
	while is_instance_valid(app.casino_panel) and app.casino_panel.slot_pending and Time.get_ticks_msec() - started < 4000:
		await get_tree().process_frame
	var party_started := Time.get_ticks_msec()
	while is_instance_valid(app.party_panel) and (app.party_panel.pending or app.party_panel.interlude_left > 0) and Time.get_ticks_msec() - party_started < 5000:
		await get_tree().process_frame
	await _settle_frames()
	_last_settled_ms = Time.get_ticks_msec() - action_started
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
	for item in app.game.get_inventory():
		if _item_button(str(item.id)) != null: inventory.append(str(item.name))
	var destinations: Array = []
	for id in MAP_IDS:
		destinations.append({"name": str(app.game.get_room(id).name), "locked": not app.game.is_unlocked(id), "current": id == app.game.room})
	var overlay_text: Array[String] = []
	var dialogue_options: Array[String] = []
	if is_instance_valid(app.modal):
		_collect_text(app.modal, overlay_text)
		var buttons: Array[Button] = []
		_collect_buttons(app.modal, buttons)
		for button in buttons:
			if button.has_meta("dialogue_choice"): dialogue_options.append(button.text)
			# Never expose save restoration or new-game controls to the bounded player.
			if button.text in ["Restore autosave", "One more evening", "Start a new evening"]: continue
			_add("Press " + ("× · close dialog and return to the room" if button.text == "×" else button.text), {"kind": "button", "button": button}, choices)
	else:
		_add("Look around the current room", {"kind": "parser", "command": "look around"}, choices)
		for h in room.hotspots:
			for action in ["look", "talk", "take", "use"]:
				_add(action.capitalize() + " " + str(h.label), {"kind": "hotspot", "verb": action, "target": str(h.id)}, choices)
		for item in app.game.get_inventory():
			if _item_button(str(item.id)) == null: continue
			_add("Inspect " + str(item.name) + " in inventory", {"kind": "inspect", "item": str(item.id)}, choices)
			_add("Use " + str(item.name) + " on its own", {"kind": "self", "item": str(item.id)}, choices)
			for h in room.hotspots:
				_add("Use " + str(item.name) + " with " + str(h.label), {"kind": "item", "item": str(item.id), "target": str(h.id)}, choices)
		var controls: Array[Button] = []
		_collect_buttons(app.canvas, controls)
		for button in controls:
			if button.text == "Tidy":
				_add("Press Tidy: " + ("show all carried items" if app.tidy_pockets else "tuck used souvenirs away"), {"kind": "button", "button": button}, choices)
			elif button.text == "Replay finale":
				_add("Press Replay finale", {"kind": "button", "button": button}, choices)
		for id in MAP_IDS:
			if id != app.game.room and app.game.is_unlocked(id):
				_add("Travel via city map to " + str(app.game.get_room(id).name), {"kind": "map", "destination": id}, choices)
	_add("Stop playtest: no suitable action; request human review", {"kind": "decline"}, choices, "decline")
	_observation = {
		"revision": revision,
		"room": {"id": str(app.game.room), "title": app.room_title.text, "subtitle": app.room_subtitle.text},
		"objective": app.objective_text.text,
		"dialogue": {"speaker": app.speaker.text, "text": app.dialogue.get_parsed_text()},
		"inventory": inventory, "pocketView": "active items; souvenirs tucked away" if app.tidy_pockets else "all carried items",
		"notebook": app.game.journal.duplicate(),
		"hotspots": spots,
		"map": destinations,
		"overlay": overlay_text, "dialogueOptions": dialogue_options,
		"score": int(app.game.score), "money": int(app.game.cash), "completed": bool(app.game.completed),
		"actions": choices,
		"diagnostics": {"fps": Engine.get_frames_per_second(), "process_seconds": Performance.get_monitor(Performance.TIME_PROCESS), "candidate_count": choices.size(), "action_callback_ms": _last_callback_ms, "action_settled_ms": _last_settled_ms, "engine_static_memory_bytes": int(Performance.get_monitor(Performance.MEMORY_STATIC)) if Performance.get_monitor(Performance.MEMORY_STATIC) > 0 else null}
	}
	if _window != null:
		_observation.diagnostics["browser"] = JSON.parse_string(str(_window.__larryQaPerformance()))
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
	return JSON.stringify([app.game.room, app.objective_text.text, app.speaker.text, app.dialogue.text, app.game.get_inventory(), app.game.journal, app.game.score, app.game.cash, app.game.completed, app.game.get_room().hotspots, app.tidy_pockets, overlay])

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
	# Inventory includes headings/arrival cues; identity must not depend on child index.
	for child in app.inventory_box.get_children():
		if child is Button and str(child.get_meta("inventory_id", "")) == id:
			return child
	# Compatibility with the pre-upgrade UI during migration tests.
	for child in app.inventory_box.get_children():
		if child.has_meta("inventory_id"): return null
	var index: int = app.game.inventory.find(id)
	if index >= 0 and index < app.inventory_box.get_child_count():
		var candidate = app.inventory_box.get_child(index)
		if candidate is Button and not candidate.has_meta("inventory_id"): return candidate
	return null

func _target_button(id: String) -> Button:
	var visible: Array = app.game.get_room().hotspots
	for index in range(visible.size()):
		if str(visible[index].id) == id:
			return app.hotspots.get_child(index) as Button
	return null

func _button_is_current(action: Dictionary) -> bool:
	if action.kind != "button": return true
	return is_instance_valid(action.button) and not action.button.disabled and action.button.is_visible_in_tree()

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
