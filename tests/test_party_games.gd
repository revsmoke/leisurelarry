extends SceneTree
## Rule and lifecycle tests, not a claim about blind-player enjoyment.
const PartyGames = preload("res://scripts/party_games.gd")
var assertions := 0
var failures: Array[String] = []

func _init() -> void:
	_run.call_deferred()

func _check(ok: bool, message: String) -> void:
	assertions += 1
	if not ok:
		failures.append(message)
		printerr("FAIL: " + message)

func _card(rank: int, suit: int = 0) -> int:
	return suit * 13 + rank - 2

func _hand(ranks: Array, suits: Array = [0, 1, 2, 3, 0]) -> Array:
	var result: Array = []
	for i in range(5): result.append(_card(ranks[i], suits[i]))
	return result

func _snapshot(game) -> String:
	return JSON.stringify({"view": game.view(), "request": game.ai_request()})

func _rankings() -> void:
	var hands: Array = [
		_hand([14, 11, 9, 5, 3]),
		_hand([4, 4, 14, 9, 2]),
		_hand([4, 4, 9, 9, 2]),
		_hand([4, 4, 4, 9, 2]),
		_hand([6, 7, 8, 9, 10]),
		_hand([2, 5, 7, 11, 14], [2, 2, 2, 2, 2]),
		_hand([4, 4, 4, 9, 9]),
		_hand([4, 4, 4, 4, 9]),
		_hand([10, 11, 12, 13, 14], [3, 3, 3, 3, 3])
	]
	for category in range(hands.size()):
		var rank: Dictionary = PartyGames.evaluate_hand(hands[category])
		_check(rank.category == category, "Correct five-card category " + str(category))
		_check(rank.name == PartyGames.RANK_NAMES[category], "Category name matches actual ranking")
		var reverse: Array = hands[category].duplicate()
		reverse.reverse()
		_check(PartyGames.evaluate_hand(reverse) == rank, "Card order does not change a hand")
		for other in range(hands.size()):
			var expected := 0 if category == other else (1 if category > other else -1)
			_check(PartyGames.compare_hands(hands[category], hands[other]) == expected, "Full category ordering %d / %d" % [category, other])
	var wheel := _hand([14, 2, 3, 4, 5])
	_check(PartyGames.evaluate_hand(wheel).tiebreak == [5], "Ace-low straight counts as five-high")
	_check(PartyGames.compare_hands(wheel, _hand([2, 3, 4, 5, 6])) == -1, "Six-high beats the wheel")
	_check(PartyGames.evaluate_hand(_hand([12, 13, 14, 2, 3])).category == 0, "Straight cannot wrap from king/ace to two")
	_check(PartyGames.compare_hands(_hand([9, 9, 14, 11, 3]), _hand([9, 9, 14, 10, 8])) == 1, "Pair tied through ace uses second kicker")
	_check(PartyGames.compare_hands(_hand([10, 10, 3, 3, 14]), _hand([9, 9, 8, 8, 14])) == 1, "Two pair compares high pair first")
	_check(PartyGames.compare_hands(_hand([10, 10, 4, 4, 2]), _hand([10, 10, 3, 3, 14])) == 1, "Two pair compares lower pair before kicker")
	_check(PartyGames.compare_hands(_hand([10, 10, 4, 4, 14]), _hand([10, 10, 4, 4, 13])) == 1, "Two pair uses final kicker")
	_check(PartyGames.compare_hands(_hand([8, 8, 8, 14, 2]), _hand([8, 8, 8, 13, 12])) == 1, "Trips compare first kicker")
	_check(PartyGames.compare_hands(_hand([8, 8, 8, 2, 2]), _hand([7, 7, 7, 14, 14])) == 1, "Full house prioritizes triplet")
	_check(PartyGames.compare_hands(_hand([8, 8, 8, 2, 2]), _hand([8, 8, 8, 3, 3])) == -1, "Full house uses pair for tie")
	_check(PartyGames.compare_hands(_hand([8, 8, 8, 8, 14]), _hand([8, 8, 8, 8, 13])) == 1, "Four of a kind compares kicker")
	_check(PartyGames.compare_hands(_hand([14, 11, 9, 5, 3], [0, 0, 0, 0, 0]), _hand([14, 11, 9, 5, 2], [2, 2, 2, 2, 2])) == 1, "Flush compares all five cards")
	_check(PartyGames.compare_hands(_hand([14, 11, 9, 5, 3]), _hand([14, 11, 9, 5, 3], [1, 2, 3, 0, 1])) == 0, "Suits never break poker ties")
	for invalid in [[], [0, 1, 2, 3], [0, 1, 2, 3, 52], [0, 1, 2, 3, -1], [0, 1, 2, 3, 3], [0, 1, 2, 3, 4.0], [0, 1, 2, 3, "4"]]:
		_check(PartyGames.evaluate_hand(invalid).is_empty(), "Malformed or duplicate cards rejected")
	_check(PartyGames.card_name(0) == "2♣" and PartyGames.card_name(51) == "A♠", "Card identity maps all ranks and suits")
	_check(PartyGames.card_name(-1) == "?" and PartyGames.card_name(52) == "?", "Invalid card name is bounded")

func _poker() -> void:
	var first_hands: Dictionary = {}
	var outcomes: Dictionary = {}
	for seed_value in range(72):
		var game = PartyGames.new()
		var repeat = PartyGames.new()
		_check(game.setup("poker", seed_value), "Poker starts with a seed")
		repeat.setup("poker", seed_value)
		_check(_snapshot(game) == _snapshot(repeat), "Identical seeds reproduce dealt cards and available actions")
		first_hands[JSON.stringify(game.view().visuals.player_cards)] = true
		for round_index in range(3):
			var view: Dictionary = game.view()
			_check(view.round == round_index + 1 and not view.finished, "Poker advances finite three-hand sequence")
			_check(view.visuals.npc_cards.all(func(card): return card == {"hidden": true}), "NPC hand is entirely hidden before showdown")
			var request: Dictionary = game.ai_request()
			_check(request.observation.keys() == ["own_cards", "player_discard_count", "round", "persona"], "AI gets own cards and public context only")
			var visible_ids: Array = []
			for card in view.visuals.player_cards: visible_ids.append(card.id)
			var all_cards: Array = visible_ids + request.observation.own_cards
			var unique: Dictionary = {}
			for card in all_cards: unique[card] = true
			_check(all_cards.size() == 10 and unique.size() == 10, "Deal contains ten unique real cards")
			var before := _snapshot(game)
			_check(not game.act("toggle_7") and not game.act("have") and not game.act("next"), "Unlisted poker actions cannot run")
			_check(not game.resolve_ai("invent_a_win") and _snapshot(game) == before, "Invalid AI choice leaves all state unchanged")
			for i in range(3): _check(game.act("toggle_" + str(i)), "Can mark card for draw")
			_check(not game.act("toggle_3"), "Fourth discard forbidden")
			_check(game.view().visuals.player_cards[0].discard, "Visual marks selected discard")
			_check(game.act("toggle_0") and game.act("toggle_3"), "Can unmark and replace a different card")
			request = game.ai_request()
			_check(request.observation.player_discard_count == 3, "AI sees exact public draw count")
			if seed_value % 2 == 0:
				var policy: String = PartyGames.POKER_POLICIES.keys()[(seed_value / 2 + round_index) % 4]
				_check(game.resolve_ai(policy), "Each closed-set strategy can be selected")
				_check(game.ai_request().is_empty() and not game.resolve_ai(policy), "One AI result per current decision")
			_check(game.act("draw"), "Draw works with AI or immediate offline fallback")
			view = game.view()
			_check(view.visuals.revealed and view.visuals.npc_cards.size() == 5, "Showdown reveals exactly five opponent cards")
			_check(view.visuals.npc_draw_count >= 0 and view.visuals.npc_draw_count <= 3, "Opponent can never redraw more than three")
			unique.clear()
			for card in view.visuals.player_cards + view.visuals.npc_cards: unique[card.id] = true
			_check(unique.size() == 10, "No duplicate cards after both draws")
			_check(view.visuals.player_cards[0].id == visible_ids[0] and view.visuals.player_cards[4].id == visible_ids[4], "Unselected cards stay held")
			_check(not visible_ids.has(view.visuals.player_cards[1].id), "Discarded card replaced from remaining deck")
			_check(view.player_score == view.npc_losses and view.npc_score == view.player_losses, "Accessory loss belongs only to losing side")
			_check(view.player_score + view.npc_score <= round_index + 1, "At most one winner per hand")
			outcomes[str(view.player_score) + ":" + str(view.npc_score)] = true
			before = _snapshot(game)
			_check(not game.act("draw") and not game.resolve_ai("keep_all") and _snapshot(game) == before, "Repeated settlement and late AI cannot score again")
			if round_index < 2: _check(game.act("next"), "Next hand begins only after result")
			else:
				_check(view.finished and view.choices.is_empty(), "Poker session finishes after three settled hands")
				_check(not game.act("next"), "No fourth hand smuggled into a session")
	_check(first_hands.size() > 60, "Different seeds create varied card hands")
	_check(outcomes.size() >= 6, "Shuffled honest hands produce different outcomes")
	var game = PartyGames.new()
	game.setup("poker", 93)
	game.resolve_ai("keep_all")
	_check(game.act("toggle_0") and not game.ai_request().is_empty(), "Changing public discards invalidates a previously selected policy")
	var exposed: Dictionary = game.view()
	exposed.visuals.player_cards[0].id = 99
	exposed.choices.clear()
	_check(game.view().visuals.player_cards[0].id != 99 and not game.view().choices.is_empty(), "Returned UI values cannot mutate model rules/cards")

func _never() -> void:
	var seen_questions: Dictionary = {}
	var have_questions := 0
	var never_questions := 0
	for seed_value in range(48):
		var game = PartyGames.new()
		game.setup("never", seed_value)
		var used: Dictionary = {}
		for round_index in range(5):
			var initial: Dictionary = game.view()
			var statement: String = initial.visuals.statement
			_check(not used.has(statement), "Never prompts do not repeat in a session")
			used[statement] = true
			seen_questions[statement] = true
			_check(initial.visuals.npc_answer.is_empty() and initial.visuals.confession.is_empty(), "Host does not expose answer before player's choice")
			_check(game.ai_request().is_empty(), "No semantic question without the player's fictional answer")
			var answer: String = ["have", "never", "pass"][(seed_value + round_index) % 3]
			_check(game.act(answer), "Each fictional-answer choice works")
			var result: Dictionary = game.view()
			_check(result.player_losses == initial.player_losses + (1 if answer == "have" else 0), "Have loses one accessory; Never and Pass lose none")
			var truth: bool = result.visuals.npc_answer == "Have"
			_check(result.npc_losses == initial.npc_losses + (1 if truth else 0), "Host's authored history determines only host accessories")
			if truth: have_questions += 1
			else: never_questions += 1
			var request: Dictionary = game.ai_request()
			if answer == "pass":
				_check(request.is_empty() and result.status.contains("Passing is always fine"), "Pass gets immediate respectful offline reply without a request")
			else:
				_check(request.observation.keys() == ["scenario_id", "player_response", "round", "persona"], "Never AI input is authored IDs, not private disclosure or free text")
				_check(request.candidates.size() == 8, "Eight bounded authored reaction choices")
				var reaction: String = PartyGames.NEVER_REACTIONS.keys()[(seed_value + round_index) % 8]
				_check(game.resolve_ai(reaction), "Authored reaction can be selected")
				var reacted: Dictionary = game.view()
				_check(reacted.player_losses == result.player_losses and reacted.npc_losses == result.npc_losses and reacted.player_score == result.player_score and reacted.npc_score == result.npc_score, "AI reaction cannot rewrite truth, scores, or accessories")
				_check(reacted.visuals.npc_answer == result.visuals.npc_answer and reacted.visuals.confession == result.visuals.confession, "AI reaction leaves established fictional facts intact")
				_check(not game.resolve_ai(reaction), "Duplicate Never AI result ignored")
			var before := _snapshot(game)
			_check(not game.act("have") and not game.act("pass") and _snapshot(game) == before, "An answered round cannot lose accessories twice")
			if round_index < 4: _check(game.act("next"), "Next fictional prompt begins after answer")
			else: _check(game.view().finished and not game.act("next"), "Never finishes at exactly five prompts")
	_check(seen_questions.size() == 24 and have_questions > 0 and never_questions > 0, "Seeds cover all24 varied questions with both truthful host answers")
	var offline = PartyGames.new()
	offline.setup("never", 99)
	for round_index in range(5):
		_check(offline.act("never"), "Never works fully offline without selecting a reaction")
		if round_index < 4: offline.act("next")
	_check(offline.view().finished, "No network wait blocks offline session completion")

func _aim(game, angle: int, power: int) -> void:
	var guard := 0
	while game.view().visuals.angle != angle and guard < 30:
		game.act("angle_plus" if game.view().visuals.angle < angle else "angle_minus")
		guard += 1
	while game.view().visuals.power != power and guard < 50:
		game.act("power_plus" if game.view().visuals.power < power else "power_minus")
		guard += 1
	_check(guard < 50, "Aim and power reachable through real legal controls")

func _pool() -> void:
	var tables: Dictionary = {}
	for seed_value in range(36):
		var game = PartyGames.new()
		game.setup("pool", seed_value)
		var twin = PartyGames.new()
		twin.setup("pool", seed_value)
		_check(game.view() == twin.view(), "Pool geometry is seeded and reproducible")
		for round_index in range(3):
			var initial: Dictionary = game.view()
			var table: Dictionary = initial.visuals
			tables[JSON.stringify([table.cue, table.object, table.pocket])] = true
			for point in [table.cue, table.object, table.pocket]:
				_check(point[0] > 0 and point[0] < 1 and point[1] > 0 and point[1] < 1, "Pool objects remain inside visible table")
			_check(game.ai_request().is_empty() and not game.resolve_ai("keep_all"), "Pool has no AI/random success shortcut")
			var condition := (seed_value + round_index) % 4
			var angle: int = table.target_angle
			var power: int = table.target_power
			if condition == 1: angle += 10
			elif condition == 2: power -= 20
			elif condition == 3: power += 20
			_aim(game, angle, power)
			_check(game.act("shoot"), "Shoot settles only after chosen angle/power")
			var result: Dictionary = game.view()
			_check(result.visuals.success == (condition == 0), "Only the physically correct angle and power produces clean pot")
			_check(result.visuals.scratch == (condition == 3), "Excess follow-through specifically scratches")
			_check(result.player_score == initial.player_score + (1 if condition == 0 else 0), "Clean pot increments player score once")
			_check(result.npc_score == initial.npc_score + (0 if condition == 0 else 1), "Miss increments opponent score once")
			_check(result.visuals.path.size() >= 2, "Animation has a cue-ball path")
			for point in result.visuals.path + result.visuals.object_path:
				_check(point[0] >= 0 and point[0] <= 1 and point[1] >= 0 and point[1] <= 1, "Animated shot coordinates stay on table")
			var before := _snapshot(game)
			_check(not game.act("shoot") and not game.act("angle_plus") and not game.act("power_plus") and _snapshot(game) == before, "Settled shot cannot change geometry or pay twice")
			if round_index < 2: _check(game.act("next"), "Next shot sets a new readable layout")
			else: _check(result.finished and not game.act("next"), "Pool finishes after three shots")
	_check(tables.size() > 30, "Different evenings and rounds vary geometry")
	var game = PartyGames.new()
	game.setup("pool", 13)
	_aim(game, 0, 10)
	_check(not game.act("angle_minus") and not game.act("power_minus"), "Aim/power cannot fall below their legal bounds")
	_aim(game, 60, 100)
	_check(not game.act("angle_plus") and not game.act("power_plus"), "Aim/power cannot exceed legal bounds")
	var good = PartyGames.new()
	good.setup("pool", 13)
	for round_index in range(3):
		var table: Dictionary = good.view().visuals
		_aim(good, table.target_angle, table.target_power + 10)
		good.act("shoot")
		_check(good.view().visuals.success, "Visible power tolerance includes +10 margin")
		if round_index < 2: good.act("next")
	_check(good.view().player_score == 3 and good.view().npc_losses == 3, "Three skillful shots win without randomness")

func _lifecycle() -> void:
	var game = PartyGames.new()
	_check(not game.act("draw") and not game.resolve_ai("keep_all"), "Uninitialized session refuses all moves")
	_check(not game.setup("strip_lottery", 4), "Unknown game does not silently select a default")
	for mode in ["poker", "never", "pool"]:
		game.setup(mode, 4)
		var before := _snapshot(game)
		_check(not game.setup("garbage", 7) and _snapshot(game) == before, "Invalid setup preserves existing session")
		var revision: int = game.view().revision
		game.setup(mode, 4)
		_check(game.view().revision > revision and game.view().round == 1 and game.view().player_losses == 0 and game.view().npc_losses == 0, "Reusing a session clears all previous scores and advances freshness")
		_check(not game.view().has("cash") and not game.view().has("quest_flags"), "Party model exposes no adventure money or quest mutators")
		var roundtrip = JSON.parse_string(JSON.stringify(game.view()))
		_check(roundtrip is Dictionary and roundtrip.mode == mode, "UI observation is JSON serializable")

func _costumes_and_fallback() -> void:
	var game = PartyGames.new()
	game.setup("never", 5)
	for round_index in range(5):
		_check(game.act("have"), "Fictional admission accepted through all five rounds")
		var before: Dictionary = game.view()
		_check(not before.visuals.reaction.is_empty(), "Offline authored reaction is immediately visible")
		_check(not game.ai_request().is_empty(), "Local quip preserves optional network decision window")
		if round_index == 2:
			_check(before.status.contains("You make a grand entrance in the courtesy robe"), "Third admission introduces the player's courtesy robe")
		if round_index >= 3:
			_check(before.status.contains("You keep the courtesy robe firmly in place"), "Fourth and fifth admissions remove no further costume layers")
		_check(game.resolve_fallback(), "Panel can explicitly close an offline decision")
		_check(game.ai_request().is_empty(), "Explicit fallback closes the network decision window")
		_check(game.view().player_losses == before.player_losses and game.view().npc_losses == before.npc_losses, "Fallback cannot reapply costume consequences")
		_check(not game.resolve_ai("wink"), "Late AI reply after explicit fallback is rejected")
		if round_index < 4: game.act("next")
	var reply = PartyGames.new()
	reply.setup("never", 8)
	reply.act("never")
	_check(reply.resolve_ai("toast"), "A timely live quip can override the immediate local quip")
	_check(reply.view().visuals.reaction == PartyGames.NEVER_REACTIONS.toast, "Selected live authored quip becomes visible")
	_check(reply.view().player_losses == 0, "Live quip does not rewrite fictional answer consequences")
	var poker = PartyGames.new()
	poker.setup("poker", 7)
	_check(poker.resolve_fallback(), "Explicit poker fallback selects a policy from the opponent's own hand")
	_check(poker.act("draw"), "Draw proceeds after explicit local fallback")

func _run() -> void:
	_rankings()
	_poker()
	_never()
	_pool()
	_lifecycle()
	_costumes_and_fallback()
	print("Party game tests: %d assertions, %d failures; 72 poker seeds, 48 Never seeds, 36 pool seeds." % [assertions, failures.size()])
	quit(0 if failures.is_empty() else 1)
