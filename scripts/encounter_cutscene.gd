extends Control
## A fully clothed, theatrical sex-farce transition. The game model resolves
## mutual invitations first; this presentation never awards progress or items.
signal finished

const Actor = preload("res://scripts/actor.gd")
const BODY_FONT = preload("res://assets/fonts/Outfit.ttf")
const TITLE_FONT = preload("res://assets/fonts/SpaceGrotesk.ttf")
const INK := Color("101323")
const CREAM := Color("f5e9d6")
const PINK := Color("f482af")
const GOLD := Color("d9b369")
const MINT := Color("94dfcf")

class PaintLayer extends Control:
	var paint: Callable
	func _ready() -> void:
		mouse_filter = Control.MOUSE_FILTER_IGNORE
	func _draw() -> void:
		if paint.is_valid():
			paint.call(self)

var active := false
var elapsed := 0.0
var duration := 5.4
var reduced_motion := false
var player_actor: Control
var partner_actor: Control
var skip_button: Button
var caption_label: Label
var stage: Control
var profile: Dictionary = {}
var encounter: Dictionary = {}
var _finished_emitted := false
var _backdrop: PaintLayer
var _foreground: PaintLayer
var _phase_label: Label
var _name_label: Label
var _player_name := "Larry"
var _partner_name := "Eve"
var _opening_caption := ""
var _aftermath_caption := ""
var _body_font: FontVariation
var _title_font: FontVariation

func _init() -> void:
	set_process(false)

func play(player_profile: Dictionary, invitation: Dictionary, reduced: bool = false) -> void:
	for child in get_children():
		remove_child(child)
		child.queue_free()
	profile = player_profile.duplicate(true)
	encounter = invitation.duplicate(true)
	_player_name = str(profile.get("name", "Lisa" if profile.get("character", "larry") == "lisa" else "Larry"))
	_partner_name = str(encounter.get("name", encounter.get("partner", "Your date")))
	_opening_caption = str(encounter.get("invitation", "%s takes your hand. 'Come on in. The wallpaper has seen worse.' The narrator suddenly remembers an appointment." % _partner_name))
	_aftermath_caption = "%s and %s had sex. A lovely time was had by both. The wallpaper refuses to comment." % [_player_name, _partner_name]
	if encounter.get("finale", false):
		_aftermath_caption = "%s got laid with %s. Both call it a happy ending. The leisure suit takes all the credit." % [_player_name, _partner_name]
	_aftermath_caption = str(encounter.get("caption", _aftermath_caption))
	reduced_motion = reduced
	duration = 1.8 if reduced_motion else 5.4
	elapsed = 0.0
	_finished_emitted = false
	active = true
	size = Vector2(1000, 700)
	mouse_filter = Control.MOUSE_FILTER_STOP
	_build()
	_update_scene()
	set_process(true)
	if is_inside_tree():
		skip_button.grab_focus()

func finish() -> void:
	if _finished_emitted:
		return
	_finished_emitted = true
	active = false
	set_process(false)
	for performer in [player_actor, partner_actor]:
		if is_instance_valid(performer):
			performer.walking = false
			performer.set_process(false)
	if is_instance_valid(skip_button):
		skip_button.disabled = true
	finished.emit()

func _exit_tree() -> void:
	active = false
	set_process(false)
	for performer in [player_actor, partner_actor]:
		if is_instance_valid(performer):
			performer.walking = false
			performer.set_process(false)

func _process(delta: float) -> void:
	if not active:
		return
	elapsed = minf(duration, elapsed + maxf(delta, 0.0))
	_update_scene()
	if elapsed >= duration:
		finish()

func _style(fill: Color, edge: Color, radius: int = 12) -> StyleBoxFlat:
	var box := StyleBoxFlat.new()
	box.bg_color = fill
	box.border_color = edge
	box.set_border_width_all(2)
	box.set_corner_radius_all(radius)
	return box

func _text(value: String, rect: Rect2, point_size: int, tint: Color = CREAM) -> Label:
	var label := Label.new()
	label.position = rect.position
	label.size = rect.size
	label.text = value
	label.clip_text = true
	label.mouse_filter = Control.MOUSE_FILTER_IGNORE
	label.add_theme_font_override("font", _body_font)
	label.add_theme_font_size_override("font_size", point_size)
	label.add_theme_color_override("font_color", tint)
	add_child(label)
	return label

func _build() -> void:
	_body_font = FontVariation.new()
	_body_font.base_font = BODY_FONT
	_body_font.variation_opentype = {2003265652: 450.0}
	_title_font = FontVariation.new()
	_title_font.base_font = TITLE_FONT
	_title_font.variation_opentype = {2003265652: 650.0}
	var panel := Panel.new()
	panel.size = size
	panel.mouse_filter = Control.MOUSE_FILTER_IGNORE
	panel.add_theme_stylebox_override("panel", _style(INK, Color("776078"), 18))
	add_child(panel)
	_text("LOST WAGES AFTER DARK  ·  POLYESTER OPTIONAL", Rect2(30, 17, 940, 27), 15, MINT)
	var title := _text(str(encounter.get("title", "A private invitation")), Rect2(28, 42, 944, 45), 30)
	title.add_theme_font_override("font", _title_font)
	stage = Control.new()
	stage.name = "EncounterStage"
	stage.position = Vector2(28, 101)
	stage.size = Vector2(944, 422)
	stage.clip_contents = true
	stage.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(stage)
	_backdrop = PaintLayer.new()
	_backdrop.size = stage.size
	_backdrop.paint = _draw_backdrop
	stage.add_child(_backdrop)
	player_actor = Actor.new()
	player_actor.role = "lisa" if profile.get("character", "larry") == "lisa" else "larry"
	player_actor.name = "EncounterPlayer"
	player_actor.gender = "female" if player_actor.role == "lisa" else "male"
	player_actor.is_larry = player_actor.role == "larry"
	player_actor.set_reduced_motion(reduced_motion)
	stage.add_child(player_actor)
	partner_actor = Actor.new()
	var partner_id: String = str(encounter.get("partner", "")).to_lower()
	partner_actor.name = "EncounterPartner"
	partner_actor.gender = str(encounter.get("gender", "male" if partner_id == "adam" else "female"))
	partner_actor.role = ("adam" if partner_actor.gender == "male" else "eve") if encounter.get("finale", false) or partner_id in ["eve", "adam"] else "romance_guest"
	partner_actor.is_larry = false
	partner_actor.suit = Color("b971a6") if partner_actor.gender == "female" else Color("79a9aa")
	partner_actor.hair = Color("4d3442")
	partner_actor.set_reduced_motion(reduced_motion)
	stage.add_child(partner_actor)
	_foreground = PaintLayer.new()
	_foreground.size = stage.size
	_foreground.paint = _draw_foreground
	stage.add_child(_foreground)
	_phase_label = _text("YOUR PLACE OR MINE?", Rect2(55, 115, 890, 31), 17, MINT)
	_name_label = _text("%s + %s" % [_player_name, _partner_name], Rect2(56, 469, 885, 33), 22)
	_name_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	var caption_scroll := ScrollContainer.new()
	caption_scroll.name = "EncounterCaptionScroll"
	caption_scroll.position = Vector2(35, 542)
	caption_scroll.size = Vector2(932, 85)
	caption_scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	caption_scroll.vertical_scroll_mode = ScrollContainer.SCROLL_MODE_AUTO
	add_child(caption_scroll)
	caption_label = Label.new()
	caption_label.text = _opening_caption
	caption_label.custom_minimum_size = Vector2(910, 77)
	caption_label.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	caption_label.add_theme_font_override("font", _body_font)
	caption_label.add_theme_font_size_override("font_size", 21)
	caption_label.add_theme_color_override("font_color", CREAM)
	caption_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	caption_scroll.add_child(caption_label)
	_text("A LITTLE PRIVACY. A GREAT DEAL OF POLYESTER.", Rect2(35, 641, 568, 29), 13, GOLD)
	skip_button = Button.new()
	skip_button.name = "SkipEncounter"
	skip_button.text = "Skip scene · Space / Escape"
	skip_button.position = Vector2(602, 635)
	skip_button.size = Vector2(363, 42)
	skip_button.add_theme_font_override("font", _body_font)
	skip_button.add_theme_font_size_override("font_size", 18)
	skip_button.add_theme_color_override("font_color", CREAM)
	skip_button.add_theme_stylebox_override("normal", _style(Color("32253e"), Color("78617b")))
	skip_button.add_theme_stylebox_override("hover", _style(Color("50334e"), PINK))
	skip_button.add_theme_stylebox_override("pressed", _style(Color("63405d"), GOLD))
	skip_button.add_theme_stylebox_override("focus", _style(Color.TRANSPARENT, MINT))
	skip_button.mouse_default_cursor_shape = Control.CURSOR_POINTING_HAND
	skip_button.pressed.connect(finish)
	add_child(skip_button)

func _progress() -> float:
	return 1.0 if reduced_motion else clampf(elapsed / duration, 0.0, 1.0)

func _update_scene() -> void:
	var p := _progress()
	var walk := smoothstep(0.03, 0.38, p)
	player_actor.position = Vector2(lerpf(199, 405, walk), 358)
	partner_actor.position = Vector2(lerpf(746, 545, walk), 358)
	player_actor.scale = Vector2.ONE * 1.38
	partner_actor.scale = Vector2(-1.38, 1.38)
	# They enter separately while fully clothed, then disappear before the
	# curtains close. No intimate action is drawn or animated behind them.
	var opacity := 1.0 - smoothstep(0.33, 0.45, p)
	for performer in [player_actor, partner_actor]:
		performer.modulate.a = opacity
		performer.visible = not reduced_motion and p < 0.46
		performer.walking = not reduced_motion and p < 0.38
	_phase_label.text = "YOUR PLACE OR MINE?" if p < 0.48 else "THE CAMERA KNOWS WHEN TO LEAVE" if p < 0.76 else "A LITTLE LATER…"
	caption_label.text = _opening_caption if p < 0.76 else _aftermath_caption
	_name_label.text = "%s + %s" % [_player_name, _partner_name] if p < 0.76 else "TWO HAPPY ADULTS. ONE SMUG NARRATOR."
	_backdrop.queue_redraw()
	_foreground.queue_redraw()

func _draw_backdrop(layer: Control) -> void:
	layer.draw_rect(Rect2(0, 0, 944, 422), Color("302137"))
	# Diamond wallpaper and a gold arch quote a gloriously over-designed motel.
	for row in range(5):
		for col in range(12):
			var pos := Vector2(27 + col * 82, 61 + row * 67)
			layer.draw_polyline(PackedVector2Array([pos + Vector2(0, -12), pos + Vector2(8, 0), pos + Vector2(0, 12), pos + Vector2(-8, 0), pos + Vector2(0, -12)]), Color("614252"), 2)
	layer.draw_rect(Rect2(0, 359, 944, 63), Color("291e34"))
	layer.draw_line(Vector2(0, 359), Vector2(944, 359), GOLD, 3)
	layer.draw_rect(Rect2(329, 65, 286, 294), GOLD)
	layer.draw_rect(Rect2(340, 76, 264, 283), Color("151522"))
	layer.draw_rect(Rect2(350, 89, 244, 270), Color("2a2230"))
	for x in [270.0, 674.0]:
		layer.draw_rect(Rect2(x - 3, 162, 6, 72), GOLD)
		layer.draw_colored_polygon(PackedVector2Array([Vector2(x - 27, 141), Vector2(x + 27, 141), Vector2(x + 18, 107), Vector2(x - 18, 107)]), Color("dc9b99"))
	# Two unattended champagne flutes deliver the joke without depicting sex.
	layer.draw_rect(Rect2(90, 319, 109, 8), GOLD)
	layer.draw_rect(Rect2(141, 327, 7, 32), Color("66515b"))
	for x in [116.0, 165.0]:
		layer.draw_line(Vector2(x, 298), Vector2(x, 316), CREAM, 2)
		layer.draw_line(Vector2(x - 8, 316), Vector2(x + 8, 316), CREAM, 2)
		layer.draw_colored_polygon(PackedVector2Array([Vector2(x - 9, 279), Vector2(x + 9, 279), Vector2(x + 5, 298), Vector2(x - 5, 298)]), Color("d9ac75"))
	layer.draw_string(_title_font, Vector2(347, 54), "THE PRIVATE SCREENING", HORIZONTAL_ALIGNMENT_CENTER, 250, 15, PINK)

func _draw_foreground(layer: Control) -> void:
	var p := _progress()
	var closed := smoothstep(0.39, 0.58, p)
	var width := lerpf(28, 132, closed)
	for side in [0, 1]:
		var x := 340.0 if side == 0 else 604.0 - width
		layer.draw_rect(Rect2(x, 76, width, 282), Color("853952") if side == 0 else Color("99445c"))
		for i in range(int(width / 17)):
			layer.draw_rect(Rect2(x + 8 + i * 17, 77, 4, 279), Color("b85e70"))
		layer.draw_rect(Rect2(x, 349, width, 9), GOLD.darkened(0.15))
	if p >= 0.5:
		var alpha := 1.0 if reduced_motion else smoothstep(0.5, 0.6, p)
		layer.draw_style_box(_style(Color(INK, alpha), Color(GOLD, alpha), 8), Rect2(370, 174, 204, 96))
		layer.draw_string(_title_font, Vector2(378, 202), "DO NOT DISTURB", HORIZONTAL_ALIGNMENT_CENTER, 188, 19, Color(PINK, alpha))
		layer.draw_string(_body_font, Vector2(378, 225), "CRITICS INCLUDED", HORIZONTAL_ALIGNMENT_CENTER, 188, 13, Color(CREAM, alpha))
		layer.draw_string(_body_font, Vector2(378, 251), "★★★★★  discretion", HORIZONTAL_ALIGNMENT_CENTER, 188, 13, Color(GOLD, alpha))
	if p >= 0.76:
		layer.draw_style_box(_style(Color("3a2b41"), GOLD, 8), Rect2(708, 213, 173, 81))
		layer.draw_string(_title_font, Vector2(717, 240), "HAPPY ENDING", HORIZONTAL_ALIGNMENT_CENTER, 155, 17, PINK)
		layer.draw_string(_body_font, Vector2(717, 263), "NO REFUNDS", HORIZONTAL_ALIGNMENT_CENTER, 155, 14, CREAM)
		layer.draw_string(_body_font, Vector2(717, 283), "NONE REQUESTED", HORIZONTAL_ALIGNMENT_CENTER, 155, 11, GOLD)
	layer.draw_rect(Rect2(1, 1, 942, 420), GOLD.darkened(0.25), false, 2)
