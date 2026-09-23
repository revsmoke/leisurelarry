extends SceneTree
## Native/headless lifecycle sampling, not browser/GPU memory or a human playtest.
class IsolatedMain:
	extends "res://scripts/main.gd"
	func _qa_enabled() -> bool: return true

var failures: Array[String] = []
var checks := 0
var app: Control
var samples: Array = []

func _init() -> void:
	_run.call_deferred()

func _check(ok: bool, message: String) -> void:
	checks += 1
	if not ok:
		failures.append(message)
		printerr("FAIL: " + message)

func _find(parent: Node, key: String, value: String) -> Button:
	for child in parent.get_children():
		if child is Button and str(child.get_meta(key, "")) == value: return child
		var nested := _find(child, key, value)
		if nested != null: return nested
	return null

func _text_button(parent: Node, label: String) -> Button:
	for child in parent.get_children():
		if child is Button and child.text == label: return child
		var nested := _text_button(child, label)
		if nested != null: return nested
	return null

func _close() -> void:
	if is_instance_valid(app.modal):
		var button := _text_button(app.modal, "×")
		_check(button != null, "Modal has a real close control")
		if button != null: button.pressed.emit()

func _hotspot(id: String, verb: String) -> void:
	_close()
	app.verbs.look.pressed.emit()
	app.verbs[verb].pressed.emit()
	var button := _find(app.hotspots, "hotspot_id", id)
	_check(button != null, "Available scene action: " + id)
	if button != null: button.pressed.emit()

func _choose(id: String) -> void:
	var button := _find(app.modal, "dialogue_choice", id) if is_instance_valid(app.modal) else null
	_check(button != null, "Available authored topic: " + id)
	if button != null: button.pressed.emit()

func _travel(id: String) -> void:
	_close()
	# This is the real map button callback and its actual destination control.
	app._map()
	var title: String = app.game.get_room(id).name
	var button := _text_button(app.modal, ">  " + title)
	_check(button != null and not button.disabled, "Available map destination: " + title)
	if button != null: button.pressed.emit()

func _cycle(index: int) -> Dictionary:
	app = IsolatedMain.new()
	app.size = Vector2(1440, 960)
	root.add_child(app)
	await process_frame
	await process_frame
	_check(app.qa_mode and app.game.score == 0, "Cycle %d starts fresh and isolated" % index)
	_hotspot("newsbox", "take")
	var paper := _find(app.inventory_box, "inventory_id", "newspaper")
	_check(paper != null, "Collected inventory control exists")
	if paper != null: paper.pressed.emit()
	_travel("bar")
	_hotspot("bartender", "talk")
	_choose("promotion_brief")
	_hotspot("promotion", "look")
	_hotspot("patron", "talk")
	_choose("regular_ticket")
	_hotspot("bartender", "talk")
	_choose("promotion_regular")
	_travel("backroom")
	_hotspot("candy", "take")
	_travel("casino")
	_hotspot("slots", "use")
	_close()
	# Exercise bounded history through actual submitted parser actions, not _say injections.
	for i in range(140):
		app.parser.text = "look around"
		app.parser.text_submitted.emit("look around")
		if i % 10 == 0: await process_frame
	_check(app.transcript.size() == 120, "Transcript remains bounded at 120 actual exchanges")
	app._transcript()
	_close()
	app._settings()
	_close()
	app._new_game_prompt()
	var reset := _text_button(app.modal, "Start a new evening")
	_check(reset != null, "New-evening confirmation control exists")
	if reset != null: reset.pressed.emit()
	var start := _text_button(app.modal, "Get lucky as Larry")
	_check(start != null and app.setup_open, "Reset presents real character setup before starting")
	if start != null: start.pressed.emit()
	_check(app.game.score == 0 and app.game.cash == 80 and app.game.inventory.is_empty(), "Real reset clears route state")
	_check(app.transcript.size() == 1 and app.inventory_snapshot.is_empty(), "Reset clears transcript and arrival bookkeeping")
	await process_frame
	await process_frame
	var loaded_bytes := int(Performance.get_monitor(Performance.MEMORY_STATIC))
	var live_ref: WeakRef = weakref(app)
	app.queue_free()
	app = null
	# Deferred render, font, scene and tween frees are given several idle frames.
	for i in range(6): await process_frame
	_check(live_ref.get_ref() == null, "Freed scene has no surviving object reference")
	return {"cycle": index, "loaded_static_bytes": loaded_bytes, "after_free_static_bytes": int(Performance.get_monitor(Performance.MEMORY_STATIC)), "node_count_after_free": int(Performance.get_monitor(Performance.OBJECT_NODE_COUNT)), "orphan_nodes_after_free": int(Performance.get_monitor(Performance.OBJECT_ORPHAN_NODE_COUNT))}

func _run() -> void:
	var original: Dictionary = {}
	for path in ["user://autosave.json", "user://savegame.json", "user://preferences.cfg"]:
		original[path] = FileAccess.get_file_as_bytes(path) if FileAccess.file_exists(path) else null
	for i in range(2): await _cycle(-2 + i)
	var baseline := int(Performance.get_monitor(Performance.MEMORY_STATIC))
	var baseline_nodes := int(Performance.get_monitor(Performance.OBJECT_NODE_COUNT))
	var baseline_orphans := int(Performance.get_monitor(Performance.OBJECT_ORPHAN_NODE_COUNT))
	for i in range(10):
		var sample := await _cycle(i + 1)
		samples.append(sample)
		_check(sample.node_count_after_free == baseline_nodes, "Node count returns to warmed baseline after cycle %d" % (i + 1))
		_check(sample.orphan_nodes_after_free <= baseline_orphans, "No additional orphan nodes after cycle %d" % (i + 1))
	var measured: bool = baseline > 0
	var final_bytes: int = samples.back().after_free_static_bytes
	var ratio: Variant = float(final_bytes) / float(baseline) if measured else null
	if measured: _check(float(ratio) <= 1.15, "Final static memory is within 15 percent of warmed native baseline")
	for path in original:
		var current: Variant = FileAccess.get_file_as_bytes(path) if FileAccess.file_exists(path) else null
		_check(current == original[path], "Lifecycle test preserves " + path)
	var report := {"generated_utc": Time.get_datetime_string_from_system(true), "engine": Engine.get_version_info(), "display": DisplayServer.get_name(), "warmup_cycles": 2, "measured_cycles": 10, "baseline_static_bytes": baseline if measured else null, "final_to_baseline_ratio": ratio, "samples": samples, "checks": checks, "failures": failures, "limits": "Native/headless Godot static-allocation monitor and scene lifecycles. Exercises visible UI callbacks, 140 real parser exchanges, reset confirmation and scene create/free per cycle. No hidden quest state injection. Does not measure browser heap, GPU/texture residency, an entire route, or ten browser resets; allocator caches may remain."}
	DirAccess.make_dir_recursive_absolute("res://docs/experiments/jev")
	var file := FileAccess.open("res://docs/experiments/jev/native-memory-lifecycle.json", FileAccess.WRITE)
	if file != null:
		file.store_string(JSON.stringify(report, "\t") + "\n")
		file.close()
	print("Native lifecycle: %d checks, %d failures; 10 cycles after 2 warmups; static baseline %d, final %d, ratio %s" % [checks, failures.size(), baseline, final_bytes, str(ratio)])
	quit(0 if failures.is_empty() else 1)
