extends Control
## Original tiny pixel actors, animated in Godot rather than baked into the scenery.
signal label_bounds_changed
const NPCAnimation = preload("res://scripts/npc_animation.gd")
const BarArt = preload("res://scripts/bar_actor_art.gd")
var npc_animation := NPCAnimation.new()
var gesture_pose: Dictionary = {}
var drawing_head := false
var body_transform := Transform2D.IDENTITY
var suit := Color("f3e6ce")
var hair := Color("403349")
var skin := Color("dca483")
var shirt := Color("ef6a9d")
var walking := false:
	set(value):
		walking = value
		_update_processing()
		queue_redraw()
var is_larry := true
var role := "larry"
## Optional adult partners use romance_guest plus this presentation-only gender.
var gender := "male"
var seated := false
var tick := 0.0
var dance_time_left := 0.0
var dance_elapsed := 0.0
var dance_style := "confident"
var reduced_motion := false
var reaction: Dictionary = {}

func label_obstacle() -> Rect2:
	# Drawing uses three-unit pixel blocks around the feet, not Control.size.
	# Include hair, hats and raised hands so labels never sit on the silhouette.
	return Rect2(-90, -190, 180, 210) if role.begins_with("bar_") else Rect2(-84, -178, 168, 190)

func _ready() -> void:
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	set_notify_local_transform(true)
	_update_processing()

func _notification(what: int) -> void:
	if what == NOTIFICATION_LOCAL_TRANSFORM_CHANGED:
		label_bounds_changed.emit()

func _process(delta: float) -> void:
	tick += delta
	npc_animation.advance(delta)
	if dance_time_left > 0.0:
		dance_time_left = maxf(0.0, dance_time_left - delta)
		dance_elapsed += delta
	_update_processing()
	queue_redraw()

func _update_processing() -> void:
	set_process(walking or dance_time_left > 0.0 or npc_animation.active())

func hover_react() -> void:
	if npc_animation.hover(role):
		_update_processing()
		queue_redraw()

func interact_react(action: String) -> void:
	npc_animation.interact(action)
	_update_processing()
	queue_redraw()

func dance(seconds: float = 2.6) -> void:
	walking = false
	dance_elapsed = 0.0
	dance_time_left = maxf(seconds, 0.0)
	_update_processing()
	queue_redraw()

func stop_dance() -> void:
	dance_time_left = 0.0
	_update_processing()
	queue_redraw()

func set_reduced_motion(value: bool) -> void:
	reduced_motion = value
	queue_redraw()

func set_dance_style(value: String) -> void:
	dance_style = value if value in ["confident", "careful", "copy"] else "confident"
	queue_redraw()

func sync_reaction(flags: Dictionary) -> void:
	reaction = flags.duplicate(true)
	queue_redraw()

func block(x: float, y: float, w: float, h: float, color: Color) -> void:
	var offset: Vector2 = gesture_pose.get("head", Vector2.ZERO) if drawing_head else Vector2.ZERO
	draw_rect(Rect2((Vector2(x, y) + offset) * 3, Vector2(w, h) * 3), color)

func _draw() -> void:
	gesture_pose = npc_animation.pose(reduced_motion)
	drawing_head = false
	var dancing := dance_time_left > 0.0
	var beat := 0.65 if reduced_motion else dance_elapsed * (6.0 if dance_style == "careful" else 10.5 if dance_style == "copy" else 9.5)
	var stride := sin(beat) * 3.0 if dancing else sin(tick * 12.0) * 2.0 if walking and not reduced_motion else 0.0
	draw_set_transform(Vector2(0, -3), 0, Vector2(1.0, 0.25))
	draw_circle(Vector2.ZERO, 26, Color(0.01, 0.01, 0.03, 0.45))
	# Move the drawing, not the Control: walking tweens retain their stage position.
	var body_offset := Vector2(sin(beat) * (3.0 if dance_style == "careful" else 8.0), -absf(sin(beat)) * 7.0) if dancing and not reduced_motion else Vector2.ZERO
	body_offset += Vector2(gesture_pose.get("offset", Vector2.ZERO))
	body_transform = Transform2D(sin(beat) * 0.065 if dancing and not reduced_motion else 0.0, body_offset)
	draw_set_transform_matrix(body_transform)
	if role.begins_with("bar_"):
		BarArt.draw(self, stride)
		_draw_reaction()
		return
	if role == "lisa":
		_draw_lisa(stride, dancing, beat)
		_draw_reaction()
		return
	if role == "adam":
		_draw_adam(stride)
		_draw_reaction()
		return
	if role in ["dancer", "eve", "receptionist"] or (role == "romance_guest" and gender == "female"):
		_draw_guest(stride)
		_draw_reaction()
		return
	block(-6, -17, 5, 15 + stride, suit.darkened(0.12))
	block(1, -17, 5, 15 - stride, suit)
	block(-7, -3 + stride, 7, 3, Color("402f48"))
	block(1, -3 - stride, 7, 3, Color("402f48"))
	block(-7, -32, 14, 17, suit)
	block(-3, -32, 6, 11, shirt)
	block(-5, -32, 3, 6, suit.lightened(0.15))
	block(2, -32, 3, 6, suit.lightened(0.15))
	block(-3, -21, 6, 2, Color("d7b45f"))
	if _draw_gesture_arms(suit):
		pass
	elif dancing and dance_style == "careful":
		# Hands at waist, little steps: every move has passed a risk assessment.
		block(-12, -27, 5, 6, suit)
		block(-10, -22, 7, 4, skin)
		block(7, -27, 5, 6, suit)
		block(4, -22, 7, 4, skin)
	elif dancing and dance_style == "copy":
		# Both arms follow Didi's broad, theatrical invitation.
		block(-16, -31, 11, 5, suit)
		block(-19, -35, 5, 7, skin)
		block(6, -31, 11, 5, suit)
		block(15, -35, 5, 7, skin)
	elif dancing:
		# A deliberately stiff disco point: The Nervous Accountant.
		var point_left := sin(beat * 0.5) >= 0.0
		block(-12, -37 if point_left else -27, 5, 10, suit.darkened(0.06))
		block(-16, -42 if point_left else -23, 7, 5, suit)
		block(-18, -47 if point_left else -22, 4, 6, skin)
		block(7, -27 if point_left else -37, 5, 10, suit)
		block(10, -23 if point_left else -42, 7, 5, suit)
		block(15, -22 if point_left else -47, 4, 6, skin)
	else:
		block(-10, -30 - stride * 0.3, 4, 16, suit.darkened(0.06))
		block(6, -30 + stride * 0.3, 4, 16, suit)
		block(-10, -15 - stride * 0.3, 4, 4, skin)
		block(6, -15 + stride * 0.3, 4, 4, skin)
	drawing_head = true
	if is_larry and role == "larry":
		_draw_larry_profile()
		drawing_head = false
		block(-4, -27, 1, 5, Color("e7bb56"))
		block(3, -26, 3, 1, Color("eaddc8"))
		_draw_reaction()
		return
	block(-3, -35, 6, 4, skin.darkened(0.08))
	block(-6, -45, 12, 11, skin)
	block(6, -41, 3, 4, skin)
	block(-7, -47, 13, 4, hair)
	block(-7, -44, 3, 7, hair)
	block(-5, -48, 8, 2, hair)
	if is_larry and role == "larry":
		block(-1, -45, 6, 2, skin)
	if role == "bouncer" and reaction.get("tv_distracted", false):
		block(-5, -43, 11, 8, hair)
		block(5, -40, 3, 4, skin)
	else:
		_draw_eye(3, -41)
	block(2, -36, 4, float(gesture_pose.get("mouth", 1.0)), Color("9b5262"))
	drawing_head = false
	if is_larry and role == "larry":
		block(-4, -27, 1, 5, Color("e7bb56"))
		block(3, -26, 3, 1, Color("eaddc8"))
		block(1, -43, 4, 1, hair)
	if role == "busker":
		drawing_head = true
		block(-8, -48, 16, 2, Color("332c3e"))
		block(-5, -52, 10, 5, Color("332c3e"))
		drawing_head = false
	if role == "bartender":
		block(-6, -25, 12, 14, Color("e7d4b2"))
	_draw_reaction()

func _draw_larry_profile() -> void:
	# The supplied side view: big nose, receding black pompadour and a small
	# determined chin above that preposterous white collar. Still fully animated.
	var locks := Color("242337")
	block(-3, -35, 6, 4, skin.darkened(0.10))
	block(-7, -48, 14, 13, skin)
	block(-8, -49, 13, 4, locks)
	block(-10, -46, 6, 11, locks)
	block(-8, -51, 9, 3, locks)
	block(-3, -50, 7, 3, locks)
	block(1, -48, 6, 4, skin.lightened(0.08))
	block(-5, -42, 3, 4, skin.darkened(0.16))
	block(6, -41, 5, 4, skin)
	block(10, -39, 2, 2, skin.lightened(0.07))
	block(3, -36, 6, 2, skin)
	block(2, -44, 5, 1, locks)
	_draw_eye(5, -42)
	block(5, -36, 4, float(gesture_pose.get("mouth", 1.0)), Color("9b5262"))

func _draw_lisa(stride: float, dancing: bool, beat: float) -> void:
	# A grown-up disco heroine: feathered hair, white flares and an enormous
	# collar. Her silhouette is clothing and attitude, never exposed anatomy.
	var locks := Color("713e4e")
	block(-9, -43, 17, 18, locks.darkened(0.17))
	block(-5, -19, 5, 13 + stride, suit.darkened(0.08))
	block(1, -19, 5, 13 - stride, suit)
	block(-8, -9 + stride, 8, 8, suit.darkened(0.08))
	block(1, -9 - stride, 8, 8, suit)
	block(-8, -2 + stride, 8, 2, Color("51405e"))
	block(1, -2 - stride, 9, 2, Color("51405e"))
	block(-7, -32, 14, 10, suit)
	block(-5, -23, 10, 8, suit)
	block(-4, -31, 8, 11, Color("bd5288"))
	block(-7, -32, 4, 8, suit.lightened(0.12))
	block(3, -32, 4, 8, suit.lightened(0.12))
	block(-5, -21, 10, 2, Color("d7b45f"))
	block(-1, -22, 3, 3, Color("f5d691"))
	if _draw_gesture_arms(suit):
		pass
	elif dancing:
		var small := dance_style == "careful"
		var high_left := sin(beat * 0.5) >= 0.0
		block(-11, -31 if small else -38 if high_left else -29, 5, 12, suit)
		block(7, -31 if small else -29 if high_left else -38, 5, 12, suit)
		block(-12, -24 if small else -41 if high_left else -19, 5, 5, skin)
		block(8, -24 if small else -19 if high_left else -41, 5, 5, skin)
	else:
		block(-10, -30 - stride * 0.3, 4, 16, suit.darkened(0.06))
		block(6, -30 + stride * 0.3, 4, 16, suit)
		block(-10, -15 - stride * 0.3, 4, 4, skin)
		block(6, -15 + stride * 0.3, 4, 4, skin)
	drawing_head = true
	block(-3, -35, 6, 4, skin.darkened(0.08))
	block(-5, -45, 11, 11, skin)
	block(6, -40, 2, 3, skin)
	block(-7, -48, 13, 5, locks)
	block(-9, -45, 5, 9, locks)
	block(-11, -39, 5, 5, locks)
	block(-10, -35, 4, 4, locks)
	block(4, -45, 5, 4, locks)
	block(7, -40, 3, 6, locks)
	block(6, -35, 5, 4, locks)
	block(-5, -47, 7, 2, Color("ad6871"))
	_draw_eye(2, -41)
	block(1, -43, 4, 1, locks)
	block(2, -36, 4, float(gesture_pose.get("mouth", 1.0)), Color("ac365d"))
	block(-5, -35, 2, 3, Color("f4ce80"))
	drawing_head = false

func _draw_adam(stride: float) -> void:
	var trousers := Color("45394f")
	var jacket := Color("4e9b92")
	block(-6, -18, 5, 16 + stride, trousers)
	block(1, -18, 5, 16 - stride, trousers.lightened(0.08))
	block(-7, -3 + stride, 7, 3, Color("30263b"))
	block(1, -3 - stride, 7, 3, Color("30263b"))
	block(-8, -33, 16, 17, jacket)
	block(-3, -33, 6, 12, Color("eee1c6"))
	block(-6, -33, 3, 7, jacket.lightened(0.2))
	block(3, -33, 3, 7, jacket.lightened(0.2))
	if not _draw_gesture_arms(jacket):
		block(-11, -31 - stride * 0.3, 4, 17, jacket.darkened(0.1))
		block(7, -31 + stride * 0.3, 4, 17, jacket)
		block(-11, -15 - stride * 0.3, 4, 4, skin)
		block(7, -15 + stride * 0.3, 4, 4, skin)
	block(-6, -19, 12, 2, Color("d7b45f"))
	drawing_head = true
	block(-3, -36, 6, 4, skin)
	block(-6, -46, 12, 11, skin)
	block(6, -42, 3, 4, skin)
	block(-7, -49, 14, 5, Color("5c3a3b"))
	block(-8, -46, 3, 8, Color("5c3a3b"))
	block(-5, -47, 9, 2, Color("9c6b55"))
	_draw_eye(3, -42)
	block(1, -44, 4, 1, Color("5c3a3b"))
	block(-1, -37, 7, 2, Color("6c4143"))
	block(2, -36, 3, float(gesture_pose.get("mouth", 1.0)), skin if gesture_pose.is_empty() else Color("9b5262"))
	drawing_head = false

func _draw_guest(stride: float = 0.0) -> void:
	var dress := Color("dc789e") if role == "eve" else suit if role == "romance_guest" else Color("57bbb8")
	var locks := Color("5d3048") if role == "eve" else hair if role == "romance_guest" else Color("d4a667")
	block(-5, -15, 4, 12 + stride, skin)
	block(2, -15, 4, 12 - stride, skin)
	block(-7, -3 + stride, 6, 3, Color("34273e"))
	block(1, -3 - stride, 7, 3, Color("34273e"))
	block(-7, -32, 14, 14, dress)
	block(-9, -21, 18, 8, dress.darkened(0.1))
	block(-3, -34, 6, 4, skin)
	if not _draw_gesture_arms(dress, true):
		block(-8, -29, 3, 16, skin)
		block(6, -29, 3, 16, skin)
		block(-9, -32, 5, 6, dress)
		block(5, -32, 5, 6, dress)
	drawing_head = true
	block(-5, -44, 11, 11, skin)
	block(-7, -47, 13, 5, locks)
	block(-8, -44, 4, 13, locks)
	block(5, -43, 3, 9, locks)
	_draw_eye(1, -41)
	block(4, -36, 2, float(gesture_pose.get("mouth", 1.0)), Color("ae405b"))
	block(-5, -33, 2, 2, Color("f5cb75"))
	drawing_head = false
	block(-5, -21, 10, 2, Color("efc269"))
	if role == "receptionist":
		block(-4, -30, 8, 4, Color("eee1c6"))

func _draw_eye(x: float, y: float) -> void:
	block(x, y, 2, 1 if gesture_pose.get("blink", false) else 2, Color("26223b"))
	if gesture_pose.get("brow", false): block(x - 1, y - 3, 4, 1, hair)

func _draw_gesture_arms(sleeve: Color, bare: bool = false) -> bool:
	if gesture_pose.is_empty(): return false
	for side in [-1, 1]:
		var angle := deg_to_rad(float(gesture_pose.left if side < 0 else gesture_pose.right))
		draw_set_transform_matrix(body_transform * Transform2D(angle, Vector2(side * 24, -90)))
		draw_rect(Rect2(-6, 0, 12, 42), skin if bare else sleeve)
		if bare: draw_rect(Rect2(-7, 0, 14, 12), sleeve)
		draw_rect(Rect2(-6, 39, 12, 12), skin)
	draw_set_transform_matrix(body_transform)
	if gesture_pose.get("cloth", false):
		block(-3, -22, 6, 5, Color("eee1c6"))
	return true


func _draw_reaction() -> void:
	if role == "bartender" and reaction.get("whiskey_given", false):
		block(8, -24, 5, 4, skin)
		block(11, -30, 5, 10, Color("bb8249"))
		block(12, -34, 3, 5, Color("dcca97"))
		block(11, -27, 5, 3, Color("c35678"))
	if role in ["eve", "adam"] and reaction.get("apple_given", false):
		block(-12, -26, 7, 4, skin)
		block(-14, -31, 6, 6, Color("e95968"))
		block(-12, -33, 2, 3, Color("d0b877"))
	if role == "receptionist" and (reaction.get("coffee_delivered", false) or reaction.get("award_coffee_given", false)):
		block(7, -24, 5, 4, skin)
		block(10, -29, 6, 7, Color("eee1c6"))
		block(10, -30, 6, 2, Color("543441"))
	if role == "dancer" and reaction.get("rehearsal_started", false):
		block(-14, -34, 8, 4, skin)
		block(-16, -40, 4, 7, skin)
	if role == "dancer" and reaction.get("show_started", false):
		block(7, -30, 8, 4, skin)
		block(13, -35, 4, 8, Color("322b43"))
		block(12, -37, 6, 4, Color("d5c4b3"))
