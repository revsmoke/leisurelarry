extends RefCounted
## Five original pixel patrons, drawn in the actor's three-unit block grid.
## Stool, clothes and poses are presentation only. The actor owns animation.

const INK := Color("27243b")
const WHITE := Color("ece4d8")
const BLUE := Color("465ac1")
const PINK := Color("cf448f")
const BRASS := Color("c8a56b")

static func draw(actor: Control, stride: float) -> void:
	actor.drawing_head = false
	if actor.seated:
		_stool(actor)
	match actor.role:
		"bar_quiff": _quiff(actor, stride)
		"bar_curls": _curls(actor, stride)
		"bar_round": _round_patron(actor, stride)
		"bar_hat": _hat(actor, stride)
		"bar_biker": _biker(actor, stride)
	actor.drawing_head = false
	actor.draw_set_transform_matrix(actor.body_transform)

static func _stool(a: Control) -> void:
	# Seat centre is y=-45 in scene units; shoes stay on the floor at y=0.
	a.block(-2, -14, 4, 13, Color("707e91"))
	a.block(-1, -13, 1, 12, Color("b5bdc9"))
	a.block(-8, -2, 16, 2, Color("536172"))
	a.block(-6, -3, 12, 1, Color("b5bdc9"))
	a.block(-10, -17, 20, 4, Color("87396b"))
	a.block(-12, -17, 24, 2, PINK)
	a.block(-9, -19, 18, 2, Color("eb66ad"))
	a.block(-9, -17, 6, 1, Color("f186be"))
	# A brass foot ring, visible behind the bent trouser legs.
	a.block(-11, -6, 22, 1, BRASS.darkened(0.2))
	a.block(-11, -7, 1, 3, BRASS)
	a.block(10, -7, 1, 3, BRASS)

static func _legs(a: Control, stride: float, color: Color, broad: bool = false) -> void:
	var width := 7.0 if broad else 5.0
	if a.seated:
		# Distinct thighs and shins, rather than a standing actor over a stool.
		a.block(-8, -20, 8, 6, color.darkened(0.12))
		a.block(-12, -16, 11, 5, color.darkened(0.12))
		a.block(-13, -12, width, 10, color.darkened(0.12))
		a.block(0, -19, 9, 6, color)
		a.block(5, -15, 9, 5, color)
		a.block(10, -12, width, 10, color)
		a.block(-15, -3, width + 3, 3, INK)
		a.block(10, -3, width + 4, 3, INK)
		a.block(-13, -12, 1, 8, color.lightened(0.08))
		a.block(10, -11, 1, 8, color.lightened(0.2))
	else:
		a.block(-width - 1, -19, width, 17 + stride, color.darkened(0.12))
		a.block(1, -19, width, 17 - stride, color)
		a.block(-width - 3, -3 + stride, width + 3, 3, INK)
		a.block(1, -3 - stride, width + 4, 3, INK)
		a.block(2, -15, 1, 9 - stride, color.lightened(0.15))

static func _quiff(a: Control, stride: float) -> void:
	var locks := Color("e3c353")
	_legs(a, stride, BLUE)
	# Long, narrow shirt, rolled sleeves and a slightly ludicrous collar.
	a.block(-7, -35, 14, 17, WHITE)
	a.block(-7, -23, 14, 5, WHITE.darkened(0.1))
	a.block(-2, -35, 5, 7, a.skin)
	a.block(-7, -35, 4, 6, WHITE.lightened(0.14))
	a.block(3, -35, 5, 6, WHITE.lightened(0.14))
	a.block(-2, -28, 1, 10, WHITE.darkened(0.24))
	a.block(-6, -19, 13, 2, Color("573647"))
	a.block(0, -19, 3, 2, BRASS)
	if not a._draw_gesture_arms(WHITE, true):
		a.block(-11, -32, 5, 8, WHITE.darkened(0.06))
		a.block(-11, -25, 4, 8, a.skin)
		a.block(-9, -20, 10, 4, a.skin)
		a.block(7, -32, 5, 7, WHITE)
		a.block(9, -28, 8, 4, a.skin)
		a.block(15, -32, 3, 7, a.skin)
		_glass(a, 14, -36)
	a.drawing_head = true
	a.block(-3, -38, 6, 5, a.skin.darkened(0.13))
	a.block(-6, -50, 12, 14, a.skin)
	a.block(5, -44, 4, 4, a.skin)
	a.block(7, -42, 3, 3, a.skin.lightened(0.08))
	a.block(-7, -51, 3, 14, locks.darkened(0.17))
	a.block(-7, -52, 12, 4, locks)
	a.block(-4, -55, 13, 3, locks)
	a.block(4, -57, 7, 2, locks.lightened(0.16))
	a.block(9, -59, 4, 2, locks.lightened(0.25))
	a.block(-5, -51, 6, 1, locks.lightened(0.26))
	if a.gender == "female":
		a.block(-9, -48, 3, 12, locks)
		a.block(-10, -39, 4, 5, locks.darkened(0.12))
		a.block(-5, -38, 2, 3, BRASS.lightened(0.25))
	# White frames leave the eye readable, including the shared wink cue.
	a.block(-2, -47, 9, 1, INK)
	a.block(0, -46, 7, 3, WHITE.lightened(0.1))
	a._draw_eye(3, -45)
	a.block(3, -38, 5, float(a.gesture_pose.get("mouth", 1.0)), Color("a45159"))
	a.drawing_head = false

static func _curls(a: Control, stride: float) -> void:
	var velvet := Color("a33c9b")
	var locks := Color("955934")
	if a.gender == "female":
		if a.seated:
			a.block(-5, -17, 7, 8, a.skin.darkened(0.1))
			a.block(0, -14, 11, 5, a.skin)
			a.block(8, -12, 5, 8, a.skin)
			a.block(10, -6, 6, 3, a.skin)
			a.block(-4, -11, 4, 9, a.skin.darkened(0.1))
			a.block(-6, -3, 7, 3, INK)
			a.block(12, -4, 7, 3, INK)
			a.block(12, -2, 2, 3, INK)
		else:
			a.block(-5, -17, 4, 15 + stride, a.skin.darkened(0.1))
			a.block(2, -17, 4, 15 - stride, a.skin)
			a.block(-7, -3 + stride, 6, 3, INK)
			a.block(1, -3 - stride, 8, 3, INK)
		a.block(-8, -23, 16, 10, PINK)
		a.block(-9, -19, 18, 5, PINK.darkened(0.08))
		a.block(-7, -22, 3, 8, PINK.lightened(0.2))
	else:
		_legs(a, stride, PINK)
		a.block(-7, -23, 14, 6, velvet.darkened(0.12))
	a.block(-8, -34, 16, 13, velvet)
	a.block(-3, -35, 6, 6, a.skin)
	a.block(-7, -34, 4, 9, Color("d369ca"))
	a.block(3, -34, 4, 9, Color("d369ca"))
	a.block(-2, -27, 4, 6, velvet.darkened(0.15))
	a.block(-6, -23, 12, 2, BRASS)
	a.block(-1, -24, 3, 3, BRASS.lightened(0.25))
	if not a._draw_gesture_arms(velvet, true):
		a.block(-12, -31, 5, 4, velvet)
		a.block(-13, -28, 4, 9, a.skin)
		a.block(-10, -22, 7, 4, a.skin)
		a.block(7, -31, 5, 4, velvet)
		a.block(9, -28, 8, 4, a.skin)
		a.block(14, -25, 4, 7, a.skin)
	a.drawing_head = true
	a.block(-9, -47, 16, 16, locks.darkened(0.19))
	a.block(-4, -37, 7, 5, a.skin.darkened(0.1))
	a.block(-5, -46, 11, 11, a.skin)
	a.block(5, -42, 3, 4, a.skin)
	# Staggered curls give a round silhouette rather than a square helmet.
	for curl in [Vector2(-9, -46), Vector2(-8, -50), Vector2(-4, -52), Vector2(1, -51), Vector2(5, -48), Vector2(-10, -41), Vector2(-9, -36), Vector2(6, -38)]:
		a.block(curl.x, curl.y, 5, 6, locks)
		a.block(curl.x + 1, curl.y + 1, 2, 2, locks.lightened(0.18))
	a._draw_eye(2, -43)
	a.block(3, -37, 4, float(a.gesture_pose.get("mouth", 1.0)), Color("a43e63"))
	a.block(-5, -35, 2, 3, BRASS.lightened(0.24))
	if a.gender == "male":
		a.block(-3, -36, 3, 3, locks.darkened(0.18))
	a.drawing_head = false

static func _round_patron(a: Control, stride: float) -> void:
	var locks := Color("b78543")
	_legs(a, stride, BLUE, true)
	# A rounded shirt silhouette is built in wide horizontal steps.
	a.block(-10, -33, 20, 4, WHITE)
	a.block(-13, -29, 26, 12, WHITE)
	a.block(-10, -18, 20, 3, WHITE.darkened(0.12))
	a.block(-13, -27, 3, 8, WHITE.darkened(0.12))
	a.block(10, -26, 3, 7, WHITE.lightened(0.06))
	a.block(-4, -34, 8, 4, a.skin)
	a.block(-4, -32, 8, 2, WHITE.darkened(0.22))
	a.block(-6, -17, 12, 2, Color("596082"))
	if not a._draw_gesture_arms(WHITE):
		a.block(-17, -31, 8, 9, WHITE.darkened(0.06))
		a.block(-17, -23, 5, 5, a.skin)
		a.block(-17, -22, 10, 4, a.skin)
		a.block(10, -30, 8, 8, WHITE)
		a.block(13, -23, 5, 6, a.skin)
		a.block(8, -20, 8, 4, a.skin)
	a.drawing_head = true
	a.block(-5, -37, 10, 5, a.skin.darkened(0.1))
	a.block(-8, -47, 15, 12, a.skin)
	a.block(6, -43, 4, 5, a.skin.lightened(0.06))
	a.block(-9, -49, 15, 5, locks)
	a.block(-5, -51, 11, 3, locks.lightened(0.12))
	a.block(-10, -46, 3, 8, locks.darkened(0.12))
	a.block(5, -47, 3, 3, locks)
	if a.gender == "female":
		a.block(-12, -47, 4, 12, locks)
		a.block(-10, -39, 4, 5, locks.lightened(0.08))
		a.block(-6, -37, 2, 3, BRASS)
	else:
		a.block(-7, -38, 14, 5, locks.darkened(0.12))
		a.block(-4, -33, 8, 2, locks.darkened(0.18))
		a.block(0, -39, 7, 2, locks)
	a._draw_eye(3, -43)
	a.block(2, -36, 5, float(a.gesture_pose.get("mouth", 1.0)), Color("9c5155"))
	a.drawing_head = false

static func _hat(a: Control, stride: float) -> void:
	var teal := Color("36bfc0")
	var plum := Color("9d4099")
	_legs(a, stride, plum)
	# Three-quarter shoulders and an off-centre seam suggest the bar-facing pose.
	a.block(-7, -34, 14, 18, teal)
	a.block(-7, -34, 4, 17, teal.darkened(0.17))
	a.block(3, -33, 2, 15, teal.lightened(0.27))
	a.block(-4, -35, 8, 4, teal.lightened(0.14))
	a.block(-3, -18, 11, 2, plum.darkened(0.26))
	a.block(2, -17, 2, 2, BRASS)
	if not a._draw_gesture_arms(teal, true):
		a.block(-11, -32, 5, 7, teal.darkened(0.09))
		a.block(-14, -29, 7, 4, a.skin)
		a.block(-15, -35, 4, 9, a.skin)
		_glass(a, -17, -40)
		a.block(7, -31, 5, 7, teal)
		a.block(9, -27, 9, 4, a.skin)
		a.block(16, -25, 4, 6, a.skin)
	a.drawing_head = true
	a.block(-3, -38, 6, 5, a.skin.darkened(0.14))
	a.block(-6, -48, 12, 12, a.skin)
	a.block(5, -43, 4, 4, a.skin.lightened(0.09))
	a.block(-7, -48, 3, 9, INK)
	a.block(-10, -51, 21, 3, INK)
	a.block(-7, -57, 15, 6, INK)
	a.block(-6, -56, 12, 1, INK.lightened(0.13))
	a.block(-7, -53, 15, 2, Color("4453a2"))
	if a.gender == "female":
		a.block(-9, -47, 3, 13, INK)
		a.block(-11, -39, 4, 6, INK)
		a.block(-5, -37, 2, 3, BRASS.lightened(0.2))
	else:
		a.block(0, -38, 5, 1, INK)
	a._draw_eye(3, -44)
	a.block(2, -36, 5, float(a.gesture_pose.get("mouth", 1.0)), Color("763f49"))
	a.drawing_head = false

static func _biker(a: Control, stride: float) -> void:
	var denim := Color("354da6")
	var locks := Color("b55242")
	_legs(a, stride, Color("555569"), true)
	# Broad back, asymmetrical vest and a fictional winged spark-plug crest.
	# The head looks over one shoulder, so a face remains visible while idle.
	a.block(-12, -33, 24, 18, denim)
	a.block(-15, -28, 30, 12, denim)
	a.block(-12, -17, 24, 3, denim.darkened(0.2))
	a.block(9, -31, 4, 15, denim.lightened(0.16))
	a.block(-13, -30, 3, 12, denim.darkened(0.18))
	a.block(-5, -35, 10, 4, Color("252d41"))
	a.block(-7, -29, 12, 10, BRASS.darkened(0.2))
	a.block(-5, -30, 8, 12, BRASS)
	a.block(-5, -28, 8, 8, denim.darkened(0.3))
	a.block(-3, -27, 4, 6, Color("c6ced5"))
	a.block(-4, -24, 6, 2, Color("e2d5b1"))
	a.block(-6, -25, 2, 2, Color("e2d5b1"))
	a.block(2, -25, 2, 2, Color("e2d5b1"))
	a.block(-2, -22, 2, 3, Color("efb94f"))
	if not a._draw_gesture_arms(denim, true):
		a.block(-18, -30, 6, 6, a.skin)
		a.block(-20, -26, 6, 10, a.skin)
		a.block(-18, -19, 9, 4, a.skin)
		a.block(12, -31, 6, 7, a.skin)
		a.block(15, -29, 5, 10, a.skin)
		a.block(17, -35, 4, 9, a.skin)
		a.block(16, -22, 5, 2, INK)
		a.block(18, -35, 3, 2, BRASS)
	a.drawing_head = true
	a.block(-6, -38, 12, 6, a.skin.darkened(0.14))
	a.block(-8, -48, 15, 13, a.skin)
	a.block(6, -43, 4, 4, a.skin.lightened(0.09))
	a.block(-9, -49, 13, 4, locks)
	a.block(-8, -46, 6, 11, locks.darkened(0.12))
	a.block(-6, -51, 9, 3, locks.lightened(0.1))
	if a.gender == "female":
		a.block(-12, -43, 5, 13, locks)
		a.block(-11, -33, 6, 3, locks.lightened(0.07))
		a.block(-4, -38, 2, 3, BRASS.lightened(0.17))
	else:
		a.block(-4, -38, 11, 4, locks.darkened(0.15))
		a.block(1, -39, 6, 2, locks)
	a._draw_eye(3, -43)
	a.block(2, -45, 4, 1, locks.darkened(0.24))
	a.block(3, -36, 4, float(a.gesture_pose.get("mouth", 1.0)), Color("92484d"))
	a.drawing_head = false

static func _glass(a: Control, x: float, y: float) -> void:
	a.block(x, y, 5, 8, Color("718c9e"))
	a.block(x + 1, y + 2, 3, 5, Color("d69c51"))
	a.block(x, y, 5, 2, Color("f2e2ba"))
	a.block(x + 1, y + 3, 1, 3, Color("f2ca7e"))
