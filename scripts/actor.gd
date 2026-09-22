extends Control
## Original tiny pixel actors, animated in Godot rather than baked into the scenery.
var suit := Color("f3e6ce")
var hair := Color("403349")
var skin := Color("dca483")
var shirt := Color("ef6a9d")
var walking := false
var is_larry := true
var role := "larry"
var tick := 0.0
var dance_time_left := 0.0
var dance_elapsed := 0.0

func _ready() -> void:
	mouse_filter = Control.MOUSE_FILTER_IGNORE

func _process(delta: float) -> void:
	tick += delta
	if dance_time_left > 0.0:
		dance_time_left = maxf(0.0, dance_time_left - delta)
		dance_elapsed += delta
	queue_redraw()

func dance(seconds: float = 2.6) -> void:
	walking = false
	dance_elapsed = 0.0
	dance_time_left = maxf(seconds, 0.0)
	queue_redraw()

func stop_dance() -> void:
	dance_time_left = 0.0
	queue_redraw()

func block(x: float, y: float, w: float, h: float, color: Color) -> void:
	draw_rect(Rect2(x * 3, y * 3, w * 3, h * 3), color)

func _draw() -> void:
	var dancing := dance_time_left > 0.0
	var beat := dance_elapsed * 9.5
	var stride := sin(beat) * 3.0 if dancing else sin(tick * 12.0) * 2.0 if walking else 0.0
	draw_set_transform(Vector2(0, -3), 0, Vector2(1.0, 0.25))
	draw_circle(Vector2.ZERO, 26, Color(0.01, 0.01, 0.03, 0.45))
	# Move the drawing, not the Control: walking tweens retain their stage position.
	draw_set_transform(Vector2(sin(beat) * 8.0, -absf(sin(beat)) * 7.0) if dancing else Vector2.ZERO, sin(beat) * 0.065 if dancing else 0.0)
	if role in ["dancer", "eve", "receptionist"]:
		_draw_guest()
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
	if dancing:
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
	block(-3, -35, 6, 4, skin.darkened(0.08))
	block(-6, -45, 12, 11, skin)
	block(6, -41, 3, 4, skin)
	block(-7, -47, 13, 4, hair)
	block(-7, -44, 3, 7, hair)
	block(-5, -48, 8, 2, hair)
	if is_larry:
		block(-1, -45, 6, 2, skin)
	block(3, -41, 2, 2, Color("26223b"))
	block(2, -36, 4, 1, Color("9b5262"))
	if is_larry:
		block(-4, -27, 1, 5, Color("e7bb56"))
		block(3, -26, 3, 1, Color("eaddc8"))
		block(1, -43, 4, 1, hair)
	if role == "busker":
		block(-8, -48, 16, 2, Color("332c3e"))
		block(-5, -52, 10, 5, Color("332c3e"))
	if role == "bartender":
		block(-6, -25, 12, 14, Color("e7d4b2"))

func _draw_guest() -> void:
	var dress := Color("dc789e") if role == "eve" else Color("57bbb8")
	var locks := Color("5d3048") if role == "eve" else Color("d4a667")
	block(-5, -15, 4, 12, skin)
	block(2, -15, 4, 12, skin)
	block(-7, -3, 6, 3, Color("34273e"))
	block(1, -3, 7, 3, Color("34273e"))
	block(-7, -32, 14, 14, dress)
	block(-9, -21, 18, 8, dress.darkened(0.1))
	block(-3, -34, 6, 4, skin)
	block(-8, -29, 3, 16, skin)
	block(6, -29, 3, 16, skin)
	block(-9, -32, 5, 6, dress)
	block(5, -32, 5, 6, dress)
	block(-5, -44, 11, 11, skin)
	block(-7, -47, 13, 5, locks)
	block(-8, -44, 4, 13, locks)
	block(5, -43, 3, 9, locks)
	block(1, -41, 2, 2, Color("282039"))
	block(4, -36, 2, 1, Color("ae405b"))
	block(-5, -33, 2, 2, Color("f5cb75"))
	block(-5, -21, 10, 2, Color("efc269"))
	if role == "receptionist":
		block(-4, -30, 8, 4, Color("eee1c6"))
