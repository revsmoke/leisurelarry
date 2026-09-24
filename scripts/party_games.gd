extends RefCounted
## Free, transient party games. Rules and outcomes stay local; optional AI chooses
## an opponent's legal draw policy or a harmless authored quip, never the result.

const SUITS := ["♣", "♦", "♥", "♠"]
const RANK_NAMES := ["High card", "One pair", "Two pair", "Three of a kind", "Straight", "Flush", "Full house", "Four of a kind", "Straight flush"]
# JSON-compatible records also support the server's reviewed, closed-set content.
const NEVER_SCENARIOS := [
	{"id":"n01","text":"Never have I ever sent a love note to the wrong hotel room.","have":true,"confession":"Two honeymoon suites. One fax machine. I am still getting Christmas cards."},
	{"id":"n02","text":"Never have I ever rehearsed a pickup line in a mirror.","have":true,"confession":"The mirror asked if I came here often. It was better at this than I was."},
	{"id":"n03","text":"Never have I ever mistaken a coat check ticket for a phone number.","have":false,"confession":"No. I verify the number before I take my coat off. Professional standards."},
	{"id":"n04","text":"Never have I ever worn sunglasses indoors to seem mysterious.","have":true,"confession":"I looked mysterious right up until I flirted with the cigarette machine."},
	{"id":"n05","text":"Never have I ever dated someone because of their record collection.","have":true,"confession":"We had three glorious weeks and irreconcilable disco differences."},
	{"id":"n06","text":"Never have I ever proposed strip charades and regretted the word octopus.","have":false,"confession":"Not yet. My insurance policy specifically excludes interpretive tentacles."},
	{"id":"n07","text":"Never have I ever called a taxi just to impress a date.","have":true,"confession":"We were across the street. The meter had a more fulfilling evening than I did."},
	{"id":"n08","text":"Never have I ever left a party wearing somebody else's feather boa.","have":true,"confession":"We agreed it was a loan. The feathers disagreed and moved in."},
	{"id":"n09","text":"Never have I ever practiced a seductive entrance and hit a screen door.","have":false,"confession":"No. I use revolving doors. They give my entrances a second chance."},
	{"id":"n10","text":"Never have I ever used a hotel ice bucket as a champagne cooler.","have":true,"confession":"It was champagne in spirit. The label said sparkling grapefruit."},
	{"id":"n11","text":"Never have I ever named a dance move after my own pants.","have":true,"confession":"The Corduroy Catastrophe. It had tremendous friction and no repeat bookings."},
	{"id":"n12","text":"Never have I ever flirted while wearing a borrowed mustache.","have":false,"confession":"Never. My eyebrows already make promises I cannot keep."},
	{"id":"n13","text":"Never have I ever read a romance horoscope out loud to a willing date.","have":true,"confession":"Venus promised passion. Mercury delivered a parking ticket."},
	{"id":"n14","text":"Never have I ever confused a waterbed showroom with a singles mixer.","have":false,"confession":"No, but I admire any shop that lets you test the motion of the ocean."},
	{"id":"n15","text":"Never have I ever kept a souvenir matchbook from a very good date.","have":true,"confession":"The date is a fond memory. The matchbook has a better filing system than I do."},
	{"id":"n16","text":"Never have I ever said 'my place or yours' before checking for roommates.","have":true,"confession":"Four roommates and a parrot. The parrot was the most discreet."},
	{"id":"n17","text":"Never have I ever lost an accessory playing a suspiciously named party game.","have":true,"confession":"Strip backgammon. Thirty minutes, two cufflinks, one terrible pun."},
	{"id":"n18","text":"Never have I ever worn satin because an advertisement called it irresistible.","have":true,"confession":"The static was irresistible. So was every loose napkin in the lounge."},
	{"id":"n19","text":"Never have I ever dedicated a song to a date under the wrong name.","have":false,"confession":"Never. 'To the ravishing person in the room' covers a surprising number of emergencies."},
	{"id":"n20","text":"Never have I ever tried to look casual while waiting by a pay phone.","have":true,"confession":"Three hours. Two poses. One man asking me to move so he could call his plumber."},
	{"id":"n21","text":"Never have I ever brought a silk scarf to a picnic just for dramatic effect.","have":false,"confession":"No. The ants are pretentious enough without giving them a red carpet."},
	{"id":"n22","text":"Never have I ever suggested a slow dance to a song with a kazoo solo.","have":true,"confession":"We made it work. Romance is ninety percent commitment and ten percent earplugs."},
	{"id":"n23","text":"Never have I ever mistaken a stage curtain for the exit after a flirtation.","have":false,"confession":"Not personally. I prefer leaving people wanting more, not selling them tickets."},
	{"id":"n24","text":"Never have I ever packed a spare outfit for an optimistic first date.","have":true,"confession":"Of course. If romance fails, I can still become a completely different embarrassment."}
]
const NEVER_REACTIONS := {
	"wink":"The host winks. 'A little mystery goes beautifully with those lapels.'",
	"commiserate":"'We've all had a night when the outfit had better luck than its owner.'",
	"tease_self":"'My autobiography is mostly apologies to coat-check attendants.'",
	"toast":"The host raises a glass of soda. 'To consenting adults and questionable tailoring.'",
	"deadpan":"'Very glamorous. I'll alert the society pages. In very small print.'",
	"wardrobe":"'This town puts strip in front of everything. Even the laundromat has a waiting list.'",
	"mystery":"'An air of mystery! At last, an accessory nobody has to take off.'",
	"gracious":"'Passing is always fine, darling. Your privacy is more interesting than a forced confession.'"
}
const POKER_POLICIES := {
	"keep_all":"Stand pat: keep all five cards.",
	"keep_pairs":"Keep a made hand, or matching ranks and high kickers; replace up to three other cards.",
	"chase_flush":"Keep the most common suit and replace up to three other cards.",
	"draw_three":"Keep the two highest cards and draw three. A bold high-card gamble."
}

var _mode := ""
var _seed := 0
var _rng := RandomNumberGenerator.new()
var _revision := 0
var _round := 0
var _rounds := 0
var _stage := "closed"
var _player_score := 0
var _npc_score := 0
var _player_losses := 0
var _npc_losses := 0
var _status := ""
var _base_status := ""
var _deck: Array[int] = []
var _player_hand: Array[int] = []
var _npc_hand: Array[int] = []
var _discards: Array[int] = []
var _npc_policy := ""
var _npc_draw_count := 0
var _questions: Array[int] = []
var _player_answer := ""
var _reaction := ""
var _reaction_final := false
var _pool: Dictionary = {}

func setup(mode: String, seed_value: int = -1) -> bool:
	if not mode in ["poker", "never", "pool"]: return false
	_mode = mode
	if seed_value < 0:
		_rng.randomize()
		_seed = _rng.randi_range(0, 2147483646)
	else: _seed = seed_value % 2147483647
	_rng.seed = _seed
	_revision += 1
	_round = 1
	_rounds = 5 if mode == "never" else 3
	_player_score = 0
	_npc_score = 0
	_player_losses = 0
	_npc_losses = 0
	_questions.clear()
	for i in range(NEVER_SCENARIOS.size()): _questions.append(i)
	_shuffle(_questions)
	_begin_round()
	return true

func act(action: String) -> bool:
	var allowed := false
	for choice in _choices():
		if choice.id == action: allowed = true; break
	if not allowed: return false
	_revision += 1
	if action == "next":
		_round += 1
		_begin_round()
	elif _mode == "poker":
		if action == "draw": _draw_poker()
		else:
			var index := int(action.trim_prefix("toggle_"))
			if _discards.has(index): _discards.erase(index)
			else: _discards.append(index)
			_npc_policy = ""
			_status = "Mark up to three cards to replace, then Draw. %d of 3 marked. The other hand stays private until showdown." % _discards.size()
	elif _mode == "never": _answer_never(action)
	else:
		match action:
			"angle_minus": _pool.angle -= 5
			"angle_plus": _pool.angle += 5
			"power_minus": _pool.power -= 10
			"power_plus": _pool.power += 10
			"shoot": _shoot_pool()
	return true

func view() -> Dictionary:
	var rules := ""
	var title := ""
	var visuals: Dictionary = {}
	match _mode:
		"poker":
			title = "Strip Poker · Five-card draw"
			rules = "Three hands. Mark 0–3 cards, then Draw. Best five-card poker hand wins; ties keep both outfits intact. Losses change costume layers, ending in a courtesy robe at three. Free play; no money or quest stakes."
			var revealed := _stage == "result"
			var hidden: Array = []
			for i in range(5): hidden.append({"hidden": true})
			visuals = {"player_cards": _card_views(_player_hand, true), "npc_cards": _card_views(_npc_hand, false) if revealed else hidden, "revealed": revealed, "player_rank": evaluate_hand(_player_hand).get("name", ""), "npc_rank": evaluate_hand(_npc_hand).get("name", "") if revealed else "Private hand", "npc_draw_count": _npc_draw_count if revealed else -1}
		"never":
			title = "Strip Never · Confessions in costume"
			rules = "Five fictional prompts. Answer as your character: Have, Never, or Pass. 'Have' changes a costume layer; at three, keep the courtesy robe on. No winner, real-life disclosures or drinking required. Pass freely."
			var question := _question()
			visuals = {"statement": question.get("text", ""), "player_answer": _player_answer, "npc_answer": ("Have" if question.get("have", false) else "Never") if _stage == "result" else "", "confession": question.get("confession", "") if _stage == "result" else "", "reaction": _reaction}
		"pool":
			title = "Strip Pool · Three shots, questionable trousers"
			rules = "Three trick shots. Aim through the colored ball to the top-right pocket. One power unit rolls 10 table units. Too much follow-through scratches. A clean pot changes your rival's costume; a miss changes yours. Three changes bring a courtesy robe. No money stakes."
			visuals = _pool.duplicate(true)
	return {"mode": _mode, "revision": _revision, "title": title, "rules": rules, "status": _status, "choices": _choices(), "round": _round, "rounds": _rounds, "finished": _stage == "result" and _round >= _rounds, "player_score": _player_score, "npc_score": _npc_score, "player_losses": _player_losses, "npc_losses": _npc_losses, "visuals": visuals}

func ai_request() -> Dictionary:
	if _mode == "poker" and _stage == "play" and _npc_policy.is_empty():
		var candidates: Array = []
		for id in POKER_POLICIES: candidates.append({"id": id, "label": id.replace("_", " ").capitalize(), "description": POKER_POLICIES[id]})
		return {"mode": _mode, "revision": _revision, "kind": "poker_draw", "instructions": "Choose a legal five-card draw policy for this playful fictional opponent. Only the opponent's own cards and the player's public discard count are known. Favor a plausible poker decision; do not assume the player's hand.", "observation": {"own_cards": _npc_hand.duplicate(), "player_discard_count": _discards.size(), "round": _round, "persona": "playful_sharp"}, "candidates": candidates}
	if _mode == "never" and _stage == "result" and not _reaction_final:
		var candidates: Array = []
		for id in NEVER_REACTIONS: candidates.append({"id": id, "label": id.replace("_", " ").capitalize(), "description": NEVER_REACTIONS[id]})
		return {"mode": _mode, "revision": _revision, "kind": "never_reaction", "instructions": "Choose a warm, campy authored host reaction to a fictional party-game answer. Respect a Pass without pressure. The truthful host confession and accessory counts have already been settled by code; do not reinterpret them.", "observation": {"scenario_id": _question().id, "player_response": _player_answer, "round": _round, "persona": "party_host"}, "candidates": candidates}
	return {}

func resolve_ai(choice: String) -> bool:
	var request := ai_request()
	if request.is_empty(): return false
	var valid := false
	for candidate in request.candidates:
		if candidate.id == choice: valid = true; break
	if not valid: return false
	if _mode == "poker": _npc_policy = choice
	else:
		_reaction = NEVER_REACTIONS[choice]
		_reaction_final = true
		_status = _base_status + "\n" + _reaction
	_revision += 1
	return true

func resolve_fallback() -> bool:
	# A panel can explicitly close the optional decision after a timeout. Never
	# already displays this local quip while an online choice is still eligible.
	if _mode == "poker": return resolve_ai(_fallback_policy())
	if _mode == "never": return resolve_ai(_fallback_reaction())
	return false

func _choices() -> Array:
	if _stage == "closed": return []
	if _stage == "result": return [{"id": "next", "label": "Next hand" if _mode == "poker" else ("Next confession" if _mode == "never" else "Next shot")}] if _round < _rounds else []
	if _mode == "poker":
		var result: Array = []
		for i in range(5):
			if _discards.has(i) or _discards.size() < 3:
				result.append({"id": "toggle_" + str(i), "label": ("Keep " if _discards.has(i) else "Replace ") + card_name(_player_hand[i])})
		result.append({"id": "draw", "label": "Draw %d · Showdown" % _discards.size() if not _discards.is_empty() else "Keep all · Showdown"})
		return result
	if _mode == "never": return [{"id": "have", "label": "My character has!"}, {"id": "never", "label": "My character never has"}, {"id": "pass", "label": "Pass · No explanation needed"}]
	var result: Array = []
	if _pool.angle > 0: result.append({"id": "angle_minus", "label": "Aim −5°"})
	if _pool.angle < 60: result.append({"id": "angle_plus", "label": "Aim +5°"})
	if _pool.power > 10: result.append({"id": "power_minus", "label": "Power −10"})
	if _pool.power < 100: result.append({"id": "power_plus", "label": "Power +10"})
	result.append({"id": "shoot", "label": "Shoot · %d° / %d power" % [_pool.angle, _pool.power]})
	return result

func _begin_round() -> void:
	_stage = "play"
	_reaction = ""
	_reaction_final = false
	_player_answer = ""
	_npc_policy = ""
	_npc_draw_count = 0
	_discards.clear()
	match _mode:
		"poker":
			_deck.clear()
			for i in range(52): _deck.append(i)
			_shuffle(_deck)
			_player_hand.clear()
			_npc_hand.clear()
			for i in range(5):
				_player_hand.append(_deck.pop_back())
				_npc_hand.append(_deck.pop_back())
			_status = "Mark up to three cards to replace, then Draw. Poker face optional; outfit enthusiasm mandatory."
		"never": _status = _question().text + "\nThis is your character's invented history. You can always Pass."
		"pool": _make_pool()

func _draw_poker() -> void:
	var policy := _npc_policy if not _npc_policy.is_empty() else _fallback_policy()
	var npc_discard := _policy_discards(policy)
	for index in _discards: _player_hand[index] = _deck.pop_back()
	for index in npc_discard: _npc_hand[index] = _deck.pop_back()
	_npc_draw_count = npc_discard.size()
	var comparison := compare_hands(_player_hand, _npc_hand)
	var yours: String = evaluate_hand(_player_hand).name
	var theirs: String = evaluate_hand(_npc_hand).name
	_status = "You: %s. Your rival: %s (drew %d). " % [yours, theirs, _npc_draw_count]
	if comparison > 0:
		_player_score += 1
		_status += "You win! " + _costume_change("Your rival", _npc_losses)
		_npc_losses += 1
	elif comparison < 0:
		_npc_score += 1
		_status += "Your rival wins. " + _costume_change("You", _player_losses)
		_player_losses += 1
	else: _status += "A tie! Both outfits survive. The tailor breathes again."
	_status += " " + ["The only thing stacked here is the laundry.", "Your poker face could use a zipper.", "All in? Those lapels have been all out since 1978."][_round - 1]
	_settled()

func _fallback_policy() -> String:
	var rank := int(evaluate_hand(_npc_hand).category)
	if rank >= 4: return "keep_all"
	if rank > 0: return "keep_pairs"
	var suits := [0, 0, 0, 0]
	for card in _npc_hand: suits[int(card / 13)] += 1
	if suits.max() >= 4: return "chase_flush"
	return "draw_three"

func _policy_discards(policy: String) -> Array[int]:
	var discard: Array[int] = []
	if policy == "keep_all": return discard
	var ranks: Dictionary = {}
	var suits := [0, 0, 0, 0]
	for card in _npc_hand:
		var rank := card % 13 + 2
		ranks[rank] = int(ranks.get(rank, 0)) + 1
		suits[int(card / 13)] += 1
	var indices: Array[int] = [0, 1, 2, 3, 4]
	indices.sort_custom(func(a, b): return _npc_hand[a] % 13 < _npc_hand[b] % 13)
	if policy == "keep_pairs":
		if int(evaluate_hand(_npc_hand).category) >= 4: return discard
		for index in indices:
			if ranks[_npc_hand[index] % 13 + 2] == 1 and discard.size() < 3: discard.append(index)
	elif policy == "chase_flush":
		var suit: int = suits.find(suits.max())
		for index in indices:
			if int(_npc_hand[index] / 13) != suit and discard.size() < 3: discard.append(index)
	else:
		for index in indices.slice(0, 3): discard.append(index)
	return discard

func _question() -> Dictionary:
	return NEVER_SCENARIOS[_questions[_round - 1]] if not _questions.is_empty() and _round >= 1 else {}

func _answer_never(answer: String) -> void:
	_player_answer = answer
	var question := _question()
	_status = ""
	if answer == "have":
		_status = "Your character claims it with a grin. " + _costume_change("You", _player_losses) + " "
		_player_losses += 1
		_player_score += 1
	elif answer == "never": _status = "'Never,' says your character. An entirely respectable plot twist. "
	else: _status = "You pass. No explanation, accessory or apology required. "
	_status += "The host says '%s.' %s" % ["I have" if question.have else "Never", question.confession]
	if question.have:
		_status += " " + _costume_change("The host", _npc_losses)
		_npc_losses += 1
		_npc_score += 1
	_settled()
	_base_status = _status
	_reaction = NEVER_REACTIONS[_fallback_reaction()]
	_status = _base_status + "\n" + _reaction
	# Passing is a completed decision and never invites an online judgment.
	_reaction_final = answer == "pass"

func _fallback_reaction() -> String:
	if _player_answer == "pass": return "gracious"
	if _player_answer == "have" and _question().get("have", false): return "commiserate"
	if _player_answer == "never": return "mystery"
	return ["wink", "tease_self", "toast", "deadpan", "wardrobe"][(_seed + _round) % 5]

static func _costume_change(subject: String, losses_before: int) -> String:
	var suffix := "" if subject == "You" else "s"
	match losses_before:
		0: return "%s retire%s a costume layer; two stages to the courtesy robe." % [subject, suffix]
		1: return "%s retire%s another outer layer; the courtesy robe is next." % [subject, suffix]
		2: return "%s make%s a grand entrance in the courtesy robe." % [subject, suffix]
	return "%s keep%s the courtesy robe firmly in place. Only the confession count changes." % [subject, suffix]

func _make_pool() -> void:
	var angle := _rng.randi_range(2, 6) * 5
	var power := _rng.randi_range(6, 8) * 10
	var direction := Vector2(cos(deg_to_rad(angle)), -sin(deg_to_rad(angle)))
	var pocket := Vector2(940, 50)
	var cue := pocket - direction * float(power * 10)
	var object := pocket - direction * float(_rng.randi_range(16, 22) * 10)
	_pool = {"cue": _point(cue), "object": _point(object), "pocket": _point(pocket), "angle": clampi(angle + (10 if _rng.randi_range(0, 1) == 0 else -10), 0, 60), "power": 40, "target_angle": angle, "target_power": power, "path": [], "object_path": [], "shot": false, "success": false, "scratch": false, "distance": power * 10, "table_units": [1000, 500]}
	_status = "Shot %d: the pocket is %d table units away. Aim through the colored ball; use enough power to reach it without more than 100 units of follow-through. A straight shot, like a pickup line, needs the right delivery." % [_round, power * 10]

func _shoot_pool() -> void:
	var cue := _from_point(_pool.cue)
	var object := _from_point(_pool.object)
	var pocket := _from_point(_pool.pocket)
	var direction := Vector2(cos(deg_to_rad(_pool.angle)), -sin(deg_to_rad(_pool.angle)))
	var travel := float(_pool.power * 10)
	var forward := (object - cue).dot(direction)
	var nearest := cue + direction * maxf(0.0, forward)
	var contact := forward > 0.0 and travel >= forward and nearest.distance_to(object) <= 17.0
	var angle_error := absf(float(_pool.angle - _pool.target_angle))
	var enough := travel >= float(_pool.distance) - 8.0
	var scratch := contact and angle_error < 1.0 and travel > float(_pool.distance) + 100.0
	var success := contact and angle_error < 1.0 and enough and not scratch
	_pool.shot = true
	_pool.success = success
	_pool.scratch = scratch
	_pool.path = [_pool.cue, _point(nearest if contact else _table_clip(cue, direction, travel))]
	_pool.object_path = []
	if contact:
		var object_direction := (pocket - object).normalized() if angle_error < 1.0 else (object - nearest).normalized()
		if object_direction.length() < 0.1: object_direction = direction
		var object_travel := maxf(0.0, travel - forward)
		_pool.object_path = [_pool.object, _point(pocket if enough and angle_error < 1.0 else _table_clip(object, object_direction, object_travel))]
	if scratch: _pool.path.append(_pool.pocket)
	if success:
		_player_score += 1
		_status = "Clean pot! " + _costume_change("Your rival", _npc_losses) + " 'Nice cue control. I'm trying very hard to behave.'"
		_npc_losses += 1
	else:
		_npc_score += 1
		var why := "Too much follow-through: the white ball follows into the pocket. Scratch!" if scratch else ("The aim misses the potting line." if not contact or angle_error >= 1.0 else "Right line, not enough power: the colored ball stops short.")
		_status = why + " " + _costume_change("You", _player_losses)
		_player_losses += 1
	_status += " The clean line was %d° at %d–%d power." % [_pool.target_angle, _pool.target_power, mini(100, _pool.target_power + 10)]
	_settled()

func _settled() -> void:
	_stage = "result"
	if _round >= _rounds:
		_status += "\n" + ("Five fictional confessions, no winners or losers. Your original outfits wait by the exit; keep the stories." if _mode == "never" else "Session complete: %d–%d. Your original outfits wait by the exit. The flirting is complimentary." % [_player_score, _npc_score])

func _shuffle(values: Array[int]) -> void:
	for i in range(values.size() - 1, 0, -1):
		var j := _rng.randi_range(0, i)
		var value: int = values[i]
		values[i] = values[j]
		values[j] = value

func _card_views(hand: Array[int], player: bool) -> Array:
	var result: Array = []
	for i in range(hand.size()):
		var card := hand[i]
		result.append({"id": card, "rank": card % 13 + 2, "suit": int(card / 13), "label": card_name(card), "red": int(card / 13) in [1, 2], "discard": player and _stage == "play" and _discards.has(i)})
	return result

static func _point(point: Vector2) -> Array:
	return [point.x / 1000.0, point.y / 500.0]

static func _from_point(point: Array) -> Vector2:
	return Vector2(float(point[0]) * 1000.0, float(point[1]) * 500.0)

static func _table_clip(origin: Vector2, direction: Vector2, distance: float) -> Vector2:
	var result := origin + direction * distance
	# Clip the ray at its first cushion rather than independently clamping axes.
	var fraction := 1.0
	if result.x < 35.0: fraction = minf(fraction, (35.0 - origin.x) / (result.x - origin.x))
	if result.x > 965.0: fraction = minf(fraction, (965.0 - origin.x) / (result.x - origin.x))
	if result.y < 35.0: fraction = minf(fraction, (35.0 - origin.y) / (result.y - origin.y))
	if result.y > 465.0: fraction = minf(fraction, (465.0 - origin.y) / (result.y - origin.y))
	return origin.lerp(result, clampf(fraction, 0.0, 1.0))

static func card_name(card: int) -> String:
	if card < 0 or card >= 52: return "?"
	var rank := card % 13 + 2
	var label: String = {11: "J", 12: "Q", 13: "K", 14: "A"}.get(rank, str(rank))
	return label + SUITS[int(card / 13)]

static func evaluate_hand(cards: Array) -> Dictionary:
	if cards.size() != 5: return {}
	var seen: Dictionary = {}
	var counts: Dictionary = {}
	var ranks: Array[int] = []
	var suits: Array[int] = []
	for card in cards:
		if not card is int or card < 0 or card >= 52 or seen.has(card): return {}
		seen[card] = true
		var rank: int = card % 13 + 2
		counts[rank] = int(counts.get(rank, 0)) + 1
		ranks.append(rank)
		suits.append(int(card / 13))
	ranks.sort()
	ranks.reverse()
	var flush := suits.all(func(suit): return suit == suits[0])
	var straight_high := 0
	if counts.size() == 5:
		if ranks[0] - ranks[4] == 4: straight_high = ranks[0]
		elif ranks == [14, 5, 4, 3, 2]: straight_high = 5
	var groups: Array = []
	for rank in counts: groups.append([counts[rank], rank])
	groups.sort_custom(func(a, b): return a[0] > b[0] if a[0] != b[0] else a[1] > b[1])
	var category := 0
	var tiebreak: Array = []
	if straight_high > 0 and flush: category = 8; tiebreak = [straight_high]
	elif groups[0][0] == 4: category = 7; tiebreak = [groups[0][1], groups[1][1]]
	elif groups[0][0] == 3 and groups[1][0] == 2: category = 6; tiebreak = [groups[0][1], groups[1][1]]
	elif flush: category = 5; tiebreak = ranks.duplicate()
	elif straight_high > 0: category = 4; tiebreak = [straight_high]
	elif groups[0][0] == 3: category = 3
	elif groups[0][0] == 2 and groups[1][0] == 2: category = 2
	elif groups[0][0] == 2: category = 1
	if tiebreak.is_empty():
		for group in groups: tiebreak.append(group[1])
	return {"category": category, "name": RANK_NAMES[category], "tiebreak": tiebreak}

static func compare_hands(first: Array, second: Array) -> int:
	var a := evaluate_hand(first)
	var b := evaluate_hand(second)
	if a.is_empty() or b.is_empty(): return 0
	if a.category != b.category: return 1 if a.category > b.category else -1
	for index in range(a.tiebreak.size()):
		if a.tiebreak[index] != b.tiebreak[index]: return 1 if a.tiebreak[index] > b.tiebreak[index] else -1
	return 0
