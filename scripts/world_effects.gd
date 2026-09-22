extends Control
## Small state-dependent props over the painted room, below actors and labels.
## The planter anchor matches game_state.gd's garden hotspot (0.49, 0.65).
const PLANTER_ANCHOR := Vector2(1140.0 * 0.49, 506.0 * 0.65)
const GROW_SECONDS := 1.1
var room_id := ""
var seeds_planted := false
var apple_grown := false
var apple_taken := false
var growth := 1.0
var water_glimmer := 0.0

func _ready() -> void:
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	set_process(false)

func sync_state(next_room: String, flags: Dictionary) -> void:
	var was_garden := room_id == "garden"
	var was_grown := apple_grown
	room_id = next_room
	seeds_planted = bool(flags.get("seeds_planted", false))
	apple_grown = bool(flags.get("apple_grown", false))
	apple_taken = bool(flags.get("taken_apple", false))
	visible = room_id == "garden"
	if visible and was_garden and not was_grown and apple_grown:
		growth = 0.0
		water_glimmer = 1.6
	elif not visible or not apple_grown:
		growth = 1.0
		water_glimmer = 0.0
	set_process(visible and (growth < 1.0 or water_glimmer > 0.0))
	queue_redraw()

func _process(delta: float) -> void:
	growth = minf(1.0, growth + delta / GROW_SECONDS)
	water_glimmer = maxf(0.0, water_glimmer - delta)
	set_process(growth < 1.0 or water_glimmer > 0.0)
	queue_redraw()

func _draw() -> void:
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
	var leaf := Color("2b8564")
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
