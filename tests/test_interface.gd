extends SceneTree
## Full adventure through the real scene's UI signals and callbacks.
## Preserves the existing autosave; never touches the manual save slot.

const MainScene = preload("res://scenes/main.tscn")
const AUTOSAVE := "user://autosave.json"
var failures: Array[String] = []
var assertions := 0
var app: Control
var _had_autosave := false
var _original_autosave := PackedByteArray()


func _init() -> void:
	_run.call_deferred()


func _check(condition: bool, description: String) -> void:
	assertions += 1
	if not condition:
		failures.append(description)
		printerr("FAIL: " + description)


func _find_button(parent: Node, text: String) -> Button:
	for child in parent.get_children():
		if child is Button and (child.text == text or child.text.ends_with(text)):
			return child
		var found := _find_button(child, text)
		if found != null:
			return found
	return null


func _dismiss_overlay() -> void:
	if not is_instance_valid(app.modal): return
	var close := _find_button(app.modal, "×")
	_check(close != null, "Overlay has a visible close control")
	if close != null: close.pressed.emit()
	_check(not is_instance_valid(app.modal), "Overlay closes before world interaction")


func _choice(id: String) -> void:
	_check(is_instance_valid(app.modal) and app.dialogue_choice_buttons.has(id), "Dialogue choice is visibly offered: " + id)
	if not app.dialogue_choice_buttons.has(id): return
	var button: Button = app.dialogue_choice_buttons[id]
	_check(button.get_meta("dialogue_choice", "") == id and not button.disabled, "Dialogue button has matching identity and is enabled: " + id)
	button.pressed.emit()


func _submit(command: String) -> void:
	_dismiss_overlay()
	app.parser.text = command
	app.parser.text_submitted.emit(command)
	_check(app.parser.text.is_empty(), "Parser consumed: " + command)


func _click_hotspot(id: String, verb: String = "use") -> void:
	_dismiss_overlay()
	# Select the verb exactly as the toolbar does, clearing any previous item.
	app.verbs.look.pressed.emit()
	app.verbs[verb].pressed.emit()
	_click_current_target(id)


func _click_current_target(id: String) -> void:
	var spot: Dictionary = app.game.get_hotspot(id)
	_check(not spot.is_empty(), "Visible target: " + id)
	if spot.is_empty():
		return
	var button := _find_button(app.hotspots, str(spot.label))
	_check(button != null and not button.disabled, "Clickable scene target: " + id)
	if button != null:
		button.pressed.emit()


func _select_inventory(id: String) -> void:
	_dismiss_overlay()
	var button := _find_button(app.inventory_box, str(app.game.items[id].name))
	_check(button != null, "Inventory button exists: " + id)
	if button != null:
		button.pressed.emit()
	_check(app.selected_item == id, "Inventory selection reaches model/UI: " + id)


func _use_item(id: String, target: String) -> void:
	app.verbs.look.pressed.emit()
	_select_inventory(id)
	_click_current_target(target)


func _map_to(destination: String) -> void:
	_dismiss_overlay()
	app._map()
	_check(is_instance_valid(app.modal), "Map modal opens for " + destination)
	var name: String = app.game.get_room(destination).name
	var button := _find_button(app.modal, name)
	_check(button != null and not button.disabled, "Map destination available: " + destination)
	if button != null and not button.disabled:
		button.pressed.emit()
	_check(app.game.room == destination and not is_instance_valid(app.modal), "Map travels and closes: " + destination)


func _restore_original_autosave() -> void:
	if _had_autosave:
		var file := FileAccess.open(AUTOSAVE, FileAccess.WRITE)
		if file == null:
			_check(false, "Original autosave could not be restored")
			return
		file.store_buffer(_original_autosave)
		file.close()
		_check(FileAccess.get_file_as_bytes(AUTOSAVE) == _original_autosave, "Original autosave restored byte-for-byte")
	else:
		if FileAccess.file_exists(AUTOSAVE):
			DirAccess.remove_absolute(ProjectSettings.globalize_path(AUTOSAVE))
		_check(not FileAccess.file_exists(AUTOSAVE), "Temporary UI-test autosave removed")


func _run() -> void:
	if "--smoke-ui" in OS.get_cmdline_user_args() or "--capture-all" in OS.get_cmdline_user_args():
		printerr("Run test_interface.gd without UI automation arguments.")
		quit(1)
		return
	_had_autosave = FileAccess.file_exists(AUTOSAVE)
	if _had_autosave:
		_original_autosave = FileAccess.get_file_as_bytes(AUTOSAVE)
	app = MainScene.instantiate()
	root.add_child(app)
	await process_frame
	await process_frame
	_check(app.game.room == "street" and app.game.cash == 80, "Real main scene starts a fresh evening")
	_check(app.background.texture != null and app.hotspots.get_child_count() > 0, "Main scene loads art and interactive controls")
	_click_hotspot("newsbox", "take")
	_select_inventory("newspaper")
	_check(app.game.flags.get("newspaper_read", false), "Inventory selection reads newspaper through real UI")
	_click_hotspot("flowercart", "take")
	_submit("go bar")
	_click_hotspot("bartender", "take")
	_check(app.game.cash == 70 and not app.game.inventory.has("whiskey"), "TAKE a person cannot make an unexpected purchase")
	_click_hotspot("bartender", "use")
	_check(app.game.cash == 70 and not app.game.inventory.has("whiskey"), "USE Lefty opens offers without spending money")
	_choice("buy_whiskey")
	_check(app.game.cash == 60 and app.game.inventory.has("whiskey"), "Explicit whiskey offer performs the purchase")
	_use_item("whiskey", "patron")
	_check(app.game.inventory.has("remote"), "Click trade receives remote")
	_submit("go bathroom")
	var graffiti := _find_button(app.hotspots, "Wall graffiti")
	_check(graffiti != null, "Graffiti has an actual right-click target")
	if graffiti != null:
		var right_click := InputEventMouseButton.new()
		right_click.button_index = MOUSE_BUTTON_RIGHT
		right_click.pressed = true
		graffiti.gui_input.emit(right_click)
	_check(app.game.flags.get("password_known", false), "Right-click LOOK learns the password in the running model")
	var right_click_save: Variant = JSON.parse_string(FileAccess.get_file_as_string(AUTOSAVE))
	_check(right_click_save is Dictionary and right_click_save.get("flags", {}).get("password_known", false), "Right-click clue is immediately persisted to autosave")
	_click_hotspot("graffiti", "look")
	_click_hotspot("ring", "take")
	_submit("go bar")
	_submit("BELLYBUTTON")
	_use_item("remote", "television")
	_submit("go backroom")
	_click_hotspot("candy", "take")
	_map_to("casino")
	_click_hotspot("pass", "take")
	# The real parser opens the native casino modal; the actual Spin button
	# drives the animation and model settlement rather than bypassing the panel.
	_submit("play slots")
	_check(is_instance_valid(app.casino_panel) and is_instance_valid(app.modal), "Parser opens slots modal")
	var spin := _find_button(app.casino_panel, "SPIN  ·  $5")
	_check(spin != null, "Slots exposes a real Spin button")
	if spin != null:
		spin.pressed.emit()
	_check(app.casino_panel.slot_pending, "Spin button starts animation")
	await create_timer(1.2).timeout
	_check(not app.casino_panel.slot_pending and int(app.game.flags.get("slot_spins", 0)) == 1, "Animated UI spin settles exactly once")
	_check(app.money_label.text == "$%d" % app.game.cash, "Casino outcome refreshes main wallet label")
	var leave := _find_button(app.casino_panel, "Leave table")
	_check(leave != null, "Casino Leave table button exists")
	if leave != null:
		leave.pressed.emit()
	_check(not is_instance_valid(app.modal) and not is_instance_valid(app.casino_panel), "Leave table closes casino UI")
	_map_to("disco")
	_click_hotspot("dancer", "use")
	var dancer_save: Variant = JSON.parse_string(FileAccess.get_file_as_string(AUTOSAVE))
	_check(dancer_save is Dictionary and dancer_save.get("flags", {}).get("dancer_met", false), "USE Didi's early offer path persists the new introduction")
	_click_hotspot("dancefloor", "use")
	_check(not app.game.flags.get("danced", false), "Dance floor offers styles before executing a dance")
	_choice("dance_confident")
	_check(app.game.flags.get("dance_confident", false) and app.game.flags.get("danced", false), "Chosen dance style performs the dance")
	_use_item("ring", "dancer")
	_use_item("candy", "dancer")
	_use_item("flowers", "dancer")
	_check(app.game.flags.get("phone_known", false), "Click interactions reveal stage-manager number")
	_click_hotspot("phone", "use")
	_map_to("shop")
	_click_hotspot("wine_shelf", "take")
	_map_to("alley")
	_use_item("wine", "busker")
	_click_hotspot("hammer", "take")
	_click_hotspot("core", "take")
	var core_button := _find_button(app.inventory_box, "Apple core")
	_check(core_button != null, "Core is displayed in inventory")
	if core_button != null:
		var double_click := InputEventMouseButton.new()
		double_click.button_index = MOUSE_BUTTON_LEFT
		double_click.pressed = true
		double_click.double_click = true
		core_button.gui_input.emit(double_click)
	_check(app.game.inventory.has("seeds") and not app.game.inventory.has("core"), "Inventory double-click extracts apple seeds")
	_map_to("disco")
	_use_item("knife", "rigging")
	_map_to("backroom")
	_use_item("rope", "railing")
	_submit("go balcony")
	_use_item("hammer", "window")
	_click_hotspot("voucher", "take")
	_map_to("shop")
	_use_item("voucher", "espresso")
	_map_to("hotel")
	_use_item("coffee", "receptionist")
	_check(app.game.is_unlocked("penthouse"), "Coffee click unlocks penthouse")
	_map_to("garden")
	_click_hotspot("stool", "take")
	_use_item("seeds", "planter")
	_map_to("penthouse")
	_use_item("stool", "cabinet")
	_click_hotspot("pitcher", "take")
	_use_item("pitcher", "sink")
	_check(_find_button(app.inventory_box, "Pitcher of water") != null, "Full pitcher label is visible in inventory")
	_map_to("garden")
	# Filled pitcher has a dynamic label, so select its actual visible button.
	app.verbs.look.pressed.emit()
	var water_button := _find_button(app.inventory_box, "Pitcher of water")
	if water_button != null:
		water_button.pressed.emit()
	_click_current_target("planter")
	_click_hotspot("tree", "take")
	_map_to("rooftop")
	_click_hotspot("eve", "talk")
	_choice("eve_story")
	_check(not app.game.completed, "Sharing a story before dinner does not finish the evening")
	_choice("eve_gardens")
	_check(not app.game.completed, "Listening to Eve does not silently select an ending")
	_use_item("apple", "eve")
	_click_hotspot("eve", "talk")
	_check(not app.game.completed, "Ready conversation waits for explicit ending choice")
	_choice("ending_flirt")
	await process_frame
	await process_frame
	_check(app.game.completed, "Full UI route completes the adventure")
	_check(app.game.score == 100 and app.score_label.text == "100 / 100", "Full UI route earns and displays 100 points")
	_check(app.ending_shown and is_instance_valid(app.modal), "Completion opens the ending modal")
	_check(_find_button(app.modal, "Stay a little longer") != null, "Ending modal contains its visible final action")
	_check(app.last_message.contains("THE END"), "Ending narration reaches dialogue UI")
	# Test the existing autosave through actual New Game / Restore callbacks.
	# The original user's autosave is restored only after the scene is removed.
	var final_inventory: Array = app.game.inventory.duplicate()
	var final_cash: int = app.game.cash
	var again := _find_button(app.modal, "One more evening")
	_check(again != null, "Ending exposes new-evening button")
	if again != null:
		again.pressed.emit()
	_check(not app.game.completed and app.game.score == 0 and app.game.room == "street", "New-evening button resets real UI")
	app._help()
	var restore := _find_button(app.modal, "Restore autosave")
	_check(restore != null, "Help modal exposes Restore autosave")
	if restore != null:
		restore.pressed.emit()
	_check(app.game.completed and app.game.score == 100 and app.game.room == "rooftop", "Restore-autosave button restores completed evening")
	_check(app.game.inventory == final_inventory and app.game.cash == final_cash, "UI restore preserves inventory and wallet")
	_check(app.score_label.text == "100 / 100" and app.status.text == "A NIGHT TO REMEMBER", "Restored model repaints the UI")
	app._close_modal()
	app.queue_free()
	await process_frame
	_restore_original_autosave()
	print("Interface tests: %d assertions, %d failures. Full UI route: 100/100 and ending verified." % [assertions, failures.size()])
	quit(0 if failures.is_empty() else 1)
