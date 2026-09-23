extends SceneTree
## Public-action routes verify six identities, clue-gated invitations, and save migration.
const GameState = preload("res://scripts/game_state.gd")
var assertions := 0
var failures: Array[String] = []
var context := ""

func _init() -> void:
	_run.call_deferred()

func _check(ok: bool, message: String) -> void:
	assertions += 1
	if not ok:
		failures.append(context + ": " + message)
		printerr("FAIL: " + failures.back())

func _snapshot(game) -> String:
	return JSON.stringify({"room": game.room, "profile": game.profile, "inventory": game.inventory, "flags": game.flags, "score": game.score, "cash": game.cash, "turns": game.turns, "completed": game.completed, "journal": game.journal})

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
	_check(false, "No route to " + destination)

func _choose(game, id: String) -> String:
	_check(game.dialogue_options().any(func(option): return option.id == id), "Choice offered " + id)
	return game.choose_dialogue(id)

func _date(game, id: String) -> void:
	_go(game, GameState.DATE_ROOMS[id])
	var original_score: int = game.score
	var original_cash: int = game.cash
	var original_items: Array = game.inventory.duplicate()
	var person: Dictionary = game.actor_profile(id)
	_check(game.get_hotspot(id).label.begins_with(person.name), "Visible guest label matches profile")
	var premature := _snapshot(game)
	game.choose_dialogue("date_accept_" + id)
	_check(_snapshot(game) == premature and game.consume_encounter().is_empty(), "Cannot accept unoffered invitation")
	_check(game.command("talk " + person.name).contains(person.name), "Parser resolves displayed guest name")
	_check(not game.dialogue_options().any(func(option): return option.id == "date_accept_" + id), "No accept choice before puzzle or flirt")
	_choose(game, "date_solve_" + id)
	_check(not game.flags.get("date_solved_" + id, false), "Correct guess requires observed clue")
	_choose(game, "date_wrong_" + id)
	_check(not game.flags.get("date_solved_" + id, false), "Wrong answer remains retryable")
	game.interact(GameState.DATE_CLUES[id], "look")
	var notes: int = game.journal.size()
	game.interact(GameState.DATE_CLUES[id], "look")
	_check(game.journal.size() == notes, "Clue journal entry deduplicates")
	game.interact(id, "talk")
	_choose(game, "date_solve_" + id)
	_check(game.flags.get("date_solved_" + id, false) and game.consume_encounter().is_empty(), "Puzzle completion does not imply a fling")
	_choose(game, "date_flirt_" + id)
	_choose(game, "date_decline_" + id)
	_check(not game.flags.get("encounter_" + id, false) and game.consume_encounter().is_empty(), "Decline causes no encounter or penalty")
	_choose(game, "date_flirt_" + id)
	var acceptance: String = _choose(game, "date_accept_" + id)
	_check(acceptance.contains("got laid") and acceptance.contains(person.name), "Clear non-graphic aftermath names partner")
	_check(game.score == original_score and game.cash == original_cash and game.inventory == original_items, "Optional fling adds no score, item cost, or money cost")
	_check(not game.completed, "Optional fling never completes the main goal")
	var event: Dictionary = game.consume_encounter()
	_check(event.get("partner") == id and event.get("gender") == person.gender and not event.get("finale", true), "One-shot presentation contains correct partner")
	_check(not event.get("caption", "").contains("{finale}") and event.caption.contains(game.finale_name()), "Scene caption is fully personalized")
	_check(game.consume_encounter().is_empty(), "Encounter presentation consumes exactly once")
	var after := _snapshot(game)
	game.choose_dialogue("date_accept_" + id)
	_check(_snapshot(game) == after, "Stale accept cannot repeat or mutate")
	game.command("talk " + person.name)
	_check(not game.dialogue_options().any(func(option): return option.id == "date_accept_" + id), "Completed fling cannot repeat")

func _identity(character: String, orientation: String) -> void:
	context = character + " / " + orientation
	var game = GameState.new()
	game.configure_profile(character, orientation)
	_check(game.player_name() == ("Lisa" if character == "lisa" else "Larry"), "Chosen name")
	var same := orientation == "homosexual"
	_check((game.finale_gender() == game.player_gender()) == same, "Finale follows same/opposite rule; bi finale opposite")
	_check(game.actor_profile("eve").role == ("adam" if game.finale_gender() == "male" else "eve"), "Finale drawing role follows gender")
	_check(game.objective().contains("Get laid with " + game.finale_name()), "Opening objective clearly states primary aim")
	_check(game.journal[0].contains(game.finale_name()), "Opening notebook personalizes target")
	var genders: Array = []
	for id in GameState.DATE_IDS:
		_check(game.is_eligible_partner(id), "Eligible optional partner " + id)
		genders.append(game.actor_profile(id).gender)
		_check(game.actor_profile(id).role == "romance_guest", "Optional guest has drawing role")
	_check(genders.has("male") and genders.has("female") if orientation == "bisexual" else not genders.has("male" if game.finale_gender() == "female" else "female"), "Optional roster represents selected orientation")
	_check(not game.is_eligible_partner("bartender") and not game.is_eligible_partner("unknown"), "Unromanced NPCs never become sexual targets")
	_check(game.rooms.rooftop.name == game.finale_name() + "'s Rooftop", "Raw room map name personalized")
	_check(game.items.apple.description.contains(game.finale_name()), "Raw inventory description personalized")
	_check(game.present("Every evening, even Larryville.") == "Every evening, even Larryville.", "Presentation never mangles ordinary name substrings")
	game.command("take newspaper")
	game.command("read newspaper")
	_go(game, "bar")
	game.command("talk lefty")
	_choose(game, "promotion_brief")
	game.command("look promotion")
	game.command("talk regular")
	_choose(game, "regular_ticket")
	game.command("talk lefty")
	_choose(game, "promotion_regular")
	game.command("buy whiskey")
	game.command("give whiskey to regular")
	var bowling: String = game.command("use remote on television")
	_check(bowling.contains("already vouched") and not bowling.contains("Provide the password"), "Bowling after social access never invents another door prerequisite")
	for id in GameState.DATE_IDS: _date(game, id)
	var selected: Dictionary = game.profile.duplicate()
	game.configure_profile("lisa" if character == "larry" else "larry", "homosexual")
	_check(game.profile == selected, "Cannot silently switch identity mid-evening")
	_go(game, "casino")
	game.command("take pass")
	_go(game, "disco")
	game.command("talk didi")
	_choose(game, "rehearsal_start")
	_choose(game, "rehearsal_correct")
	game.command("use phone")
	var rope_reply: String = game.command("take spare rope")
	_check(rope_reply.contains("already cleared") and rope_reply.contains("knife") and not rope_reply.contains("Call the stage manager"), "Cleared rope requests only the missing knife")
	game.command("talk phone")
	_choose(game, "manager_setup")
	_choose(game, "manager_intro")
	_go(game, "hotel")
	game.command("talk receptionist")
	_choose(game, "hotel_introduction")
	_go(game, "rooftop")
	var introduction: String = game.command("talk " + game.finale_name())
	_check(introduction.contains(game.finale_name()) and introduction.contains(game.player_name()), "Displayed target parser/name works")
	_choose(game, "eve_story")
	_choose(game, "eve_gardens")
	_go(game, "alley")
	game.command("take apple core")
	game.command("use apple core")
	_go(game, "garden")
	game.command("take stool")
	game.command("plant seeds")
	_go(game, "penthouse")
	game.command("use stool on cabinet")
	game.command("take pitcher")
	game.command("fill pitcher")
	_go(game, "garden")
	game.command("water planter")
	game.command("take apple")
	_go(game, "rooftop")
	game.command("give apple to " + game.finale_name())
	game.command("talk " + game.finale_name())
	var score_before: int = game.score
	_choose(game, "ending_friends")
	_check(not game.completed and game.score == score_before and game.consume_encounter().is_empty(), "Friends leaves goal open and does not award finale")
	_choose(game, "ending_afterparty")
	_check(not game.completed and game.room == "rooftop" and game.score == score_before, "After-party conversation preserves roof and goal")
	var output: String = _choose(game, "ending_flirt")
	_check(game.completed and output.contains("got laid") and output.contains(game.finale_name()), "Every identity can complete the clear primary goal")
	_check(game.score == score_before + 4 and game.score <= 100, "Existing finale milestone awarded once")
	var save := "user://identity-romance-test.json"
	game.save_game(save)
	var loaded = GameState.new()
	_check(loaded.load_game(save).contains("restored") and _snapshot(loaded) == _snapshot(game), "Full profile/encounter/completion state round-trips")
	_check(loaded.consume_encounter().is_empty(), "Reload does not replay private scene")
	for partner in GameState.DATE_IDS + ["eve"]:
		_check(loaded.actor_profile(partner) == game.actor_profile(partner), "Reload preserves exact gender and name " + partner)
	_check(loaded.get_room("rooftop").name == loaded.finale_name() + "'s Rooftop" and not loaded.items.apple.description.contains("{finale}"), "Reload resolves room and inventory tokens")
	var event: Dictionary = game.consume_encounter()
	_check(event.get("partner") == "eve" and event.get("finale", false) and event.get("name") == game.finale_name(), "Finale event correctly identifies target")
	_check(game.consume_encounter().is_empty(), "Finale event is one-shot")
	for room_id in game.rooms:
		_check(not JSON.stringify(game.get_room(room_id)).contains("{player}") and not JSON.stringify(game.get_room(room_id)).contains("{finale}"), "No unresolved room tokens " + room_id)
	_check(not game.command("journal").contains("{player}") and not game.epilogue().contains("{player}"), "Journal and epilogue fully personalized")
	DirAccess.remove_absolute(ProjectSettings.globalize_path(save))

func _migration() -> void:
	context = "profile/save boundary"
	var game = GameState.new()
	_check(game.profile == {"character": "larry", "orientation": "bisexual"}, "Default is bisexual Larry")
	game.configure_profile("invalid", "invalid")
	_check(game.profile == {"character": "larry", "orientation": "bisexual"}, "Invalid fresh inputs use safe defaults")
	var path := "user://identity-legacy-test.json"
	var old := {"version": 1, "room": "rooftop", "inventory": [], "flags": {"penthouse_access": true, "apple_given": true, "eve_met": true, "eve_story_shared": true, "eve_heard": true, "ending_friends": true, "award_ending": true}, "cash": 48, "score": 100, "turns": 85, "completed": true, "journal": ["An earlier evening."]}
	var file := FileAccess.open(path, FileAccess.WRITE)
	file.store_string(JSON.stringify(old)); file.close()
	_check(game.load_game(path).contains("restored") and not game.completed and game.score == 100, "Legacy completion reopens invitation without deleting earned score")
	game.command("talk eve")
	_choose(game, "ending_flirt")
	_check(game.completed and game.score == 100, "Legacy score milestone cannot duplicate")
	var stable := _snapshot(game)
	old.version = 2
	old.profile = {"character": "lisa", "orientation": "unknown"}
	file = FileAccess.open(path, FileAccess.WRITE)
	file.store_string(JSON.stringify(old)); file.close()
	_check(game.load_game(path).contains("invalid character profile") and _snapshot(game) == stable, "Invalid profile save rejected atomically")
	old.erase("profile")
	file = FileAccess.open(path, FileAccess.WRITE)
	file.store_string(JSON.stringify(old)); file.close()
	_check(game.load_game(path).contains("invalid character profile") and _snapshot(game) == stable, "Version two requires its profile")
	old.profile = {"character": "lisa", "orientation": "bisexual"}
	file = FileAccess.open(path, FileAccess.WRITE)
	file.store_string(JSON.stringify(old)); file.close()
	_check(game.load_game(path).contains("invalid ending") and _snapshot(game) == stable, "Version two cannot claim completion without the final encounter")
	game.new_game()
	_check(game.consume_encounter().is_empty() and not game.completed, "Restart clears any pending scene and encounters")
	DirAccess.remove_absolute(ProjectSettings.globalize_path(path))

func _run() -> void:
	for character in ["larry", "lisa"]:
		for orientation in ["heterosexual", "homosexual", "bisexual"]:
			_identity(character, orientation)
	_migration()
	print("Identity and romance tests: %d assertions, %d failures; six identities, three optional encounters each." % [assertions, failures.size()])
	quit(0 if failures.is_empty() else 1)
