extends SceneTree
## Resize the actual root Window, never main.size or _fit(). This catches
## canvas_items stretching hiding physical browser dimensions from the layout.
## Does not load/alter a save, preferences, or external data.
const MainScene = preload("res://scenes/main.tscn")
var failures: Array[String] = []
var assertions := 0

func _init() -> void:
	_run.call_deferred()

func check(ok: bool, message: String) -> void:
	assertions += 1
	if not ok:
		failures.append(message)
		printerr("FAIL: " + message)

func _labels(node: Node) -> Array[Label]:
	var output: Array[Label] = []
	for child in node.get_children():
		if child is Label: output.append(child)
		output.append_array(_labels(child))
	return output

func _scroll_labels(node: Node) -> Array[Label]:
	var output: Array[Label] = []
	for label in _labels(node):
		if label.get_parent() is ScrollContainer:
			output.append(label)
	return output

func _visible_rect(control: Control) -> Rect2:
	var rect := control.get_global_rect()
	var ancestor := control.get_parent()
	while ancestor is Control:
		if ancestor.clip_contents:
			rect = rect.intersection(ancestor.get_global_rect())
		ancestor = ancestor.get_parent()
	return rect

func _settle() -> void:
	# Container layout and Window resize notifications settle on separate frames.
	await process_frame
	await process_frame
	await process_frame

func _run() -> void:
	var original: Dictionary = {}
	for path in ["user://autosave.json", "user://savegame.json", "user://preferences.cfg"]:
		original[path] = FileAccess.get_file_as_bytes(path) if FileAccess.file_exists(path) else null
	check(str(ProjectSettings.get_setting("display/window/stretch/mode")) == "disabled", "Production window does not lock responsive layout to a fixed logical viewport")
	# Optional regression proof: reproduce the former fixed logical viewport in
	# this isolated test process without editing production project settings.
	if "--legacy-fixed-viewport" in OS.get_cmdline_user_args():
		root.content_scale_mode = Window.CONTENT_SCALE_MODE_CANVAS_ITEMS
		root.content_scale_size = Vector2i(1440, 960)
	var app = MainScene.instantiate()
	root.add_child(app)
	await _settle()
	# Important: never assign app.size or invoke app._fit() in this regression.
	# The actual scene anchors and resized signal must carry every size change.
	for dimensions in [Vector2i(884, 886), Vector2i(1440, 960), Vector2i(1280, 720), Vector2i(884, 886)]:
		root.size = dimensions
		await _settle()
		var viewport_size: Vector2 = root.get_visible_rect().size
		var window := Rect2(Vector2.ZERO, Vector2(dimensions))
		var name := str(dimensions)
		check(root.size == dimensions, "Root Window accepted physical size " + name)
		check(viewport_size.is_equal_approx(Vector2(dimensions)), "Viewport follows actual Window dimensions " + name)
		check(app.size.is_equal_approx(Vector2(dimensions)), "Real scene anchors deliver Window resize to main " + name)
		var compact: bool = dimensions.x == 884
		var expected := Vector2(1120, 1180) if compact else Vector2(1440, 960)
		check(app.canvas.size.is_equal_approx(expected), "Resized signal selects intended compact/desktop layout " + name)
		check(window.grow(0.1).encloses(app.canvas.get_global_rect()), "Complete canvas fits actual Window " + name)
		check(window.grow(0.1).encloses(app.parser.get_global_rect()), "Parser remains inside actual Window " + name)
		check(window.grow(0.1).encloses(app.inventory_scroll.get_global_rect()), "Pocket viewport remains inside actual Window " + name)
		check(not app.dialogue.get_global_rect().intersects(app.scene_area.get_global_rect()), "Dialogue clears scene after actual resize " + name)
		check(not app.dialogue.get_global_rect().intersects(app.parser.get_global_rect()), "Dialogue clears parser after actual resize " + name)
		check(app.dialogue.get_theme_font_size("normal_font_size") * app.canvas.scale.x >= 14.0, "Dialogue retains at least 14 rendered pixels " + name)
		check(app.objective_text.size.y > 0.0 and _visible_rect(app.objective_text).size.y > 0.0, "Objective text has visible nonzero height " + name)
		check(not app.objective_text.clip_text, "Scrollable objective retains content-driven height " + name)
		check(not app.objective_text.text.is_empty(), "Objective contains a player-facing goal " + name)
		app.settings_button.pressed.emit()
		await _settle()
		check(is_instance_valid(app.modal), "Actual Options button opens modal " + name)
		var panel: Control = app.modal.get_child(1)
		check(window.grow(0.1).encloses(panel.get_global_rect()), "Options panel fits actual Window " + name)
		var body: Label
		for label in _labels(panel):
			if label.text.begins_with("Keyboard: Tab"):
				body = label
		check(is_instance_valid(body), "Options contains its long keyboard/browser paragraph " + name)
		if is_instance_valid(body):
			check(body.clip_text, "Fixed Options paragraph constrains its width " + name)
			check(body.autowrap_mode != TextServer.AUTOWRAP_OFF and body.get_line_count() > 1, "Options long paragraph wraps " + name)
			check(panel.get_global_rect().grow(0.1).encloses(body.get_global_rect()), "Full Options paragraph rectangle stays inside modal " + name)
			check(body.size.y > 0.0 and body.get_line_count() * body.get_line_height() <= body.size.y + 1.0, "Every wrapped Options line fits its height without clipping " + name)
			check(body.text.ends_with("the same actions."), "Options preserves its final instruction " + name)
		app._close_modal()
		for method in ["_help", "_transcript", "_ending"]:
			app.call(method)
			await _settle()
			var scroll_labels := _scroll_labels(app.modal)
			check(not scroll_labels.is_empty(), "%s contains scrolling content at %s" % [method, name])
			for label in scroll_labels:
				check(label.size.y > 0.0 and not label.clip_text, "%s content expands beyond zero-height construction at %s" % [method, name])
				check(not label.text.is_empty() and _visible_rect(label).size.y > 0.0, "%s content is visible at %s" % [method, name])
				var scroll: ScrollContainer = label.get_parent()
				scroll.scroll_vertical = 100000
				await _settle()
				check(label.get_global_rect().end.y <= scroll.get_global_rect().end.y + 1.0, "%s final content line can scroll into view at %s" % [method, name])
			app._close_modal()
	for path in original:
		var current: Variant = FileAccess.get_file_as_bytes(path) if FileAccess.file_exists(path) else null
		check(current == original[path], "Responsive checks preserve " + path)
	app.queue_free()
	await _settle()
	print("Actual Window responsive layout: %d passed, %d failed" % [assertions - failures.size(), failures.size()])
	quit(0 if failures.is_empty() else 1)
