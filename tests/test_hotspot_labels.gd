extends SceneTree
## Exercise the rendered UI and actual pixel-head extents, without player saves.
class TestMain:
	extends "res://scripts/main.gd"
	func _autosave() -> void: pass
	func _start_music() -> void: pass
	func _automation() -> void: pass
	func _load_preferences() -> void: pass
	func _save_preferences() -> void: pass

var checks := 0
var failures: Array[String] = []

func _settle() -> void:
	await process_frame
	await process_frame

func _layout_checks(app: Control, context: String) -> void:
	var visible_scene: Rect2 = app.scene_area.get_global_rect().intersection(Rect2(Vector2.ZERO, root.get_visible_rect().size))
	var labels: Array[Rect2] = []
	var faces: Array[Rect2] = []
	for actor in app.actors.get_children():
		# Cover the head/hair of the actual 3-unit pixel sprites, independent of
		# the production label obstacle (which also reserves shoulders and hands).
		faces.append(actor.get_global_transform() * Rect2(-24, -156, 51, 63))
	var on_screen := true
	var faces_clear := true
	var labels_clear := true
	for button in app.hotspots.get_children():
		var rect: Rect2 = button.get_global_rect()
		on_screen = on_screen and visible_scene.grow(0.1).encloses(rect)
		for face in faces: faces_clear = faces_clear and not rect.intersects(face)
		for other in labels: labels_clear = labels_clear and not rect.intersects(other)
		labels.append(rect)
	check(on_screen, context + ": labels stay inside the visible scene")
	check(faces_clear, context + ": every character head stays unobstructed")
	check(labels_clear, context + ": labels remain separate click targets")

func _init() -> void: _run.call_deferred()

func check(ok: bool, description: String) -> void:
	checks += 1
	if not ok:
		failures.append(description)
		printerr("FAIL: " + description)

func _run() -> void:
	var app := TestMain.new()
	root.add_child(app)
	await process_frame
	app.game.configure_profile("lisa", "bisexual")
	app.game.room = "rooftop"
	app._render()
	await process_frame
	var adam: Control
	var label: Button
	for actor in app.actors.get_children():
		if actor.role == "adam": adam = actor
	for button in app.hotspots.get_children():
		if button.get_meta("hotspot_id", "") == "eve": label = button
	check(is_instance_valid(adam) and is_instance_valid(label), "Real rooftop contains Adam and his hotspot")
	# Adam's face is painted by block(-6,-46,12,11) plus the nose;
	# each pixel block is three local units. This is independent of placement.
	var face: Rect2 = adam.get_global_transform() * Rect2(-18, -138, 45, 36)
	check(not label.get_global_rect().intersects(face), "Adam's hotspot does not cover his actual face")
	# Check real Window resize, both cast variants, compact '+' hotspots, crowded
	# rooms, and extra visible props. No scene-specific position exceptions.
	for dimensions in [Vector2i(1440, 960), Vector2i(884, 886)]:
		root.size = dimensions
		await _settle()
		for character in ["larry", "lisa"]:
			app.game.new_game()
			app.game.configure_profile(character, "bisexual")
			app.game.flags = {"stool_placed": true, "window_open": true, "apple_grown": true}
			for room in app.game.rooms:
				app.game.room = room
				for expanded in [true, false]:
					app.show_hotspots = expanded
					app._render()
					await _settle()
					_layout_checks(app, "%s/%s/%s/labels=%s" % [dimensions, character, room, expanded])
	app.show_hotspots = true
	app.game.room = "rooftop"
	app._render()
	await _settle()
	adam = app.actors.get_child(0)
	for button in app.hotspots.get_children():
		if button.get_meta("hotspot_id", "") == "eve": label = button
	var original_position: Vector2 = adam.position
	for position in [Vector2(25, 170), Vector2(1115, 170), Vector2(570, 150), original_position]:
		# Move the actual actor, not the label or placement helper. Its change
		# notification must reflow the existing labels automatically.
		adam.position = position
		await _settle()
		_layout_checks(app, "Moved Adam to " + str(position))
		if position != original_position:
			var body: Rect2 = adam.get_transform() * adam.label_obstacle()
			check(label.get_rect().end.x <= body.position.x or label.position.x >= body.end.x, "Top-edge character automatically receives a side label")
	adam.scale = Vector2.ONE * 1.2
	await _settle()
	_layout_checks(app, "Larger Adam")
	adam.scale = Vector2.ONE * 0.85
	await _settle()
	app._set_verb("look")
	label.pressed.emit()
	await _settle()
	check(app.last_message.contains("Adam has the skyline"), "Repositioned label still invokes Adam's actual interaction")
	app.queue_free()
	await process_frame
	print("Hotspot label checks: %d passed, %d failed" % [checks - failures.size(), failures.size()])
	quit(0 if failures.is_empty() else 1)
