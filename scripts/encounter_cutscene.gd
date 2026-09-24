extends Control
## A fully clothed, theatrical sex-farce transition. The game model resolves
## mutual invitations first; this presentation never awards progress or items.
signal finished
signal phase_changed

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
var is_finale := false
var phase := "invitation"
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
var _title_label: Label

func _init() -> void:
	set_process(false)

func play(player_profile: Dictionary, invitation: Dictionary, reduced: bool = false) -> void:
	for child in get_children():
		remove_child(child)
		child.queue_free()
	profile = player_profile.duplicate(true)
	encounter = invitation.duplicate(true)
	is_finale = bool(encounter.get("finale", false))
	_player_name = str(profile.get("name", "Lisa" if profile.get("character", "larry") == "lisa" else "Larry"))
	_partner_name = str(encounter.get("name", encounter.get("partner", "Your date")))
	_opening_caption = str(encounter.get("invitation", "%s takes your hand. 'Come on in. The wallpaper has seen worse.' The narrator suddenly remembers an appointment." % _partner_name))
	_aftermath_caption = "%s and %s had sex. A lovely time was had by both. The wallpaper refuses to comment." % [_player_name, _partner_name]
	if is_finale:
		_aftermath_caption = "%s got laid with %s. Both call it a happy ending. The leisure suit takes all the credit." % [_player_name, _partner_name]
	_aftermath_caption = str(encounter.get("caption", _aftermath_caption))
	reduced_motion = reduced
	duration = (3.0 if reduced_motion else 12.0) if is_finale else (1.8 if reduced_motion else 5.4)
	phase = ""
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
	_text("LAST CALL IN LOST WAGES  ·  THE GRAND FINALE" if is_finale else "LOST WAGES AFTER DARK  ·  POLYESTER OPTIONAL", Rect2(30, 17, 940, 27), 15, MINT)
	_title_label = _text("One last, very good bad idea." if is_finale else str(encounter.get("title", "A private invitation")), Rect2(28, 42, 944, 45), 30)
	_title_label.add_theme_font_override("font", _title_font)
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
	var appearance: Dictionary = encounter.get("appearance", {})
	if str(appearance.get("role", "")).begins_with("bar_") or str(appearance.get("role", "")).begins_with("party_"):
		partner_actor.role = appearance.role
		partner_actor.skin = Color(str(appearance.get("skin", "dca483")))
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
	if is_finale:
		_update_finale(p)
		return
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
	if is_finale:
		_draw_finale_backdrop(layer)
		return
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
	if is_finale:
		_draw_finale_foreground(layer)
		return
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

func _update_finale(p: float) -> void:
	# Four readable acts, including a full final tableau instead of ending on an
	# empty curtain. The actors stay fully clothed throughout the presentation.
	var previous_phase := phase
	phase = "invitation" if p < 0.25 else "together" if p < 5.0 / 12.0 else "privacy" if p < 2.0 / 3.0 else "sunrise"
	var approach := smoothstep(0.015, 0.25, p)
	player_actor.position = Vector2(lerpf(219, 427, approach), 361)
	partner_actor.position = Vector2(lerpf(727, 519, approach), 361)
	player_actor.scale = Vector2.ONE * 1.4
	partner_actor.scale = Vector2(-1.4, 1.4)
	var morning := smoothstep(2.0 / 3.0, 0.76, p)
	var fade := 1.0 - smoothstep(0.385, 0.435, p) if p < 2.0 / 3.0 else morning
	for performer in [player_actor, partner_actor]:
		performer.visible = phase != "privacy"
		performer.walking = not reduced_motion and phase == "invitation" and p < 0.25
		performer.modulate = Color.WHITE.lerp(Color("ffe4cc"), morning * 0.22)
		performer.modulate.a = 1.0 if reduced_motion else fade
	match phase:
		"invitation":
			_phase_label.text = "01  /  ABOVE THE NEON, BELOW YOUR STANDARDS"
			caption_label.text = "%s crosses the terrace. %s is waiting. For once, that ridiculous collar is not the main attraction." % [_player_name, _partner_name]
		"together":
			_phase_label.text = "02  /  THE FEELING IS MUTUAL"
			caption_label.text = "%s: 'Come here, you magnificent fashion emergency.' The city sparkles. So does your luck." % _partner_name
		"privacy":
			_phase_label.text = "03  /  THE CAMERA EXCUSES ITSELF"
			caption_label.text = "The curtains close. The narrator waits outside. For the first time tonight, nobody needs a walkthrough."
		"sunrise":
			_phase_label.text = "04  /  MORNING GLORY. STRICTLY THE SUNRISE."
			caption_label.text = _aftermath_caption
	_title_label.text = "A sunrise worth staying up for." if phase == "sunrise" else "One last, very good bad idea."
	_name_label.text = "%s  +  %s" % [_player_name, _partner_name]
	_name_label.add_theme_color_override("font_color", GOLD if phase == "sunrise" else CREAM)
	_backdrop.queue_redraw()
	_foreground.queue_redraw()
	if phase != previous_phase:
		# Publish only complete act snapshots, never one callback per frame.
		phase_changed.emit()

func _draw_finale_backdrop(layer: Control) -> void:
	var p := _progress()
	var morning := smoothstep(0.66, 0.77, p)
	var sky_top := Color("171b42").lerp(Color("79445c"), morning)
	var sky_base := Color("6e315b").lerp(Color("f5b17f"), morning)
	for band in range(24):
		layer.draw_rect(Rect2(0, band * 12, 944, 12), sky_top.lerp(sky_base, float(band) / 23.0))
	# A slowly rising disk changes from nightclub moon to improbable happy dawn.
	var sun_y := lerpf(155, 130, morning)
	for glow in range(5, 0, -1):
		layer.draw_circle(Vector2(730, sun_y), 42 + glow * 9, Color(1.0, 0.72, 0.52, 0.018 * morning))
	layer.draw_circle(Vector2(730, sun_y), 42, Color("ddafd4").lerp(Color("ffdda1"), morning))
	for star in range(26):
		var position := Vector2(39 + (star * 131) % 870, 56 + (star * 53) % 139)
		var shine := 0.6 if reduced_motion else 0.5 + sin(elapsed * 1.4 + star) * 0.16
		layer.draw_rect(Rect2(position, Vector2(2, 2)), Color(CREAM, shine * (1.0 - morning)))
	# Chunked skyline and warm windows, framed by palms and the rooftop rail.
	for building in range(15):
		var x := float(building * 68 - 13)
		var height := float(55 + (building * 37) % 92)
		var tint := Color("292440").lerp(Color("785763"), morning * 0.72)
		layer.draw_rect(Rect2(x, 282 - height, 57, height), tint)
		layer.draw_rect(Rect2(x + 8, 270 - height, 39, 12), tint.lightened(0.03))
		for row in range(int(height / 16.0) - 1):
			for col in range(3):
				var color := PINK if (row + building) % 3 == 0 else GOLD
				layer.draw_rect(Rect2(x + 9 + col * 15, 280 - height + row * 16, 5, 5), Color(color, lerpf(0.8, 0.45, morning)))
		if building % 4 == 1:
			layer.draw_line(Vector2(x + 8, 269 - height), Vector2(x + 47, 269 - height), PINK.lerp(GOLD, morning), 3)
	layer.draw_rect(Rect2(0, 281, 944, 141), Color("293345").lerp(Color("6d5361"), morning))
	for tile in range(8):
		layer.draw_line(Vector2(472, 278), Vector2(-90 + tile * 171, 422), Color(GOLD, 0.12), 1)
	for y in [314.0, 352.0, 395.0]:
		layer.draw_line(Vector2(0, y), Vector2(944, y), Color(GOLD, 0.14), 1)
	layer.draw_rect(Rect2(0, 266, 944, 16), Color("514251").lerp(Color("c69276"), morning))
	layer.draw_line(Vector2(0, 266), Vector2(944, 266), GOLD, 3)
	for x in range(16, 944, 80):
		layer.draw_line(Vector2(x, 220), Vector2(x, 268), Color("b28a80"), 5)
	layer.draw_line(Vector2(0, 218), Vector2(944, 218), GOLD.darkened(0.12), 5)
	_draw_finale_palm(layer, Vector2(49, 339), 1.0, morning)
	_draw_finale_palm(layer, Vector2(895, 339), -1.0, morning)
	# Champagne remains outside the curtain, responsibly minding its own bubbles.
	layer.draw_rect(Rect2(259, 301, 82, 7), GOLD)
	layer.draw_rect(Rect2(297, 308, 6, 53), GOLD.darkened(0.3))
	layer.draw_rect(Rect2(272, 358, 57, 5), GOLD.darkened(0.5))
	for x in [281.0, 318.0]:
		layer.draw_colored_polygon(PackedVector2Array([Vector2(x - 7, 277), Vector2(x + 7, 277), Vector2(x + 4, 291), Vector2(x - 4, 291)]), Color("eedb9c"))
		layer.draw_line(Vector2(x, 291), Vector2(x, 302), CREAM, 2)
		layer.draw_line(Vector2(x - 6, 302), Vector2(x + 6, 302), CREAM, 2)
		if morning > 0.6:
			for bubble in range(3):
				var rise := 8.0 + bubble * 8 if reduced_motion else fposmod(elapsed * 12.0 + bubble * 8, 25.0)
				layer.draw_circle(Vector2(x + (bubble % 2) * 4 - 2, 275 - rise), 1.5, Color(CREAM, 0.7))
	# A stable dark name strip ensures both names remain legible in every act.
	layer.draw_rect(Rect2(0, 367, 944, 55), Color(INK, 0.85))

func _draw_finale_palm(layer: Control, base: Vector2, direction: float, morning: float) -> void:
	var leaf := Color("192f39").lerp(Color("31534a"), morning)
	var crown := base + Vector2(direction * 28, -175)
	layer.draw_line(base, crown, Color("765359"), 11)
	for i in range(6):
		var angle := -PI + float(i) * PI / 5.0
		var endpoint := crown + Vector2(cos(angle) * 81, sin(angle) * 37 + 15)
		layer.draw_colored_polygon(PackedVector2Array([crown, endpoint, crown + Vector2(cos(angle) * 52, sin(angle) * 19 + 27)]), leaf)
	layer.draw_rect(Rect2(base + Vector2(-27, -5), Vector2(54, 30)), Color("9c7371"))
	layer.draw_rect(Rect2(base + Vector2(-30, -9), Vector2(60, 8)), GOLD.darkened(0.15))

func _draw_finale_foreground(layer: Control) -> void:
	var p := _progress()
	var closing := smoothstep(0.39, 0.46, p)
	var opening := smoothstep(2.0 / 3.0, 0.73, p)
	var curtain := closing * (1.0 - opening)
	# Velvet covers the entire couple during the private interlude, then opens
	# onto the dawn scene. Nothing is animated or silhouetted behind the fabric.
	if curtain > 0.001:
		var width := 472.0 * curtain
		for side in [0, 1]:
			var x := 0.0 if side == 0 else 944.0 - width
			layer.draw_rect(Rect2(x, 0, width, 366), Color("81364e") if side == 0 else Color("98425a"))
			for fold in range(int(width / 23.0)):
				layer.draw_rect(Rect2(x + 8 + fold * 23, 0, 5, 361), Color("b2576c"))
			layer.draw_rect(Rect2(x, 356, width, 10), GOLD)
	if phase == "privacy":
		layer.draw_style_box(_style(INK, GOLD, 12), Rect2(279, 113, 386, 153))
		layer.draw_string(_title_font, Vector2(295, 155), "DO NOT DISTURB", HORIZONTAL_ALIGNMENT_CENTER, 354, 31, PINK)
		layer.draw_string(_body_font, Vector2(295, 193), "YES, THAT MEANS YOU, NARRATOR.", HORIZONTAL_ALIGNMENT_CENTER, 354, 16, CREAM)
		layer.draw_string(_body_font, Vector2(295, 235), "COLLARS LEFT AT THE DOOR", HORIZONTAL_ALIGNMENT_CENTER, 354, 18, GOLD)
	if phase in ["together", "sunrise"] and curtain < 0.08:
		# A tiny linked-hand gesture, never an intimate or sexual action.
		layer.draw_line(player_actor.position + Vector2(38, -60), partner_actor.position + Vector2(-38, -60), Color("dca483"), 6)
		_draw_heart(layer, Vector2(473, 143), 10.0 if reduced_motion else 10.0 + sin(elapsed * 2.0) * 0.6, PINK)
	if phase == "sunrise":
		var reveal := 1.0 if reduced_motion else smoothstep(0.73, 0.78, p)
		layer.draw_style_box(_style(Color(INK, reveal * 0.86), Color(GOLD, reveal), 10), Rect2(303, 51, 338, 64))
		layer.draw_string(_title_font, Vector2(313, 95), "YOU GOT LAID", HORIZONTAL_ALIGNMENT_CENTER, 318, 34, Color(CREAM, reveal))
		# Slow confetti drifts in the outer frame; faces and names stay clear.
		for piece in range(24):
			var x := 110.0 + float((piece * 61) % 223) if piece % 2 == 0 else 638.0 + float((piece * 53) % 217)
			var y := 85.0 + float((piece * 47) % 205) if reduced_motion else 65.0 + fposmod(float(piece * 47) + (p - 0.73) * 230.0, 267.0)
			var color := PINK if piece % 3 == 0 else GOLD if piece % 3 == 1 else MINT
			layer.draw_rect(Rect2(x, y, 4, 8), Color(color, reveal * 0.82))
		layer.draw_string(_body_font, Vector2(582, 334), "THE SUIT TAKES", HORIZONTAL_ALIGNMENT_CENTER, 217, 14, Color(CREAM, reveal))
		layer.draw_string(_title_font, Vector2(582, 354), "ALL THE CREDIT.", HORIZONTAL_ALIGNMENT_CENTER, 217, 18, Color(GOLD, reveal))
	layer.draw_rect(Rect2(1, 1, 942, 420), GOLD.darkened(0.15), false, 2)

func _draw_heart(layer: Control, center: Vector2, radius: float, color: Color) -> void:
	layer.draw_circle(center + Vector2(-radius * 0.5, 0), radius * 0.6, color)
	layer.draw_circle(center + Vector2(radius * 0.5, 0), radius * 0.6, color)
	layer.draw_colored_polygon(PackedVector2Array([center + Vector2(-radius, radius * 0.12), center + Vector2(radius, radius * 0.12), center + Vector2(0, radius * 1.3)]), color)
