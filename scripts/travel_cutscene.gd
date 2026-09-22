extends Control
## Authored, skippable travel vignettes. This is presentation only: no quest,
## inventory, money, or save mutations, and no model-generated routing.
signal finished

const Actor = preload("res://scripts/actor.gd")
const BODY_FONT = preload("res://assets/fonts/Outfit.ttf")
const TITLE_FONT = preload("res://assets/fonts/SpaceGrotesk.ttf")
const INK := Color("101323")
const CREAM := Color("f5e9d6")
const PINK := Color("f482af")
const MINT := Color("94dfcf")
const GOLD := Color("d9b369")
const STAGE_SIZE := Vector2(944, 422)
const DURATIONS := {"door": 3.5, "walk": 3.5, "taxi": 4.4, "elevator": 4.1, "rope": 4.1, "terrace": 3.6}

class PaintLayer extends Control:
	var paint: Callable
	func _ready() -> void:
		mouse_filter = Control.MOUSE_FILTER_IGNORE
	func _draw() -> void:
		if paint.is_valid():
			paint.call(self)

var elapsed := 0.0
var duration := 3.5
var mode := "walk"
var active := false
var reduced_motion := false
var actor: Control
var skip_button: Button
var caption_label: Label
var stage: Control
var _from_id := ""
var _to_id := ""
var _departure: TextureRect
var _arrival: TextureRect
var _backdrop: PaintLayer
var _foreground: PaintLayer
var _phase_label: Label
var _progress: ColorRect
var _from_name := ""
var _to_name := ""
var _taxi_x := 370.0
var _finished_emitted := false
var _body_font: FontVariation
var _title_font: FontVariation

func _init() -> void:
	set_process(false)

static func _district(id: String) -> String:
	if id in ["bar", "bathroom", "backroom", "balcony"]:
		return "leftys"
	if id in ["hotel", "garden", "penthouse", "rooftop"]:
		return "hotel"
	return id

static func mode_for(from_id: String, to_id: String) -> String:
	var origin := _district(from_id)
	var destination := _district(to_id)
	var pair := [from_id, to_id]
	if origin == destination:
		if origin == "leftys":
			return "rope" if pair.has("balcony") else "door"
		if origin == "hotel":
			var starts_upstairs := from_id in ["penthouse", "rooftop"]
			var ends_upstairs := to_id in ["penthouse", "rooftop"]
			return "elevator" if starts_upstairs != ends_upstairs else "terrace"
		return "walk"
	# A map jump can span several connected rooms. Classify by the buildings
	# first so a restroom-to-casino journey does not become a bathroom doorway.
	var districts := [origin, destination]
	if districts.has("street"):
		var other := destination if origin == "street" else origin
		if other == "leftys":
			return "door"
		return "walk" if other in ["shop", "alley"] else "taxi"
	# The casino and hotel share a neighboring entrance; other venues are farther.
	if pair.has("casino") and pair.has("hotel"):
		return "walk"
	return "taxi"

static func caption_for(from_id: String, to_id: String, variant: int = 0) -> String:
	var lines: Array = []
	if to_id == "bar":
		lines = ["Larry makes an entrance. His cologne has already reserved a table.", "He loosens his collar. The dress code breathes a sigh of relief.", "Lefty's: where the drinks are stiff and the competition is mostly furniture."]
	elif from_id == "bar" and to_id == "street":
		lines = ["Larry leaves them wanting more. Specifically, more distance.", "Back on the Strip. His suit is white; his intentions have mood lighting.", "A fresh breeze. At last, someone willing to mess up his hair."]
	elif to_id == "bathroom":
		lines = ["A little powder-room diplomacy. Larry's fly requests a private audience.", "He follows the international symbol for regretting that last drink.", "Some men freshen up. Larry renews the lease on his cologne."]
	elif from_id == "bathroom":
		lines = ["Hands washed. Hopes filthy. Standards under negotiation.", "Larry emerges refreshed, if not substantially improved.", "The mirror asked for his number. Purely for its therapist."]
	elif mode_for(from_id, to_id) == "rope":
		lines = ["At last: a line that supports him. Larry tests it before committing.", "One hand on the rope. One eye on the trousers. Romance requires preparation.", "Larry takes it slowly. For once, everybody appreciates that."]
	elif mode_for(from_id, to_id) == "elevator":
		lines = ["Going up? Finally, a question Larry can answer without exaggerating.", "He presses the right button. There's a first time for everything.", "The elevator has smooth moves. Larry takes notes."] if to_id == "penthouse" else ["Larry comes down to earth. The elevator does most of the work.", "Going down. Larry wisely lets the elevator finish the sentence.", "He leaves the penthouse with his dignity. Small luggage travels well."]
	elif to_id == "rooftop":
		lines = ["The air gets cooler. Larry's opening line has not received the memo.", "A moonlit terrace. He checks his collar and lowers his expectations to charming.", "Larry steps into the night. For once, the view gets the first compliment."]
	elif to_id == "garden":
		lines = ["Moonlight. Fertile soil. Larry promises to keep the conversation organic.", "The garden is blooming. Larry hopes it's contagious.", "Something here knows how to grow without bragging about it."]
	elif mode_for(from_id, to_id) == "taxi":
		lines = ["'Take me somewhere hot.' The driver politely leaves the heater off.", "Larry slides into the back seat. His best move all evening has a seat belt.", "He asks for a scenic route. The driver points out three divorce attorneys."]
	elif to_id == "backroom":
		lines = ["Behind the velvet curtain: less mystery, considerably more feather maintenance.", "Larry slips backstage. His collar has been waiting years for this moment.", "He walks like he belongs. The shoulders are doing most of the acting."]
	elif to_id == "shop":
		lines = ["Open all night. Larry admires a business with compatible ambitions.", "A little retail therapy. The wine has a better pickup line than he does.", "He enters with champagne tastes and convenience-store timing."]
	else:
		lines = ["Larry puts his best foot forward. The other one denies any involvement.", "A man, a plan, and trousers with absolutely no room for doubt.", "The night is young. Larry's cologne remembers the original release."]
	return lines[posmod(variant, lines.size())]

func play(from_id: String, to_id: String, from_room: Dictionary, to_room: Dictionary, from_texture: Texture2D, to_texture: Texture2D, reduced: bool = false, variant: int = 0) -> void:
	# Replaying the same instance is supported without leaving animation children.
	for child in get_children():
		remove_child(child)
		child.queue_free()
	_from_id = from_id
	_to_id = to_id
	_from_name = str(from_room.get("name", from_id.capitalize()))
	_to_name = str(to_room.get("name", to_id.capitalize()))
	mode = mode_for(from_id, to_id)
	reduced_motion = reduced
	duration = 1.0 if reduced else float(DURATIONS[mode])
	elapsed = 0.0
	_finished_emitted = false
	active = true
	size = Vector2(1000, 700)
	mouse_filter = Control.MOUSE_FILTER_STOP
	_build(from_texture, to_texture, caption_for(from_id, to_id, variant))
	_update_scene()
	set_process(true)
	queue_redraw()
	if is_inside_tree():
		skip_button.grab_focus()

func finish() -> void:
	if _finished_emitted:
		return
	active = false
	_finished_emitted = true
	set_process(false)
	if is_instance_valid(actor):
		actor.walking = false
		actor.set_process(false)
	if is_instance_valid(skip_button):
		skip_button.disabled = true
	finished.emit()

func _exit_tree() -> void:
	active = false
	set_process(false)
	if is_instance_valid(actor):
		actor.walking = false
		actor.set_process(false)

func _process(delta: float) -> void:
	if not active:
		return
	elapsed = minf(duration, elapsed + maxf(0.0, delta))
	_update_scene()
	if elapsed >= duration:
		finish()

func _style(color: Color, edge: Color, radius: int = 10) -> StyleBoxFlat:
	var box := StyleBoxFlat.new()
	box.bg_color = color
	box.border_color = edge
	box.set_border_width_all(2)
	box.set_corner_radius_all(radius)
	return box

func _text(value: String, rect: Rect2, font_size: int, color: Color = CREAM) -> Label:
	var label := Label.new()
	label.clip_text = true
	label.position = rect.position
	label.size = rect.size
	label.text = value
	label.add_theme_font_override("font", _body_font)
	label.add_theme_font_size_override("font_size", font_size)
	label.add_theme_color_override("font_color", color)
	label.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(label)
	return label

func _image(texture: Texture2D) -> TextureRect:
	var picture := TextureRect.new()
	picture.texture = texture
	picture.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	picture.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_COVERED
	picture.size = STAGE_SIZE
	picture.mouse_filter = Control.MOUSE_FILTER_IGNORE
	stage.add_child(picture)
	return picture

func _build(from_texture: Texture2D, to_texture: Texture2D, caption: String) -> void:
	_body_font = FontVariation.new()
	_body_font.base_font = BODY_FONT
	_body_font.variation_opentype = {2003265652: 450.0}
	_title_font = FontVariation.new()
	_title_font.base_font = TITLE_FONT
	_title_font.variation_opentype = {2003265652: 650.0}
	var panel := Panel.new()
	panel.size = size
	panel.add_theme_stylebox_override("panel", _style(INK, Color("776078"), 18))
	panel.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(panel)
	_text("MEANWHILE, IN LOST WAGES…", Rect2(30, 17, 710, 27), 15, MINT)
	var title := _text(_to_name, Rect2(28, 42, 944, 45), 31)
	title.add_theme_font_override("font", _title_font)
	stage = Control.new()
	stage.name = "TravelStage"
	stage.position = Vector2(28, 101)
	stage.size = STAGE_SIZE
	stage.clip_contents = true
	stage.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(stage)
	_departure = _image(from_texture)
	_arrival = _image(to_texture)
	_backdrop = PaintLayer.new()
	_backdrop.size = STAGE_SIZE
	_backdrop.paint = _draw_backdrop
	stage.add_child(_backdrop)
	actor = Actor.new()
	actor.name = "TravelLarry"
	actor.set_reduced_motion(reduced_motion)
	stage.add_child(actor)
	_foreground = PaintLayer.new()
	_foreground.size = STAGE_SIZE
	_foreground.paint = _draw_foreground
	stage.add_child(_foreground)
	_phase_label = _text("", Rect2(47, 116, 898, 31), 17)
	_phase_label.add_theme_color_override("font_shadow_color", Color.BLACK)
	_phase_label.add_theme_constant_override("shadow_offset_x", 2)
	_phase_label.add_theme_constant_override("shadow_offset_y", 2)
	caption_label = _text(caption, Rect2(34, 539, 932, 77), 24)
	caption_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	var track := ColorRect.new()
	track.position = Vector2(34, 626)
	track.size = Vector2(460, 4)
	track.color = Color("343749")
	track.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(track)
	_progress = ColorRect.new()
	_progress.size = Vector2(0, 4)
	_progress.color = MINT
	_progress.mouse_filter = Control.MOUSE_FILTER_IGNORE
	track.add_child(_progress)
	_text("%s  →  %s" % [_from_name, _to_name], Rect2(34, 642, 544, 27), 14, Color("c1b6c8"))
	skip_button = Button.new()
	skip_button.name = "SkipTravel"
	skip_button.text = "Skip travel · Space / Escape"
	skip_button.position = Vector2(593, 633)
	skip_button.size = Vector2(372, 43)
	skip_button.add_theme_font_override("font", _body_font)
	skip_button.add_theme_font_size_override("font_size", 18)
	skip_button.add_theme_color_override("font_color", CREAM)
	skip_button.add_theme_stylebox_override("normal", _style(Color("202c3d"), Color("536377")))
	skip_button.add_theme_stylebox_override("hover", _style(Color("304052"), MINT))
	skip_button.add_theme_stylebox_override("pressed", _style(Color("435064"), PINK))
	skip_button.add_theme_stylebox_override("focus", _style(Color.TRANSPARENT, PINK))
	skip_button.mouse_default_cursor_shape = Control.CURSOR_POINTING_HAND
	skip_button.pressed.connect(finish)
	add_child(skip_button)
	if reduced_motion:
		_departure.size = Vector2(466, STAGE_SIZE.y)
		_arrival.position = Vector2(478, 0)
		_arrival.size = Vector2(466, STAGE_SIZE.y)
		_phase_label.text = "DEPARTURE"
		var arrival_label := _text("ARRIVAL", Rect2(524, 116, 420, 31), 17)
		arrival_label.add_theme_color_override("font_shadow_color", Color.BLACK)
		arrival_label.add_theme_constant_override("shadow_offset_x", 2)
		arrival_label.add_theme_constant_override("shadow_offset_y", 2)

func _ramp(start: float, end: float, progress: float) -> float:
	return smoothstep(start, end, progress)

func _update_scene() -> void:
	var p := clampf(elapsed / duration, 0.0, 1.0)
	_progress.size.x = 460.0 * p
	if reduced_motion:
		actor.visible = false
		actor.walking = false
		_departure.modulate = Color.WHITE
		_arrival.modulate = Color.WHITE
		_progress.size.x = 460.0
		return
	var arrival_blend := _ramp(0.53, 0.72, p)
	_arrival.modulate.a = arrival_blend
	_departure.modulate.a = 1.0
	actor.visible = true
	actor.rotation = 0.0
	actor.scale = Vector2(1.15, 1.15)
	actor.modulate.a = 1.0
	actor.walking = true
	_phase_label.text = ("LEAVING  ·  " + _from_name) if p < 0.57 else ("ARRIVING  ·  " + _to_name)
	match mode:
		"taxi": _update_taxi(p)
		"elevator": _update_elevator(p)
		"rope":
			actor.position = Vector2(lerpf(218, 718, p), 303 + sin(p * PI) * 42)
			actor.rotation = sin(p * TAU) * 0.045
			actor.scale = Vector2(0.95, 0.95)
			actor.walking = p < 0.9
		"door", "terrace":
			if p < 0.56:
				actor.position = Vector2(lerpf(136, _door_x(true), _ramp(0.02, 0.52, p)), 350)
				actor.modulate.a = 1.0 - _ramp(0.43, 0.54, p)
				actor.scale = Vector2.ONE * lerpf(1.2, 0.93, _ramp(0.2, 0.52, p))
			else:
				actor.position = Vector2(lerpf(219, 454, _ramp(0.62, 0.96, p)), 350)
				actor.modulate.a = _ramp(0.62, 0.7, p)
				actor.scale = Vector2.ONE * lerpf(0.95, 1.2, _ramp(0.62, 0.96, p))
			actor.walking = p < 0.96
		_:
			actor.position = Vector2(lerpf(123, 820, _ramp(0.02, 0.97, p)), 349)
			actor.walking = p < 0.97
	_backdrop.queue_redraw()
	_foreground.queue_redraw()

func _update_taxi(p: float) -> void:
	# Boarding happens on an exterior curb, even when the departure room is indoors.
	# The car disappears fully before the destination interior can be revealed.
	_arrival.modulate.a = _ramp(0.76, 0.88, p)
	_phase_label.text = ("OUTSIDE  ·  " + _from_name) if p < 0.3 else "ON THE NEON STRIP" if p < 0.76 else ("ARRIVING  ·  " + _to_name)
	_taxi_x = lerpf(384, 632, _ramp(0.3, 0.77, p))
	if p < 0.24:
		actor.position = Vector2(lerpf(113, _taxi_x - 40, _ramp(0.0, 0.23, p)), 356)
		actor.modulate.a = 1.0 - _ramp(0.19, 0.24, p)
	elif p < 0.77:
		actor.position = Vector2(_taxi_x + 19, 302)
		actor.scale = Vector2(0.47, 0.47)
		actor.walking = false
		actor.modulate.a = _ramp(0.24, 0.29, p) * (1.0 - _ramp(0.66, 0.75, p))
	else:
		actor.position = Vector2(lerpf(_taxi_x + 78, 870, _ramp(0.77, 0.96, p)), 356)
		actor.modulate.a = _ramp(0.81, 0.87, p)
		actor.walking = p < 0.97

func _update_elevator(p: float) -> void:
	_arrival.modulate.a = _ramp(0.64, 0.8, p)
	actor.position = Vector2(lerpf(176, 471, _ramp(0.0, 0.26, p)), 353)
	actor.scale = Vector2.ONE * lerpf(1.15, 0.94, _ramp(0.0, 0.28, p))
	actor.walking = p < 0.27 or p > 0.78
	if p > 0.78:
		actor.position = Vector2(lerpf(471, 696, _ramp(0.78, 0.98, p)), 353)
		actor.scale = Vector2.ONE * lerpf(0.94, 1.15, _ramp(0.78, 0.98, p))

func _draw_backdrop(layer: Control) -> void:
	if reduced_motion:
		layer.draw_rect(Rect2(468, 0, 8, STAGE_SIZE.y), INK)
		return
	var p := clampf(elapsed / duration, 0.0, 1.0)
	layer.draw_rect(Rect2(Vector2.ZERO, STAGE_SIZE), Color(0.03, 0.02, 0.08, 0.16))
	# A deliberate foreground pavement gives the small pixel actor a stable stage.
	layer.draw_rect(Rect2(0, 354, 944, 68), Color(0.035, 0.03, 0.07, 0.72))
	layer.draw_line(Vector2(0, 356), Vector2(944, 356), Color(0.96, 0.4, 0.7, 0.28), 2)
	match mode:
		"door", "terrace": _draw_door(layer, p)
		"taxi":
			_draw_city(layer, p)
			_draw_taxi_back(layer, p)
		"elevator":
			layer.draw_rect(Rect2(326, 77, 292, 279), Color("252334"))
			layer.draw_rect(Rect2(343, 93, 257, 262), Color("4b3847"))
			layer.draw_rect(Rect2(348, 99, 247, 249), Color("30212f"))
			layer.draw_line(Vector2(352, 274), Vector2(590, 274), GOLD, 5)
			layer.draw_rect(Rect2(391, 54, 160, 33), Color("151822"))
			var up := _to_id in ["penthouse", "rooftop"]
			var level := int(lerpf(1, 8, _ramp(0.4, 0.66, p)))
			layer.draw_string(_title_font, Vector2(405, 77), ("UP  %02d" % level) if up else ("DOWN  %02d" % (9 - level)), HORIZONTAL_ALIGNMENT_CENTER, 132, 20, GOLD)
			layer.draw_circle(Vector2(644, 213), 14, GOLD)
			layer.draw_circle(Vector2(644, 213), 8, PINK)
		"rope": _draw_rope(layer)

func _door_x(departing: bool) -> float:
	if departing and _from_id == "street" and _to_id == "bar":
		return 370.0
	return 582.0 if departing else 205.0

func _draw_door(layer: Control, p: float) -> void:
	var departing := p < 0.6
	var x := _door_x(departing)
	var visibility := 1.0 - _ramp(0.49, 0.61, p) if departing else _ramp(0.6, 0.73, p)
	var trim := GOLD if mode == "door" else MINT
	var door_color := Color("4a263c") if mode == "door" else Color("244444")
	layer.draw_rect(Rect2(x - 63, 127, 139, 229), Color(trim, visibility))
	layer.draw_rect(Rect2(x - 55, 135, 123, 219), Color(INK, visibility))
	# The hinged panel narrows as Larry opens it; the dark passage remains behind.
	var openness := _ramp(0.18, 0.41, p) if departing else 1.0 - _ramp(0.78, 0.97, p)
	var panel_width := lerpf(120, 23, openness)
	layer.draw_colored_polygon(PackedVector2Array([Vector2(x - 54, 136), Vector2(x - 54 + panel_width, 136 + openness * 13), Vector2(x - 54 + panel_width, 354 - openness * 12), Vector2(x - 54, 354)]), Color(door_color, visibility))
	layer.draw_line(Vector2(x - 53, 136), Vector2(x - 53, 354), Color(trim, visibility), 3)
	layer.draw_circle(Vector2(x - 61 + panel_width, 247), 4, Color(GOLD, visibility))
	var sign := "LEFTY'S" if _to_id == "bar" else "EXIT" if _from_id == "bar" and _to_id == "street" else "WC" if _to_id == "bathroom" else "BACKSTAGE" if _to_id == "backroom" else "TERRACE" if mode == "terrace" else "THIS WAY"
	layer.draw_rect(Rect2(x - 95, 84, 196, 32), Color(INK, visibility))
	layer.draw_string(_body_font, Vector2(x - 90, 108), sign, HORIZONTAL_ALIGNMENT_CENTER, 184, 18, Color(trim, visibility))
	if mode == "terrace":
		for offset in [-110.0, 109.0]:
			layer.draw_rect(Rect2(x + offset - 17, 322, 34, 34), Color("6b4c61"))
			layer.draw_circle(Vector2(x + offset, 313), 25, Color("305343"))
			layer.draw_circle(Vector2(x + offset - 7, 287), 16, Color("457352"))

func _draw_city(layer: Control, p: float) -> void:
	var strength := 1.0 - _ramp(0.76, 0.88, p)
	if strength <= 0.0:
		return
	layer.draw_rect(Rect2(Vector2.ZERO, STAGE_SIZE), Color(Color("171a34"), strength))
	layer.draw_rect(Rect2(0, 354, 944, 68), Color(Color("222337"), strength))
	layer.draw_circle(Vector2(794, 68), 33, Color(Color("ffb796"), strength))
	for i in range(11):
		var x := fposmod(float(i * 113) - p * 250.0, 1230.0) - 143.0
		var height := float(102 + (i * 43) % 169)
		var tint := Color("362742") if i % 2 == 0 else Color("242b48")
		layer.draw_rect(Rect2(x, 355 - height, 98, height), Color(tint, strength))
		for row in range(int(height / 25.0) - 1):
			for col in range(3):
				var color := GOLD if (row + col + i) % 3 == 0 else Color("6796b3")
				layer.draw_rect(Rect2(x + 14 + col * 27, 365 - height + row * 25, 10, 7), Color(color, strength * 0.65))
		if i % 3 == 0:
			layer.draw_line(Vector2(x + 5, 356 - height), Vector2(x + 91, 356 - height), Color(PINK, strength), 4)
	for i in range(7):
		var x := fposmod(i * 180.0 - p * 1460.0, 1260.0) - 180.0
		layer.draw_rect(Rect2(x, 391, 75, 3), Color(GOLD, strength * 0.7))

func _draw_taxi_back(layer: Control, p: float) -> void:
	if p >= 0.75:
		return
	var visibility := 1.0 - _ramp(0.66, 0.75, p)
	layer.draw_set_transform(Vector2.ZERO)
	layer.draw_style_box(_style(Color(Color("2a2130"), visibility), Color(Color("efc768"), visibility), 14), Rect2(_taxi_x - 92, 235, 195, 82))
	layer.draw_rect(Rect2(_taxi_x - 69, 241, 144, 58), Color(Color("588390"), visibility))
	layer.draw_rect(Rect2(_taxi_x - 17, 210, 61, 25), Color(Color("ffe1a2"), visibility))
	layer.draw_string(_body_font, Vector2(_taxi_x - 12, 229), "TAXI", HORIZONTAL_ALIGNMENT_CENTER, 52, 17, Color(INK, visibility))
	# Driver silhouette remains distinct from Larry in the passenger window.
	layer.draw_circle(Vector2(_taxi_x - 42, 268), 12, Color(Color("443147"), visibility))
	layer.draw_rect(Rect2(_taxi_x - 56, 279, 28, 22), Color(Color("443147"), visibility))

func _draw_rope(layer: Control) -> void:
	layer.draw_rect(Rect2(130, 311, 105, 111), Color("322d41"))
	layer.draw_rect(Rect2(711, 311, 105, 111), Color("322d41"))
	for x in [178, 765]:
		layer.draw_line(Vector2(x, 202), Vector2(x, 355), Color("768797"), 7)
		layer.draw_line(Vector2(x - 42, 220), Vector2(x + 42, 220), Color("92a0ad"), 5)
	var rope := PackedVector2Array()
	var hand_rope := PackedVector2Array()
	for i in range(31):
		var t := float(i) / 30.0
		rope.append(Vector2(lerpf(185, 757, t), 311 + sin(t * PI) * 42))
		hand_rope.append(Vector2(lerpf(185, 757, t), 224 + sin(t * PI) * 26))
	layer.draw_polyline(rope, Color("493325"), 8, true)
	layer.draw_polyline(rope, GOLD, 4, true)
	layer.draw_polyline(hand_rope, GOLD, 4, true)

func _draw_foreground(layer: Control) -> void:
	if reduced_motion:
		layer.draw_rect(Rect2(1, 1, 942, 420), Color(0.88, 0.7, 0.46, 0.7), false, 2)
		return
	var p := clampf(elapsed / duration, 0.0, 1.0)
	if mode == "taxi" and p < 0.75:
		var visibility := 1.0 - _ramp(0.66, 0.75, p)
		var body_color := Color(Color("e6b94e"), visibility)
		layer.draw_style_box(_style(body_color, Color(Color("f9d780"), visibility), 15), Rect2(_taxi_x - 140, 294, 298, 50))
		layer.draw_rect(Rect2(_taxi_x - 105, 302, 228, 13), Color(Color("302a3b"), visibility))
		for i in range(15):
			layer.draw_rect(Rect2(_taxi_x - 103 + i * 15, 302 + (i % 2) * 6, 7, 6), Color(CREAM, visibility))
		layer.draw_line(Vector2(_taxi_x - 6, 241), Vector2(_taxi_x - 6, 331), Color(Color("e6b94e"), visibility), 5)
		layer.draw_rect(Rect2(_taxi_x + 4, 321, 16, 3), Color(Color("795636"), visibility))
		for x in [_taxi_x - 82, _taxi_x + 99]:
			layer.draw_circle(Vector2(x, 344), 24, Color(Color("161725"), visibility))
			layer.draw_circle(Vector2(x, 344), 12, Color(Color("b1a8b4"), visibility))
			var spin := p * 28.0
			layer.draw_line(Vector2(x, 344) + Vector2(cos(spin), sin(spin)) * 9, Vector2(x, 344) - Vector2(cos(spin), sin(spin)) * 9, Color(INK, visibility), 3)
		layer.draw_rect(Rect2(_taxi_x + 142, 307, 16, 12), Color(Color("fff0cb"), visibility))
		layer.draw_rect(Rect2(_taxi_x - 141, 307, 10, 10), Color(PINK, visibility))
	elif mode == "elevator":
		var closure := _ramp(0.26, 0.4, p) * (1.0 - _ramp(0.68, 0.8, p))
		var door_width := 126.0 * closure
		layer.draw_rect(Rect2(345, 96, door_width, 260), Color("6c5662"))
		layer.draw_rect(Rect2(598 - door_width, 96, door_width, 260), Color("806975"))
		if closure > 0.01:
			layer.draw_line(Vector2(345 + door_width, 96), Vector2(345 + door_width, 356), GOLD, 2)
			layer.draw_line(Vector2(598 - door_width, 96), Vector2(598 - door_width, 356), GOLD, 2)
	# Restrained cinematic mattes and a stable gold frame. Never flash to white.
	layer.draw_rect(Rect2(0, 0, 944, 10), Color(0.02, 0.02, 0.05, 0.8))
	layer.draw_rect(Rect2(0, 412, 944, 10), Color(0.02, 0.02, 0.05, 0.8))
	layer.draw_rect(Rect2(1, 1, 942, 420), Color(0.88, 0.7, 0.46, 0.7), false, 2)
