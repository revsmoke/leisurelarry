extends SceneTree
## Regression coverage for actions discovered during the browser playthrough.
## UI callbacks run with autosave/music/automation disabled; user saves are untouched.
const GameState = preload("res://scripts/game_state.gd")

class IsolatedMain:
	extends "res://scripts/main.gd"
	func _autosave() -> void:
		pass
	func _start_music() -> void:
		pass
	func _automation() -> void:
		pass

var failures: Array[String] = []
var assertions := 0

func _init() -> void:
	_run.call_deferred()

func _check(condition: bool, description: String) -> void:
	assertions += 1
	if not condition:
		failures.append(description)
		printerr("FAIL: " + description)

func _progress(game: RefCounted) -> Dictionary:
	# A refused action may count as a turn, but may not spend money/items or advance a quest.
	return {"cash": game.cash, "inventory": game.inventory.duplicate(), "flags": game.flags.duplicate(true), "score": game.score, "completed": game.completed, "journal": game.journal.duplicate()}

func _refused_take(game: RefCounted, target: String, held: String = "") -> void:
	var before := _progress(game)
	var message: String = game.interact(target, "take", held)
	_check(not message.is_empty() and _progress(game) == before, "TAKE %s cannot perform USE or TALK, even with %s ready" % [target, held if not held.is_empty() else "quest prerequisites"])

func _wrong_item(game: RefCounted, item: String, target: String) -> void:
	var before := _progress(game)
	var message: String = game.interact(target, "use", item)
	_check(not message.is_empty() and _progress(game) == before, "Wrong item %s on %s preserves inventory and progress" % [item, target])

func _run() -> void:
	var game = GameState.new()
	game.room = "bar"
	_refused_take(game, "bartender")
	var before := _progress(game)
	game.command("take lefty")
	_check(_progress(game) == before, "Parser TAKE LEFTY does not buy whiskey")
	game.command("buy whiskey")
	_check(game.cash == 70 and game.inventory.has("whiskey"), "Explicit BUY WHISKEY still purchases one drink")
	_wrong_item(game, "whiskey", "bartender")
	game.interact("patron", "use", "whiskey")
	_check(not game.inventory.has("whiskey") and game.inventory.has("remote"), "Correct whiskey trade still consumes drink and awards remote")

	game.room = "disco"
	game.flags["dancer_met"] = true
	_refused_take(game, "dancer")
	_refused_take(game, "dancefloor")
	before = _progress(game)
	game.command("take didi")
	_check(_progress(game) == before, "Parser TAKE DIDI does not dance")
	game.interact("dancefloor", "use")
	_check(game.flags.get("danced", false), "USE dance floor still performs the dance after introduction")
	game.inventory.append("ring")
	_wrong_item(game, "ring", "phone")

	game.room = "rooftop"
	game.flags.merge({"eve_met": true, "apple_given": true, "eve_story_shared": true, "eve_heard": true}, true)
	_refused_take(game, "eve")
	before = _progress(game)
	game.command("take eve")
	_check(_progress(game) == before and not game.completed, "Parser TAKE EVE cannot finish the game")
	game.interact("eve", "talk")
	_check(game.completed, "The intended final TALK still completes the story")

	game = GameState.new()
	game.room = "balcony"
	game.inventory.append("hammer")
	_refused_take(game, "window")
	_refused_take(game, "window", "hammer")
	game.interact("window", "use", "hammer")
	_check(game.flags.get("window_open", false), "USE mallet on window still opens it")
	game.room = "penthouse"
	game.inventory.append("pitcher")
	_refused_take(game, "sink")
	_refused_take(game, "sink", "pitcher")
	game.interact("sink", "use", "pitcher")
	_check(game.flags.get("pitcher_filled", false), "USE pitcher on sink still fills it")
	game.room = "garden"
	game.inventory.append("seeds")
	game.flags["newspaper_read"] = true
	_refused_take(game, "planter")
	_refused_take(game, "planter", "seeds")
	_wrong_item(game, "hammer", "planter")
	game.interact("planter", "use", "seeds")
	_check(game.flags.get("seeds_planted", false) and not game.inventory.has("seeds"), "USE seeds on planter still plants them")
	_refused_take(game, "planter")
	_refused_take(game, "planter", "pitcher")
	game.interact("planter", "use", "pitcher")
	_check(game.flags.get("apple_grown", false) and not game.flags.get("pitcher_filled", false), "USE full pitcher still waters the planter")

	var app := IsolatedMain.new()
	root.add_child(app)
	await process_frame
	app.game.room = "disco"
	app.game.flags["dancer_met"] = true
	app._render()
	app._set_verb("take")
	app._hotspot_click(app.game.get_hotspot("dancer"))
	_check(not app.game.flags.get("danced", false) and app.larry.dance_time_left == 0.0, "Real TAKE Didi callback does not start model or visual dance")
	app._set_verb("use")
	app._hotspot_click(app.game.get_hotspot("dancefloor"))
	_check(app.game.flags.get("danced", false) and app.larry.dance_time_left > 0.0, "Real USE floor callback starts the dance and its animation")
	app._move_larry(Vector2(700, 490))
	_check(app.larry.dance_time_left == 0.0 and app.larry.walking, "Walking cancels dance animation")
	app._command("dance")
	_check(app.larry.dance_time_left > 0.0, "Parser repeat dance replays the animation")
	app.game.room = "garden"
	app._render()
	_check(app.larry.dance_time_left == 0.0, "Changing rooms cancels dance animation")
	_check(app.world_effects.visible and not app.world_effects.seeds_planted and not app.world_effects.apple_grown, "Fresh garden does not display planted seeds or a tree")
	app.game.inventory.append("seeds")
	app.game.flags["newspaper_read"] = true
	app._render()
	app._select_item("seeds")
	app._hotspot_click(app.game.get_hotspot("planter"))
	_check(app.world_effects.seeds_planted and not app.world_effects.apple_grown, "Planting via UI refreshes seed markers without a premature tree")
	app.game.inventory.append("pitcher")
	app.game.flags["pitcher_filled"] = true
	app._render()
	app._select_item("pitcher")
	app._hotspot_click(app.game.get_hotspot("planter"))
	_check(app.world_effects.apple_grown and not app.world_effects.apple_taken and app.world_effects.growth < 1.0, "Watering via UI starts a fruit-bearing tree growth animation")
	var tree_spot: Dictionary = app.game.get_hotspot("tree")
	var planter_spot: Dictionary = app.game.get_hotspot("planter")
	_check(absf(float(tree_spot.x) - float(planter_spot.x)) < 0.01 and float(tree_spot.y) < float(planter_spot.y), "Apple tree target sits over its planter rather than the fountain")
	app._set_verb("take")
	app._hotspot_click(tree_spot)
	_check(app.game.inventory.has("apple") and app.world_effects.apple_taken and app.world_effects.apple_grown, "Taking fruit via UI removes the visible apple and retains the tree")
	app.game.room = "street"
	app._render()
	_check(not app.world_effects.visible, "Garden effects do not follow Larry into other rooms")
	app.game.room = "garden"
	app._render()
	_check(app.world_effects.visible and app.world_effects.apple_taken and app.world_effects.growth == 1.0, "Returning restores the mature, picked tree without replaying growth")
	app.game.new_game()
	app._render()
	_check(not app.world_effects.seeds_planted and not app.world_effects.apple_grown and not app.world_effects.apple_taken, "New evening clears all garden visual state")
	app.queue_free()
	await process_frame
	print("Action intent regression checks: %d passed, %d failed" % [assertions - failures.size(), failures.size()])
	quit(0 if failures.is_empty() else 1)
