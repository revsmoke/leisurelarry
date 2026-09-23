extends SceneTree
## Real viewport mouse input plus UI/model lifecycle tests; no saves or API calls.
class TestMain:
	extends "res://scripts/main.gd"
	func _autosave() -> void: pass
	func _start_music() -> void: pass
	func _automation() -> void: pass
	func _load_preferences() -> void: pass
	func _save_preferences() -> void: pass

var checks := 0
var failures: Array[String] = []
var app: Control

func _init() -> void: _run.call_deferred()

func check(value: bool, message: String) -> void:
	checks += 1
	if not value:
		failures.append(message)
		printerr("FAIL: " + message)

func settle() -> void:
	await process_frame
	await process_frame

func move_pointer(point: Vector2) -> void:
	var event := InputEventMouseMotion.new()
	event.position = point
	event.global_position = point
	root.push_input(event, true)

func click_at(point: Vector2, button: MouseButton = MOUSE_BUTTON_LEFT) -> void:
	move_pointer(point)
	for pressed in [true, false]:
		var event := InputEventMouseButton.new()
		event.button_index = button
		event.position = point
		event.global_position = point
		event.pressed = pressed
		root.push_input(event, true)

func hotspot(id: String) -> Button:
	for button in app.hotspots.get_children():
		if button.get_meta("hotspot_id", "") == id: return button
	return null

func fingerprint() -> String:
	return JSON.stringify([app.game.room, app.game.profile, app.game.flags, app.game.inventory, app.game.turns, app.game.score, app.game.cash])

func _run() -> void:
	root.size = Vector2i(1440, 960)
	app = TestMain.new()
	app.size = Vector2(1440, 960)
	root.add_child(app)
	await settle()
	app.game.configure_profile("lisa", "bisexual")
	app.game.room = "rooftop"
	app._render()
	await settle()
	root.notify_mouse_entered()
	var adam: Control = app._npc_actor("eve")
	var body: Control = adam.get_node("BodyHitTarget")
	check(hotspot("eve").tooltip_text.is_empty(), "NPC name does not spawn a second tooltip over the face")
	check(str(hotspot("eve").get_meta("accessible_label")).contains("Adam"), "NPC name remains available to compact keyboard controls")
	var before := fingerprint()
	move_pointer(body.get_global_rect().get_center())
	await settle()
	check(root.gui_get_hovered_control() == body, "The actual NPC body receives viewport mouse input")
	check(adam.npc_animation.clip == "wave" and adam.is_processing(), "Entering Adam's body starts a wave")
	var elapsed: float = adam.npc_animation.elapsed
	move_pointer(hotspot("eve").get_global_rect().get_center())
	await settle()
	check(adam.npc_animation.clip == "wave" and adam.npc_animation.elapsed >= elapsed, "Crossing to the label does not restart the gesture")
	adam._process(2.0)
	check(not adam.is_processing(), "Finished gestures stop redraw processing")
	move_pointer(Vector2(280, 200))
	move_pointer(hotspot("eve").get_global_rect().get_center())
	await settle()
	check(adam.npc_animation.clip == "preen", "A later hotspot entry chooses another gesture")
	adam._process(2.0)
	move_pointer(Vector2(280, 200))
	move_pointer(body.get_global_rect().get_center())
	await settle()
	check(adam.npc_animation.clip == "wink", "A third body entry uses the third hover variant")
	check(fingerprint() == before, "Hover gestures never change progress, wallet or turns")
	app.verbs.take.pressed.emit()
	var instance := adam.get_instance_id()
	var turns: int = app.game.turns
	click_at(body.get_global_rect().get_center())
	await settle()
	check(adam.npc_animation.clip == "recoil", "Clicking the body with Take gives a hands-off reaction")
	check(app.last_message.contains("People are not pocket-sized"), "Body click executes the real Take response")
	check(app.game.turns == turns + 1, "A body click executes exactly one game action")
	check(app._npc_actor("eve").get_instance_id() == instance, "Same-room action refresh retains the performing NPC")
	move_pointer(hotspot("eve").get_global_rect().get_center())
	check(adam.npc_animation.clip == "recoil", "Hover cannot interrupt an action reaction")
	app.verbs.use.pressed.emit()
	click_at(hotspot("eve").get_global_rect().get_center())
	await settle()
	check(adam.npc_animation.clip == "offer", "Use on the label triggers the reaching gesture")
	click_at(body.get_global_rect().get_center(), MOUSE_BUTTON_RIGHT)
	await settle()
	check(adam.npc_animation.clip == "brow" and app.last_message.contains("Adam has the skyline"), "Right-clicking the body examines the NPC")
	app.verbs.talk.pressed.emit()
	click_at(body.get_global_rect().get_center())
	await settle()
	check(is_instance_valid(app.modal) and adam.npc_animation.clip == "talk", "Talk opens its real conversation and starts animation")
	var portrait: Control = app.modal.find_child("ConversationActor", true, false)
	check(is_instance_valid(portrait) and portrait.role == "adam" and portrait.npc_animation.clip == "talk", "Dialog shows the correct animated conversation portrait")
	var pose: Dictionary = portrait.npc_animation.pose(false)
	portrait._process(0.3)
	check(portrait.npc_animation.pose(false) != pose, "Talking visibly changes pose over time")
	turns = app.game.turns
	click_at(body.get_global_rect().get_center())
	await settle()
	check(app.game.turns == turns, "An open conversation blocks clicks into the scene")
	app._close_modal()
	app.parser.text_submitted.emit("take adam")
	check(adam.npc_animation.clip == "recoil", "Parser aliases share the same NPC action animation")
	app.reduced_motion = true
	app._render()
	adam.interact_react("talk")
	pose = adam.npc_animation.pose(true)
	adam._process(0.6)
	check(adam.npc_animation.pose(true) == pose, "Reduced motion holds one still pose")
	adam._process(3.0)
	check(adam.npc_animation.pose(true).is_empty() and not adam.is_processing(), "Reduced-motion response expires to idle")
	var old_adam: WeakRef = weakref(adam)
	app.game.room = "bar"
	app._render()
	await settle()
	check(old_adam.get_ref() == null, "Changing rooms frees the old actors and animation state")
	app.parser.text_submitted.emit("buy whiskey")
	var lefty: Control = app._npc_actor("bartender")
	check(lefty.npc_animation.clip == "offer", "Buying from Lefty uses a service gesture rather than hands-off")
	app.parser.text_submitted.emit("talk lefty")
	check(app.modal.find_child("ConversationActor", true, false).role == "bartender", "Conversation portrait changes with the actual speaker")
	app._close_modal()
	# Cover both gender presentations, all NPC roles, repeated UI refreshes,
	# face clearance with the larger gesture envelope, and every action cue.
	for character in ["larry", "lisa"]:
		app.game.configure_profile(character, "bisexual")
		for room in app.game.rooms:
			app.game.room = room
			app._render()
			await settle()
			var count: int = app.actors.get_child_count()
			app._render()
			app._render()
			check(app.actors.get_child_count() == count, "Refresh never duplicates NPCs: " + character + "/" + room)
			for npc in app.actors.get_children():
				for action in ["look", "talk", "take", "use"]:
					npc.interact_react(action)
					npc._process(0.3)
					check(not npc.npc_animation.pose(false).is_empty(), "NPC performs " + action + ": " + npc.role)
					var envelope: Rect2 = npc.get_global_transform() * npc.label_obstacle()
					check(not hotspot(str(npc.get_meta("hotspot_id"))).get_global_rect().intersects(envelope), "Own label clears gesture envelope: " + npc.role)
					npc._process(3.0)
					check(not npc.is_processing(), "NPC returns to idle: " + npc.role)
	app.queue_free()
	await settle()
	print("NPC animation checks: %d passed, %d failed" % [checks - failures.size(), failures.size()])
	quit(0 if failures.is_empty() else 1)
