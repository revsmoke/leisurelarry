extends Control
## Transient party session. Adventure progress changes only via completed signal.
signal completed(result: String)
signal dismissed
signal invitation
signal changed
const PartyGames = preload("res://scripts/party_games.gd")
const Hosts = preload("res://scripts/party_hosts.gd")
const Actor = preload("res://scripts/actor.gd")
const Table = preload("res://scripts/party_table.gd")
const LOCAL_ORIGIN := "http://127.0.0.1:8766"
const CREAM := Color("f6e4bc")
const MINT := Color("70e1cb")
const PINK := Color("ef83b6")
var model := PartyGames.new()
var host_id := ""
var host: Dictionary
var player_name := ""
var player_profile: Dictionary = {}
var ui_font: Font
var reduced_motion := false
var live_rival := true
var network_available := false
var pending := false
var intro := true
var active := false
var interlude_left := 0.0
var interlude_duration := 1.15
var completed_sent := false
var serial := 0
var request_token := ""
var pending_revision := -1
var pending_action := ""
var last_ai: Dictionary = {}
var http: HTTPRequest
var timeout_timer: Timer
var table: Control
var player_actor: Control
var host_actor: Control
var rules: Label
var score: Label
var detail: RichTextLabel
var visual_text: Label
var controls: HFlowContainer
var footer: HBoxContainer
var action_buttons: Dictionary = {}

func setup(state: RefCounted, id: String, font: Font, reduced: bool = false, allow_network: bool = true) -> void:
	host_id = id
	host = state.actor_profile(id)
	player_name = state.player_name()
	player_profile = state.profile.duplicate(true)
	ui_font = font
	reduced_motion = reduced
	network_available = allow_network and DisplayServer.get_name() != "headless"
	if OS.has_feature("web"):
		network_available = network_available and str(JavaScriptBridge.eval("window.location.origin")) == LOCAL_ORIGIN
	active = true
	size = Vector2(732, 718)
	model.setup(Hosts.mode_for(id))
	rules = _label("", Rect2(0, 0, 732, 90), 17)
	score = _label("", Rect2(0, 101, 732, 30), 19, MINT)
	table = Table.new()
	table.position = Vector2(0, 140)
	add_child(table)
	table.setup(font)
	player_actor = _actor("party_player", state.player_gender(), Vector2(55, 350))
	host_actor = _actor(host.role, host.gender, Vector2(677, 350))
	host_actor.skin = Color(host.get("skin", "dca483"))
	_label(player_name, Rect2(2, 352, 108, 23), 16, PINK).horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_label(host.name, Rect2(623, 352, 108, 23), 16, PINK).horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	detail = RichTextLabel.new()
	detail.position = Vector2(0, 389)
	detail.size = Vector2(732, 100)
	detail.add_theme_font_override("normal_font", font)
	detail.add_theme_font_size_override("normal_font_size", 20)
	detail.add_theme_color_override("default_color", CREAM)
	detail.scroll_active = true
	add_child(detail)
	visual_text = _label("", Rect2(0, 491, 732, 51), 15, Color("a8c0c5"))
	controls = HFlowContainer.new()
	controls.position = Vector2(0, 554)
	controls.size = Vector2(732, 104)
	controls.add_theme_constant_override("h_separation", 8)
	controls.add_theme_constant_override("v_separation", 8)
	add_child(controls)
	footer = HBoxContainer.new()
	footer.position = Vector2(0, 673)
	footer.size = Vector2(732, 44)
	footer.add_theme_constant_override("separation", 8)
	add_child(footer)
	http = HTTPRequest.new()
	http.timeout = 1.8
	add_child(http)
	http.request_completed.connect(_reply)
	timeout_timer = Timer.new()
	timeout_timer.one_shot = true
	timeout_timer.wait_time = 1.7
	add_child(timeout_timer)
	timeout_timer.timeout.connect(_offline_reply)
	_refresh()
	_begin_interlude(1.25)

func _actor(role: String, gender: String, at: Vector2) -> Control:
	var actor := Actor.new()
	actor.role = role
	actor.gender = gender
	actor.is_larry = role == "party_player"
	actor.position = at
	actor.scale = Vector2.ONE * 0.83
	actor.set_reduced_motion(reduced_motion)
	add_child(actor)
	actor.interact_react("talk")
	return actor

func _label(value: String, rect: Rect2, font_size: int, color: Color = CREAM) -> Label:
	var label := Label.new()
	label.text = value
	label.position = rect.position
	label.size = rect.size
	label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	label.add_theme_font_override("font", ui_font)
	label.add_theme_font_size_override("font_size", font_size)
	label.add_theme_color_override("font_color", color)
	label.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(label)
	return label

func _button(parent: Control, value: String, action: Callable, width: float = 237) -> Button:
	var button := Button.new()
	button.text = value
	button.custom_minimum_size = Vector2(width, 44)
	button.add_theme_font_override("font", ui_font)
	button.add_theme_font_size_override("font_size", 17)
	button.add_theme_color_override("font_color", CREAM)
	button.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	for state in ["normal", "hover", "pressed", "focus"]:
		var style := StyleBoxFlat.new()
		style.bg_color = Color("28354b") if state == "normal" else Color("365366")
		style.border_color = PINK if state == "focus" else MINT
		style.set_border_width_all(1)
		style.set_corner_radius_all(7)
		style.content_margin_left = 8
		style.content_margin_right = 8
		button.add_theme_stylebox_override(state, style)
	parent.add_child(button)
	button.pressed.connect(action)
	return button

func _clear(parent: Node) -> void:
	for child in parent.get_children():
		parent.remove_child(child)
		child.queue_free()

func _refresh() -> void:
	if not active: return
	var view: Dictionary = model.view()
	rules.text = str(view.rules)
	score.text = "Round %d / %d   ·   %s %d : %d %s   ·   No cash stakes" % [view.round, view.rounds, player_name, view.player_score, view.npc_score, host.name]
	if view.mode == "never": score.text = "Prompt %d / %d   ·   Confessions: %s %d, %s %d   ·   No winner" % [view.round, view.rounds, player_name, view.player_score, host.name, view.npc_score]
	table.model_view = view
	table.reduced_motion = reduced_motion
	table.queue_redraw()
	player_actor.party_loss = mini(3, int(view.player_losses))
	host_actor.party_loss = mini(3, int(view.npc_losses))
	player_actor.queue_redraw()
	host_actor.queue_redraw()
	detail.text = Hosts.table_intro(host_id, player_profile) if intro else str(view.status)
	if pending: detail.text += "\n" + host.name + " considers the next move…"
	if not intro and not pending:
		detail.text += "\nCostumes: " + player_name + " — " + Hosts.wardrobe("party_player", view.player_losses) + "; " + host.name + " — " + Hosts.wardrobe(host_id, view.npc_losses) + "."
	detail.scroll_to_line(0)
	visual_text.text = _visible_details(view)
	_clear(controls)
	_clear(footer)
	action_buttons.clear()
	if intro:
		action_buttons.start = _button(controls, "Let's play · start the game", _start, 732)
	elif interlude_left > 0:
		action_buttons.skip = _button(controls, "Skip the wardrobe interlude", _skip_interlude, 732)
	else:
		for choice in view.choices:
			var key: String = str(choice.id)
			var button := _button(controls, str(choice.label), _action.bind(key))
			button.disabled = pending
			action_buttons[key] = button
		if view.finished:
			action_buttons.rematch = _button(controls, "Play a fresh rematch", _rematch, 362)
			action_buttons.chat = _button(controls, "A little after-game flirting?", func(): invitation.emit(), 362)
	_button(footer, "Leave table · no penalty", func(): dismissed.emit(), 362)
	if network_available and Hosts.mode_for(host_id) != "pool":
		var toggle := _button(footer, "Live rival: on" if live_rival else "Live rival: off", _toggle_rival, 362)
		toggle.tooltip_text = "Optional online rival tactics and banter. Rules and scores are always local; offline play is immediate."
		toggle.disabled = pending
	else:
		_button(footer, "Rules / costume check", _rules_reminder, 362)
	changed.emit()

func _visible_details(view: Dictionary) -> String:
	var v: Dictionary = view.visuals
	if view.mode == "poker":
		var cards: Array[String] = []
		for card in v.get("player_cards", []): cards.append(str(card.get("label", "")))
		return "Your hand: " + ", ".join(cards) + ("\nShowdown: " + str(v.get("player_rank", "")) + " / rival: " + str(v.get("npc_rank", "")) if v.get("revealed", false) else "\nRival's cards stay face down. Select up to three cards to swap, then Draw.")
	if view.mode == "pool": return "Aim %d° · Power %d%%. The pink ring marks your pocket. Adjust the cue, then Shoot." % [v.get("angle", 0), v.get("power", 0)]
	return "Play as " + player_name + ", not as yourself. Pass skips the confession without losing clothing."

func _start() -> void:
	intro = false
	interlude_left = 0
	table.interlude = false
	set_process(false)
	_refresh()

func _action(id: String) -> void:
	if not active or intro or pending or interlude_left > 0: return
	if id == "draw" and live_rival and network_available and not model.ai_request().is_empty():
		_request_judgment(id)
		return
	_execute(id)

func _execute(id: String) -> void:
	if not model.act(id): return
	_record_finish()
	if id in ["draw", "shoot", "have", "never", "pass"]:
		if Hosts.mode_for(host_id) == "never" and id != "pass" and live_rival and network_available and not model.ai_request().is_empty():
			_request_judgment("")
			return
		_settled()
	else: _refresh()

func _settled() -> void:
	var view: Dictionary = model.view()
	host_actor.interact_react("talk")
	player_actor.interact_react("use")
	_record_finish()
	_begin_interlude(1.45 if view.mode == "pool" else 1.15)
	_refresh()

func _record_finish() -> void:
	var view: Dictionary = model.view()
	if view.finished and not completed_sent:
		completed_sent = true
		completed.emit(str(view.status))

func _begin_interlude(seconds: float) -> void:
	interlude_duration = 0.45 if reduced_motion else seconds
	interlude_left = interlude_duration
	table.motion = 1.0 if reduced_motion else 0.0
	table.interlude = true
	set_process(true)

func _process(delta: float) -> void:
	if not active: return
	interlude_left = maxf(0, interlude_left - delta)
	table.motion = 1.0 if reduced_motion else 1.0 - interlude_left / interlude_duration
	table.queue_redraw()
	if interlude_left <= 0:
		set_process(false)
		table.interlude = false
		_refresh()

func _skip_interlude() -> void:
	interlude_left = 0
	table.motion = 1.0
	table.interlude = false
	set_process(false)
	_refresh()

func _rules_reminder() -> void:
	detail.text = "Lose an accessory, never your right to leave. Hats, ties and outer layers give way to an emergency dressing gown. Everyone stays covered. No cash, quest items or exploration points change hands."
	changed.emit()

func _toggle_rival() -> void:
	live_rival = not live_rival
	_refresh()

func _rematch() -> void:
	http.cancel_request()
	timeout_timer.stop()
	pending = false
	pending_action = ""
	request_token = ""
	pending_revision = -1
	serial += 1
	completed_sent = false
	last_ai.clear()
	model.setup(Hosts.mode_for(host_id))
	intro = true
	_refresh()
	_begin_interlude(1.0)

func _request_judgment(action: String) -> void:
	var question: Dictionary = model.ai_request()
	if question.is_empty():
		if not action.is_empty(): _execute(action)
		return
	pending = true
	pending_action = action
	pending_revision = int(model.view().revision)
	serial += 1
	request_token = "%s-%d-%d-%d" % [host_id, get_instance_id(), Time.get_ticks_msec(), serial]
	var candidates: Array = []
	for candidate in question.candidates: candidates.append({"id": candidate.id, "label": candidate.label})
	var payload := {"request_id": request_token, "mode": question.mode, "observation": question.observation, "candidates": candidates}
	_refresh()
	var headers := PackedStringArray(["Content-Type: application/json"])
	if not OS.has_feature("web"): headers.append("Origin: " + LOCAL_ORIGIN)
	var error := http.request(LOCAL_ORIGIN + "/api/party-judge", headers, HTTPClient.METHOD_POST, JSON.stringify(payload))
	if error != OK: _offline_reply()
	else: timeout_timer.start()

func _reply(result: int, code: int, _headers: PackedStringArray, body: PackedByteArray) -> void:
	if not active or not pending: return
	var answer: Variant = null
	if result == HTTPRequest.RESULT_SUCCESS and code == 200 and body.size() < 8192:
		var parsed := JSON.new()
		if parsed.parse(body.get_string_from_utf8()) == OK: answer = parsed.data
	if answer is Dictionary and answer.get("request_id") != request_token: return
	_finish_judgment(answer)

func _offline_reply() -> void:
	if not pending: return
	http.cancel_request()
	_finish_judgment(null)

func _finish_judgment(answer: Variant) -> void:
	if not active or not pending: return
	timeout_timer.stop()
	var action := pending_action
	pending = false
	pending_action = ""
	if int(model.view().revision) != pending_revision:
		_refresh()
		return
	if answer is Dictionary and answer.get("request_id") == request_token and answer.get("choice") is String:
		if model.resolve_ai(answer.choice): last_ai = answer.duplicate(true)
	if not model.ai_request().is_empty(): model.resolve_fallback()
	if not action.is_empty(): _execute(action)
	else: _settled()

func close_game() -> void:
	active = false
	pending = false
	serial += 1
	set_process(false)
	if is_instance_valid(http): http.cancel_request()
	if is_instance_valid(timeout_timer): timeout_timer.stop()

func _exit_tree() -> void:
	close_game()
