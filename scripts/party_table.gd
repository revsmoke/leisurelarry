extends Control
## Presentation only. Cards, geometry and outcomes come from PartyGames.
var model_view: Dictionary = {}
var ui_font: Font
var motion := 1.0
var interlude := false
var reduced_motion := false

func setup(font: Font) -> void:
	ui_font = font
	size = Vector2(732, 232)
	mouse_filter = Control.MOUSE_FILTER_IGNORE

func _box(rect: Rect2, fill: Color, border: Color, radius: int = 10) -> void:
	var style := StyleBoxFlat.new()
	style.bg_color = fill
	style.border_color = border
	style.set_border_width_all(2)
	style.set_corner_radius_all(radius)
	draw_style_box(style, rect)

func _word(value: String, at: Vector2, font_size: int = 18, color: Color = Color("f6e4bc")) -> void:
	if ui_font: draw_string(ui_font, at, value, HORIZONTAL_ALIGNMENT_LEFT, -1, font_size, color)

func _draw() -> void:
	_box(Rect2(0, 0, 732, 232), Color("101727"), Color("b77790"), 16)
	for x in range(16, 730, 28):
		draw_circle(Vector2(x, 12), 2.0, Color("ef83b6"))
	_box(Rect2(126, 27, 480, 184), Color("123c39"), Color("b08348"), 24)
	if model_view.is_empty(): return
	var visuals: Dictionary = model_view.get("visuals", {})
	match model_view.get("mode", ""):
		"poker":
			_word("RIVAL", Vector2(138, 65), 12, Color("95bfb8"))
			_word("YOU", Vector2(144, 150), 12, Color("95bfb8"))
			_cards(visuals.get("npc_cards", []), Vector2(197, 36))
			_cards(visuals.get("player_cards", []), Vector2(197, 126))
		"never":
			_box(Rect2(177, 57, 378, 125), Color("e7d7bb"), Color("ba8c50"))
			_word("NEVER HAVE I EVER…", Vector2(206, 93), 24, Color("4b2549"))
			_word("A confession. A collar. Plausible deniability.", Vector2(200, 127), 15, Color("563548"))
			_word("Answer as your character — or pass.", Vector2(227, 156), 15, Color("563548"))
		"pool": _pool(visuals)
	if interlude:
		var progress := 0.5 if reduced_motion else motion
		# The curtains part while the costumes change behind a velvet swish.
		var curtain_width: float = 122.0 * sin(clampf(progress, 0, 1) * PI)
		_box(Rect2(0, 0, maxf(curtain_width, 0.1), 232), Color("6d254e"), Color("b05d85"), 3)
		_box(Rect2(732 - curtain_width, 0, maxf(curtain_width, 0.1), 232), Color("6d254e"), Color("b05d85"), 3)
		_word("WARDROBE DEPARTMENT: SEND HELP", Vector2(204, 226), 14, Color("f6e4bc"))

func _cards(cards: Array, origin: Vector2) -> void:
	for i in cards.size():
		var card: Dictionary = cards[i]
		var rect := Rect2(origin + Vector2(i * 77, 0), Vector2(65, 70))
		var hidden: bool = card.get("hidden", false)
		_box(rect, Color("533358") if hidden else Color("f6e7ca"), Color("ef83b6") if card.get("discard", false) else Color("b99367"), 6)
		if hidden:
			for row in 4:
				for column in 3: draw_circle(rect.position + Vector2(16 + column * 16, 14 + row * 14), 2.5, Color("b576a1"))
		else:
			var rank: int = int(card.get("rank", 0))
			var face: String = {11: "J", 12: "Q", 13: "K", 14: "A"}.get(rank, str(rank))
			var suit: int = int(card.get("suit", 0))
			var color := Color("ad3358") if card.get("red", false) else Color("243646")
			_word(face, rect.position + Vector2(9, 28), 24, color)
			var symbol: String = ["♣", "♦", "♥", "♠"][clampi(suit, 0, 3)]
			_word(symbol, rect.position + Vector2(33, 51), 25, color)
			if card.get("discard", false): _word("SWAP", rect.position + Vector2(9, 65), 12, Color("913958"))

func _point(value: Array) -> Vector2:
	return Vector2(142, 41) + Vector2(float(value[0]) * 446, float(value[1]) * 149)

func _pool(visuals: Dictionary) -> void:
	if not visuals.has("cue"): return
	var cue := _point(visuals.cue)
	var object := _point(visuals.object)
	var pocket := _point(visuals.pocket)
	for point in [Vector2(142, 41), Vector2(365, 41), Vector2(588, 41), Vector2(142, 190), Vector2(365, 190), Vector2(588, 190)]:
		draw_circle(point, 9, Color("0a121b"))
	draw_circle(pocket, 9, Color("0a121b"))
	draw_arc(pocket, 13, 0, TAU, 24, Color("ef83b6"), 3)
	var angle := deg_to_rad(float(visuals.get("angle", 0)))
	# The model's physical table is 1000 by 500; positive aim goes upward.
	var direction := Vector2(cos(angle) * 446.0 / 1000.0, -sin(angle) * 149.0 / 500.0).normalized()
	if not visuals.get("shot", false):
		draw_line(cue - direction * 48, cue - direction * 11, Color("d6b180"), 4)
		var ray_length := (588.0 - cue.x) / maxf(direction.x, 0.01)
		if direction.y < -0.001: ray_length = minf(ray_length, (41.0 - cue.y) / direction.y)
		draw_dashed_line(cue, cue + direction * ray_length, Color("b3d9c580"), 2, 6)
	else:
		var path: Array = visuals.get("path", [])
		var object_path: Array = visuals.get("object_path", [])
		if path.size() >= 2:
			draw_line(_point(path[0]), _point(path[-1]), Color("badcc370"), 2)
			cue = _point(path[0]).lerp(_point(path[-1]), clampf(motion * 2.0, 0, 1))
		if object_path.size() >= 2:
			object = _point(object_path[0]).lerp(_point(object_path[-1]), clampf(motion * 2.0 - 0.7, 0, 1))
	draw_circle(cue, 7, Color("f4ead5"))
	if not (visuals.get("success", false) and motion > 0.95):
		draw_circle(object, 8, Color("dd5990"))
		draw_circle(object + Vector2(-2, -2), 2, Color("f7c9d7"))
