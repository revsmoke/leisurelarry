extends RefCounted
## Original party cast drawn on the shared three-unit pixel grid.
## draw() uses actor.party_loss only as presentation: no awards or game rules.
## Body and props fit x=-66..66, y=-165..3, inside the normal label obstacle.

const INK := Color("292538")
const CREAM := Color("eee3d2")
const GOLD := Color("e7b861")
const PLUM := Color("804779")
const TEAL := Color("329b99")

static func draw(a: Control, stride: float) -> void:
	var loss := clampi(int(a.party_loss), 0, 3)
	a.drawing_head = false
	match a.role:
		"party_cabbie": _cabbie(a, stride, loss)
		"party_host": _host(a, stride, loss)
		"party_shark": _shark(a, stride, loss)
		"party_player": _player(a, stride, loss)
	a.drawing_head = false
	a.draw_set_transform_matrix(a.body_transform)

static func _legs(a: Control, stride: float, color: Color, flares: bool = false) -> void:
	a.block(-6, -18, 5, 17 + stride, color.darkened(0.14))
	a.block(1, -18, 5, 17 - stride, color)
	if flares:
		a.block(-8, -8 + stride, 7, 7, color.darkened(0.14))
		a.block(1, -8 - stride, 8, 7, color)
	a.block(-8, -3 + stride, 8, 3, INK)
	a.block(1, -3 - stride, 9, 3, INK)

static func _arms(a: Control, sleeve: Color, rolled: bool = false) -> bool:
	if a._draw_gesture_arms(sleeve, rolled): return true
	a.block(-11, -31, 5, 14, sleeve.darkened(0.13))
	a.block(7, -31, 5, 14, sleeve)
	if rolled:
		a.block(-11, -25, 5, 3, CREAM)
		a.block(7, -25, 5, 3, CREAM)
		a.block(-11, -22, 4, 9, a.skin)
		a.block(8, -22, 4, 9, a.skin)
	else:
		a.block(-11, -17, 4, 4, a.skin)
		a.block(8, -17, 4, 4, a.skin)
	return false

static func _robe(a: Control, color: Color) -> void:
	# The wrap is a costume reveal, with trousers visible under its closed hem.
	a.block(-9, -33, 18, 24, color)
	a.block(-11, -22, 22, 16, color)
	a.block(-9, -10, 19, 4, color.darkened(0.09))
	a.block(-7, -32, 4, 15, color.lightened(0.22))
	a.block(3, -32, 4, 15, color.lightened(0.22))
	a.block(-3, -33, 6, 9, CREAM)
	a.block(-9, -20, 18, 3, GOLD)
	a.block(-1, -20, 4, 5, GOLD.lightened(0.17))
	a.block(3, -17, 2, 8, GOLD)
	a.block(-7, -14, 4, 4, color.darkened(0.16))
	_arms(a, color)

static func _neck(a: Control) -> void:
	a.block(-3, -37, 6, 5, a.skin.darkened(0.12))

static func _face(a: Control, locks: Color, wide: bool = false) -> void:
	_neck(a)
	a.block(-6 if wide else -5, -47, 13 if wide else 11, 12, a.skin)
	a.block(6, -43, 3, 4, a.skin.lightened(0.07))
	a.block(-7, -48, 3, 10, locks)
	a.block(-6, -50, 13, 4, locks)
	a._draw_eye(3, -43)
	a.block(2, -36, 5, float(a.gesture_pose.get("mouth", 1.0)), Color("974a5b"))

static func _cabbie(a: Control, stride: float, loss: int) -> void:
	var saffron := Color("c69437")
	_legs(a, stride, Color("474d6d"))
	if loss == 3:
		_robe(a, Color("d6a645"))
	else:
		a.block(-8, -34, 16, 19, saffron)
		a.block(-3, -34, 6, 18, CREAM)
		a.block(-7, -33, 4, 6, saffron.lightened(0.2))
		a.block(3, -33, 4, 6, saffron.lightened(0.2))
		a.block(-7, -24, 4, 1, INK)
		a.block(4, -24, 3, 1, INK)
		a.block(-7, -16, 14, 2, INK)
		a.block(0, -16, 3, 2, GOLD)
		if loss < 2:
			a.block(-4, -33, 8, 2, Color("da647f"))
			a.block(1, -32, 3, 8, Color("da647f"))
		var gesturing := _arms(a, saffron)
		if not gesturing:
			# A single visible card, kept well away from the animated face.
			a.block(-15, -23, 6, 9, CREAM)
			a.block(-13, -21, 2, 2, Color("c45470"))
			a.block(-13, -18, 2, 2, Color("c45470"))
	a.drawing_head = true
	_face(a, INK, true)
	if a.gender == "female":
		a.block(-9, -47, 3, 11, INK)
		a.block(-10, -38, 4, 5, INK)
		a.block(-5, -37, 2, 2, GOLD)
	else:
		a.block(0, -38, 7, 1, INK)
		a.block(-6, -44, 2, 5, Color("afafb6"))
	if loss == 0:
		a.block(-8, -52, 17, 5, saffron)
		a.block(-6, -54, 13, 3, saffron.lightened(0.19))
		a.block(-8, -49, 17, 2, CREAM)
		for x in range(-8, 9, 4): a.block(x, -49, 2, 2, INK)
		a.block(0, -47, 12, 2, INK)
	a.drawing_head = false

static func _host(a: Control, stride: float, loss: int) -> void:
	_legs(a, stride, Color("453650"), true)
	if loss == 3:
		_robe(a, Color("944f95"))
	else:
		a.block(-8, -34, 16, 19, PLUM)
		a.block(-3, -34, 6, 18, CREAM)
		a.block(-7, -34, 4, 9, PLUM.lightened(0.25))
		a.block(3, -34, 4, 9, PLUM.lightened(0.25))
		a.block(-8, -22, 3, 7, PLUM.darkened(0.14))
		a.block(1, -21, 1, 2, GOLD)
		if loss == 0:
			a.block(4, -28, 4, 1, INK)
			a.block(4, -31, 2, 3, Color("f1c876"))
			a.block(6, -30, 2, 2, Color("f1c876"))
		if loss < 2:
			a.block(-3, -34, 6, 2, Color("d464a1"))
			a.block(-2, -31, 5, 6, Color("d464a1"))
		var gesturing := _arms(a, PLUM)
		if not gesturing:
			a.block(9, -21, 8, 6, CREAM)
			a.block(10, -20, 5, 1, PLUM)
			a.block(10, -18, 4, 1, PLUM)
	a.drawing_head = true
	var locks := Color("3e2e36")
	_face(a, locks)
	if a.gender == "female":
		a.block(-6, -53, 10, 4, locks)
		a.block(-5, -55, 6, 3, locks)
		a.block(-7, -47, 2, 10, locks)
		a.block(-7, -53, 2, 2, GOLD)
	else:
		a.block(-3, -37, 9, 3, locks)
		a.block(-1, -34, 5, 1, locks)
		a.block(2, -47, 4, 1, Color("77605a"))
	a.block(-6, -37, 2, 3, GOLD)
	a.block(-6, -37, 1, 2, GOLD.lightened(0.28))
	a.drawing_head = false

static func _shark(a: Control, stride: float, loss: int) -> void:
	_legs(a, stride, Color("38424d"))
	if loss == 3:
		_robe(a, TEAL)
	else:
		a.block(-8, -34, 16, 18, CREAM)
		a.block(-8, -32, 6, 17, TEAL.darkened(0.15))
		a.block(2, -32, 6, 17, TEAL)
		a.block(-6, -33, 3, 7, TEAL.lightened(0.16))
		a.block(3, -33, 3, 7, TEAL.lightened(0.2))
		a.block(-2, -23, 1, 1, GOLD)
		a.block(-2, -19, 1, 1, GOLD)
		if loss < 2:
			a.block(-3, -34, 3, 3, Color("c7588c"))
			a.block(1, -34, 3, 3, Color("c7588c"))
		var gesturing := _arms(a, CREAM, true)
		if not gesturing:
			if loss == 0: a.block(-11, -18, 4, 2, Color("c7588c"))
			# The cue is upright and held below the eye line.
			a.block(16, -45, 2, 43, Color("be965d"))
			a.block(16, -46, 2, 2, TEAL.lightened(0.3))
			a.block(16, -20, 2, 15, Color("70504a"))
			a.block(11, -21, 7, 4, a.skin)
	a.drawing_head = true
	var locks := Color("8f4c3c")
	_face(a, locks)
	a.block(-3, -52, 10, 3, locks.lightened(0.17))
	a.block(2, -51, 7, 2, locks.lightened(0.25))
	if a.gender == "female":
		a.block(-9, -47, 3, 17, locks)
		a.block(-10, -38, 2, 9, locks.lightened(0.18))
		a.block(-10, -32, 3, 2, TEAL)
	else:
		a.block(-6, -45, 2, 7, locks.darkened(0.24))
		a.block(-4, -36, 4, 2, locks)
	a.block(-5, -37, 1, 2, GOLD)
	a.drawing_head = false

static func _player(a: Control, stride: float, loss: int) -> void:
	var lisa: bool = a.gender == "female"
	var suit := Color("f3e6ce")
	var shirt := Color("bd5288") if lisa else Color("ef6a9d")
	_legs(a, stride, suit, lisa)
	if loss == 3:
		_robe(a, Color("c95e9a"))
	else:
		a.block(-7, -33, 14, 18, shirt if loss >= 2 else suit)
		if loss < 2:
			a.block(-3, -33, 6, 17, shirt)
			a.block(-7, -33, 4, 8, suit.lightened(0.1))
			a.block(3, -33, 4, 8, suit.lightened(0.1))
		else:
			a.block(-2, -31, 1, 15, shirt.darkened(0.22))
			a.block(-6, -32, 4, 3, shirt.lightened(0.18))
			a.block(2, -32, 4, 3, shirt.lightened(0.18))
		a.block(-6, -18, 12, 2, GOLD)
		if loss == 0:
			a.block(-4, -33, 4, 3, PLUM)
			a.block(1, -33, 4, 3, PLUM)
		_arms(a, shirt if loss >= 2 else suit)
	a.drawing_head = true
	if not lisa:
		a._draw_larry_profile()
	else:
		# Match Lisa's existing feathered hair and face while changing only clothes.
		var locks := Color("713e4e")
		a.block(-3, -35, 6, 4, a.skin.darkened(0.08))
		a.block(-5, -45, 11, 11, a.skin)
		a.block(6, -40, 2, 3, a.skin)
		a.block(-7, -48, 13, 5, locks)
		a.block(-9, -45, 5, 9, locks)
		a.block(-11, -39, 5, 5, locks)
		a.block(-10, -35, 4, 4, locks)
		a.block(4, -45, 5, 4, locks)
		a.block(7, -40, 3, 6, locks)
		a.block(6, -35, 5, 4, locks)
		a.block(-5, -47, 7, 2, Color("ad6871"))
		a._draw_eye(2, -41)
		a.block(1, -43, 4, 1, locks)
		a.block(2, -36, 4, float(a.gesture_pose.get("mouth", 1.0)), Color("ac365d"))
		a.block(-5, -35, 2, 3, GOLD)
	a.drawing_head = false
