extends SceneTree
## Real font/layout checks for modal prose colliding with fixed footers.
## Does not load, save, or advance the player's adventure.

const MainScene = preload("res://scenes/main.tscn")
var failures: Array[String] = []
var assertions := 0


func _init() -> void:
	_run.call_deferred()


func _check(condition: bool, description: String) -> void:
	assertions += 1
	if not condition:
		failures.append(description)
		printerr("FAIL: " + description)


func _labels(parent: Node) -> Array[Label]:
	var result: Array[Label] = []
	for child in parent.get_children():
		if child is Label:
			result.append(child)
		result.append_array(_labels(child))
	return result


func _visible_rect(control: Control) -> Rect2:
	var rect := control.get_global_rect()
	var ancestor := control.get_parent()
	while ancestor is Control:
		if ancestor.clip_contents:
			rect = rect.intersection(ancestor.get_global_rect())
		ancestor = ancestor.get_parent()
	return rect


func _run() -> void:
	var app = MainScene.instantiate()
	root.add_child(app)
	await process_frame
	await process_frame
	for viewport in [Vector2(1440, 960), Vector2(884, 886), Vector2(1280, 720)]:
		app.size = viewport
		app._fit()
		# Advance only the objective's prerequisites, leaving player saves alone.
		app.game.new_game()
		var milestones := ["", "promotion_brief", "whiskey_given", "password_spoken", "tv_distracted", "taken_candy", "pass", "dancer_met", "danced", "gift_ring", "gift_flowers", "gift_candy", "phone_known", "phone_called", "rope_taken", "rope_anchored", "window_open", "penthouse_access", "eve_met", "apple_grown", "apple_given", "eve_story_shared", "eve_heard", "completed"]
		for milestone in milestones:
			if milestone == "pass":
				app.game.inventory.append("pass")
			elif milestone == "completed":
				app.game.completed = true
			elif not milestone.is_empty():
				app.game.flags[milestone] = true
			app.objective_text.text = app.game.objective()
			await process_frame
			var plan: Control
			var pockets: Label
			for child in app.canvas.get_children():
				if child is Panel and child.position == Vector2(20, 325):
					plan = child
				if child is Label and child.text == "POCKETS":
					pockets = child
			_check(plan.get_global_rect().encloses(app.objective_scroll.get_global_rect()), "Objective viewport remains inside plan card after '%s' at %s" % [milestone, viewport])
			_check(not _visible_rect(app.objective_text).intersects(pockets.get_global_rect()), "Visible objective clears pockets after '%s' at %s" % [milestone, viewport])
			app.objective_scroll.scroll_vertical = 100000
			await process_frame
			_check(app.objective_text.get_global_rect().end.y <= app.objective_scroll.get_global_rect().end.y + 1, "Objective can scroll its final line into view after '%s' at %s" % [milestone, viewport])
		for method in ["_help", "_journal", "_map", "_new_game_prompt", "_ending", "_settings", "_transcript"]:
			app.call(method)
			await process_frame
			await process_frame
			var panel: Control = app.modal.get_child(1)
			var labels := _labels(panel)
			_check(not labels[0].get_global_rect().intersects(labels[1].get_global_rect()), "%s title does not overlap subtitle at %s" % [method, viewport])
			for label in labels:
				for child in panel.get_children():
					if child is Button:
						_check(not _visible_rect(label).intersects(child.get_global_rect()), "%s text '%s' clears button '%s' at %s" % [method, label.text.left(20), child.text, viewport])
			if method == "_help":
				var body: Label = labels.back()
				_check(body.text.ends_with("stays suggestive and consensual. Polyester remains inexcusable."), "Help preserves its final paragraph")
				if body.get_parent() is ScrollContainer:
					var scroll: ScrollContainer = body.get_parent()
					scroll.scroll_vertical = 10000
					await process_frame
					_check(body.get_global_rect().end.y <= scroll.get_global_rect().end.y + 1, "Help can scroll its final line into view")
			if method == "_ending":
				var body: Label = labels[2]
				var score: Label = labels[3]
				_check(body.get_parent() is ScrollContainer, "Ending prose has its own scroll viewport at %s" % viewport)
				_check(not _visible_rect(body).intersects(score.get_global_rect()), "Visible ending prose clears score row at %s" % viewport)
				_check(body.text.contains("LATER THAT MORNING"), "Ending includes the route epilogue at %s" % viewport)
				var scroll: ScrollContainer = body.get_parent()
				scroll.scroll_vertical = 100000
				await process_frame
				_check(body.get_global_rect().end.y <= scroll.get_global_rect().end.y + 1, "Ending can scroll its final callback into view at %s" % viewport)
			_check(Rect2(Vector2.ZERO, app.size).encloses(panel.get_global_rect()), "%s panel fits the actual window at %s" % [method, viewport])
	app._close_modal()
	app.queue_free()
	await process_frame
	print("Modal layout: %d assertions, %d failures" % [assertions, failures.size()])
	quit(1 if not failures.is_empty() else 0)
