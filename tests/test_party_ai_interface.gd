extends SceneTree
## Client lifecycle tests with a transport boundary double, not live API play.
## HTTPRequest's native request method is not virtual. This double only arms the
## pending request instead of sending it; action, reply, timeout, settlement,
## completion and close behavior remain the production panel's implementations.
## No .env, socket, player save, secret, or external judgment is used.
const Game = preload("res://scripts/game_state.gd")
const Hosts = preload("res://scripts/party_hosts.gd")
const FONT = preload("res://assets/fonts/Outfit.ttf")

class MockPartyPanel:
	extends "res://scripts/party_panel.gd"
	var requests: Array[Dictionary] = []
	var event_order: Array[String] = []
	var mock_deadline := 60.0
	func _request_judgment(action: String) -> void:
		var question: Dictionary = model.ai_request()
		if question.is_empty():
			if not action.is_empty(): _execute(action)
			return
		pending = true
		pending_action = action
		pending_revision = int(model.view().revision)
		serial += 1
		request_token = "mock-%d-%d" % [get_instance_id(), serial]
		requests.append({"request_id": request_token, "question": question.duplicate(true)})
		event_order.append("request")
		timeout_timer.start(mock_deadline)
		_refresh()

var checks := 0
var failures: Array[String] = []
var context := ""

func _init() -> void: _run.call_deferred()

func check(value: bool, message: String) -> void:
	checks += 1
	if not value:
		failures.append(context + ": " + message)
		printerr("FAIL: " + context + ": " + message)

func make_panel(mode: String = "poker", seed_value: int = 312) -> MockPartyPanel:
	var game := Game.new()
	game.new_game(17)
	var panel := MockPartyPanel.new()
	root.add_child(panel)
	var id: String = {"poker": "party_cabbie", "never": "party_host"}[mode]
	panel.setup(game, id, FONT, false, true)
	check(not panel.network_available, "Headless setup cannot make a live call")
	panel.model.setup(mode, seed_value)
	panel._start()
	# Only the overridden transport boundary runs when network_available is true.
	panel.network_available = true
	panel._refresh()
	return panel

func dispose(panel: MockPartyPanel) -> void:
	panel.close_game()
	panel.queue_free()

func press(panel: MockPartyPanel, id: String) -> void:
	var button: Button = panel.action_buttons.get(id)
	check(is_instance_valid(button) and not button.disabled, "Real enabled table button: " + id)
	if is_instance_valid(button) and not button.disabled: button.pressed.emit()

func skip(panel: MockPartyPanel) -> void:
	if panel.interlude_left > 0: panel._skip_interlude()

func result_for(panel: MockPartyPanel, choice: String, id: String = "") -> Dictionary:
	return {"request_id": panel.request_token if id.is_empty() else id, "choice": choice, "source": "jev", "confidence": 0.61, "model": "jev-client-fixture"}

func deliver(panel: MockPartyPanel, data: Variant, result_code: int = HTTPRequest.RESULT_SUCCESS, http_code: int = 200) -> void:
	panel._reply(result_code, http_code, PackedStringArray(), JSON.stringify(data).to_utf8_buffer())

func _run() -> void:
	root.size = Vector2i(1440, 960)
	_valid_and_private()
	_bad_and_missing_results()
	_no_network_and_pass()
	_late_and_stale()
	_close_and_revision()
	_final_never_ordering()
	_final_pending_rematch()
	await _actual_timeout()
	await process_frame
	await process_frame
	print("Party AI interface checks: %d passed, %d failed" % [checks - failures.size(), failures.size()])
	quit(0 if failures.is_empty() else 1)

func _valid_and_private() -> void:
	context = "valid reply / private information"
	var panel := make_panel()
	check(panel.timeout_timer.wait_time > 0 and panel.timeout_timer.wait_time <= 2.0 and panel.timeout_timer.wait_time < panel.http.timeout, "A finite client deadline precedes the transport deadline")
	press(panel, "toggle_0")
	press(panel, "toggle_2")
	var before: Dictionary = panel.model.view()
	press(panel, "draw")
	check(panel.pending and panel.requests.size() == 1, "One draw asks for one opponent decision")
	check(not panel.timeout_timer.is_stopped(), "A pending decision has a deadline")
	check(panel.model.view() == before, "Waiting never deals or reveals a card")
	for button in panel.action_buttons.values(): check(button.disabled, "Every pending table move is disabled")
	var request: Dictionary = panel.requests[0].question
	var keys: Array = request.observation.keys()
	keys.sort()
	check(keys == ["own_cards", "persona", "player_discard_count", "round"], "Only four allowed opponent/public fields are observed")
	check(request.observation.own_cards == panel.model._npc_hand, "Opponent observes its own hand")
	check(request.observation.own_cards != panel.model._player_hand, "Opponent is not given the player's private hand")
	check(request.observation.player_discard_count == 2, "Player discard count is public; discarded card identities are not sent")
	for hidden_key in ["player_cards", "player_hand", "deck", "seed", "flags", "cash"]:
		check(not request.observation.has(hidden_key), "No hidden field: " + hidden_key)
	var ids: Array[String] = []
	for candidate in request.candidates: ids.append(candidate.id)
	ids.sort()
	check(ids == ["chase_flush", "draw_three", "keep_all", "keep_pairs"], "Opponent receives exactly four legal strategies")
	deliver(panel, result_for(panel, "keep_pairs"))
	check(not panel.pending and panel.timeout_timer.is_stopped(), "A valid reply clears pending state and deadline")
	check(panel.model.view().visuals.revealed, "The accepted reply executes the original Draw action")
	check(panel.last_ai.get("model") == "jev-client-fixture" and panel.last_ai.get("choice") == "keep_pairs", "Matching legal reply retains model decision metadata")
	check(panel.interlude_left > 0 and panel.table.interlude, "A settled hand gets its wardrobe interlude")
	var settled: Dictionary = panel.model.view()
	deliver(panel, result_for(panel, "draw_three"))
	panel.timeout_timer.timeout.emit()
	check(panel.model.view() == settled, "Duplicate replies and a late timeout cannot draw twice")
	dispose(panel)

func _bad_and_missing_results() -> void:
	for failure in ["illegal_policy", "wrong_mode_policy", "bad_json", "bad_shape", "http_error", "transport_error", "oversized"]:
		context = "fallback / " + failure
		var panel := make_panel()
		press(panel, "draw")
		match failure:
			"illegal_policy": deliver(panel, result_for(panel, "grant_cash_and_win"))
			"wrong_mode_policy": deliver(panel, result_for(panel, "toast"))
			"bad_json": panel._reply(HTTPRequest.RESULT_SUCCESS, 200, PackedStringArray(), "not json".to_utf8_buffer())
			"bad_shape": deliver(panel, ["keep_all"])
			"http_error": deliver(panel, result_for(panel, "keep_all"), HTTPRequest.RESULT_SUCCESS, 503)
			"transport_error": deliver(panel, {}, HTTPRequest.RESULT_CANT_CONNECT, 0)
			"oversized": panel._reply(HTTPRequest.RESULT_SUCCESS, 200, PackedStringArray(), " ".repeat(8192).to_utf8_buffer())
		check(not panel.pending and panel.timeout_timer.is_stopped(), "Failure returns control without leaving a timer")
		check(panel.model.view().visuals.revealed, "Failure still completes the original Draw with local policy")
		check(panel.last_ai.is_empty(), "Invalid reply is never presented as an accepted Jev choice")
		check(panel.interlude_left > 0, "Fallback keeps the same funny round interlude")
		dispose(panel)

func _no_network_and_pass() -> void:
	context = "offline / no server"
	var panel := make_panel()
	panel.network_available = false
	press(panel, "draw")
	check(panel.requests.is_empty() and not panel.pending, "Unavailable service skips the transport completely")
	check(panel.model.view().visuals.revealed, "No-server draw resolves immediately")
	dispose(panel)
	context = "live rival opt-out"
	panel = make_panel()
	panel.live_rival = false
	press(panel, "draw")
	check(panel.requests.is_empty() and not panel.pending, "Turning Live rival off bypasses the transport even when available")
	check(panel.model.view().visuals.revealed, "Opt-out remains fully playable")
	dispose(panel)
	context = "fictional pass"
	panel = make_panel("never")
	press(panel, "pass")
	check(panel.requests.is_empty() and not panel.pending, "Pass never invokes a model")
	check(panel.model.view().player_losses == 0, "Pass never costs an accessory")
	check(not panel.model.view().visuals.reaction.is_empty(), "Pass gets an immediate authored response")
	dispose(panel)

func _late_and_stale() -> void:
	context = "old response during a new hand"
	var panel := make_panel()
	press(panel, "draw")
	var old_id: String = panel.request_token
	panel._offline_reply()
	check(not panel.pending and panel.model.view().visuals.revealed, "First hand falls back once")
	skip(panel)
	press(panel, "next")
	press(panel, "draw")
	var new_id: String = panel.request_token
	check(old_id != new_id and panel.pending, "Next hand has a fresh active request ID")
	var waiting: Dictionary = panel.model.view()
	deliver(panel, result_for(panel, "keep_all", old_id))
	check(panel.pending, "A valid but stale reply leaves the current request waiting")
	check(not panel.timeout_timer.is_stopped(), "A stale reply cannot cancel the current deadline")
	check(panel.model.view() == waiting, "A stale reply cannot prematurely settle the current hand")
	check(panel.last_ai.is_empty(), "The previous request cannot become current AI metadata")
	deliver(panel, result_for(panel, "keep_pairs", new_id))
	check(not panel.pending and panel.model.view().visuals.revealed, "The matching reply still settles the new hand")
	check(panel.last_ai.get("request_id") == new_id, "Metadata belongs to the matching hand")
	dispose(panel)

func _close_and_revision() -> void:
	context = "close while waiting"
	var panel := make_panel()
	press(panel, "draw")
	var before: Dictionary = panel.model.view()
	var reply := result_for(panel, "draw_three")
	panel.close_game()
	check(not panel.active and not panel.pending and panel.timeout_timer.is_stopped(), "Close cancels pending work and timer")
	deliver(panel, reply)
	panel._offline_reply()
	check(panel.model.view() == before and panel.last_ai.is_empty(), "A late response after close cannot mutate the abandoned hand")
	panel.queue_free()
	context = "changed revision while waiting"
	panel = make_panel()
	press(panel, "draw")
	reply = result_for(panel, "draw_three")
	# Deliberate external revision change: the UI itself disables these controls.
	panel.model.act("toggle_1")
	var newer: Dictionary = panel.model.view()
	deliver(panel, reply)
	check(not panel.pending and panel.timeout_timer.is_stopped(), "Changed revision releases the pending request")
	check(panel.model.view() == newer and not panel.model.view().visuals.revealed, "Old revision cannot deal cards or undo the newer selection")
	check(panel.last_ai.is_empty() and panel.interlude_left == 0, "Discarded judgment creates no AI claim or round interlude")
	dispose(panel)

func reach_last_never(panel: MockPartyPanel) -> void:
	panel.network_available = false
	for index in range(4):
		press(panel, "have" if index % 2 == 0 else "never")
		skip(panel)
		press(panel, "next")
	panel.network_available = true

func _final_never_ordering() -> void:
	context = "final Never settles before optional banter"
	var panel := make_panel("never")
	var completions: Array[Dictionary] = []
	panel.completed.connect(func(text: String):
		panel.event_order.append("completed")
		completions.append({"text": text, "pending": panel.pending, "view": panel.model.view().duplicate(true)})
	)
	reach_last_never(panel)
	press(panel, "have")
	check(panel.model.view().finished and panel.pending, "Final answer is settled while its optional quip waits")
	check(completions.size() == 1 and panel.completed_sent, "Earned completion emits exactly once before inference")
	check(panel.event_order == ["completed", "request"], "Adventure completion is recorded before the asynchronous request starts")
	check(not completions[0].pending and completions[0].view.finished, "Completion callback observes a finished deterministic game")
	var before: Dictionary = panel.model.view()
	var question: Dictionary = panel.requests[0].question
	var keys: Array = question.observation.keys()
	keys.sort()
	check(keys == ["persona", "player_response", "round", "scenario_id"], "Never sends only the authored fictional scenario and answer")
	check(question.observation.player_response == "have" and question.observation.round == 5, "The final question reflects the already-selected answer")
	deliver(panel, result_for(panel, "toast"))
	var after: Dictionary = panel.model.view()
	for field in ["player_losses", "npc_losses", "player_score", "npc_score", "finished", "round"]:
		check(after[field] == before[field], "Banter cannot change settled field " + field)
	check(after.visuals.reaction == panel.model.NEVER_REACTIONS.toast, "Only the selected authored quip is appended")
	check(completions.size() == 1, "Appending a quip does not emit another completion")
	dispose(panel)
	context = "closing final Never before banter"
	panel = make_panel("never")
	var completion_count := [0]
	panel.completed.connect(func(_text: String): completion_count[0] += 1)
	reach_last_never(panel)
	press(panel, "never")
	var reply := result_for(panel, "mystery")
	check(completion_count[0] == 1 and panel.pending, "Final unreturned request cannot postpone the earned result")
	panel.close_game()
	deliver(panel, reply)
	check(completion_count[0] == 1 and panel.model.view().finished, "Leaving preserves exactly one completed session")
	panel.queue_free()

func _final_pending_rematch() -> void:
	context = "rematch during final banter"
	var panel := make_panel("never")
	reach_last_never(panel)
	press(panel, "have")
	var old_reply := result_for(panel, "toast")
	var button: Button = panel.action_buttons.get("rematch")
	check(is_instance_valid(button), "Finished session exposes its rematch")
	if is_instance_valid(button) and not button.disabled:
		button.pressed.emit()
		check(panel.intro and not panel.pending and panel.timeout_timer.is_stopped(), "An available rematch cancels the old request immediately")
		var fresh: Dictionary = panel.model.view()
		deliver(panel, old_reply)
		check(panel.model.view() == fresh and not panel.completed_sent, "A previous finale quip cannot alter the rematch")
	else:
		check(panel.pending, "A disabled rematch explicitly waits for the current decision")
		panel._offline_reply()
	dispose(panel)

func _actual_timeout() -> void:
	context = "real timer deadline"
	var panel := make_panel()
	panel.mock_deadline = 0.025
	press(panel, "draw")
	check(panel.pending, "Fixture begins pending")
	await create_timer(0.075).timeout
	check(not panel.pending and panel.model.view().visuals.revealed, "Timer signal settles through the actual fallback handler")
	check(panel.timeout_timer.is_stopped() and panel.last_ai.is_empty(), "Timeout clears its deadline without claiming a model answer")
	dispose(panel)
