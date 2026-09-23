extends SceneTree
## Deterministic, source-aware regression routes; NOT unaided model playtests.
## Actions use the public game API. Authored answers are test expectations only.
const GameState = preload("res://scripts/game_state.gd")
const BarRegulars = preload("res://scripts/bar_regulars.gd")
const SAVE_PATH := "user://bar-regulars-test.json"
const SOURCES := {"bar_rox": ["hotel", "guestbook"], "bar_bo": ["shop", "magazines"], "bar_jazz": ["alley", "busker"], "bar_red": ["street", "newsbox"]}
var assertions := 0
var failures: Array[String] = []
var context := ""
var covered_seeds: Array[int] = []
var restore_diagnostics := 0

func _init() -> void:
	_run.call_deferred()

func _check(ok: bool, message: String) -> void:
	assertions += 1
	if not ok:
		failures.append(context + ": " + message)
		printerr("FAIL: " + failures.back())

func _persistent(game) -> Dictionary:
	return {"room": game.room, "profile": game.profile.duplicate(true), "inventory": game.inventory.duplicate(), "flags": game.flags.duplicate(true), "score": game.score, "cash": game.cash, "turns": game.turns, "completed": game.completed, "journal": game.journal.duplicate(), "bar_night": game.bar_regulars.snapshot()}

func _snapshot(game) -> String:
	var data := _persistent(game)
	data["dialogue"] = game.get_dialogue_target()
	return JSON.stringify(data)

func _progress(game, id: String) -> Dictionary:
	return game.bar_regulars.snapshot().progress[id]

func _others(game, id: String) -> Dictionary:
	var result: Dictionary = game.bar_regulars.snapshot().progress
	result.erase(id)
	return result

func _go(game, destination: String) -> void:
	var paths: Array = [[game.room]]
	var visited: Array = []
	while not paths.is_empty():
		var route: Array = paths.pop_front()
		var node: String = route.back()
		if node == destination:
			for step in route.slice(1): game.travel(step)
			_check(game.room == destination, "Reached " + destination)
			return
		if visited.has(node): continue
		visited.append(node)
		for exit in game.get_room(node).exits:
			if game.is_unlocked(exit.id): paths.append(route + [exit.id])
	_check(false, "No unlocked route to " + destination)

func _offered(game, id: String, action: String) -> bool:
	var key := "bar|" + id + "|" + action
	return game.dialogue_options().any(func(option): return option.id == key)

func _choose(game, id: String, action: String) -> String:
	_check(_offered(game, id, action), "Choice offered: " + id + "/" + action)
	return game.choose_dialogue("bar|" + id + "|" + action)

func _answer(game, id: String) -> Array:
	var variant := int(game.bar_regulars.snapshot().variants[id])
	return BarRegulars.PUZZLES[id][variant].answer

func _write(data: Dictionary) -> void:
	var file := FileAccess.open(SAVE_PATH, FileAccess.WRITE)
	_check(file != null, "Temporary save opened")
	if file == null: return
	file.store_string(JSON.stringify(data))
	file.close()

func _read() -> Dictionary:
	return JSON.parse_string(FileAccess.get_file_as_string(SAVE_PATH))

func _restore_matches(loaded, expected: Dictionary) -> bool:
	var response: String = loaded.load_game(SAVE_PATH)
	if not response.contains("restored"):
		if restore_diagnostics < 3: printerr("Restore rejected: " + response)
		restore_diagnostics += 1
		return false
	var actual := _persistent(loaded)
	if JSON.stringify(actual) == JSON.stringify(expected): return true
	if restore_diagnostics < 3:
		for key in expected:
			if JSON.stringify(actual[key]) != JSON.stringify(expected[key]):
				printerr("Restore mismatch " + key + ": expected=" + JSON.stringify(expected[key]) + " actual=" + JSON.stringify(actual[key]))
	restore_diagnostics += 1
	return false

func _variant_seeds() -> Array[int]:
	context = "deterministic evening coverage"
	var result: Array[int] = []
	var coverage: Dictionary = {}
	var seating: Array[String] = []
	for id in BarRegulars.IDS: coverage[id] = []
	for seed_value in range(64):
		var cast = BarRegulars.new()
		cast.new_night(seed_value)
		var fresh: Dictionary = cast.snapshot()
		var adds_coverage := false
		for id in BarRegulars.IDS:
			if not coverage[id].has(fresh.variants[id]):
				coverage[id].append(fresh.variants[id])
				adds_coverage = true
		if adds_coverage:
			result.append(seed_value)
			var arrangement := JSON.stringify(fresh.seating)
			if not seating.has(arrangement): seating.append(arrangement)
		var repeated = BarRegulars.new()
		repeated.new_night(seed_value)
		_check(repeated.snapshot() == fresh, "Identical seed reproduces variants and seating: " + str(seed_value))
		if coverage.values().all(func(values): return values.size() == 3): break
	for id in BarRegulars.IDS:
		_check(coverage[id].size() == 3, "All three authored variants covered: " + id)
	_check(result.size() >= 3 and seating.size() > 1, "Different evenings vary puzzles and seating")
	return result

func _learn(game, id: String) -> void:
	game.interact(id, "talk")
	_check(_progress(game, id).met, "Conversation starts own story")
	_check(not _offered(game, id, "accept") and not _offered(game, id, "flirt"), "No romantic acceptance before the favor")
	_check(not game.dialogue_options().any(func(option): return str(option.id).contains("|pick_")), "No puzzle guesses offered before finding the clue")
	if id == "bar_kit":
		_choose(game, id, "clue")
	else:
		_choose(game, id, "clue")
		_check(not _progress(game, id).clue, "Asking for directions does not grant the external clue")
		_go(game, SOURCES[id][0])
		var observed: String = game.interact(SOURCES[id][1], "look")
		_check(observed.contains(game.actor_profile(id).name) and observed.contains(BarRegulars.PUZZLES[id][int(game.bar_regulars.snapshot().variants[id])].clue), "External source shows this evening's named clue")
		var notes: int = game.journal.size()
		game.interact(SOURCES[id][1], "look")
		_check(game.journal.size() == notes, "Repeated observation does not duplicate notebook clue")
		_go(game, "bar")
		game.interact(id, "talk")
	_check(_progress(game, id).clue and not _progress(game, id).solved, "Clue learned without silently solving the favor")

func _solve(game, id: String, test_wrong: bool = true) -> void:
	var answer := _answer(game, id)
	var others := _others(game, id)
	if test_wrong:
		_choose(game, id, "pick_" + str(answer[0]))
		_check(int(_progress(game, id).step) == 1 and not _progress(game, id).solved, "First correct answer only advances one stage")
		var wrong := ""
		for option in game.dialogue_options():
			var action: String = str(option.id).get_slice("|", 2)
			if action.begins_with("pick_") and action != "pick_" + str(answer[1]):
				wrong = action
				break
		_check(not wrong.is_empty(), "A recoverable wrong second-stage choice exists")
		var cash: int = game.cash
		var inventory: Array = game.inventory.duplicate()
		_choose(game, id, wrong)
		_check(int(_progress(game, id).step) == 0 and not _progress(game, id).solved and _progress(game, id).clue, "Wrong sequence resets its stage and retains the observed clue")
		_check(game.cash == cash and game.inventory == inventory and game.consume_encounter().is_empty(), "Wrong guess consumes no money, items or encounter")
	for pick in answer:
		_choose(game, id, "pick_" + str(pick))
	_check(_progress(game, id).solved and not _progress(game, id).invited and not _progress(game, id).encounter, "Favor completion does not imply invitation or sex")
	_check(_others(game, id) == others, "This puzzle never advances another patron")
	_check(game.consume_encounter().is_empty(), "Solving a favor never emits an encounter")

func _route(character: String, orientation: String, seed_value: int) -> void:
	context = character + "/" + orientation + "/seed " + str(seed_value)
	var game = GameState.new()
	game.new_game(seed_value)
	game.configure_profile(character, orientation)
	var night: Dictionary = game.bar_regulars.snapshot()
	var genders: Array[String] = []
	_go(game, "bar")
	for id in BarRegulars.IDS:
		var person: Dictionary = game.actor_profile(id)
		genders.append(person.gender)
		_check(game.is_eligible_partner(id) and person.get("adult", false), "Compatible adult cast member: " + id)
		_check(person.gender == game.player_gender() if orientation == "homosexual" else person.gender != game.player_gender() if orientation == "heterosexual" else true, "Presentation follows profile attraction: " + id)
		_check(game.get_hotspot(id).label == person.name and game.get_hotspot(id).get("seated", false), "Named seated hotspot exists: " + id)
	_check(genders.has("male") and genders.has("female") if orientation == "bisexual" else true, "Bisexual evening has both genders")
	var original_score: int = game.score
	var original_cash: int = game.cash
	var original_inventory: Array = game.inventory.duplicate()
	for id in BarRegulars.IDS:
		context = character + "/" + orientation + "/seed " + str(seed_value) + "/" + id
		var premature := _snapshot(game)
		game.choose_dialogue("bar|" + id + "|accept")
		_check(_snapshot(game) == premature, "Unoffered acceptance changes nothing")
		var others := _others(game, id)
		_learn(game, id)
		_solve(game, id)
		_check(not _offered(game, id, "accept"), "Acceptance still requires the separate flirt")
		_choose(game, id, "flirt")
		_check(_progress(game, id).invited and _offered(game, id, "decline"), "Mutual invitation offers a refusal")
		var cash_before: int = game.cash
		_choose(game, id, "decline")
		_check(not _progress(game, id).invited and not _progress(game, id).encounter and _progress(game, id).solved, "Declining preserves favor without an encounter")
		_check(game.cash == cash_before and game.consume_encounter().is_empty(), "Decline charges nothing and plays no private scene")
		_choose(game, id, "flirt")
		if id == "bar_rox":
			_check(game.dialogue_options().any(func(option): return str(option.id).ends_with("|accept") and str(option.label).contains("$20")), "Escort fee is visible before acceptance")
		var accepted: String = _choose(game, id, "accept")
		var person: Dictionary = game.actor_profile(id)
		_check(accepted.contains("got laid") and accepted.contains(person.name) and accepted.contains(game.finale_name()) and not accepted.contains("{finale}"), "Aftermath identifies optional partner and remaining finale")
		_check(_progress(game, id).encounter and not _progress(game, id).invited, "Accepted invitation resolves once")
		_check(game.cash == cash_before - (20 if id == "bar_rox" else 0), "Only the agreed escort appointment charges $20")
		_check(not game.completed and game.score == original_score and game.inventory == original_inventory, "Optional encounter never wins the main game, awards score or takes items")
		var event: Dictionary = game.consume_encounter()
		_check(event.get("partner") == id and event.get("name") == person.name and event.get("gender") == person.gender and not event.get("finale", true), "Private presentation identifies the correct optional partner")
		_check(event.get("appearance", {}).get("role") == person.role and not str(event.get("caption", "")).contains("{finale}"), "Presentation retains the patron's appearance and resolved caption")
		_check(game.consume_encounter().is_empty(), "Presentation is consumed exactly once")
		var settled := _snapshot(game)
		game.choose_dialogue("bar|" + id + "|accept")
		_check(_snapshot(game) == settled, "Stale acceptance cannot repeat payment or progress")
		game.interact(id, "talk")
		_check(not _offered(game, id, "accept") and not _offered(game, id, "flirt"), "Returning to a completed story offers no second encounter")
		_check(_others(game, id) == others, "Full story remains independent of every other patron")
	_check(game.cash == original_cash - 20 and game.score == original_score and not game.completed, "Five encounters have exactly one fee and leave the main objective open")
	_check(game.bar_regulars.snapshot().seating == night.seating and game.bar_regulars.snapshot().variants == night.variants, "Visits and actions never reroll this evening")
	_check(game.save_game(SAVE_PATH).contains("saved"), "Completed optional routes saved")
	var loaded = GameState.new()
	_check(_restore_matches(loaded, _persistent(game)), "All optional progress, identities and variants round-trip")
	_check(loaded.consume_encounter().is_empty(), "Loading never replays a private scene")

func _mid_puzzle() -> void:
	context = "independent mid-puzzle save and stale actions"
	var game = GameState.new()
	game.new_game(927)
	game.configure_profile("lisa", "bisexual")
	_go(game, "bar")
	_learn(game, "bar_bo")
	_choose(game, "bar_bo", "pick_" + str(_answer(game, "bar_bo")[0]))
	var first_progress := _progress(game, "bar_bo")
	_learn(game, "bar_kit")
	_choose(game, "bar_kit", "pick_" + str(_answer(game, "bar_kit")[0]))
	_check(_progress(game, "bar_bo") == first_progress, "Switching stories preserves another unfinished sequence")
	var active := _snapshot(game)
	game.choose_dialogue("bar|bar_bo|pick_" + str(_answer(game, "bar_bo")[1]))
	_check(_snapshot(game) == active, "A valid answer for the wrong current NPC cannot execute")
	game.save_game(SAVE_PATH)
	var saved := _read()
	_check(int(saved.get("version", 0)) == 3 and saved.has("bar_night"), "Version three persists the whole bar evening")
	var loaded = GameState.new()
	_check(_restore_matches(loaded, _persistent(game)), "Mid-sequence save preserves two independent puzzles and seating")
	_check(loaded.get_dialogue_target().is_empty() and loaded.consume_encounter().is_empty(), "Load requires a fresh conversation and no pending scene")
	loaded.interact("bar_bo", "talk")
	var answer := _answer(loaded, "bar_bo")
	_choose(loaded, "bar_bo", "pick_" + str(answer[1]))
	_check(not "\n".join(loaded.journal).contains("step 2.0"), "Resumed notebook stages remain whole-number labels")
	_choose(loaded, "bar_bo", "pick_" + str(answer[2]))
	_check(_progress(loaded, "bar_bo").solved and int(_progress(loaded, "bar_kit").step) == 1, "Saved second and third steps complete only their own puzzle")
	loaded.interact("bar_kit", "talk")
	_choose(loaded, "bar_kit", "pick_" + str(_answer(loaded, "bar_kit")[1]))
	_choose(loaded, "bar_kit", "flirt")
	_go(loaded, "street")
	var away := _snapshot(loaded)
	loaded.choose_dialogue("bar|bar_kit|accept")
	loaded.interact("bar_kit", "talk")
	_check(_snapshot(loaded) == away and loaded.consume_encounter().is_empty(), "Away-room choices and interactions cannot reach a bar patron")
	_go(loaded, "bar")
	loaded.interact("bar_kit", "talk")
	_check(_offered(loaded, "bar_kit", "accept"), "Leaving and returning preserves an unaccepted invitation")

func _empty_hand_use() -> void:
	context = "empty-hand interaction callback"
	var game = GameState.new()
	game.new_game(13)
	_go(game, "bar")
	for id in BarRegulars.IDS:
		var reply: String = game.interact(id, "use")
		_check(reply.contains(game.actor_profile(id).name) and game.get_dialogue_target() == id and _progress(game, id).met, "Empty-hand USE opens the named patron's conversation: " + id)
		_check(_offered(game, id, "clue") and not _offered(game, id, "accept"), "USE offers the same clue-first dialogue as TALK: " + id)

func _payment_boundary() -> void:
	context = "escort payment and recovery"
	var game = GameState.new()
	game.new_game(43)
	_go(game, "bar")
	_learn(game, "bar_rox")
	_solve(game, "bar_rox", false)
	_choose(game, "bar_rox", "flirt")
	# Explicit financial boundary fixture, not a model gameplay shortcut.
	game.cash = 19
	var before := _progress(game, "bar_rox")
	_choose(game, "bar_rox", "accept")
	_check(game.cash == 19 and _progress(game, "bar_rox") == before and game.consume_encounter().is_empty(), "Insufficient funds charge nothing and retain the invitation")
	_check(_offered(game, "bar_rox", "accept") and _offered(game, "bar_rox", "decline"), "Insufficient funds still allow retry or refusal")
	_choose(game, "bar_rox", "decline")
	_check(game.cash == 19 and not _progress(game, "bar_rox").encounter, "Declining after insufficient funds remains free")
	game.cash = 20
	_choose(game, "bar_rox", "flirt")
	_choose(game, "bar_rox", "accept")
	_check(game.cash == 0 and _progress(game, "bar_rox").encounter and not game.consume_encounter().is_empty(), "Exact fee can resolve the appointment once")
	game.save_game(SAVE_PATH)
	var loaded = GameState.new()
	loaded.load_game(SAVE_PATH)
	loaded.interact("bar_rox", "talk")
	var settled := _snapshot(loaded)
	loaded.choose_dialogue("bar|bar_rox|accept")
	_check(_snapshot(loaded) == settled and loaded.cash == 0 and loaded.consume_encounter().is_empty(), "Save and reload cannot charge or replay a settled appointment")

func _migration() -> void:
	context = "legacy evening migration"
	for version in [1, 2]:
		var old := {"version": version, "room": "bar", "profile": {"character": "lisa", "orientation": "homosexual"}, "inventory": ["newspaper"], "flags": {"password_known": true}, "cash": 47, "score": 8, "turns": 24, "completed": false, "journal": ["An earlier evening with unfinished business."]}
		if version == 1: old.erase("profile")
		_write(old)
		var game = GameState.new()
		_check(game.load_game(SAVE_PATH).contains("restored"), "Version " + str(version) + " is accepted")
		_check(game.room == "bar" and game.inventory == ["newspaper"] and game.flags == old.flags and game.cash == 47 and game.score == 8 and game.turns == 24 and game.journal == old.journal, "Legacy adventure progress remains intact")
		_check(game.profile == ({"character": "larry", "orientation": "bisexual"} if version == 1 else old.profile), "Legacy profile policy is preserved")
		for id in BarRegulars.IDS:
			var progress := _progress(game, id)
			_check(not progress.met and not progress.clue and int(progress.step) == 0 and not progress.solved and not progress.invited and not progress.encounter, "Legacy save starts a fresh optional story: " + id)
			_check(not game.get_hotspot(id).is_empty() and game.is_eligible_partner(id), "Migrated bar exposes a compatible patron: " + id)
		var migrated := _persistent(game)
		game.save_game(SAVE_PATH)
		var loaded = GameState.new()
		_check(_restore_matches(loaded, migrated), "Migrated evening becomes stable after its first new-format save")

func _invalid_saves() -> void:
	context = "atomic bar save validation"
	var game = GameState.new()
	game.new_game(88)
	game.configure_profile("lisa", "homosexual")
	_go(game, "bar")
	_learn(game, "bar_kit")
	_choose(game, "bar_kit", "pick_" + str(_answer(game, "bar_kit")[0]))
	game.save_game(SAVE_PATH)
	var good := _read()
	var malformed: Array[Dictionary] = []
	var bad: Dictionary = good.duplicate(true)
	bad.erase("bar_night"); malformed.append(bad)
	bad = good.duplicate(true); bad.bar_night = []; malformed.append(bad)
	bad = good.duplicate(true); bad.bar_night.seed = -1; malformed.append(bad)
	bad = good.duplicate(true); bad.bar_night.seed = 1.5; malformed.append(bad)
	bad = good.duplicate(true); bad.bar_night.seed = 2147483647; malformed.append(bad)
	bad = good.duplicate(true); bad.bar_night.seating[0] = bad.bar_night.seating[1]; malformed.append(bad)
	bad = good.duplicate(true); bad.bar_night.seating[0] = "stranger"; malformed.append(bad)
	bad = good.duplicate(true); bad.bar_night.variants.erase("bar_red"); malformed.append(bad)
	bad = good.duplicate(true); bad.bar_night.variants.bar_red = 3; malformed.append(bad)
	bad = good.duplicate(true); bad.bar_night.variants.bar_red = 0.5; malformed.append(bad)
	bad = good.duplicate(true); bad.bar_night.progress.bar_kit.met = "yes"; malformed.append(bad)
	bad = good.duplicate(true); bad.bar_night.progress.bar_kit.met = false; malformed.append(bad)
	bad = good.duplicate(true); bad.bar_night.progress.bar_kit.clue = false; malformed.append(bad)
	bad = good.duplicate(true); bad.bar_night.progress.bar_kit.step = 1.5; malformed.append(bad)
	bad = good.duplicate(true); bad.bar_night.progress.bar_kit.solved = true; malformed.append(bad)
	bad = good.duplicate(true); bad.bar_night.progress.bar_rox.invited = true; malformed.append(bad)
	bad = good.duplicate(true); bad.bar_night.progress.bar_rox.encounter = true; malformed.append(bad)
	bad = good.duplicate(true); bad.bar_night.progress.bar_kit = {"met": true, "clue": true, "step": 2, "solved": true, "invited": true, "encounter": true}; malformed.append(bad)
	for i in malformed.size():
		# A different valid profile makes partial application observable as well.
		malformed[i].profile = {"character": "larry", "orientation": "heterosexual"}
		_write(malformed[i])
		var stable := _snapshot(game)
		var label_before: String = game.get_hotspot("bar_kit").label
		var response: String = game.load_game(SAVE_PATH)
		_check(not response.contains("restored") and _snapshot(game) == stable and game.get_hotspot("bar_kit").label == label_before, "Invalid bar record " + str(i) + " rejects without changing any live evening or cast")
	game.new_game(88)
	_check(game.consume_encounter().is_empty() and not game.completed and _progress(game, "bar_kit").step == 0 and not _progress(game, "bar_kit").met, "New evening clears optional story and pending presentation")

func _run() -> void:
	covered_seeds = _variant_seeds()
	for character in ["larry", "lisa"]:
		for orientation in ["heterosexual", "homosexual", "bisexual"]:
			for seed_value in covered_seeds:
				_route(character, orientation, seed_value)
	_mid_puzzle()
	_empty_hand_use()
	_payment_boundary()
	_migration()
	_invalid_saves()
	DirAccess.remove_absolute(ProjectSettings.globalize_path(SAVE_PATH))
	print("Bar regular tests: %d assertions, %d failures; six profiles, %d seeds, all three variants per patron." % [assertions, failures.size(), covered_seeds.size()])
	quit(0 if failures.is_empty() else 1)
