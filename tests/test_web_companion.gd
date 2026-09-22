extends SceneTree
## Companion adapter validation, without browser execution or user save access.
const Companion = preload("res://scripts/web_companion.gd")
class IsolatedMain:
	extends "res://scripts/main.gd"
	func _autosave() -> void: pass
	func _save_preferences() -> void: pass
class Surface:
	extends Control
	var qa_mode := false
	var transcript: Array[String] = ["Narrator: A visible response."]
	var canvas := Control.new()
	var modal: Control
	var room_title := Label.new()
	var money_label := Label.new()
	var score_label := Label.new()
	var status := Label.new()
	var objective_text := Label.new()
	var selected_label := Label.new()
	var speaker := Label.new()
	var dialogue := RichTextLabel.new()
	func _ready() -> void:
		add_child(canvas)
		for node in [room_title, money_label, score_label, status, objective_text, selected_label, speaker, dialogue]:
			canvas.add_child(node)
		room_title.text = "The Room"
		money_label.text = "$80"
		score_label.text = "0 / 100"
		objective_text.text = "A visible clue."
		speaker.text = "Narrator"
		dialogue.text = "A visible response."
var assertions := 0
var failures: Array[String] = []
var clicked := 0
var volume_changes := 0
func _init() -> void:
	_run.call_deferred()
func check(value: bool, message: String) -> void:
	assertions += 1
	if not value:
		failures.append(message)
		printerr("FAIL: " + message)
func _run() -> void:
	check(Companion.allowed_context(true, false, false, false), "Production Web allows companion")
	check(not Companion.allowed_context(true, true, false, false), "QA export never starts companion")
	check(not Companion.allowed_context(true, false, true, false), "QA session never starts companion")
	check(not Companion.allowed_context(true, false, false, true), "Headless never starts companion")
	check(not Companion.allowed_context(false, false, false, false), "Native never starts companion")
	var app := Surface.new()
	root.add_child(app)
	var companion := Companion.new()
	root.add_child(companion)
	companion.app = app
	var button := Button.new()
	button.text = "Take clue"
	button.pressed.connect(func(): clicked += 1)
	app.canvas.add_child(button)
	var hidden_button := Button.new()
	hidden_button.text = "Hidden spoiler"
	hidden_button.hide()
	app.canvas.add_child(hidden_button)
	var disabled_button := Button.new()
	disabled_button.text = "Locked room"
	disabled_button.disabled = true
	app.canvas.add_child(disabled_button)
	await process_frame
	companion.refresh()
	check(companion._snapshot.buttons.size() == 2, "Visible disabled control is described; hidden control omitted")
	check(companion._snapshot.dialogue == "Narrator: A visible response.", "Companion uses visible narration")
	check(not JSON.stringify(companion._snapshot).contains("Hidden spoiler"), "Hidden label never leaks")
	var id: String = companion._snapshot.buttons[0].id
	check(not companion._activate({"id": id, "revision": companion.revision - 1}) and clicked == 0, "Stale revision cannot activate a control")
	check(not companion._activate({"id": "invented", "revision": companion.revision}) and clicked == 0, "Only published action IDs execute")
	check(companion._activate({"id": id, "revision": companion.revision}) and clicked == 1, "Valid action emits the real button signal")
	await process_frame
	var disabled_id: String = companion._snapshot.buttons[1].id
	check(not companion._activate({"id": disabled_id, "revision": companion.revision}), "Disabled button cannot execute")
	await process_frame
	var captured_revision: int = companion.revision
	app.modal = Control.new()
	app.add_child(app.modal)
	var close := Button.new()
	close.text = "×"
	app.modal.add_child(close)
	var modal_label := Label.new()
	modal_label.text = "Make a choice."
	app.modal.add_child(modal_label)
	check(not companion._activate({"id": id, "revision": captured_revision}) and clicked == 1, "A newly opened modal blocks previously published underlying button")
	check(companion._snapshot.buttons.size() == 1 and companion._snapshot.buttons[0].text == "Close dialog", "Modal surface includes only its own controls with accessible close name")
	check(companion._snapshot.overlay == ["Make a choice."], "Modal exposes only its visible text")
	var slider := HSlider.new()
	slider.tooltip_text = "Effects volume"
	slider.min_value = 0
	slider.max_value = 100
	slider.step = 1
	slider.value_changed.connect(func(_value): volume_changes += 1)
	app.modal.add_child(slider)
	companion.refresh()
	var slider_id: String = companion._snapshot.ranges[0].id
	check(companion._activate({"id": slider_id, "revision": companion.revision, "value": 35}) and slider.value == 35 and volume_changes == 1, "HTML range changes the real slider and emits its signal")
	await process_frame
	check(not companion._activate({"id": slider_id, "revision": companion.revision, "value": 200}) and slider.value == 35, "Out-of-range slider action is rejected")
	await process_frame
	check(not companion._activate({"id": slider_id, "revision": companion.revision, "value": "35"}), "Untyped slider value is rejected")
	await process_frame
	check(companion._snapshot.transcript.size() == 1, "Repeated refresh does not duplicate transcript")
	app.dialogue.text = "Another response."
	app.transcript.append("Narrator: Another response.")
	companion.refresh()
	check(companion._snapshot.transcript.size() == 2, "New visible response enters transcript")
	app.transcript.assign(["Narrator: A new evening."])
	app.dialogue.text = "A new evening."
	companion.refresh()
	check(companion._snapshot.transcript == ["Narrator: A new evening."], "New evening replaces previous transcript")
	app.transcript.assign(["Narrator: A second new evening."])
	app.dialogue.text = "A second new evening."
	companion.refresh()
	check(companion._snapshot.transcript == ["Narrator: A second new evening."], "Same-length transcript reset still replaces previous evening")
	close.tooltip_text = "Cancel selected item (Escape)"
	companion.refresh()
	check(companion._snapshot.buttons[0].text == "Cancel selected item", "Selected-item cancel does not get mislabeled as dialog close")
	# Integration with actual game controls: HTML has a single-activation equivalent
	# for using an inventory item on itself, without inventing a model-only action.
	var real_app := IsolatedMain.new()
	real_app.size = Vector2(1440, 960)
	root.add_child(real_app)
	await process_frame
	real_app.parser.text = "go alley"
	real_app.parser.text_submitted.emit("go alley")
	real_app.verbs.take.pressed.emit()
	var core_target: Button
	for candidate in real_app.hotspots.get_children():
		if candidate is Button and candidate.get_meta("hotspot_id", "") == "core": core_target = candidate
	check(core_target != null, "Actual game offers a core collection control")
	if core_target != null: core_target.pressed.emit()
	check(real_app.game.inventory.has("core"), "Real collection callback supplies the core")
	companion.app = real_app
	companion.refresh()
	var core_id := ""
	for entry in companion._snapshot.buttons:
		if entry.text.ends_with("Apple core"): core_id = entry.id
	check(not core_id.is_empty(), "Companion publishes the actual inventory selection control")
	check(companion._activate({"id": core_id, "revision": companion.revision}), "Companion activates the real core selection signal")
	await process_frame
	companion.refresh()
	var self_use_id := ""
	for entry in companion._snapshot.buttons:
		if entry.text == "Use Apple core by itself": self_use_id = entry.id
	check(not self_use_id.is_empty(), "Companion publishes the visible self-use inventory button")
	check(companion._activate({"id": self_use_id, "revision": companion.revision}), "Companion activates self-use through the actual UI button")
	check(real_app.game.inventory.has("seeds") and not real_app.game.inventory.has("core"), "Companion single-activation path extracts seeds without double-click or hidden-state edits")
	await process_frame
	companion.refresh()
	check(not companion._activate({"id": self_use_id, "revision": companion.revision}) and real_app.game.inventory.count("seeds") == 1, "Consumed self-use control cannot be reused to duplicate seeds")
	real_app.queue_free()
	app.queue_free()
	companion.queue_free()
	await process_frame
	print("Web companion: %d passed, %d failed" % [assertions - failures.size(), failures.size()])
	quit(0 if failures.is_empty() else 1)
