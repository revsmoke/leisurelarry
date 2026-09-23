extends Control

const SoundEffects = preload("res://scripts/sound_effects.gd")
const GameState = preload("res://scripts/game_state.gd")
const Actor = preload("res://scripts/actor.gd")
const WorldEffects = preload("res://scripts/world_effects.gd")
const QABridge = preload("res://scripts/qa_bridge.gd")
const TravelCutscene = preload("res://scripts/travel_cutscene.gd")
const EncounterCutscene = preload("res://scripts/encounter_cutscene.gd")
const HotspotLayout = preload("res://scripts/hotspot_layout.gd")
const CasinoPanel = preload("res://scripts/casino_panel.gd")
const INK := Color("0c1020")
const PANEL := Color("141b2e")
const EDGE := Color("2a334c")
const CREAM := Color("f6e4bc")
const MUTED := Color("98a4be")
const MINT := Color("70e1cb")
const PINK := Color("ef83b6")
var game = GameState.new()
var canvas: Control
var scene_area: Control
var background: TextureRect
var hotspots: Control
var actors: Control
var world_effects: Control
var larry: Control
var room_title: Label
var room_subtitle: Label
var status: Label
var objective_text: Label
var objective_scroll: ScrollContainer
var dialogue: RichTextLabel
var speaker: Label
var inventory_box: VBoxContainer
var exit_box: HFlowContainer
var hover_label: Label
var score_label: Label
var money_label: Label
var selected_label: Label
var music_button: Button
var parser: LineEdit
var modal: Control
var verbs: Dictionary = {}
var font: Font
var display_font: Font
var verb := "look"
var selected_item := ""
var current_render_room := ""
var current_background_path := ""
var show_hotspots := true
var music: AudioStreamPlayer
var music_on := true
var walk_tween: Tween
var last_message := ""
var ending_shown := false
var casino_panel: Control
var qa_mode := false
var qa_bridge: Node
var inventory_scroll: ScrollContainer
var dialogue_choice_buttons: Dictionary = {}
var transcript: Array[String] = []
var inventory_snapshot: Array = []
var tidy_pockets := false
var reduced_motion := false
var effects_on := true
var music_volume := 0.5
var effects_volume := 0.5
var sound_effects: Node
var web_companion: Node
var selection_cancel: Button
var arrival_label: Label
var base_rects: Dictionary = {}
var hint_stage := 0
var hint_objective := ""
var settings_button: Button
var travel_cutscene: Control
var animate_travel_in_tests := false
var travel_result := ""
var travel_speaker := "THE NARRATOR"
var travel_variants: Dictionary = {}
var encounter_cutscene: Control
var encounter_result := ""
var logo_label: Label
var profile_label: Label
var finale_replay_button: Button
var hotspot_layout_queued := false
var setup_open := false
var setup_can_cancel := false
var setup_return_to_resume := false
var resume_pending := false
var draft_character := "larry"
var draft_orientation := "bisexual"

func _qa_enabled() -> bool:
	return QABridge.runtime_allowed()

func _ready() -> void:
	qa_mode = _qa_enabled()
	var body_font := FontVariation.new()
	body_font.base_font = load("res://assets/fonts/Outfit.ttf")
	body_font.fallbacks = [load("res://assets/fonts/NotoSansSymbols2.ttf")]
	body_font.variation_opentype = {2003265652: 450.0}
	font = body_font
	var heading_font := FontVariation.new()
	heading_font.base_font = load("res://assets/fonts/SpaceGrotesk.ttf")
	heading_font.variation_opentype = {2003265652: 650.0}
	display_font = heading_font
	game.new_game()
	game.interaction_started.connect(_animate_npc)
	_load_preferences()
	_build_ui()
	resized.connect(_fit)
	_fit()
	_render()
	_say("THE NARRATOR", "Lost Wages, 1987. Eighty bucks. One polyester suit. One mission: get laid. Your fly has higher ambitions than your bank balance.")
	_start_music()
	sound_effects = SoundEffects.new()
	add_child(sound_effects)
	sound_effects.set_enabled(effects_on and not qa_mode and DisplayServer.get_name() != "headless")
	sound_effects.set_volume(effects_volume)
	if OS.has_feature("web") and not qa_mode:
		web_companion = load("res://scripts/web_companion.gd").new()
		add_child(web_companion)
		web_companion.start(self)
	if qa_mode:
		qa_bridge = QABridge.new()
		add_child(qa_bridge)
		qa_bridge.start.call_deferred(self)
	else:
		_automation.call_deferred()
	if DisplayServer.get_name() != "headless" and not ("--capture-all" in OS.get_cmdline_user_args() or "--smoke-ui" in OS.get_cmdline_user_args()):
		if not qa_mode and FileAccess.file_exists("user://autosave.json"):
			_resume_prompt.call_deferred()
		else:
			_character_setup.call_deferred(false)

func _fit() -> void:
	var compact := size.x < 1100 and size.y / maxf(size.x, 1) > 0.85
	var design := Vector2(1120, 1180) if compact else Vector2(1440, 960)
	canvas.size = design
	for node in base_rects:
		if not is_instance_valid(node): continue
		var rect: Rect2 = base_rects[node]
		node.position = rect.position
		node.size = rect.size
		node.scale = Vector2.ONE
		if not compact: continue
		if rect == Rect2(0, 0, 1440, 960): node.size = design
		elif rect == Rect2(0, 0, 1440, 88): node.size = Vector2(1120, 128)
		elif rect == Rect2(0, 88, 246, 872): node.size = Vector2(246, 1092)
		elif node == money_label: node.position = Vector2(820, 22)
		elif node == score_label: node.position = Vector2(925, 22)
		elif rect.position.x >= 1080 and rect.position.y == 23:
			node.position = Vector2(714 + (rect.position.x - 1080), 75)
		elif node == settings_button: node.position = Vector2(626, 75)
		elif node == room_title: node.position.y = 142; node.size.x = 800
		elif node == room_subtitle: node.position.y = 177; node.size.x = 800
		elif node == finale_replay_button: node.position = Vector2(861, 140)
		elif node == status: node.visible = false
		elif node == scene_area:
			node.position = Vector2(270, 210); node.scale = Vector2.ONE * (822.0 / 1140.0)
		elif rect == Rect2(270, 731, 1140, 112): node.position = Vector2(270, 630); node.size = Vector2(822, 330)
		elif rect == Rect2(271, 746, 3, 80): node.position = Vector2(271, 646); node.size.y = 294
		elif node == speaker: node.position = Vector2(292, 646); node.size.x = 776
		elif node == dialogue: node.position = Vector2(292, 680); node.size = Vector2(776, 255)
		elif rect.position.y == 860 and node != parser: node.position.y = 975
		elif node == parser: node.position = Vector2(270, 1036); node.size = Vector2(822, 45)
		elif node == exit_box: node.position = Vector2(270, 1100); node.size = Vector2(822, 70)
		elif node == inventory_scroll: node.size.y = 466
		elif rect.position == Vector2(20, 898): node.position.y = 1140
	if not compact: status.visible = not finale_replay_button.visible
	var ratio := minf(size.x / design.x, size.y / design.y)
	canvas.scale = Vector2.ONE * ratio
	canvas.position = (size - design * ratio) / 2.0
	if is_instance_valid(modal):
		modal.size = design
		modal.get_child(0).size = design
		var panel: Control = modal.get_child(1)
		panel.position = (design - panel.size) / 2.0

func _exit_tree() -> void:
	if is_instance_valid(music):
		music.stop()
		music.stream = null

func _style(bg: Color, border: Color = Color.TRANSPARENT, radius: int = 8) -> StyleBoxFlat:
	var s := StyleBoxFlat.new()
	s.bg_color = bg
	s.border_color = border
	s.set_border_width_all(1)
	s.set_corner_radius_all(radius)
	s.content_margin_left = 16
	s.content_margin_right = 16
	s.content_margin_top = 8
	s.content_margin_bottom = 8
	return s

func _panel(parent: Node, rect: Rect2, color: Color, border: Color = Color.TRANSPARENT, radius: int = 8) -> Panel:
	var p := Panel.new()
	p.position = rect.position
	p.size = rect.size
	p.add_theme_stylebox_override("panel", _style(color, border, radius))
	p.mouse_filter = Control.MOUSE_FILTER_IGNORE
	parent.add_child(p)
	return p

func _label(parent: Node, text: String, rect: Rect2, font_size: int = 18, color: Color = CREAM) -> Label:
	var l := Label.new()
	# Fixed rectangles must not expand before wrapping is configured. Labels in
	# containers use zero height so their wrapped content can grow and scroll.
	l.clip_text = rect.size.y > 0
	l.text = text
	l.position = rect.position
	l.size = rect.size
	l.add_theme_font_override("font", font)
	l.add_theme_font_size_override("font_size", font_size)
	l.add_theme_color_override("font_color", color)
	l.mouse_filter = Control.MOUSE_FILTER_IGNORE
	parent.add_child(l)
	return l

func _button(parent: Node, text: String, rect: Rect2, callback: Callable, accent: bool = false) -> Button:
	var b := Button.new()
	b.text = text
	b.position = rect.position
	b.size = rect.size
	b.custom_minimum_size = rect.size
	b.mouse_default_cursor_shape = Control.CURSOR_POINTING_HAND
	b.add_theme_font_override("font", font)
	b.add_theme_font_size_override("font_size", 17)
	b.add_theme_color_override("font_color", INK if accent else CREAM)
	b.add_theme_color_override("font_hover_color", INK if accent else MINT)
	b.add_theme_color_override("font_focus_color", INK if accent else CREAM)
	b.add_theme_color_override("font_pressed_color", INK)
	b.add_theme_color_override("font_disabled_color", MUTED.darkened(0.3))
	b.add_theme_stylebox_override("normal", _style(MINT if accent else PANEL, EDGE))
	b.add_theme_stylebox_override("hover", _style(MINT.lightened(0.13) if accent else Color("202c43"), MINT))
	b.add_theme_stylebox_override("pressed", _style(MINT, MINT))
	b.add_theme_stylebox_override("focus", _style(Color.TRANSPARENT, PINK))
	b.add_theme_stylebox_override("disabled", _style(INK, EDGE))
	b.pressed.connect(func():
		if is_cinematic(): return
		if (setup_open or resume_pending) and (not is_instance_valid(modal) or not modal.is_ancestor_of(b)): return
		callback.call()
	)
	parent.add_child(b)
	return b

func _build_ui() -> void:
	canvas = Control.new()
	canvas.size = Vector2(1440, 960)
	add_child(canvas)
	_panel(canvas, Rect2(0, 0, 1440, 960), INK, Color.TRANSPARENT, 0)
	_panel(canvas, Rect2(0, 0, 1440, 88), Color("111729"), EDGE, 0)
	_label(canvas, "LEISURE SUIT", Rect2(28, 13, 210, 23), 16, PINK)
	logo_label = _label(canvas, "LARRY", Rect2(26, 29, 210, 48), 38)
	logo_label.add_theme_font_override("font", display_font)
	_label(canvas, "LAST CALL IN LOST WAGES", Rect2(274, 20, 500, 29), 21)
	profile_label = _label(canvas, "Bisexual · dressed to get lucky.", Rect2(274, 49, 480, 22), 15, MUTED)
	money_label = _label(canvas, "$80", Rect2(840, 29, 94, 34), 23, MINT)
	score_label = _label(canvas, "0 / 100", Rect2(941, 29, 118, 34), 20, CREAM)
	_button(canvas, "Save", Rect2(1080, 23, 74, 42), _save).disabled = qa_mode
	_button(canvas, "Load", Rect2(1162, 23, 74, 42), _load).disabled = qa_mode
	music_button = _button(canvas, "Music", Rect2(1244, 23, 82, 42), _toggle_music)
	music_button.disabled = qa_mode
	settings_button = _button(canvas, "Options", Rect2(730, 23, 100, 42), _settings)
	_button(canvas, "?", Rect2(1334, 23, 76, 42), _help)
	_panel(canvas, Rect2(0, 88, 246, 872), Color("111729"), EDGE, 0)
	_label(canvas, "YOUR EVENING", Rect2(26, 108, 210, 24), 13, MUTED)
	_button(canvas, "City map", Rect2(20, 145, 206, 45), _map)
	_button(canvas, "Notebook", Rect2(20, 201, 206, 45), _journal)
	_button(canvas, "Need a nudge?", Rect2(20, 257, 206, 45), _hint)
	_panel(canvas, Rect2(20, 325, 206, 230), Color("1c2436"), EDGE)
	_label(canvas, "THE PLAN", Rect2(35, 337, 170, 23), 12, MINT)
	objective_scroll = ScrollContainer.new()
	objective_scroll.position = Vector2(35, 368)
	objective_scroll.size = Vector2(174, 174)
	objective_scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	canvas.add_child(objective_scroll)
	objective_text = _label(objective_scroll, "", Rect2(0, 0, 154, 0), 18)
	objective_text.custom_minimum_size = Vector2(154, 0)
	objective_text.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	objective_text.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	_label(canvas, "POCKETS", Rect2(26, 575, 170, 26), 13, MUTED)
	selected_label = _label(canvas, "Select an item to use it.", Rect2(26, 603, 156, 36), 13, MUTED)
	selected_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	selection_cancel = _button(canvas, "×", Rect2(190, 603, 36, 36), _cancel_selection)
	selection_cancel.tooltip_text = "Cancel selected item (Escape)"
	_button(canvas, "Tidy", Rect2(151, 571, 75, 30), _toggle_tidy).tooltip_text = "Show or hide used souvenirs"
	arrival_label = _label(scene_area if scene_area else canvas, "", Rect2(278, 694, 900, 24), 15, MINT)
	var scroll := ScrollContainer.new()
	inventory_scroll = scroll
	scroll.position = Vector2(20, 649)
	scroll.size = Vector2(212, 226)
	scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	canvas.add_child(scroll)
	inventory_box = VBoxContainer.new()
	inventory_box.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	inventory_box.add_theme_constant_override("separation", 7)
	scroll.add_child(inventory_box)
	_button(canvas, "New evening", Rect2(20, 898, 206, 37), _new_game_prompt)
	room_title = _label(canvas, "Outside Lefty's", Rect2(270, 102, 740, 35), 28)
	room_subtitle = _label(canvas, "DOWNTOWN  /  LOST WAGES", Rect2(272, 134, 690, 20), 12, MUTED)
	status = _label(canvas, "NIGHT IS YOUNG", Rect2(1140, 118, 264, 27), 13, MINT)
	status.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
	finale_replay_button = _button(canvas, "Replay finale", Rect2(1175, 112, 230, 38), _replay_finale, true)
	finale_replay_button.visible = false
	scene_area = Control.new()
	scene_area.position = Vector2(270, 166)
	scene_area.size = Vector2(1140, 553)
	scene_area.clip_contents = true
	canvas.add_child(scene_area)
	background = TextureRect.new()
	background.size = scene_area.size
	background.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	background.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_COVERED
	background.mouse_filter = Control.MOUSE_FILTER_STOP
	background.gui_input.connect(_background_input)
	scene_area.add_child(background)
	world_effects = WorldEffects.new()
	world_effects.size = scene_area.size
	scene_area.add_child(world_effects)
	actors = Control.new()
	actors.mouse_filter = Control.MOUSE_FILTER_IGNORE
	scene_area.add_child(actors)
	larry = Control.new()
	larry.set_script(Actor)
	larry.position = Vector2(475, 491)
	scene_area.add_child(larry)
	hotspots = Control.new()
	hotspots.mouse_filter = Control.MOUSE_FILTER_IGNORE
	scene_area.add_child(hotspots)
	_panel(scene_area, Rect2(0, 514, 1140, 39), Color(0.04, 0.055, 0.1, 0.87), Color.TRANSPARENT, 0)
	arrival_label.reparent(scene_area)
	arrival_label.position = Vector2(16, 486)
	hover_label = _label(scene_area, "Click the scenery to walk. Explore with the verbs below.", Rect2(16, 521, 1090, 24), 14, CREAM)
	_panel(canvas, Rect2(270, 731, 1140, 112), PANEL, EDGE)
	_panel(canvas, Rect2(271, 746, 3, 80), PINK, Color.TRANSPARENT, 0)
	speaker = _label(canvas, "THE NARRATOR", Rect2(292, 744, 900, 23), 12, PINK)
	dialogue = RichTextLabel.new()
	dialogue.position = Vector2(292, 771)
	dialogue.size = Vector2(1094, 62)
	dialogue.add_theme_font_override("normal_font", font)
	dialogue.add_theme_font_size_override("normal_font_size", 20)
	dialogue.add_theme_color_override("default_color", CREAM)
	dialogue.scroll_active = true
	canvas.add_child(dialogue)
	var labels := ["1  Look", "2  Talk", "3  Take", "4  Use"]
	var actions := ["look", "talk", "take", "use"]
	for i in range(4):
		var action: String = actions[i]
		verbs[action] = _button(canvas, labels[i], Rect2(270 + i * 130, 860, 120, 45), _set_verb.bind(action))
	_button(canvas, "H", Rect2(793, 860, 50, 45), _toggle_hotspots).tooltip_text = "Show or hide hotspot labels (H)"
	parser = LineEdit.new()
	parser.position = Vector2(855, 860)
	parser.size = Vector2(555, 45)
	parser.placeholder_text = "Or type a command…  e.g. look taxi"
	parser.add_theme_font_override("font", font)
	parser.add_theme_font_size_override("font_size", 16)
	parser.add_theme_color_override("font_color", CREAM)
	parser.add_theme_color_override("font_placeholder_color", MUTED)
	parser.add_theme_stylebox_override("normal", _style(PANEL, EDGE))
	parser.add_theme_stylebox_override("focus", _style(PANEL, MINT))
	parser.text_submitted.connect(_command)
	canvas.add_child(parser)
	exit_box = HFlowContainer.new()
	exit_box.position = Vector2(270, 919)
	exit_box.size = Vector2(1140, 32)
	exit_box.add_theme_constant_override("separation", 8)
	canvas.add_child(exit_box)
	for child in canvas.get_children():
		if child is Control: base_rects[child] = child.get_rect()
	_set_verb("look")

func _clear(node: Node) -> void:
	for child in node.get_children():
		node.remove_child(child)
		child.queue_free()

func _render() -> void:
	if is_cinematic(): return
	var encounter: Dictionary = game.consume_encounter()
	if not encounter.is_empty() and (DisplayServer.get_name() != "headless" or animate_travel_in_tests) and not "--smoke-ui" in OS.get_cmdline_user_args():
		_present_encounter(encounter)
		return
	logo_label.text = game.player_name().to_upper()
	profile_label.text = str(game.profile.orientation).capitalize() + " · dressed to get lucky."
	larry.role = str(game.profile.character)
	larry.gender = game.player_gender()
	larry.queue_redraw()
	var room: Dictionary = game.get_room()
	room_title.text = room.get("name", game.room)
	room_subtitle.text = str(room.get("subtitle", "LOST WAGES / AFTER HOURS")).to_upper()
	if objective_text.text != game.objective(): objective_scroll.scroll_vertical = 0
	objective_text.text = game.objective()
	score_label.text = "%d / 100" % game.score
	money_label.text = "$%d" % game.cash
	status.text = "A NIGHT TO REMEMBER" if game.completed else "NO BAD DECISIONS. YET."
	finale_replay_button.visible = game.completed and game.flags.get("encounter_eve", false)
	status.visible = not finale_replay_button.visible and canvas.size.x >= 1440
	var art_path: String = WorldEffects.background_path_for(game.room, game.flags)
	if art_path != current_background_path and ResourceLoader.exists(art_path):
		background.texture = load(art_path)
		current_background_path = art_path
	if current_render_room != game.room:
		_clear(actors)
		if walk_tween and walk_tween.is_valid():
			walk_tween.kill()
		larry.walking = false
		larry.stop_dance()
		arrival_label.text = ""
		current_render_room = game.room
		background.modulate = Color.WHITE if reduced_motion else Color(0.6, 0.6, 0.7)
		if not reduced_motion: create_tween().tween_property(background, "modulate", Color.WHITE, 0.4)
		_cue("transition")
		larry.position = Vector2(490, 493)
	world_effects.set_reduced_motion(reduced_motion)
	larry.set_reduced_motion(reduced_motion)
	world_effects.sync_state(game.room, game.flags, _visual_profile())
	_clear(hotspots)
	# Keep NPCs through same-room UI refreshes so gestures finish naturally.
	var present_ids: Array = room.get("hotspots", []).map(func(h): return str(h.id))
	for actor in actors.get_children():
		if not present_ids.has(str(actor.get_meta("hotspot_id", ""))):
			actors.remove_child(actor)
			actor.queue_free()
	for h in room.get("hotspots", []):
		_build_hotspot(h)
	_layout_hotspots()
	_clear(exit_box)
	_label(exit_box, "GO TO", Rect2(0, 0, 55, 30), 12, MUTED).custom_minimum_size = Vector2(55, 30)
	for e in room.get("exits", []):
		var id: String = e.id
		var b := _button(exit_box, str(e.label) + "  →", Rect2(0, 0, 130, 30), _travel.bind(id))
		b.add_theme_font_size_override("font_size", 13)
	_clear(inventory_box)
	if not game.inventory.has(selected_item):
		selected_item = ""
	selected_label.text = "Use %s on…" % game.items[selected_item].name if not selected_item.is_empty() else verb.capitalize() + " · choose a target"
	selection_cancel.visible = not selected_item.is_empty()
	if game.inventory.is_empty():
		var empty := _label(inventory_box, "Nothing but optimism.\nAnd a wallet.", Rect2(0, 0, 200, 58), 16, MUTED)
		empty.custom_minimum_size = Vector2(180, 58)
	else:
		for item in game.get_inventory():
			var id: String = item.id
			if tidy_pockets and game.item_status(id) == "souvenir" and id != selected_item: continue
			var b := _button(inventory_box, ("*  " if selected_item == id else "+  ") + str(item.name), Rect2(0, 0, 202, 39), _select_item.bind(id), selected_item == id)
			b.set_meta("inventory_id", id)
			b.alignment = HORIZONTAL_ALIGNMENT_LEFT
			b.add_theme_font_size_override("font_size", 15)
			b.tooltip_text = item.get("description", "")
			b.gui_input.connect(_inventory_input.bind(id))
			if selected_item == id:
				var self_use := _button(inventory_box, "Use %s by itself" % item.name, Rect2(0, 0, 202, 52), _use_selected_self)
				self_use.add_theme_font_size_override("font_size", 14)
				self_use.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	var arrived: Array = []
	for id in game.inventory:
		if not inventory_snapshot.has(id): arrived.append(id)
	inventory_snapshot = game.inventory.duplicate()
	if not arrived.is_empty():
		arrival_label.text = "POCKETED · " + ", ".join(arrived.map(func(id): return game.items[id].name))
		_cue("pickup")
		_scroll_to_item.call_deferred(str(arrived.back()))
	_refresh_companion()
	if game.completed and not ending_shown:
		ending_shown = true
		_ending.call_deferred()

func _build_hotspot(h: Dictionary) -> void:
	var point := Vector2(float(h.get("x", 0.5)) * 1140, float(h.get("y", 0.5)) * 506)
	if h.get("kind", "object") == "person":
		var npc := _npc_actor(str(h.id))
		var fresh := not is_instance_valid(npc)
		if fresh: npc = Actor.new()
		npc.is_larry = false
		var casting: Dictionary = game.actor_profile(str(h.id))
		if npc.role != str(casting.get("role", h.id)) or npc.gender != str(casting.get("gender", "male")):
			npc.npc_animation = Actor.NPCAnimation.new()
		npc.role = str(casting.get("role", h.id))
		npc.gender = str(casting.get("gender", "male"))
		npc.suit = PINK if str(h.id).length() % 2 == 0 else Color("52b7b1")
		npc.shirt = Color("2a294d")
		npc.hair = Color("b77147")
		npc.position = point + Vector2(0, 76)
		npc.scale = Vector2.ONE * 0.85
		npc.set_meta("hotspot_id", str(h.id))
		if fresh:
			actors.add_child(npc)
			# The art is drawn above a zero-size feet anchor. Give its visible body
			# a real input surface, without adding duplicate keyboard/QA buttons.
			var body := Control.new()
			body.name = "BodyHitTarget"
			body.position = Vector2(-38, -158)
			body.size = Vector2(76, 164)
			body.mouse_filter = Control.MOUSE_FILTER_STOP
			body.mouse_default_cursor_shape = Control.CURSOR_POINTING_HAND
			npc.add_child(body)
			body.mouse_entered.connect(_hotspot_enter.bind(str(h.id)))
			body.mouse_exited.connect(_hotspot_exit)
			body.gui_input.connect(_npc_body_input.bind(str(h.id)))
			npc.label_bounds_changed.connect(_queue_hotspot_layout)
		npc.set_reduced_motion(reduced_motion)
		npc.sync_reaction(game.flags)
	var label_text := str(h.get("label", h.id))
	var prefix := ">  " if h.get("kind") == "exit" else "·  "
	var width := clampf(font.get_string_size(prefix + label_text, HORIZONTAL_ALIGNMENT_LEFT, -1, 14).x + 28, 80, 260)
	width = width if show_hotspots else 32.0
	var b := _button(hotspots, prefix + label_text if show_hotspots else "+", Rect2(Vector2.ZERO, Vector2(width, 34)), _hotspot_click.bind(h))
	b.set_meta("hotspot_id", str(h.id))
	b.set_meta("hotspot_kind", str(h.get("kind", "object")))
	b.set_meta("hotspot_anchor", point)
	b.set_meta("accessible_label", label_text)
	# Names already appear on the button and hover line. A duplicate tooltip
	# below an NPC label would cover the face precisely while it is performing.
	b.tooltip_text = "" if h.get("kind", "object") == "person" else label_text
	b.add_theme_font_size_override("font_size", 14)
	b.clip_text = true
	b.size = Vector2(width, 34)
	b.add_theme_stylebox_override("normal", _style(Color(0.04, 0.07, 0.13, 0.87), Color(0.44, 0.88, 0.8, 0.55), 6))
	b.add_theme_stylebox_override("hover", _style(Color("172e3c"), MINT, 6))
	b.mouse_entered.connect(_hotspot_enter.bind(str(h.id)))
	b.focus_entered.connect(_hotspot_enter.bind(str(h.id)))
	b.mouse_exited.connect(_hotspot_exit)
	b.gui_input.connect(_hotspot_input.bind(h))
	b.resized.connect(_queue_hotspot_layout)

func _npc_actor(id: String) -> Control:
	if not is_instance_valid(actors): return null
	for actor in actors.get_children():
		if str(actor.get_meta("hotspot_id", "")) == id: return actor
	return null

func _hotspot_enter(id: String) -> void:
	if is_cinematic() or is_instance_valid(modal) or setup_open or resume_pending: return
	var h: Dictionary = game.get_hotspot(id)
	hover_label.text = ("Use " + str(game.items[selected_item].name) + " with " if not selected_item.is_empty() else verb.capitalize() + " · ") + str(h.get("label", id))
	var npc := _npc_actor(id)
	if is_instance_valid(npc): npc.hover_react()

func _hotspot_exit() -> void:
	hover_label.text = "Click the scenery to walk. Right-click an object to look at it."

func _npc_body_input(event: InputEvent, id: String) -> void:
	if is_cinematic() or is_instance_valid(modal) or setup_open or resume_pending: return
	if event is InputEventMouseButton and event.pressed:
		if event.button_index == MOUSE_BUTTON_LEFT: _hotspot_click(game.get_hotspot(id))
		elif event.button_index == MOUSE_BUTTON_RIGHT: _hotspot_input(event, game.get_hotspot(id))

func _animate_npc(id: String, action: String) -> void:
	if is_cinematic(): return
	var npc := _npc_actor(id)
	if is_instance_valid(npc): npc.interact_react(action)

func _queue_hotspot_layout() -> void:
	if hotspot_layout_queued: return
	hotspot_layout_queued = true
	_layout_hotspots.call_deferred()

func _layout_hotspots() -> void:
	hotspot_layout_queued = false
	if not is_instance_valid(hotspots) or not is_instance_valid(actors): return
	var obstacles: Array[Rect2] = []
	var subjects: Dictionary = {}
	for actor in actors.get_children():
		var bounds: Rect2 = actor.get_transform() * actor.label_obstacle()
		obstacles.append(bounds)
		subjects[str(actor.get_meta("hotspot_id", ""))] = bounds
	var occupied: Array[Rect2] = []
	var area := Rect2(Vector2(8, 8), scene_area.size - Vector2(16, 62))
	# Reserve character names first, independent of hotspot declaration order.
	for people_first in [true, false]:
		for button in hotspots.get_children():
			var is_person: bool = button.get_meta("hotspot_kind", "") == "person"
			if is_person != people_first: continue
			var subject: Rect2 = subjects.get(str(button.get_meta("hotspot_id", "")), Rect2())
			var rect: Rect2 = HotspotLayout.place(button.get_meta("hotspot_anchor", Vector2.ZERO), button.size, area, subject, obstacles, occupied)
			button.position = rect.position
			occupied.append(rect)

func _hotspot_input(event: InputEvent, h: Dictionary) -> void:
	if is_cinematic(): return
	if event is InputEventMouseButton and event.pressed and event.button_index == MOUSE_BUTTON_RIGHT:
		_say("THE NARRATOR", game.interact(str(h.id), "look"))
		_render()
		_autosave()

func _inventory_input(event: InputEvent, id: String) -> void:
	if is_cinematic(): return
	if event is InputEventMouseButton and event.pressed and event.button_index == MOUSE_BUTTON_RIGHT:
		_say("IN YOUR POCKET", game.interact(id, "look"))
		_render()
		_autosave()
	elif event is InputEventMouseButton and event.pressed and event.button_index == MOUSE_BUTTON_LEFT and event.double_click:
		_say("IN YOUR POCKET", game.interact(id, "use", id))
		_render()
		_autosave()

func _hotspot_click(h: Dictionary) -> void:
	if is_cinematic(): return
	arrival_label.text = ""
	if h.id == "taxi" and verb == "use" and selected_item.is_empty():
		_say("THE DRIVER", game.interact("taxi", "use"))
		_render()
		_autosave()
		_map()
		return
	if h.id in ["slots", "blackjack"] and verb == "use" and selected_item.is_empty():
		_open_casino(str(h.id))
		return
	_move_larry(Vector2(clampf(float(h.get("x", 0.5)) * 1140, 80, 1040), 492))
	if h.get("kind") == "exit":
		_travel(str(h.id))
		return
	if selected_item.is_empty() and verb == "use" and h.id == "bartender":
		_say("LEFTY", game.interact("bartender", "talk"))
		_render()
		_conversation("bartender")
		_autosave()
		return
	if selected_item.is_empty() and verb == "use" and h.id in ["dancer", "dancefloor"] and not game.flags.get("danced", false):
		_say("DIDI", game.interact(str(h.id), "talk"))
		_render()
		_conversation(str(h.id))
		_autosave()
		return
	var origin: String = game.room
	var result: String = game.interact(str(h.id), "use" if not selected_item.is_empty() else verb, selected_item)
	if origin != game.room:
		_present_travel(origin, result)
		return
	if h.id in ["dancer", "dancefloor"] and verb == "use" and selected_item.is_empty() and game.flags.get("danced", false):
		_play_dance()
	_say(str(h.get("label", "THE NARRATOR")).to_upper() if verb == "talk" else "THE NARRATOR", result)
	_render()
	if is_cinematic(): return
	_autosave()
	if selected_item.is_empty() and (verb == "talk" or (verb == "use" and h.id == "phone")):
		_conversation(str(h.id))

func _background_input(event: InputEvent) -> void:
	if is_cinematic(): return
	if event is InputEventMouseButton and event.pressed and event.button_index == MOUSE_BUTTON_LEFT:
		_move_larry(Vector2(clampf(event.position.x, 50, 1090), clampf(event.position.y, 420, 505)))

func _move_larry(destination: Vector2) -> void:
	larry.stop_dance()
	if walk_tween and walk_tween.is_valid():
		walk_tween.kill()
	if reduced_motion:
		larry.position = destination
		larry.walking = false
		return
	larry.walking = true
	walk_tween = create_tween()
	walk_tween.tween_property(larry, "position", destination, larry.position.distance_to(destination) / 320.0)
	walk_tween.tween_callback(func(): larry.walking = false)

func _play_dance() -> void:
	if walk_tween and walk_tween.is_valid():
		walk_tween.kill()
	larry.position = Vector2(405, 459)
	larry.set_dance_style("confident" if game.flags.get("dance_confident", false) else "copy" if game.flags.get("dance_copy", false) else "careful")
	larry.dance()

func _set_verb(value: String) -> void:
	if is_cinematic(): return
	verb = value
	if value != "use":
		selected_item = ""
	for key in verbs:
		verbs[key].add_theme_stylebox_override("normal", _style(MINT if key == value else PANEL, MINT if key == value else EDGE))
		verbs[key].add_theme_color_override("font_color", INK if key == value else CREAM)
	if inventory_box:
		_render()

func _select_item(id: String) -> void:
	if is_cinematic(): return
	if not game.inventory.has(id):
		return
	selected_item = "" if selected_item == id else id
	_set_verb("use")
	_render()
	if not selected_item.is_empty():
		_say("IN YOUR POCKET", game.interact(id, "look") + " Select a target, choose Use by itself, or double-click the item.")
		_render()
		_autosave()

func is_travelling() -> bool:
	return is_instance_valid(travel_cutscene)

func is_cinematic() -> bool:
	return is_travelling() or is_instance_valid(encounter_cutscene)

func _visual_profile() -> Dictionary:
	return {"character": game.profile.character, "orientation": game.profile.orientation, "name": game.player_name(), "gender": game.player_gender(), "finale_name": game.finale_name(), "finale_gender": game.finale_gender()}

func _present_encounter(encounter: Dictionary, persist: bool = true) -> void:
	if is_cinematic(): return
	_close_modal()
	if walk_tween and walk_tween.is_valid(): walk_tween.kill()
	larry.walking = false
	larry.stop_dance()
	parser.release_focus()
	selected_item = ""
	encounter_result = str(encounter.get("caption", "A little later, your collar is the only thing still standing at attention."))
	modal = Control.new()
	modal.size = canvas.size
	canvas.add_child(modal)
	var dim := ColorRect.new()
	dim.color = Color(0.02, 0.025, 0.055, 0.96)
	dim.size = modal.size
	modal.add_child(dim)
	encounter_cutscene = EncounterCutscene.new()
	encounter_cutscene.size = Vector2(1000, 700)
	encounter_cutscene.position = (canvas.size - encounter_cutscene.size) / 2.0
	modal.add_child(encounter_cutscene)
	encounter_cutscene.finished.connect(_finish_encounter, CONNECT_ONE_SHOT)
	encounter_cutscene.phase_changed.connect(_refresh_companion)
	encounter_cutscene.play(_visual_profile(), encounter, reduced_motion)
	_say("DO NOT DISTURB", str(encounter.get("title", "An extremely private joke.")))
	_cue("punchline")
	if persist: _autosave()
	_refresh_companion()

func _replay_finale() -> void:
	if is_cinematic() or setup_open or resume_pending or not game.completed or not game.flags.get("encounter_eve", false): return
	ending_shown = false
	_present_encounter({"partner": "eve", "name": game.finale_name(), "gender": game.finale_gender(), "title": "THE GRAND FINALE · A NIGHT TO REMEMBER", "caption": game.ending_text(), "finale": true}, false)

func _finish_encounter() -> void:
	if not is_instance_valid(encounter_cutscene): return
	encounter_cutscene = null
	_close_modal()
	_say("A LITTLE LATER…", encounter_result)
	encounter_result = ""
	_render()

func _skip_cinematic() -> void:
	if is_travelling(): _skip_travel()
	elif is_instance_valid(encounter_cutscene): encounter_cutscene.finish()

func _travel(id: String) -> void:
	if is_cinematic(): return
	var origin: String = game.room
	_close_modal()
	_present_travel(origin, game.travel(id))

func _present_travel(origin: String, result: String, who: String = "THE NARRATOR") -> void:
	selected_item = ""
	# The model decides gates, route length and state exactly once. Animation is
	# presentation only; skipping never grants progress or replays the journey.
	if origin == game.room or (DisplayServer.get_name() == "headless" and not animate_travel_in_tests) or "--smoke-ui" in OS.get_cmdline_user_args():
		_say(who, result)
		_render()
		_autosave()
		return
	_close_modal()
	if walk_tween and walk_tween.is_valid(): walk_tween.kill()
	larry.walking = false
	larry.stop_dance()
	parser.release_focus()
	travel_result = result
	travel_speaker = who
	var destination: String = game.room
	var route_key := origin + ">" + destination
	var variant := int(travel_variants.get(route_key, 0))
	travel_variants[route_key] = variant + 1
	modal = Control.new()
	modal.size = canvas.size
	canvas.add_child(modal)
	var dim := ColorRect.new()
	dim.color = Color(0.02, 0.025, 0.055, 0.96)
	dim.size = modal.size
	modal.add_child(dim)
	travel_cutscene = TravelCutscene.new()
	travel_cutscene.size = Vector2(1000, 700)
	travel_cutscene.position = (canvas.size - travel_cutscene.size) / 2.0
	modal.add_child(travel_cutscene)
	travel_cutscene.finished.connect(_finish_travel, CONNECT_ONE_SHOT)
	var from_art: Texture2D = load(WorldEffects.background_path_for(origin, game.flags))
	var to_art: Texture2D = load(WorldEffects.background_path_for(destination, game.flags))
	travel_cutscene.play(origin, destination, game.get_room(origin), game.get_room(destination), from_art, to_art, reduced_motion, variant, _visual_profile())
	_say("ON THE MOVE", TravelCutscene.caption_for(origin, destination, variant, _visual_profile()))
	_cue("travel_" + TravelCutscene.mode_for(origin, destination))
	# Accepted travel is already complete in the model. Persist before the movie
	# so closing a tab mid-scene cannot lose the destination or duplicate moves.
	_autosave()
	_refresh_companion()

func _skip_travel() -> void:
	if is_travelling(): travel_cutscene.finish()

func _finish_travel() -> void:
	if not is_travelling(): return
	travel_cutscene = null
	_close_modal()
	_say(travel_speaker, travel_result)
	travel_result = ""
	_render()

func _command(text: String) -> void:
	if is_cinematic() or setup_open or resume_pending: return
	if text.strip_edges().is_empty():
		return
	var normalized := text.strip_edges().to_lower()
	if qa_mode and normalized in ["save", "save game", "load", "load game", "restore"]:
		parser.clear()
		_say("QA SESSION", "Save and load are disabled in this isolated playtest.")
		return
	if normalized in ["load", "load game", "restore"]:
		parser.clear()
		parser.release_focus()
		_load()
		return
	if game.room == "casino" and normalized in ["blackjack", "play blackjack", "use blackjack", "play 21", "slots", "play slots", "use slots"]:
		parser.clear()
		parser.release_focus()
		_open_casino("slots" if "slots" in normalized else "blackjack")
		return
	if game.room == "street" and normalized in ["use taxi", "use cab", "use taxi stand"]:
		selected_item = ""
		parser.clear()
		parser.release_focus()
		_set_verb("use")
		_hotspot_click(game.get_hotspot("taxi"))
		return
	var offer_target := ""
	if game.room == "bar" and normalized in ["use lefty", "use bartender", "use barman"]: offer_target = "bartender"
	if game.room == "disco" and normalized in ["dance", "dance with didi", "use didi", "use dancer", "use dance floor", "use dancefloor", "use floor"]: offer_target = "dancer"
	if not offer_target.is_empty():
		selected_item = ""
		parser.clear()
		parser.release_focus()
		_set_verb("use")
		_hotspot_click(game.get_hotspot(offer_target))
		return
	var origin: String = game.room
	var result: String = game.command(text)
	if origin != game.room:
		parser.clear()
		parser.release_focus()
		_present_travel(origin, result, "> " + text.to_upper())
		return
	_say("> " + text.to_upper(), result)
	if game.room == "disco" and normalized in ["dance", "dance with didi", "use dance floor", "use floor", "use dancefloor", "use didi"] and game.flags.get("danced", false):
		_play_dance()
	parser.clear()
	parser.release_focus()
	_render()
	if is_cinematic(): return
	_autosave()
	if normalized.begins_with("talk ") or normalized.begins_with("call ") or normalized.begins_with("dial ") or normalized.begins_with("choose ") or normalized in ["use phone", "use telephone", "555-0987", "5550987"]:
		_conversation(game.get_dialogue_target())

func _say(who: String, text: String) -> void:
	who = game.present(who)
	text = game.present(text)
	speaker.text = who
	dialogue.text = text
	dialogue.scroll_to_line(0)
	last_message = text
	transcript.append(who + ": " + text)
	if transcript.size() > 120: transcript.pop_front()
	_refresh_companion()

func _save() -> void:
	if is_cinematic(): return
	if qa_mode:
		return
	_say("SAVED FOR POSTERITY", game.save_game())

func _load() -> void:
	if is_cinematic(): return
	if qa_mode:
		return
	var restored: String = game.load_game()
	_say("PREVIOUSLY, ON " + game.player_name().to_upper() + "…", restored)
	current_render_room = ""
	ending_shown = game.completed
	_render()

func _autosave() -> void:
	if qa_mode:
		return
	if "--smoke-ui" in OS.get_cmdline_user_args() or "--capture-all" in OS.get_cmdline_user_args():
		return
	game.save_game("user://autosave.json")

func _hint() -> void:
	if is_cinematic(): return
	if hint_objective != game.objective():
		hint_stage = 0
		hint_objective = game.objective()
	var p := _modal_base("A little help, on your terms.", ["A gentle clue", "A narrower lead", "The exact solution · spoilers"][hint_stage], 450)
	var body := _label(p, game.hint_level(hint_stage), Rect2(34, 140, 730, 184), 22)
	body.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	_button(p, "Back to the evening", Rect2(34, 350, 350, 54), _close_modal)
	if hint_stage < 2:
		_button(p, "Narrow the lead" if hint_stage == 0 else "Reveal exact solution", Rect2(403, 350, 363, 54), _next_hint)
	_refresh_companion()

func _next_hint() -> void:
	hint_stage = mini(2, hint_stage + 1)
	_hint()

func _toggle_hotspots() -> void:
	show_hotspots = not show_hotspots
	_render()

func _start_music() -> void:
	music = AudioStreamPlayer.new()
	add_child(music)
	if qa_mode or DisplayServer.get_name() == "headless":
		_apply_music_preferences()
		return
	if ResourceLoader.exists("res://assets/audio/last_call.wav"):
		music.stream = load("res://assets/audio/last_call.wav")
		music.finished.connect(func():
			if music_on: music.play()
		)
		music.play()
	_apply_music_preferences()

func _toggle_music() -> void:
	if qa_mode:
		return
	music_on = not music_on
	_apply_music_preferences()
	_save_preferences()

func _modal_base(title: String, subtitle: String, height: float = 660) -> Control:
	_close_modal()
	modal = Control.new()
	modal.size = canvas.size
	canvas.add_child(modal)
	var dim := ColorRect.new()
	dim.color = Color(0.02, 0.025, 0.055, 0.86)
	dim.size = modal.size
	modal.add_child(dim)
	var p := _panel(modal, Rect2((canvas.size.x - 800) / 2, (canvas.size.y - height) / 2, 800, height), Color("151e31"), EDGE, 16)
	p.mouse_filter = Control.MOUSE_FILTER_STOP
	_label(p, title, Rect2(34, 25, 630, 54), 31)
	_label(p, subtitle, Rect2(34, 86, 725, 34), 16, MUTED)
	_button(p, "×", Rect2(711, 27, 52, 43), _close_modal)
	_refresh_companion()
	return p

func _close_modal() -> void:
	if is_cinematic():
		_skip_cinematic()
		return
	if resume_pending: return
	if setup_open and not setup_can_cancel: return
	var return_to_resume := setup_open and setup_return_to_resume
	setup_open = false
	setup_return_to_resume = false
	if is_instance_valid(casino_panel):
		casino_panel.close_game()
		casino_panel = null
	if is_instance_valid(modal):
		remove_child_if_needed(modal)
		modal.queue_free()
	modal = null
	dialogue_choice_buttons.clear()
	_refresh_companion()
	if return_to_resume:
		# Startup has not loaded the stored evening yet. Cancelling its draft
		# must return to Continue, never expose the placeholder fresh game.
		_resume_prompt()

func _open_casino(mode: String) -> void:
	if is_cinematic(): return
	var p := _modal_base("The Lucky Chip · " + mode.capitalize(), "A little luck. A little arithmetic. An absolutely enormous collar.", 646)
	casino_panel = CasinoPanel.new()
	casino_panel.position = Vector2(34, 136)
	p.add_child(casino_panel)
	casino_panel.setup(game, font, mode)
	casino_panel.outcome.connect(func(message: String):
		_say("THE LUCKY CHIP", message)
		_render()
		_autosave()
	)
	casino_panel.dismissed.connect(_close_modal)

func remove_child_if_needed(node: Node) -> void:
	if node.get_parent():
		node.get_parent().remove_child(node)

func _map() -> void:
	if is_cinematic(): return
	var p := _modal_base("A small town. Big mistakes.", "Choose a destination. Locked rooms open as you solve their puzzles.", 742)
	var ids := ["street", "bar", "bathroom", "backroom", "alley", "shop", "casino", "disco", "hotel", "balcony", "garden", "penthouse", "rooftop"]
	for i in range(ids.size()):
		var id: String = ids[i]
		if not game.rooms.has(id):
			continue
		var data: Dictionary = game.get_room(id)
		var unlocked: bool = game.is_unlocked(id)
		var b := _button(p, ("" if id == game.room else ">  " if unlocked else "+  ") + str(data.name), Rect2(34 + (i % 3) * 246, 142 + floori(i / 3.0) * 90, 231, 72), _map_travel.bind(id), id == game.room)
		b.add_theme_font_size_override("font_size", 16)
		b.disabled = not unlocked
	_label(p, "The taxi fare is on the house. Your dignity travels separately.", Rect2(34, 642, 728, 42), 16, MUTED)

func _map_travel(destination: String) -> void:
	if is_cinematic(): return
	# Follow actual unlocked exits, preserving every puzzle gate and move count.
	var frontier: Array = [[game.room]]
	var visited: Dictionary = {game.room: true}
	while not frontier.is_empty():
		var route: Array = frontier.pop_front()
		var here: String = route.back()
		if here == destination:
			var origin: String = game.room
			_close_modal()
			var result := "You are already here. The map remains impressed."
			for i in range(1, route.size()):
				result = game.travel(route[i])
			_present_travel(origin, result)
			return
		for e in game.get_room(here).exits:
			if not visited.has(e.id) and game.is_unlocked(e.id):
				visited[e.id] = true
				frontier.append(route + [e.id])
	_say("THE NARRATOR", "That route is still closed. A few good conversations may open it.")

func _journal() -> void:
	if is_cinematic(): return
	var p := _modal_base("Notes to a future, wiser " + game.player_name(), "Clues are recorded here as you discover them.")
	var scroll := ScrollContainer.new()
	scroll.position = Vector2(34, 139)
	scroll.size = Vector2(732, 475)
	p.add_child(scroll)
	var body := Label.new()
	body.custom_minimum_size = Vector2(697, 0)
	body.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	body.add_theme_font_override("font", font)
	body.add_theme_font_size_override("font_size", 20)
	body.add_theme_color_override("font_color", CREAM)
	body.text = "CURRENT PLAN\n" + game.objective() + "\n\n"
	for entry in game.journal:
		body.text += "•  " + str(entry) + "\n\n"
	if game.journal.is_empty():
		body.text += "The page is empty. Much like your evening's itinerary. Try looking around Lefty's."
	scroll.add_child(body)

func _help() -> void:
	if is_cinematic(): return
	var p := _modal_base("How to make an impression", "A point-and-click adventure with a soft spot for the text parser.", 706)
	# Wrapped Labels grow beyond a requested rectangle; the scrolling viewport
	# keeps the complete instructions readable above the fixed footer.
	var scroll := ScrollContainer.new()
	scroll.position = Vector2(34, 135)
	scroll.size = Vector2(732, 436)
	scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	p.add_child(scroll)
	var body := _label(scroll, "LOOK at things. TALK to people. TAKE useful objects.\nUSE an item by selecting it in your pockets, then clicking its target.\n\nConversations offer topics. Choices can open alternate routes.\nNeed a nudge? starts with a clue; exact solutions require another request.\nOptions include reduced motion, separate sound levels and a transcript.\n\nClick an exit or use the City map to travel. Click the scenery to walk.\nRight-click any object to inspect it. Your notebook keeps the clues.\n\nKeyboard: 1–4 verbs · M map · J notebook · H hotspots · O options · T transcript\nF5 save · F9 load · Enter type a command · Escape close / deselect\n\nTry: look sink, take ring, talk lefty, use whiskey on patron.\nSave writes your manual slot; Load restores it. Progress also autosaves.\n\nA loving, unofficial reimagining of Softporn Adventure and Larry 1.\nOriginal art, dialogue and music. All characters are adults; romance\nstays suggestive and consensual. Polyester remains inexcusable.", Rect2(0, 0, 697, 0), 20)
	body.custom_minimum_size = Vector2(697, 0)
	body.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	body.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	_button(p, "Back to a questionable evening", Rect2(34, 609, 464, 48), _close_modal, true)
	_button(p, "Restore autosave", Rect2(514, 609, 252, 48), _restore_autosave)

func _restore_autosave() -> void:
	if is_cinematic(): return
	if qa_mode:
		return
	resume_pending = false
	_close_modal()
	_say("PICKING UP THE PIECES", game.load_game("user://autosave.json"))
	current_render_room = ""
	ending_shown = game.completed
	_render()

func _resume_prompt() -> void:
	resume_pending = false
	var p := _modal_base("Your evening is still here.", "An autosaved game is ready. Continue it or start a fresh night.", 320)
	resume_pending = true
	for child in p.get_children():
		if child is Button and child.text == "×": child.visible = false
	_button(p, "Continue evening", Rect2(34, 170, 349, 62), _restore_autosave, true)
	_button(p, "Start a new evening", Rect2(401, 170, 365, 62), _character_setup.bind(true, false, true))

func _new_game_prompt() -> void:
	if is_cinematic(): return
	var p := _modal_base("Another night, another suit?", "Start over? Your manual save stays available through Load.", 300)
	_button(p, "Keep this evening", Rect2(34, 162, 344, 62), _close_modal)
	_button(p, "Start a new evening", Rect2(402, 162, 364, 62), _character_setup.bind(true), true)

func _character_setup(can_cancel: bool = true, keep_draft: bool = false, return_to_resume: bool = false) -> void:
	if is_cinematic(): return
	var resume_on_cancel := setup_return_to_resume if keep_draft else return_to_resume
	resume_pending = false
	if not keep_draft:
		draft_character = "larry"
		draft_orientation = "bisexual"
	setup_open = false
	var p := _modal_base("Dress for trouble.", "ADULTS ONLY · ONE NIGHT · ONE GLORIOUSLY BAD IDEA", 820)
	setup_open = true
	setup_can_cancel = can_cancel
	setup_return_to_resume = resume_on_cancel
	for child in p.get_children():
		if child is Button and child.text == "×": child.visible = can_cancel
	var intro := _label(p, "The mission: get laid. The obstacle: you.", Rect2(34, 134, 732, 72), 23)
	intro.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	_label(p, "Choose your suit and orientation, then start your evening.", Rect2(34, 182, 732, 32), 18, MUTED)
	for i in range(2):
		var character: String = ["larry", "lisa"][i]
		var x := 34.0 + i * 374.0
		_panel(p, Rect2(x, 224, 358, 214), PANEL, MINT if draft_character == character else EDGE)
		var preview := Actor.new()
		preview.role = character
		preview.gender = "male" if character == "larry" else "female"
		preview.position = Vector2(x + 62, 354)
		preview.scale = Vector2.ONE * 0.9
		p.add_child(preview)
		var bio := "Larry\nHe / him\nCollar first. Brain later." if character == "larry" else "Lisa · Melisa\nShe / her\nSame suit. Bigger plans."
		var description := _label(p, bio, Rect2(x + 115, 244, 225, 116), 19)
		description.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		_button(p, ("✓ " if draft_character == character else "") + "Play as " + character.capitalize(), Rect2(x + 16, 375, 326, 47), _select_character.bind(character), draft_character == character)
	_label(p, "WHO TURNS YOUR HEAD?", Rect2(34, 458, 732, 28), 15, PINK)
	var orientations := ["heterosexual", "homosexual", "bisexual"]
	for i in range(3):
		var orientation: String = orientations[i]
		_button(p, ("✓ " if draft_orientation == orientation else "") + orientation.capitalize(), Rect2(34 + i * 249, 499, 234, 52), _select_orientation.bind(orientation), draft_orientation == orientation)
		_label(p, ["Opposite gender", "Same gender", "Both genders"][i], Rect2(34 + i * 249, 561, 234, 28), 17, MUTED)
	var gender := "male" if draft_character == "larry" else "female"
	var target_gender := gender if draft_orientation == "homosexual" else ("female" if gender == "male" else "male")
	var target := "Eve" if target_gender == "female" else "Adam"
	var summary := _label(p, "Tonight's dream date: %s.\nFlings follow your orientation. Every character is an adult." % target, Rect2(34, 611, 732, 94), 19)
	summary.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	var start := _button(p, "Get lucky as " + draft_character.capitalize(), Rect2(34, 728, 732 if not can_cancel else 470, 54), _new_game, true)
	if can_cancel: _button(p, "Keep this evening", Rect2(524, 728, 242, 54), _close_modal)
	start.grab_focus()
	_refresh_companion()

func _select_character(character: String) -> void:
	draft_character = character
	_character_setup(setup_can_cancel, true)

func _select_orientation(orientation: String) -> void:
	draft_orientation = orientation
	_character_setup(setup_can_cancel, true)

func _new_game() -> void:
	if is_cinematic(): return
	setup_open = false
	_close_modal()
	game.new_game()
	game.configure_profile(draft_character, draft_orientation)
	transcript.clear()
	travel_variants.clear()
	inventory_snapshot.clear()
	arrival_label.text = ""
	hint_stage = 0
	selected_item = ""
	ending_shown = false
	current_render_room = ""
	_set_verb("look")
	_render()
	_say("THE NARRATOR", "Welcome, %s. Tonight's mission: get laid with %s. A few willing detours are available along the way. Lefty's is open, your collar is enormous, and your standards are wearing platform shoes." % [game.player_name(), game.finale_name()])
	_autosave()

func _ending() -> void:
	var p := _modal_base(game.ending_title(), "Your evening is complete. Exploration points are optional.", 750)
	var scroll := ScrollContainer.new()
	scroll.position = Vector2(34, 142)
	scroll.size = Vector2(732, 386)
	scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	p.add_child(scroll)
	var body := _label(scroll, game.ending_text() + "\n\nLATER THAT MORNING…\n\n" + game.epilogue(), Rect2(0, 0, 697, 0), 23)
	body.custom_minimum_size = Vector2(697, 0)
	body.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	_label(p, "%d / 100 EXPLORATION POINTS  ·  %d MOVES" % [game.score, game.turns], Rect2(34, 541, 730, 31), 16, MINT)
	_button(p, "Replay finale", Rect2(34, 588, 732, 45), _replay_finale, true)
	_button(p, "Stay a little longer", Rect2(34, 654, 349, 52), _close_modal)
	_button(p, "One more evening", Rect2(401, 654, 365, 52), _character_setup.bind(true), true)

func _unhandled_key_input(event: InputEvent) -> void:
	if not event is InputEventKey or not event.pressed or event.echo:
		return
	if is_cinematic():
		if event.keycode in [KEY_ESCAPE, KEY_SPACE, KEY_ENTER]: _skip_cinematic()
		get_viewport().set_input_as_handled()
		return
	if event.keycode == KEY_ESCAPE:
		if is_instance_valid(modal):
			_close_modal()
		else:
			selected_item = ""
			parser.release_focus()
			_render()
		return
	if parser.has_focus() or is_instance_valid(modal):
		return
	match event.keycode:
		KEY_1: _set_verb("look")
		KEY_2: _set_verb("talk")
		KEY_3: _set_verb("take")
		KEY_4: _set_verb("use")
		KEY_M: _map()
		KEY_J: _journal()
		KEY_H: _toggle_hotspots()
		KEY_O: _settings()
		KEY_T: _transcript()
		KEY_F5: _save()
		KEY_F9: _load()
		KEY_F11: DisplayServer.window_set_mode(DisplayServer.WINDOW_MODE_WINDOWED if DisplayServer.window_get_mode() == DisplayServer.WINDOW_MODE_FULLSCREEN else DisplayServer.WINDOW_MODE_FULLSCREEN)
		KEY_ENTER: parser.grab_focus()

func _automation() -> void:
	var args := OS.get_cmdline_user_args()
	if "--capture-all" in args:
		DirAccess.make_dir_recursive_absolute("res://exports/screenshots")
		for id in game.rooms:
			game.room = id
			_render()
			_say("THE NARRATOR", str(game.get_room().description))
			await get_tree().create_timer(0.5).timeout
			await RenderingServer.frame_post_draw
			get_viewport().get_texture().get_image().save_png("res://exports/screenshots/" + id + ".png")
		game.room = "casino"
		_render()
		_open_casino("blackjack")
		casino_panel.deal_blackjack(5)
		await get_tree().create_timer(0.5).timeout
		await RenderingServer.frame_post_draw
		get_viewport().get_texture().get_image().save_png("res://exports/screenshots/blackjack.png")
		_close_modal()
		_open_casino("slots")
		await get_tree().process_frame
		await RenderingServer.frame_post_draw
		get_viewport().get_texture().get_image().save_png("res://exports/screenshots/slots.png")
		_close_modal()
		get_tree().quit()
		return
	if "--capture" in args:
		await get_tree().process_frame
		await get_tree().process_frame
		await RenderingServer.frame_post_draw
		get_viewport().get_texture().get_image().save_png("res://exports/gameplay.png")
	if "--smoke-ui" in args:
		await get_tree().process_frame
		_set_verb("take")
		_hotspot_click(game.get_hotspot("newsbox"))
		assert(game.inventory.has("newspaper"), "UI newspaper pickup")
		_select_item("newspaper")
		assert(game.flags.get("newspaper_read", false), "Inventory selection records reading")
		_map_travel("garden")
		assert(game.room == "garden", "Map follows multi-room route")
		_map_travel("bar")
		assert(game.room == "bar", "Map can return through hub")
		_map_travel("rooftop")
		assert(game.room == "bar", "Map respects rooftop gate")
		_map()
		_close_modal()
		_journal()
		_close_modal()
		_help()
		_close_modal()
		game.room = "casino"
		_open_casino("blackjack")
		var before_bet: int = game.cash
		var opening_cards: Array[int] = [10, 9, 7, 8]
		casino_panel.set_draw_sequence(opening_cards)
		casino_panel.deal_blackjack(5)
		_close_modal()
		assert(game.cash == before_bet, "Closing casino refunds unsettled hand")
		_open_casino("slots")
		_close_modal()
		_toggle_hotspots()
		_toggle_hotspots()
		for action in ["look", "talk", "take", "use"]:
			_set_verb(action)
		for id in game.rooms:
			game.room = id
			_render()
			await get_tree().process_frame
		game.new_game()
		_render()
		print("UI_SMOKE_OK: all rooms, verbs, map routes/gates, inventory clue, notebook, help and hotspots")
		music.stop()
		music.stream = null
		await get_tree().process_frame
		await get_tree().process_frame
		get_tree().quit()

func _refresh_companion() -> void:
	if is_instance_valid(web_companion): web_companion.refresh.call_deferred()

func _cue(id: String) -> void:
	if is_instance_valid(sound_effects): sound_effects.play_cue(id)

func _cancel_selection() -> void:
	selected_item = ""
	_render()

func _toggle_tidy() -> void:
	tidy_pockets = not tidy_pockets
	_render()
	_say("YOUR POCKETS", "Used souvenirs are tucked away. Press Tidy again to see them." if tidy_pockets else "All pocket items are visible, including souvenirs from earlier puzzles.")

func _scroll_to_item(id: String) -> void:
	await get_tree().process_frame
	await get_tree().process_frame
	if not is_inside_tree(): return
	for child in inventory_box.get_children():
		if child.get_meta("inventory_id", "") == id:
			inventory_scroll.ensure_control_visible(child)
			return

func _conversation(target: String) -> void:
	if is_cinematic(): return
	var options: Array = game.dialogue_options(target)
	if options.is_empty(): return
	_animate_npc(target, "talk")
	var title: String = str(game.get_hotspot(target).get("label", target.capitalize()))
	var p := _modal_base("A word with " + title, "Choose a topic, or close this conversation to explore.", 790)
	var scroll := ScrollContainer.new()
	scroll.position = Vector2(34, 138)
	scroll.size = Vector2(732, 547)
	scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	p.add_child(scroll)
	_button(p, "Back to the room", Rect2(34, 708, 732, 48), _close_modal)
	var column := VBoxContainer.new()
	column.custom_minimum_size = Vector2(710, 0)
	column.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	column.add_theme_constant_override("separation", 14)
	scroll.add_child(column)
	var reply_parent: Control = column
	var reply_width := 697.0
	var npc := _npc_actor(target)
	if is_instance_valid(npc):
		# The dialog covers the room; let the same character perform its reply
		# here immediately, without delaying any conversation controls.
		var row := HBoxContainer.new()
		row.add_theme_constant_override("separation", 16)
		column.add_child(row)
		var stage := Control.new()
		stage.custom_minimum_size = Vector2(100, 158)
		stage.mouse_filter = Control.MOUSE_FILTER_IGNORE
		row.add_child(stage)
		var portrait := Actor.new()
		portrait.name = "ConversationActor"
		portrait.is_larry = false
		portrait.role = npc.role
		portrait.gender = npc.gender
		portrait.skin = npc.skin
		portrait.suit = npc.suit
		portrait.shirt = npc.shirt
		portrait.hair = npc.hair
		portrait.position = Vector2(50, 152)
		portrait.scale = Vector2.ONE * 0.85
		stage.add_child(portrait)
		portrait.set_reduced_motion(reduced_motion)
		portrait.sync_reaction(game.flags)
		portrait.interact_react("talk")
		reply_parent = row
		reply_width = 581.0
	var reply := _label(reply_parent, last_message, Rect2(0, 0, reply_width, 0), 21)
	reply.custom_minimum_size = Vector2(reply_width, 0)
	reply.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	for option in options:
		var id := str(option.id)
		var b := _button(column, str(option.label), Rect2(0, 0, 697, 64), _choose_dialogue.bind(id), id.begins_with("ending_"))
		b.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		b.set_meta("dialogue_choice", id)
		dialogue_choice_buttons[id] = b
	if not dialogue_choice_buttons.is_empty(): dialogue_choice_buttons.values()[0].grab_focus()
	_refresh_companion()

func _choose_dialogue(id: String) -> void:
	if is_cinematic(): return
	_close_modal()
	var response: String = game.choose_dialogue(id)
	_say("THE CONVERSATION", response)
	if id.begins_with("dance_"): _play_dance()
	if id in ["show_next", "show_start", "rehearsal_correct"]: _cue("punchline")
	_render()
	if is_cinematic(): return
	_autosave()
	_conversation(game.get_dialogue_target())

func _transcript() -> void:
	if is_cinematic(): return
	var p := _modal_base("The evening, in your own words.", "The most recent 120 exchanges from this session. Scroll to read.", 750)
	var scroll := ScrollContainer.new()
	scroll.position = Vector2(34, 139)
	scroll.size = Vector2(732, 560)
	scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	p.add_child(scroll)
	var body := _label(scroll, "\n\n".join(transcript), Rect2(0, 0, 697, 0), 20)
	body.custom_minimum_size = Vector2(697, 0)
	body.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	_refresh_companion()

func _settings() -> void:
	if is_cinematic(): return
	var p := _modal_base("Make yourself comfortable.", "Every sound has visible feedback. Settings stay on this device.", 650)
	_button(p, "Reduced motion: " + ("ON" if reduced_motion else "OFF"), Rect2(34, 142, 732, 50), _toggle_motion)
	_button(p, "Music: " + ("ON" if music_on else "OFF"), Rect2(34, 212, 250, 50), func(): _toggle_music(); _settings())
	_settings_slider(p, "Music volume", Vector2(320, 229), music_volume, _music_level)
	_button(p, "Effects: " + ("ON" if effects_on else "OFF"), Rect2(34, 282, 250, 50), _toggle_effects)
	_settings_slider(p, "Effects volume", Vector2(320, 299), effects_volume, _effects_level)
	_button(p, "Read conversation transcript", Rect2(34, 371, 732, 55), _transcript)
	var body := _label(p, "Keyboard: Tab moves focus; Enter activates a button. Escape closes a panel. In the browser, Text & keyboard controls opens a readable version of the current scene and the same actions.", Rect2(34, 454, 732, 125), 20, MUTED)
	body.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	_refresh_companion()

func _settings_slider(parent: Node, title: String, pos: Vector2, value: float, changed: Callable) -> void:
	var slider := HSlider.new()
	slider.position = pos
	slider.size = Vector2(435, 28)
	slider.min_value = 0
	slider.max_value = 1
	slider.step = 0.05
	slider.value = value
	slider.tooltip_text = title
	slider.value_changed.connect(changed)
	parent.add_child(slider)

func _toggle_motion() -> void:
	if is_cinematic(): return
	reduced_motion = not reduced_motion
	if walk_tween and walk_tween.is_valid(): walk_tween.kill()
	larry.walking = false
	larry.stop_dance()
	_render()
	_save_preferences()
	_settings()

func _toggle_effects() -> void:
	effects_on = not effects_on
	sound_effects.set_enabled(effects_on and not qa_mode and DisplayServer.get_name() != "headless")
	_save_preferences()
	_settings()

func _music_level(value: float) -> void:
	music_volume = value
	_apply_music_preferences()
	_save_preferences()

func _effects_level(value: float) -> void:
	effects_volume = value
	sound_effects.set_volume(value)
	_save_preferences()

func _load_preferences() -> void:
	if qa_mode or DisplayServer.get_name() == "headless": return
	var config := ConfigFile.new()
	if config.load("user://preferences.cfg") != OK: return
	reduced_motion = bool(config.get_value("play", "reduced_motion", false))
	music_on = bool(config.get_value("audio", "music_on", true))
	effects_on = bool(config.get_value("audio", "effects_on", true))
	music_volume = clampf(float(config.get_value("audio", "music_volume", 0.5)), 0, 1)
	effects_volume = clampf(float(config.get_value("audio", "effects_volume", 0.5)), 0, 1)

func _save_preferences() -> void:
	if qa_mode or DisplayServer.get_name() == "headless": return
	var config := ConfigFile.new()
	config.set_value("play", "reduced_motion", reduced_motion)
	config.set_value("audio", "music_on", music_on)
	config.set_value("audio", "effects_on", effects_on)
	config.set_value("audio", "music_volume", music_volume)
	config.set_value("audio", "effects_volume", effects_volume)
	config.save("user://preferences.cfg")

func _use_selected_self() -> void:
	if is_cinematic(): return
	if selected_item.is_empty() or not game.inventory.has(selected_item): return
	_say("IN YOUR POCKET", game.interact(selected_item, "use", selected_item))
	_render()
	if is_cinematic(): return
	_autosave()

func _apply_music_preferences() -> void:
	music_button.text = "Music" if music_on else "Muted"
	if is_instance_valid(music):
		music.volume_db = linear_to_db(maxf(music_volume, 0.00001)) - 9.0
		music.stream_paused = not music_on or music_volume == 0.0
