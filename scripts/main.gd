extends Control

const GameState = preload("res://scripts/game_state.gd")
const Actor = preload("res://scripts/actor.gd")
const WorldEffects = preload("res://scripts/world_effects.gd")
const QABridge = preload("res://scripts/qa_bridge.gd")
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
var dialogue: RichTextLabel
var speaker: Label
var inventory_box: VBoxContainer
var exit_box: HBoxContainer
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
var show_hotspots := true
var music: AudioStreamPlayer
var music_on := true
var walk_tween: Tween
var last_message := ""
var ending_shown := false
var casino_panel: Control
var qa_mode := false
var qa_bridge: Node

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
	_build_ui()
	resized.connect(_fit)
	_fit()
	_render()
	_say("THE NARRATOR", "Lost Wages, 1987. Eighty bucks. One polyester suit. Absolutely no reason to be this confident. Welcome to your big night, Larry.")
	_start_music()
	if qa_mode:
		qa_bridge = QABridge.new()
		add_child(qa_bridge)
		qa_bridge.start.call_deferred(self)
	else:
		_automation.call_deferred()
	if not qa_mode and DisplayServer.get_name() != "headless" and FileAccess.file_exists("user://autosave.json") and not ("--capture-all" in OS.get_cmdline_user_args() or "--smoke-ui" in OS.get_cmdline_user_args()):
		_resume_prompt.call_deferred()

func _fit() -> void:
	var ratio := minf(size.x / 1440.0, size.y / 960.0)
	canvas.scale = Vector2.ONE * ratio
	canvas.position = (size - Vector2(1440, 960) * ratio) / 2.0

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
	b.add_theme_color_override("font_pressed_color", INK)
	b.add_theme_color_override("font_disabled_color", MUTED.darkened(0.3))
	b.add_theme_stylebox_override("normal", _style(MINT if accent else PANEL, EDGE))
	b.add_theme_stylebox_override("hover", _style(MINT.lightened(0.13) if accent else Color("202c43"), MINT))
	b.add_theme_stylebox_override("pressed", _style(MINT, MINT))
	b.add_theme_stylebox_override("focus", _style(Color.TRANSPARENT, PINK))
	b.add_theme_stylebox_override("disabled", _style(INK, EDGE))
	b.pressed.connect(callback)
	parent.add_child(b)
	return b

func _build_ui() -> void:
	canvas = Control.new()
	canvas.size = Vector2(1440, 960)
	add_child(canvas)
	_panel(canvas, Rect2(0, 0, 1440, 960), INK, Color.TRANSPARENT, 0)
	_panel(canvas, Rect2(0, 0, 1440, 88), Color("111729"), EDGE, 0)
	_label(canvas, "LEISURE SUIT", Rect2(28, 13, 210, 23), 16, PINK)
	var logo := _label(canvas, "LARRY", Rect2(26, 29, 210, 48), 38)
	logo.add_theme_font_override("font", display_font)
	_label(canvas, "LAST CALL IN LOST WAGES", Rect2(274, 20, 500, 29), 21)
	_label(canvas, "A very questionable night out.", Rect2(274, 49, 480, 22), 15, MUTED)
	money_label = _label(canvas, "$80", Rect2(840, 29, 94, 34), 23, MINT)
	score_label = _label(canvas, "0 / 100", Rect2(941, 29, 118, 34), 20, CREAM)
	_button(canvas, "Save", Rect2(1080, 23, 74, 42), _save).disabled = qa_mode
	_button(canvas, "Load", Rect2(1162, 23, 74, 42), _load).disabled = qa_mode
	music_button = _button(canvas, "Music", Rect2(1244, 23, 82, 42), _toggle_music)
	music_button.disabled = qa_mode
	_button(canvas, "?", Rect2(1334, 23, 76, 42), _help)
	_panel(canvas, Rect2(0, 88, 246, 872), Color("111729"), EDGE, 0)
	_label(canvas, "YOUR EVENING", Rect2(26, 108, 210, 24), 13, MUTED)
	_button(canvas, "City map", Rect2(20, 145, 206, 45), _map)
	_button(canvas, "Notebook", Rect2(20, 201, 206, 45), _journal)
	_button(canvas, "Show next step", Rect2(20, 257, 206, 45), _hint)
	_panel(canvas, Rect2(20, 325, 206, 230), Color("1c2436"), EDGE)
	_label(canvas, "THE PLAN", Rect2(35, 337, 170, 23), 12, MINT)
	objective_text = _label(canvas, "", Rect2(35, 368, 174, 174), 18)
	objective_text.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	_label(canvas, "POCKETS", Rect2(26, 575, 170, 26), 13, MUTED)
	selected_label = _label(canvas, "Select an item to use it.", Rect2(26, 603, 194, 36), 13, MUTED)
	selected_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	var scroll := ScrollContainer.new()
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
	exit_box = HBoxContainer.new()
	exit_box.position = Vector2(270, 919)
	exit_box.size = Vector2(1140, 32)
	exit_box.add_theme_constant_override("separation", 8)
	canvas.add_child(exit_box)
	_set_verb("look")

func _clear(node: Node) -> void:
	for child in node.get_children():
		node.remove_child(child)
		child.queue_free()

func _render() -> void:
	var room: Dictionary = game.get_room()
	room_title.text = room.get("name", game.room)
	room_subtitle.text = str(room.get("subtitle", "LOST WAGES / AFTER HOURS")).to_upper()
	objective_text.text = game.objective()
	score_label.text = "%d / 100" % game.score
	money_label.text = "$%d" % game.cash
	status.text = "A NIGHT TO REMEMBER" if game.completed else "NO BAD DECISIONS. YET."
	if current_render_room != game.room:
		if walk_tween and walk_tween.is_valid():
			walk_tween.kill()
		larry.walking = false
		larry.stop_dance()
		current_render_room = game.room
		var art_path := "res://assets/backgrounds/%s.png" % room.get("background", "street")
		if ResourceLoader.exists(art_path):
			background.texture = load(art_path)
		background.modulate = Color(0.6, 0.6, 0.7)
		create_tween().tween_property(background, "modulate", Color.WHITE, 0.4)
		larry.position = Vector2(490, 493)
	world_effects.sync_state(game.room, game.flags)
	_clear(hotspots)
	_clear(actors)
	for h in room.get("hotspots", []):
		_build_hotspot(h)
	_clear(exit_box)
	_label(exit_box, "GO TO", Rect2(0, 0, 55, 30), 12, MUTED).custom_minimum_size = Vector2(55, 30)
	for e in room.get("exits", []):
		var id: String = e.id
		var b := _button(exit_box, str(e.label) + "  →", Rect2(0, 0, 130, 30), _travel.bind(id))
		b.add_theme_font_size_override("font_size", 13)
	_clear(inventory_box)
	if not game.inventory.has(selected_item):
		selected_item = ""
	selected_label.text = "Use %s with…" % game.items[selected_item].name if not selected_item.is_empty() else "Select an item to use it."
	if game.inventory.is_empty():
		var empty := _label(inventory_box, "Nothing but optimism.\nAnd a wallet.", Rect2(0, 0, 200, 58), 16, MUTED)
		empty.custom_minimum_size = Vector2(180, 58)
	else:
		for item in game.get_inventory():
			var id: String = item.id
			var b := _button(inventory_box, ("*  " if selected_item == id else "+  ") + str(item.name), Rect2(0, 0, 202, 39), _select_item.bind(id), selected_item == id)
			b.alignment = HORIZONTAL_ALIGNMENT_LEFT
			b.add_theme_font_size_override("font_size", 15)
			b.tooltip_text = item.get("description", "")
			b.gui_input.connect(_inventory_input.bind(id))
	if game.completed and not ending_shown:
		ending_shown = true
		_ending.call_deferred()

func _build_hotspot(h: Dictionary) -> void:
	var point := Vector2(float(h.get("x", 0.5)) * 1140, float(h.get("y", 0.5)) * 506)
	if h.get("kind", "object") == "person":
		var npc := Control.new()
		npc.set_script(Actor)
		npc.is_larry = false
		npc.role = str(h.id)
		npc.suit = PINK if str(h.id).length() % 2 == 0 else Color("52b7b1")
		npc.shirt = Color("2a294d")
		npc.hair = Color("b77147")
		npc.position = point + Vector2(0, 76)
		npc.scale = Vector2.ONE * 0.85
		actors.add_child(npc)
	var label_text := str(h.get("label", h.id))
	var prefix := ">  " if h.get("kind") == "exit" else "·  "
	var width := clampf(label_text.length() * 8.3 + 32, 80, 220)
	width = width if show_hotspots else 32.0
	var pos := Vector2(clampf(point.x - width / 2, 8, 1132 - width), clampf(point.y - 15, 8, 465))
	if h.get("kind", "object") == "person":
		pos.y = clampf(point.y - 66, 8, 465)
	# Labels stay readable even when several small props share a table.
	for attempt in range(8):
		var overlaps := false
		for other in hotspots.get_children():
			if other is Control and Rect2(pos, Vector2(width, 34)).grow(3).intersects(other.get_rect()):
				overlaps = true
				break
		if not overlaps:
			break
		var offset_y := 41.0 * float((attempt / 2) + 1) * (1.0 if attempt % 2 == 0 else -1.0)
		pos.y = clampf(point.y - 15 + offset_y, 8, 465)
	var b := _button(hotspots, prefix + label_text if show_hotspots else "+", Rect2(pos, Vector2(width if show_hotspots else 32.0, 34)), _hotspot_click.bind(h))
	b.add_theme_font_size_override("font_size", 14)
	b.add_theme_stylebox_override("normal", _style(Color(0.04, 0.07, 0.13, 0.87), Color(0.44, 0.88, 0.8, 0.55), 6))
	b.add_theme_stylebox_override("hover", _style(Color("172e3c"), MINT, 6))
	b.mouse_entered.connect(func(): hover_label.text = ("Use " + str(game.items[selected_item].name) + " with " if not selected_item.is_empty() else verb.capitalize() + " · ") + label_text)
	b.mouse_exited.connect(func(): hover_label.text = "Click the scenery to walk. Right-click an object to look at it.")
	b.gui_input.connect(_hotspot_input.bind(h))

func _hotspot_input(event: InputEvent, h: Dictionary) -> void:
	if event is InputEventMouseButton and event.pressed and event.button_index == MOUSE_BUTTON_RIGHT:
		_say("THE NARRATOR", game.interact(str(h.id), "look"))
		_render()

func _inventory_input(event: InputEvent, id: String) -> void:
	if event is InputEventMouseButton and event.pressed and event.button_index == MOUSE_BUTTON_RIGHT:
		_say("IN YOUR POCKET", game.interact(id, "look"))
		_render()
		_autosave()
	elif event is InputEventMouseButton and event.pressed and event.button_index == MOUSE_BUTTON_LEFT and event.double_click:
		_say("IN YOUR POCKET", game.interact(id, "use", id))
		_render()
		_autosave()

func _hotspot_click(h: Dictionary) -> void:
	if h.id in ["slots", "blackjack"] and verb == "use" and selected_item.is_empty():
		_open_casino(str(h.id))
		return
	_move_larry(Vector2(clampf(float(h.get("x", 0.5)) * 1140, 80, 1040), 492))
	if h.get("kind") == "exit":
		_travel(str(h.id))
		return
	var result: String = game.interact(str(h.id), "use" if not selected_item.is_empty() else verb, selected_item)
	if h.id in ["dancer", "dancefloor"] and verb == "use" and selected_item.is_empty() and game.flags.get("danced", false):
		_play_dance()
	_say(str(h.get("label", "THE NARRATOR")).to_upper() if verb == "talk" else "THE NARRATOR", result)
	_render()
	_autosave()

func _background_input(event: InputEvent) -> void:
	if event is InputEventMouseButton and event.pressed and event.button_index == MOUSE_BUTTON_LEFT:
		_move_larry(Vector2(clampf(event.position.x, 50, 1090), clampf(event.position.y, 420, 505)))

func _move_larry(destination: Vector2) -> void:
	larry.stop_dance()
	if walk_tween and walk_tween.is_valid():
		walk_tween.kill()
	larry.walking = true
	walk_tween = create_tween()
	walk_tween.tween_property(larry, "position", destination, larry.position.distance_to(destination) / 320.0)
	walk_tween.tween_callback(func(): larry.walking = false)

func _play_dance() -> void:
	if walk_tween and walk_tween.is_valid():
		walk_tween.kill()
	larry.position = Vector2(405, 459)
	larry.dance()

func _set_verb(value: String) -> void:
	verb = value
	if value != "use":
		selected_item = ""
	for key in verbs:
		verbs[key].add_theme_stylebox_override("normal", _style(MINT if key == value else PANEL, MINT if key == value else EDGE))
		verbs[key].add_theme_color_override("font_color", INK if key == value else CREAM)
	if inventory_box:
		_render()

func _select_item(id: String) -> void:
	if not game.inventory.has(id):
		return
	selected_item = "" if selected_item == id else id
	_set_verb("use")
	_render()
	if not selected_item.is_empty():
		_say("IN YOUR POCKET", game.interact(id, "look") + " Select a target to use it; double-click to use it on its own.")
		_render()
		_autosave()

func _travel(id: String) -> void:
	_close_modal()
	selected_item = ""
	_say("THE NARRATOR", game.travel(id))
	_render()
	_autosave()

func _command(text: String) -> void:
	if text.strip_edges().is_empty():
		return
	var normalized := text.strip_edges().to_lower()
	if qa_mode and normalized in ["save", "save game", "load", "load game", "restore"]:
		parser.clear()
		_say("QA SESSION", "Save and load are disabled in this isolated playtest.")
		return
	if game.room == "casino" and normalized in ["blackjack", "play blackjack", "use blackjack", "play 21", "slots", "play slots", "use slots"]:
		parser.clear()
		parser.release_focus()
		_open_casino("slots" if "slots" in normalized else "blackjack")
		return
	_say("> " + text.to_upper(), game.command(text))
	if game.room == "disco" and normalized in ["dance", "dance with didi", "use dance floor", "use floor", "use dancefloor", "use didi"] and game.flags.get("danced", false):
		_play_dance()
	parser.clear()
	parser.release_focus()
	_render()
	_autosave()

func _say(who: String, text: String) -> void:
	speaker.text = who
	dialogue.text = text
	dialogue.scroll_to_line(0)
	last_message = text

func _save() -> void:
	if qa_mode:
		return
	_say("SAVED FOR POSTERITY", game.save_game())

func _load() -> void:
	if qa_mode:
		return
	_say("PREVIOUSLY, ON LARRY…", game.load_game())
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
	_say("NEXT STEP · CONTAINS SPOILERS", game.hint())

func _toggle_hotspots() -> void:
	show_hotspots = not show_hotspots
	_render()

func _start_music() -> void:
	music = AudioStreamPlayer.new()
	add_child(music)
	if qa_mode or DisplayServer.get_name() == "headless":
		return
	if ResourceLoader.exists("res://assets/audio/last_call.wav"):
		music.stream = load("res://assets/audio/last_call.wav")
		music.volume_db = -15
		music.finished.connect(func(): music.play())
		music.play()

func _toggle_music() -> void:
	if qa_mode:
		return
	music_on = not music_on
	music_button.text = "Music" if music_on else "Muted"
	music.stream_paused = not music_on

func _modal_base(title: String, subtitle: String, height: float = 660) -> Control:
	_close_modal()
	modal = Control.new()
	modal.size = Vector2(1440, 960)
	canvas.add_child(modal)
	var dim := ColorRect.new()
	dim.color = Color(0.02, 0.025, 0.055, 0.86)
	dim.size = modal.size
	modal.add_child(dim)
	var p := _panel(modal, Rect2(350, (960 - height) / 2, 800, height), Color("151e31"), EDGE, 16)
	p.mouse_filter = Control.MOUSE_FILTER_STOP
	_label(p, title, Rect2(34, 25, 630, 54), 31)
	_label(p, subtitle, Rect2(34, 86, 725, 34), 16, MUTED)
	_button(p, "×", Rect2(711, 27, 52, 43), _close_modal)
	return p

func _close_modal() -> void:
	if is_instance_valid(casino_panel):
		casino_panel.close_game()
		casino_panel = null
	if is_instance_valid(modal):
		remove_child_if_needed(modal)
		modal.queue_free()
	modal = null

func _open_casino(mode: String) -> void:
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
	# Follow actual unlocked exits, preserving every puzzle gate and move count.
	var frontier: Array = [[game.room]]
	var visited: Dictionary = {game.room: true}
	while not frontier.is_empty():
		var route: Array = frontier.pop_front()
		var here: String = route.back()
		if here == destination:
			_close_modal()
			var result := "You are already here. The map remains impressed."
			for i in range(1, route.size()):
				result = game.travel(route[i])
			selected_item = ""
			_say("THE NARRATOR", result)
			_render()
			_autosave()
			return
		for e in game.get_room(here).exits:
			if not visited.has(e.id) and game.is_unlocked(e.id):
				visited[e.id] = true
				frontier.append(route + [e.id])
	_say("THE NARRATOR", "That route is still closed. A few good conversations may open it.")

func _journal() -> void:
	var p := _modal_base("Notes to a future, wiser Larry", "Clues are recorded here as you discover them.")
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
	var p := _modal_base("How to make an impression", "A point-and-click adventure with a soft spot for the text parser.", 706)
	# Wrapped Labels grow beyond a requested rectangle; the scrolling viewport
	# keeps the complete instructions readable above the fixed footer.
	var scroll := ScrollContainer.new()
	scroll.position = Vector2(34, 135)
	scroll.size = Vector2(732, 436)
	scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	p.add_child(scroll)
	var body := _label(scroll, "LOOK at things. TALK to people. TAKE useful objects.\nUSE an item by selecting it in your pockets, then clicking its target.\n\nClick an exit or use the City map to travel. Click the scenery to walk.\nRight-click any object to inspect it. Your notebook keeps the clues.\n\nKeyboard: 1–4 choose verbs · M map · J notebook · H hotspots\nF5 save · F9 load · Enter type a command · Escape close / deselect\n\nTry: look sink, take ring, talk lefty, use whiskey on patron.\nSave writes your manual slot; Load restores it. Progress also autosaves.\n\nA loving, unofficial reimagining of Softporn Adventure and Larry 1.\nOriginal art, dialogue and music. All characters are adults; romance\nstays suggestive and consensual. Polyester remains inexcusable.", Rect2(0, 0, 697, 0), 20)
	body.custom_minimum_size = Vector2(697, 0)
	body.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	body.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	_button(p, "Back to a questionable evening", Rect2(34, 609, 464, 48), _close_modal, true)
	_button(p, "Restore autosave", Rect2(514, 609, 252, 48), _restore_autosave)

func _restore_autosave() -> void:
	if qa_mode:
		return
	_close_modal()
	_say("PICKING UP THE PIECES", game.load_game("user://autosave.json"))
	current_render_room = ""
	ending_shown = game.completed
	_render()

func _resume_prompt() -> void:
	var p := _modal_base("Your evening is still here.", "An autosaved game is ready. Continue it or start a fresh night.", 320)
	_button(p, "Continue evening", Rect2(34, 170, 349, 62), _restore_autosave, true)
	_button(p, "Start a new evening", Rect2(401, 170, 365, 62), _new_game)

func _new_game_prompt() -> void:
	var p := _modal_base("Another night, another suit?", "Start over? Your manual save stays available through Load.", 300)
	_button(p, "Keep this evening", Rect2(34, 162, 344, 62), _close_modal)
	_button(p, "Start a new evening", Rect2(402, 162, 364, 62), _new_game, true)

func _new_game() -> void:
	_close_modal()
	game.new_game()
	selected_item = ""
	ending_shown = false
	current_render_room = ""
	_set_verb("look")
	_render()
	_say("THE NARRATOR", "A fresh evening. A familiar suit. Lefty's looks like the sort of establishment that might lower its standards for you.")

func _ending() -> void:
	var p := _modal_base("Last call. First connection.", "You survived Lost Wages, and even learned somebody's name.", 630)
	var body := _label(p, "The city keeps flashing. The ice keeps melting.\nFor once, Larry stops working on his next line and listens.\n\nEve smiles. The skyline does the rest.\n\nA little kindness, a very strange apple, and one resilient suit.\nNot a bad night's work.", Rect2(34, 142, 732, 317), 23)
	body.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	_label(p, "%d / 100 POINTS  ·  %d MOVES  ·  ONE GREAT STORY" % [game.score, game.turns], Rect2(34, 465, 730, 31), 16, MINT)
	_button(p, "Stay a little longer", Rect2(34, 534, 349, 52), _close_modal)
	_button(p, "One more evening", Rect2(401, 534, 365, 52), _new_game, true)

func _unhandled_key_input(event: InputEvent) -> void:
	if not event is InputEventKey or not event.pressed or event.echo:
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
