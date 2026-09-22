extends SceneTree
## Actual button/keyboard callbacks for the upgrade, with isolated persistence.
class TestMain:
	extends "res://scripts/main.gd"
	func _autosave() -> void: pass
	func _save_preferences() -> void: pass

var app: Control
var assertions := 0
var failures: Array[String] = []

func _init() -> void:
	_run.call_deferred()

func _check(ok: bool, description: String) -> void:
	assertions += 1
	if not ok:
		failures.append(description)
		printerr("FAIL: " + description)

func _find(parent: Node, text: String) -> Button:
	for child in parent.get_children():
		if child is Button and child.text == text: return child
		var nested := _find(child, text)
		if nested != null: return nested
	return null

func _meta(parent: Node, key: String, value: String) -> Button:
	for child in parent.get_children():
		if child is Button and child.get_meta(key, "") == value: return child
		var nested := _meta(child, key, value)
		if nested != null: return nested
	return null

func _press(parent: Node, text: String) -> void:
	var button := _find(parent, text)
	_check(button != null and not button.disabled, "Visible enabled button: " + text)
	if button != null and not button.disabled: button.pressed.emit()

func _close() -> void:
	if is_instance_valid(app.modal): _press(app.modal, "×")

func _hotspot(id: String, verb: String) -> void:
	_close()
	app.verbs.look.pressed.emit()
	app.verbs[verb].pressed.emit()
	var button := _meta(app.hotspots, "hotspot_id", id)
	_check(button != null and button.get_meta("hotspot_id") is String, "Hotspot has a stable String identity: " + id)
	if button != null: button.pressed.emit()

func _choice(id: String) -> void:
	var button := _meta(app.modal, "dialogue_choice", id) if is_instance_valid(app.modal) else null
	_check(button != null and button.get_meta("dialogue_choice") is String, "Dialogue button has a stable String identity: " + id)
	if button != null: button.pressed.emit()

func _command(text: String) -> void:
	_close()
	app.parser.text = text
	app.parser.text_submitted.emit(text)
	_check(app.parser.text.is_empty(), "Parser consumes " + text)
	await process_frame
	await process_frame

func _key(code: Key) -> void:
	var event := InputEventKey.new()
	event.pressed = true
	event.keycode = code
	app._unhandled_key_input(event)

func _labels(parent: Node) -> String:
	var text := ""
	for child in parent.get_children():
		if child is Label: text += child.text + "\n"
		text += _labels(child)
	return text

func _slider(parent: Node, title: String) -> HSlider:
	for child in parent.get_children():
		if child is HSlider and child.tooltip_text == title: return child
		var nested := _slider(child, title)
		if nested != null: return nested
	return null

func _run() -> void:
	var original: Dictionary = {}
	for path in ["user://autosave.json", "user://savegame.json", "user://preferences.cfg"]:
		original[path] = FileAccess.get_file_as_bytes(path) if FileAccess.file_exists(path) else null
	app = TestMain.new()
	app.size = Vector2(1440, 960)
	root.add_child(app)
	await process_frame
	await process_frame
	_check(not app.qa_mode, "Tests exercise the ordinary UI, not a QA action adapter")
	# Parser intentions route through the same offers and conversations as clicking.
	await _command("take newspaper")
	var selected_paper := _meta(app.inventory_box, "inventory_id", "newspaper")
	if selected_paper != null: selected_paper.pressed.emit()
	await _command("go bar")
	await _command("use lefty")
	_check(app.selected_item.is_empty(), "Typed person-use intention clears an unrelated selected pocket item")
	_check(is_instance_valid(app.modal) and app.dialogue_choice_buttons.has("buy_whiskey"), "Parser USE LEFTY opens the actual purchase offer")
	_check(app.game.cash == 80 and not app.game.inventory.has("whiskey"), "Parser person-use cannot charge before a purchase choice")
	_choice("buy_whiskey")
	_check(app.game.cash == 70 and app.game.inventory.has("whiskey"), "Explicit parser-opened purchase choice charges exactly once")
	await _command("talk lefty")
	_check(app.dialogue_choice_buttons.has("promotion_brief"), "Parser TALK exposes current conversation choices")
	await _command("choose promotion_brief")
	_check(app.game.flags.get("promotion_brief", false) and app.dialogue_choice_buttons.has("promotion_regular"), "Parser CHOOSE executes a valid topic and opens its follow-up choices")
	for command in ["go street", "go casino", "take pass", "go street", "go disco", "talk didi"]:
		await _command(command)
	_check(app.dialogue_choice_buttons.has("rehearsal_start"), "Parser Didi introduction exposes rehearsal alternatives")
	await _command("dance")
	_check(not app.game.flags.get("danced", false) and app.dialogue_choice_buttons.has("dance_careful"), "Parser DANCE asks for a style before performing")
	_choice("dance_careful")
	_check(app.game.flags.get("dance_careful", false) and app.game.flags.get("danced", false), "Chosen parser-opened dance style executes")
	await _command("choose rehearsal_start")
	await _command("choose rehearsal_correct")
	await _command("call 555-0987")
	_check(app.game.flags.get("phone_called", false) and app.dialogue_choice_buttons.has("manager_setup"), "Parser CALL exposes the stage manager's follow-up choices")
	await _command("choose manager_setup")
	_check(app.dialogue_choice_buttons.has("manager_intro"), "Parser phone dialogue keeps the introduction actionable")
	_close()
	_press(app.canvas, "New evening")
	_press(app.modal, "Start a new evening")
	_check(app.game.room == "street" and app.game.cash == 80 and app.game.score == 0, "Actual New evening control resets the independent parser scenario")
	_hotspot("newsbox", "take")
	await process_frame
	var paper := _meta(app.inventory_box, "inventory_id", "newspaper")
	_check(paper != null and paper.get_meta("inventory_id") is String, "Inventory action carries stable typed identity")
	_check(app.arrival_label.text.contains("Newspaper"), "Acquisition displays item-arrival feedback")
	if paper != null: paper.pressed.emit()
	_check(app.selected_item == "newspaper" and app.selected_label.text.contains("Use Newspaper on"), "Selection makes intended item action explicit")
	_check(app.selection_cancel.visible, "Selected item exposes a cancel control")
	app.selection_cancel.pressed.emit()
	_check(app.selected_item.is_empty() and not app.selection_cancel.visible, "Cancel clears item and hides itself")
	paper = _meta(app.inventory_box, "inventory_id", "newspaper")
	if paper != null: paper.pressed.emit()
	_key(KEY_ESCAPE)
	_check(app.selected_item.is_empty(), "Escape cancels selected item")
	_press(app.canvas, "Tidy")
	_check(app.tidy_pockets and _meta(app.inventory_box, "inventory_id", "newspaper") == null, "Tidy hides the already-read newspaper")
	_check(app.game.inventory.has("newspaper"), "Tidy never deletes a souvenir from the model")
	_press(app.canvas, "Tidy")
	_check(_meta(app.inventory_box, "inventory_id", "newspaper") != null, "Tidy restores all carried souvenirs")
	_press(app.canvas, "Need a nudge?")
	_check(app.hint_stage == 0 and not _labels(app.modal).contains("ticket 37"), "First requested hint is gentle and avoids the exact prize answer")
	var first_hint := _labels(app.modal)
	_press(app.modal, "Narrow the lead")
	_check(app.hint_stage == 1 and _labels(app.modal) != first_hint, "Second deliberate request narrows the clue")
	var second_hint := _labels(app.modal)
	_press(app.modal, "Reveal exact solution")
	_check(app.hint_stage == 2 and _labels(app.modal) != second_hint, "Third deliberate request reveals an exact solution")
	_check(_labels(app.modal).contains("spoilers"), "Exact solution is labeled as a spoiler")
	_check(app.game.cash == 80 and app.game.score == 4, "Requesting hints never changes money or milestone score")
	_close()
	await _command("go bar")
	_hotspot("bartender", "use")
	_check(app.game.cash == 80 and not app.game.inventory.has("whiskey"), "USE bartender opens offer choices without purchasing")
	_choice("promotion_brief")
	_check(app.last_message.contains("winning customer") or app.last_message.contains("real winner"), "Chosen topic produces its authored response")
	_choice("promotion_larry")
	_check(not app.game.flags.get("backstage_social", false) and app.game.cash == 80, "Comedic wrong answer remains safely retryable")
	_close()
	_press(app.canvas, "Need a nudge?")
	_check(app.hint_stage == 0, "A changed objective resets hint progression")
	_close()
	_hotspot("promotion", "look")
	_hotspot("patron", "talk")
	_choice("regular_ticket")
	_hotspot("bartender", "talk")
	_choice("promotion_regular")
	_check(app.game.is_unlocked("backroom"), "Observed clues and visible dialogue choices open alternate backstage route")
	_close()
	_key(KEY_O)
	_check(is_instance_valid(app.modal) and _find(app.modal, "Reduced motion: OFF") != null, "Options keyboard shortcut exposes settings")
	_press(app.modal, "Reduced motion: OFF")
	_check(app.reduced_motion and app.larry.reduced_motion and app.world_effects.reduced_motion, "Reduced motion reaches character and world visuals")
	_close()
	var turns_before: int = app.game.turns
	var click := InputEventMouseButton.new()
	click.pressed = true
	click.button_index = MOUSE_BUTTON_LEFT
	click.position = Vector2(680, 470)
	app.background.gui_input.emit(click)
	_check(app.larry.position == Vector2(680, 470) and not app.larry.walking, "Reduced-motion walk reaches destination without an ongoing tween")
	_check(app.game.turns == turns_before, "Motion preference does not change puzzle state")
	_press(app.canvas, "Options")
	var music_slider := _slider(app.modal, "Music volume")
	var effects_slider := _slider(app.modal, "Effects volume")
	_check(music_slider != null and effects_slider != null, "Music and effects expose separate sliders")
	if music_slider != null: music_slider.value = 0.25
	_check(is_equal_approx(app.music_volume, 0.25) and is_equal_approx(app.effects_volume, 0.5), "Music level leaves effects level unchanged")
	if effects_slider != null: effects_slider.value = 0.8
	_check(is_equal_approx(app.effects_volume, 0.8) and is_equal_approx(app.music_volume, 0.25), "Effects level leaves music level unchanged")
	_press(app.modal, "Effects: ON")
	_check(not app.effects_on and app.music_on, "Muting effects leaves music preference unchanged")
	var narrative_before: String = app.last_message
	_press(app.modal, "Read conversation transcript")
	_check(_labels(app.modal).contains(narrative_before) and _labels(app.modal).contains("golden"), "Readable transcript contains actual authored exchanges")
	_key(KEY_ESCAPE)
	_check(not is_instance_valid(app.modal), "Escape closes transcript")
	_key(KEY_3)
	_check(app.verb == "take", "Keyboard verb shortcut remains available after modal closes")
	# Collect a long pocket list through real parser actions, then inspect the new-item scroll.
	for command in ["go street", "buy flowers", "go bar", "buy whiskey", "give whiskey to regular", "go bathroom", "take ring", "go bar", "go backroom", "take candy", "go bar", "go street", "go casino", "take pass", "go street", "go shop", "buy wine"]:
		await _command(command)
	await process_frame
	await process_frame
	var newest := _meta(app.inventory_box, "inventory_id", "wine")
	_check(newest != null and app.inventory_scroll.scroll_vertical > 0, "New inventory arrival scrolls a long pocket list")
	if newest != null:
		_check(app.inventory_scroll.get_global_rect().encloses(newest.get_global_rect()), "Newly acquired item is visible in the pocket viewport")
	for command in ["go street", "go alley", "take apple core"]:
		await _command(command)
	var core := _meta(app.inventory_box, "inventory_id", "core")
	_check(core != null, "Collected core has a normal selectable inventory button")
	if core != null: core.pressed.emit()
	await process_frame
	_press(app.inventory_box, "Use Apple core by itself")
	_check(app.game.inventory.has("seeds") and not app.game.inventory.has("core"), "Visible single-activation inventory action extracts seeds without a double-click")
	_check(app.selected_item.is_empty() and not app.selection_cancel.visible, "Consuming the core clears its selection")
	_check(_find(app.inventory_box, "Use Apple core by itself") == null, "Consumed-item self-use action disappears")
	_check(app.last_message.contains("three seeds") and app.arrival_label.text.contains("Apple seeds"), "Self-use supplies both narration and newly acquired item feedback")
	for viewport in [Vector2(884, 886), Vector2(1280, 720), Vector2(1440, 960)]:
		app.size = viewport
		app._fit()
		await process_frame
		await process_frame
		var window := Rect2(Vector2.ZERO, viewport)
		_check(window.encloses(app.parser.get_global_rect()), "Parser stays in window at " + str(viewport))
		_check(window.encloses(app.inventory_scroll.get_global_rect()), "Inventory stays in window at " + str(viewport))
		_check(not app.dialogue.get_global_rect().intersects(app.parser.get_global_rect()), "Dialogue and parser do not overlap at " + str(viewport))
		_check(not app.dialogue.get_global_rect().intersects(app.scene_area.get_global_rect()), "Dialogue clears the actual scene viewport at " + str(viewport))
		_check(app.dialogue.get_theme_font_size("normal_font_size") * app.canvas.scale.x >= 14, "Dialogue has at least 14 rendered pixels at " + str(viewport))
		_press(app.canvas, "Options")
		await process_frame
		var panel: Control = app.modal.get_child(1)
		_check(window.encloses(panel.get_global_rect()), "Settings panel fits at " + str(viewport))
		_close()
	for path in original:
		var current: Variant = FileAccess.get_file_as_bytes(path) if FileAccess.file_exists(path) else null
		_check(current == original[path], "UI upgrade tests preserve user data: " + path)
	app.queue_free()
	await process_frame
	print("Upgrade interface tests: %d assertions, %d failures." % [assertions, failures.size()])
	quit(0 if failures.is_empty() else 1)
