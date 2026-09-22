extends SceneTree
## Isolated UI protocol test. Uses the same bounded adapter as the Web experiment.
const Bridge = preload("res://scripts/qa_bridge.gd")

class QAMain:
	extends "res://scripts/main.gd"
	func _qa_enabled() -> bool: return true

var assertions := 0
var max_candidates := 0
var failures: Array[String] = []
var app: Control
var bridge: Node

func _init() -> void:
	_run.call_deferred()

func _check(ok: bool, message: String) -> void:
	assertions += 1
	if not ok:
		failures.append(message)
		printerr("FAIL: " + message)

func _act(label: String) -> Dictionary:
	var observation: Dictionary = bridge.observation()
	max_candidates = maxi(max_candidates, observation.actions.size())
	for action in observation.actions:
		if action.label == label:
			var result: Dictionary = await bridge.request({"type": "larry-qa-action", "requestId": "test-%d" % assertions, "revision": observation.revision, "action": action.id})
			_check(not result.has("error"), "UI action accepted: " + label)
			_check(result.observation.revision == observation.revision + 1, "One fresh revision: " + label)
			return result.observation
	_check(false, "Missing visible action: " + label)
	return observation

func _travel(name: String) -> void:
	await _act("Travel via city map to " + name)

func _run() -> void:
	_check(Bridge.allowed_context(true, true, "http://127.0.0.1:8767"), "Dedicated loopback Web QA allowed")
	for context in [[false, true, Bridge.ORIGIN], [true, false, Bridge.ORIGIN], [true, true, "http://127.0.0.1:8766"], [true, true, "https://example.com"], [true, true, "http://localhost:8767"]]:
		_check(not Bridge.allowed_context(context[0], context[1], context[2]), "Bridge unavailable outside exact QA origin/features")
	_check(not Bridge.runtime_allowed(), "Normal native test cannot activate Web bridge")
	var paths := ["user://savegame.json", "user://autosave.json"]
	var original: Dictionary = {}
	for path in paths:
		original[path] = FileAccess.get_file_as_bytes(path) if FileAccess.file_exists(path) else null
	app = QAMain.new()
	root.add_child(app)
	await process_frame
	bridge = app.qa_bridge
	await bridge.start(app, false)
	_check(app.qa_mode and app.game.cash == 80 and app.game.score == 0, "QA starts fresh rather than restoring saves")
	_check(app.music.stream == null and not app.music.playing, "QA has no music playback")
	app._save()
	app._load()
	app._autosave()
	app._restore_autosave()
	app._command("save")
	app._command("load")
	for path in paths:
		var current: Variant = FileAccess.get_file_as_bytes(path) if FileAccess.file_exists(path) else null
		_check(current == original[path], "All save paths preserve " + path)
	var initial: Dictionary = bridge.observation()
	_check(initial.room.id == "street" and initial.inventory.is_empty(), "Public initial observation mirrors UI")
	_check(initial.actions.size() <= 255, "Bounded candidate coverage")
	_check(not JSON.stringify(initial).contains("flags") and not JSON.stringify(initial).contains("password_known"), "Public observation contains no hidden flags")
	_check(not JSON.stringify(initial).contains("bellybutton"), "Undiscovered password not leaked")
	for action in initial.actions:
		_check(not action.label.to_lower().contains("hint") and not action.label.to_lower().contains("next step"), "Hints absent from candidates")
	var rejected: Dictionary = await bridge.request({"type": "larry-qa-action", "revision": 0, "action": "eval:game.cash=999", "requestId": "invalid"})
	_check(rejected.error == "unsupported_action" and app.game.cash == 80 and bridge.revision == 0, "Unlisted executable text rejected without mutation")
	rejected = await bridge.request({"type": "larry-qa-action", "revision": -1, "action": "a000"})
	_check(rejected.error == "stale_revision" and bridge.revision == 0, "Stale revision rejected")
	rejected = await bridge.request({"type": "other", "revision": 0, "action": "a000"})
	_check(rejected.error == "unsupported_message", "Unknown message rejected")
	app._command("look around")
	rejected = await bridge.request({"type": "larry-qa-action", "revision": 0, "action": "a000"})
	_check(rejected.error == "state_changed" and bridge.revision == 1, "Human UI interaction during inference invalidates old observation")
	await _act("Take Free newspaper")
	_check(app.game.inventory.has("newspaper"), "TAKE through actual hotspot signal picks newspaper")
	await _act("Inspect Newspaper in inventory")
	_check(app.game.flags.get("newspaper_read", false), "Inventory right-click records visible clue")
	await _act("Take Flower cart · $10")
	await _travel("Lefty's Bar")
	await _act("Use Lefty · whiskey $10")
	await _act("Use Whiskey with Thirsty regular")
	_check(app.game.inventory.has("remote") and not app.game.inventory.has("whiskey"), "Item and target callbacks complete a trade")
	await _travel("The Restroom")
	await _act("Look Wall graffiti")
	await _act("Take Costume ring")
	await _travel("Lefty's Bar")
	await _act("Talk Backstage bouncer")
	await _act("Use TV remote with Television")
	_check(app.game.is_unlocked("backroom"), "Discovered clue and item unlock next room")
	await _travel("Backstage Lounge")
	await _act("Take Promotional candy")
	await _travel("The Lucky Chip")
	await _act("Take Studio 69 pass")
	await _act("Use Demonstration slots · $5")
	_check(not bridge.observation().overlay.is_empty(), "Casino overlay exposes only visible text and buttons")
	await _act("Press SPIN  ·  $5")
	_check(app.game.flags.get("slot_spins", 0) == 1 and not app.casino_panel.slot_pending, "Real casino animation settles before observation")
	await _act("Press Leave table")
	_check(not is_instance_valid(app.modal), "Real modal close callback used")
	await _travel("Studio 69")
	await _act("Talk Didi · stage designer")
	await _act("Use Dance floor")
	await _act("Use Costume ring with Didi · stage designer")
	await _act("Use Candy with Didi · stage designer")
	await _act("Use Flowers with Didi · stage designer")
	await _act("Use Wall telephone")
	await _travel("Quik-E-Mart")
	await _act("Take Wine · $12")
	await _travel("The Service Alley")
	await _act("Use Wine with Blues busker")
	await _act("Take Loaner rubber mallet")
	await _act("Take Apple core")
	await _act("Use Apple core on its own")
	_check(app.game.inventory.has("seeds"), "Real inventory double-click extracts seeds")
	await _travel("Studio 69")
	await _act("Use Pocket knife with Spare stage rope")
	await _travel("Backstage Lounge")
	await _act("Use Stage rope with Safety railing")
	await _travel("The Fire Escape")
	await _act("Use Rubber mallet with Sticking service window")
	await _act("Take Espresso voucher")
	await _travel("Quik-E-Mart")
	await _act("Use Espresso voucher with Espresso machine")
	await _travel("The Come-On Inn")
	await _act("Use Espresso with Night receptionist")
	await _travel("Eve's Rooftop")
	await _act("Talk Eve · rooftop host")
	await _travel("Moonlight Garden")
	await _act("Take Loaner folding stool")
	await _act("Use Apple seeds with Experimental planter")
	await _travel("The Penthouse")
	await _act("Use Folding stool with High cabinet")
	await _act("Take Water pitcher")
	await _act("Use Water pitcher with Kitchenette sink")
	await _travel("Moonlight Garden")
	await _act("Use Pitcher of water with Experimental planter")
	await _act("Take Miniature apple tree")
	await _travel("Eve's Rooftop")
	await _act("Use Perfect apple with Eve · rooftop host")
	await _act("Talk Eve · rooftop host")
	await _act("Talk Eve · rooftop host")
	await _act("Talk Eve · rooftop host")
	_check(app.game.completed and bridge.observation().score == 100, "All candidates cover a complete 100-point UI game")
	_check(not bridge.observation().overlay.is_empty(), "Completed-game ending rendered before observation")
	await _act("Press Stay a little longer")
	var duplicate: Control = QAMain.new()
	root.add_child(duplicate)
	await process_frame
	_check(duplicate.game.score == 0 and duplicate.game.cash == 80 and duplicate.game.inventory.is_empty(), "Second QA instance starts independently")
	_check(app.game.score > 0 and app.game.inventory.size() > 0, "Second instance cannot reset first")
	duplicate.queue_free()
	var stop: Dictionary = await bridge.request({"type": "larry-qa-action", "requestId": "stop", "revision": bridge.revision, "action": "decline"})
	_check(stop.get("stopped", false), "No-match reports a bounded stop")
	app.queue_free()
	await process_frame
	for path in paths:
		var current: Variant = FileAccess.get_file_as_bytes(path) if FileAccess.file_exists(path) else null
		_check(current == original[path], "Route testing leaves save untouched: " + path)
	print("Maximum route candidate count: %d" % max_candidates)
	print("QA bridge checks: %d passed, %d failed" % [assertions - failures.size(), failures.size()])
	quit(0 if failures.is_empty() else 1)
