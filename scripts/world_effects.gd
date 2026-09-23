extends Control
## State-driven stage dressing over the painted room, below actors and labels.
## Clean background plates remove baked props; the code owns every collectible layer.
## The planter anchor matches game_state.gd's garden hotspot (0.49, 0.65).
const PLANTER_ANCHOR := Vector2(1140.0 * 0.49, 506.0 * 0.65)
const GROW_SECONDS := 1.1
const PROP_ROOMS := ["bar", "bathroom", "backroom", "disco", "alley", "hotel", "balcony", "garden", "penthouse", "rooftop"]
const INK := Color("25243b")
const BRASS := Color("c59b59")
const CREAM := Color("f0d7ab")
const TEAL := Color("418e8b")
const PINK := Color("e96f99")
var room_id := ""
var state: Dictionary = {}
var player_profile: Dictionary = {}
var reduced_motion := false
var _font: Font = preload("res://assets/fonts/SpaceGrotesk.ttf")
var seeds_planted := false
var apple_grown := false
var apple_taken := false
var growth := 1.0
var water_glimmer := 0.0

static func background_path_for(room: String, flags: Dictionary) -> String:
	var suffix := "-open" if room == "balcony" and flags.get("window_open", false) else "-clean" if room in ["garden", "penthouse", "backroom", "alley", "balcony"] else ""
	return "res://assets/backgrounds/%s%s.png" % [room, suffix]

func _ready() -> void:
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	set_process(false)

func sync_state(next_room: String, flags: Dictionary, profile: Dictionary = {}) -> void:
	var was_garden := room_id == "garden"
	var was_grown := apple_grown
	room_id = next_room
	state = flags.duplicate(true)
	player_profile = profile.duplicate(true)
	seeds_planted = bool(flags.get("seeds_planted", false))
	apple_grown = bool(flags.get("apple_grown", false))
	apple_taken = bool(flags.get("taken_apple", false))
	visible = room_id in PROP_ROOMS
	if room_id == "garden" and was_garden and not was_grown and apple_grown and not reduced_motion:
		growth = 0.0
		water_glimmer = 1.6
	elif room_id != "garden" or not was_garden or not apple_grown or reduced_motion:
		growth = 1.0
		water_glimmer = 0.0
	set_process(visible and (growth < 1.0 or water_glimmer > 0.0))
	queue_redraw()

func _process(delta: float) -> void:
	growth = minf(1.0, growth + delta / GROW_SECONDS)
	water_glimmer = maxf(0.0, water_glimmer - delta)
	set_process(growth < 1.0 or water_glimmer > 0.0)
	queue_redraw()

func set_reduced_motion(value: bool) -> void:
	reduced_motion = value
	if reduced_motion:
		growth = 1.0
		water_glimmer = 0.0
		set_process(false)
	queue_redraw()

func visual_state() -> Dictionary:
	# These semantic states also drive the actual rendering; tests inspect this
	# contract without pretending it measures aesthetic quality.
	return {
		"stool_on_rack": room_id == "garden" and not state.get("taken_stool", false),
		"stool_at_cabinet": room_id == "penthouse" and state.get("stool_placed", false),
		"core": room_id == "alley" and not state.get("taken_core", false),
		"mallet": room_id == "alley" and not state.get("taken_hammer", false),
		"pitcher": room_id == "penthouse" and not state.get("taken_pitcher", false),
		"cabinet_open": room_id == "penthouse" and state.get("stool_placed", false),
		"ring": room_id == "bathroom" and not state.get("taken_ring", false),
		"candy": room_id == "backroom" and not state.get("taken_candy", false),
		"voucher": room_id == "balcony" and state.get("window_open", false) and not state.get("taken_voucher", false),
		"window_open": room_id == "balcony" and state.get("window_open", false),
		"spare_rope": room_id == "disco" and not state.get("rope_taken", false),
		"anchored_rope": room_id in ["backroom", "balcony"] and state.get("rope_anchored", false),
		"bowling": room_id == "bar" and state.get("tv_distracted", false),
		"coffee": room_id == "hotel" and (state.get("coffee_delivered", false) or state.get("award_coffee_given", false)),
		"eve_apple": room_id == "rooftop" and state.get("apple_given", false),
		"show": room_id == "disco" and state.get("show_started", false),
		"show_beat": 3 if state.get("show_completed", false) else 2 if state.get("show_beat_2", false) else 1 if state.get("show_beat_1", false) else 0,
		"seeds": room_id == "garden" and seeds_planted,
		"tree": room_id == "garden" and apple_grown,
		"tree_apple": room_id == "garden" and apple_grown and not apple_taken
	}

func _draw() -> void:
	var props := visual_state()
	match room_id:
		"bar": _draw_bar(props)
		"bathroom": _draw_jewelry(props)
		"backroom": _draw_backroom(props)
		"disco": _draw_disco(props)
		"alley": _draw_alley(props)
		"hotel": _draw_hotel(props)
		"balcony": _draw_balcony(props)
		"garden": _draw_loan_rack(props)
		"penthouse": _draw_cabinet(props)
		"rooftop": _draw_rooftop(props)
	_draw_camp_dressing()
	_draw_garden()

func _draw_camp_dressing() -> void:
	# Small set-dressing jokes belong to the room's furniture, never a screen
	# overlay. No flashing and no new hotspots or puzzle-relevant fake objects.
	match room_id:
		"bar":
			_camp_sign(Rect2(75, 239, 150, 43), "STIFF DRINKS", "LOOSE EXCUSES", PINK)
		"bathroom":
			_camp_sign(Rect2(840, 272, 174, 44), "FOR A GOOD TIME", "TRY BASIC HYGIENE", TEAL)
		"disco":
			_camp_sign(Rect2(905, 281, 174, 48), "THE PELVIC AUDIT", "ALL ACCOUNTS WELCOME", PINK)
		"hotel":
			_camp_sign(Rect2(677, 321, 160, 50), "HOURLY RATES", "ETERNAL ALIBIS", BRASS)
		"penthouse":
			_camp_sign(Rect2(786, 367, 159, 43), "AFTER HOURS", "BEFORE REGRETS", PINK)
		"rooftop":
			_camp_sign(Rect2(62, 305, 164, 46), "PARADISE SUITE", "FIG LEAVES OPTIONAL", PINK)

func _camp_sign(rect: Rect2, headline: String, punchline: String, tint: Color) -> void:
	if room_id in ["hotel", "rooftop"]:
		# Freestanding brass lobby/terrace notices have an actual foot on the floor.
		var center_x := rect.get_center().x
		draw_rect(Rect2(center_x - 2, rect.end.y, 4, 51), BRASS.darkened(0.2))
		draw_rect(Rect2(center_x - 24, rect.end.y + 49, 48, 5), BRASS.darkened(0.45))
		draw_line(Vector2(center_x - 22, rect.end.y + 49), Vector2(center_x + 22, rect.end.y + 49), BRASS, 2)
	draw_rect(rect.grow(2), BRASS.darkened(0.3))
	draw_rect(rect, INK)
	draw_line(rect.position + Vector2(7, 4), rect.position + Vector2(rect.size.x - 7, 4), tint, 2)
	draw_string(_font, rect.position + Vector2(6, 20), headline, HORIZONTAL_ALIGNMENT_CENTER, rect.size.x - 12, 12, tint)
	draw_string(_font, rect.position + Vector2(6, 35), punchline, HORIZONTAL_ALIGNMENT_CENTER, rect.size.x - 12, 9, CREAM)

func _draw_garden() -> void:
	if room_id != "garden" or not seeds_planted:
		return
	draw_set_transform(PLANTER_ANCHOR)
	# Disturbed soil and three visible seed markers keep planting legible before water.
	draw_rect(Rect2(-42, -5, 84, 10), Color("302838"))
	draw_rect(Rect2(-30, -9, 64, 5), Color("423145"))
	if not apple_grown:
		for x in [-24.0, 0.0, 24.0]:
			draw_rect(Rect2(x - 3, -7, 6, 4), Color("d9b476"))
		return
	# The trunk grows from the same soil patch; the crown reaches the tree hotspot.
	var eased := 1.0 - pow(1.0 - growth, 3.0)
	draw_set_transform(PLANTER_ANCHOR, 0.0, Vector2(0.4 + eased * 0.6, maxf(0.02, eased)))
	_draw_tree()
	draw_set_transform(PLANTER_ANCHOR)
	if water_glimmer > 0.0:
		var opacity := minf(1.0, water_glimmer)
		for i in range(7):
			var x := -46.0 + float(i) * 15.0
			var y := -10.0 - fmod((1.6 - water_glimmer) * 42.0 + float(i) * 13.0, 46.0)
			draw_rect(Rect2(x, y, 3, 7), Color(0.45, 0.9, 0.95, opacity))

func _draw_tree() -> void:
	# Chunked silhouettes echo the existing actors without covering the room art.
	draw_rect(Rect2(-9, -106, 18, 108), Color("5c3f46"))
	draw_rect(Rect2(-5, -108, 6, 108), Color("b78161"))
	draw_rect(Rect2(-22, -87, 20, 8), Color("89604f"))
	draw_rect(Rect2(-28, -100, 8, 22), Color("89604f"))
	draw_rect(Rect2(4, -103, 27, 8), Color("755047"))
	draw_rect(Rect2(26, -118, 8, 23), Color("755047"))
	var shade := Color("194e49")
	var leaf := Color("648550") if state.get("cultivar_midlife", false) else Color("2b8564")
	var light := Color("78b86e")
	draw_rect(Rect2(-57, -156, 108, 80), shade)
	draw_rect(Rect2(-73, -143, 24, 54), shade)
	draw_rect(Rect2(46, -145, 25, 59), shade)
	draw_rect(Rect2(-36, -173, 71, 21), shade)
	draw_rect(Rect2(-66, -139, 27, 42), leaf)
	draw_rect(Rect2(-48, -152, 59, 52), leaf)
	draw_rect(Rect2(-29, -166, 59, 47), leaf)
	draw_rect(Rect2(13, -143, 50, 50), leaf)
	draw_rect(Rect2(-37, -102, 74, 20), leaf)
	for patch in [Rect2(-45, -149, 26, 7), Rect2(-23, -161, 22, 7), Rect2(-59, -132, 14, 6), Rect2(26, -137, 20, 7), Rect2(-25, -99, 16, 5)]:
		draw_rect(patch, light)
	if not apple_taken:
		# One apple, one payoff. Picking it removes the fruit while preserving the tree.
		draw_rect(Rect2(23, -117, 4, 9), Color("cebc75"))
		draw_rect(Rect2(26, -118, 9, 4), light)
		draw_rect(Rect2(14, -109, 22, 17), Color("bd355c"))
		draw_rect(Rect2(18, -112, 15, 22), Color("e95968"))
		draw_rect(Rect2(19, -108, 5, 6), Color("ffd299"))


func _plate(rect: Rect2, title: String, color: Color = TEAL) -> void:
	draw_rect(rect.grow(3), BRASS.darkened(0.35))
	draw_rect(rect, INK)
	draw_rect(Rect2(rect.position, Vector2(rect.size.x, 4)), color)
	if not title.is_empty():
		draw_string(_font, rect.position + Vector2(8, 20), title, HORIZONTAL_ALIGNMENT_LEFT, rect.size.x - 12, 12, CREAM)

func _stool(anchor: Vector2) -> void:
	draw_rect(Rect2(anchor + Vector2(-27, -53), Vector2(54, 9)), Color("847497"))
	draw_line(anchor + Vector2(-22, -44), anchor + Vector2(22, 0), BRASS, 6)
	draw_line(anchor + Vector2(22, -44), anchor + Vector2(-22, 0), BRASS, 6)
	draw_rect(Rect2(anchor + Vector2(-30, -53), Vector2(60, 4)), Color("bca8b9"))
	draw_rect(Rect2(anchor + Vector2(-29, -4), Vector2(15, 5)), INK)
	draw_rect(Rect2(anchor + Vector2(15, -4), Vector2(15, 5)), INK)

func _draw_loan_rack(props: Dictionary) -> void:
	if props.stool_on_rack:
		_stool(Vector2(400, 445))
	# A tiny brass loan tag remains after collection; the floor is otherwise clear.
	draw_rect(Rect2(440, 395, 30, 17), BRASS.darkened(0.3))
	draw_string(_font, Vector2(443, 407), "LOAN", HORIZONTAL_ALIGNMENT_LEFT, 27, 8, CREAM)

func _draw_jewelry(props: Dictionary) -> void:
	_plate(Rect2(237, 297, 110, 68), "FREE COSTUME", Color("e0aa76"))
	draw_rect(Rect2(250, 325, 86, 29), Color("726072"))
	draw_rect(Rect2(255, 329, 76, 19), Color("39344b"))
	if props.ring:
		draw_arc(Vector2(286, 335), 10, 0.0, TAU, 12, BRASS, 4)
		draw_rect(Rect2(281, 321, 11, 11), PINK)
		draw_rect(Rect2(282, 322, 4, 4), CREAM)
	else:
		draw_string(_font, Vector2(266, 343), "EMPTY", HORIZONTAL_ALIGNMENT_LEFT, 58, 11, CREAM)

func _draw_backroom(props: Dictionary) -> void:
	if props.candy:
		# A shallow perspective tray sits on the cleaned table, then disappears.
		draw_colored_polygon(PackedVector2Array([Vector2(747, 407), Vector2(853, 416), Vector2(839, 448), Vector2(735, 436)]), Color("522b3b"))
		draw_polyline(PackedVector2Array([Vector2(747, 407), Vector2(853, 416), Vector2(839, 448), Vector2(735, 436), Vector2(747, 407)]), BRASS.darkened(0.3), 3)
		for row in range(2):
			for col in range(5):
				var p := Vector2(750 + col * 19 - row * 5, 414 + row * 13 + col * 1.5)
				draw_rect(Rect2(p, Vector2(13, 8)), Color("a86845"))
				draw_rect(Rect2(p + Vector2(2, 1), Vector2(4, 2)), CREAM)
	if props.anchored_rope:
		_draw_rope(PackedVector2Array([Vector2(626, 163), Vector2(645, 176), Vector2(664, 162), Vector2(645, 151), Vector2(627, 171), Vector2(638, 241), Vector2(628, 318)]))

func _draw_alley(props: Dictionary) -> void:
	if props.core:
		draw_rect(Rect2(330, 426, 17, 5), Color("b94f5c"))
		draw_rect(Rect2(334, 431, 9, 14), CREAM)
		draw_rect(Rect2(330, 445, 17, 5), Color("b94f5c"))
		draw_rect(Rect2(338, 422, 3, 5), BRASS)
	if props.mallet:
		draw_line(Vector2(829, 453), Vector2(850, 427), BRASS, 6)
		draw_line(Vector2(839, 420), Vector2(864, 437), Color("737184"), 14)

func _draw_cabinet(props: Dictionary) -> void:
	# Upper-right cabinet replaces the painted watering vessel with a real prop.
	_plate(Rect2(984, 0, 153, 118), "GUEST EQUIPMENT")
	draw_rect(Rect2(995, 30, 130, 79), Color("4a3c46"))
	draw_rect(Rect2(1003, 35, 114, 66), Color("171f30"))
	draw_rect(Rect2(1002, 97, 114, 6), BRASS)
	if props.pitcher:
		draw_rect(Rect2(1054, 54, 32, 39), Color("7dbab9"))
		draw_rect(Rect2(1058, 59, 22, 30), Color("bad9cf"))
		draw_rect(Rect2(1050, 49, 37, 8), CREAM)
		draw_rect(Rect2(1086, 60, 12, 23), BRASS)
		draw_rect(Rect2(1086, 65, 7, 13), INK)
	if props.cabinet_open:
		draw_colored_polygon(PackedVector2Array([Vector2(995, 31), Vector2(977, 43), Vector2(977, 112), Vector2(995, 104)]), Color("756051"))
		_stool(Vector2(979, 498))
	else:
		draw_rect(Rect2(1001, 32, 56, 66), Color(0.17, 0.28, 0.31, 0.7))
		draw_line(Vector2(1057, 32), Vector2(1057, 97), BRASS, 3)

func _draw_rope(points: PackedVector2Array) -> void:
	draw_polyline(points, Color("594c42"), 10, true)
	draw_polyline(points, Color("d2aa69"), 6, true)
	for p in points:
		draw_circle(p, 3, CREAM)

func _draw_balcony(props: Dictionary) -> void:
	# The background swaps to a raised sash. Only the collectible card is drawn here.
	if props.voucher:
		draw_colored_polygon(PackedVector2Array([Vector2(752, 302), Vector2(790, 307), Vector2(779, 325), Vector2(741, 320)]), CREAM)
		draw_string(_font, Vector2(751, 313), "COFFEE", HORIZONTAL_ALIGNMENT_LEFT, 35, 8, INK)
		draw_line(Vector2(750, 318), Vector2(775, 321), PINK.darkened(0.3), 2)
	# The fixed rope visible in this illustration is the same secured line from backstage.

func _draw_disco(props: Dictionary) -> void:
	_plate(Rect2(134, 128, 103, 113), "SPARE STAGE LINE")
	if props.spare_rope:
		for i in range(4):
			draw_arc(Vector2(184, 187), 19.0 + i * 4.0, 0.0, TAU, 16, BRASS, 3)
		draw_rect(Rect2(179, 156, 10, 63), Color("b76d7c"))
	else:
		draw_string(_font, Vector2(148, 185), "ON LOAN", HORIZONTAL_ALIGNMENT_LEFT, 80, 13, CREAM)
		draw_string(_font, Vector2(146, 207), "NOT THE CEILING!", HORIZONTAL_ALIGNMENT_LEFT, 88, 9, PINK)
	if state.get("rehearsal_started", false) or props.show:
		for center in [Vector2(414, 419), Vector2(572, 398)]:
			draw_line(center - Vector2(14, 6), center + Vector2(14, 6), CREAM, 4)
			draw_line(center + Vector2(-14, 6), center + Vector2(14, -6), CREAM, 4)
	if props.show:
		var color := PINK if int(props.show_beat) % 2 == 0 else TEAL
		# No flashing or time-sensitive action: each beat advances on player input.
		for x in range(327, 761, 42):
			draw_rect(Rect2(x, 439, 13, 8), color)
		var show_text := "DIDI PRESENTS • THE ACCOUNTANTS OF DESIRE"
		if state.get("show_completed", false): show_text = "ENCORE! • THANK YOU, " + str(player_profile.get("name", "Lisa" if player_profile.get("character", "larry") == "lisa" else "Larry")).to_upper()
		_plate(Rect2(376, 209, 359, 28), show_text, color)
		if state.get("gift_ring", false):
			draw_arc(Vector2(640, 376), 13, 0.0, TAU, 16, BRASS, 5)
			draw_rect(Rect2(633, 358, 14, 10), PINK)
		if state.get("gift_flowers", false):
			for x in [660, 672, 681]:
				draw_line(Vector2(671, 410), Vector2(x, 376), TEAL, 3)
				draw_rect(Rect2(x - 5, 370, 10, 10), PINK)
		if state.get("gift_candy", false):
			draw_rect(Rect2(685, 397, 34, 18), Color("ab546f"))
			draw_rect(Rect2(698, 397, 5, 18), CREAM)

func _draw_bar(props: Dictionary) -> void:
	if props.bowling:
		draw_rect(Rect2(969, 0, 103, 45), Color("222b43"))
		draw_string(_font, Vector2(976, 14), "CHANNEL 6", HORIZONTAL_ALIGNMENT_LEFT, 90, 10, CREAM)
		for x in [999, 1011, 1023]:
			draw_rect(Rect2(x, 22, 4, 12), CREAM)
		draw_circle(Vector2(989, 34), 6, PINK)
	if state.get("whiskey_given", false):
		draw_rect(Rect2(621, 342, 10, 24), BRASS)
		draw_rect(Rect2(624, 335, 4, 9), CREAM)
		draw_rect(Rect2(621, 349, 10, 8), PINK)

func _draw_hotel(props: Dictionary) -> void:
	if props.coffee:
		draw_rect(Rect2(746, 237, 23, 24), CREAM)
		draw_rect(Rect2(745, 234, 25, 5), Color("503448"))
		draw_rect(Rect2(769, 240, 8, 12), BRASS)
		draw_rect(Rect2(742, 262, 36, 4), CREAM)
	if state.get("hotel_social", false):
		_plate(Rect2(756, 300, 131, 30), "CABARET GUEST LIST", TEAL)

func _draw_rooftop(props: Dictionary) -> void:
	if props.eve_apple:
		# Kept beside Eve; her actor also holds it during the conversation.
		draw_rect(Rect2(817, 382, 30, 6), CREAM)
		draw_rect(Rect2(825, 367, 16, 14), PINK)
		draw_rect(Rect2(832, 363, 3, 5), BRASS)
	if state.get("ending_friends", false):
		_plate(Rect2(486, 72, 172, 30), "GOOD COMPANY. NO SCRIPT.", TEAL)
	elif state.get("ending_flirt", false):
		_plate(Rect2(486, 72, 172, 30), "SUNRISE • TABLE FOR TWO", PINK)
