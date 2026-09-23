extends RefCounted
## Presentation notification only; listeners must not resolve or repeat actions.
signal interaction_started(target: String, action: String)
## The entire adventure lives here, independent of scenes or rendering.
## Every irreversible trade has a renewable source or a permanent reward.

const SAVE_VERSION := 2
const max_score := 100
const PASSWORD := "bellybutton"
const PHONE_NUMBER := "5550987"
const SEED_SOURCE_CLUE := "Apple cores contain usable seeds. The Service Alley bin lid is the staff's collection spot: take a core and use it to separate the seeds."
const DIDI_REHEARSAL_CLUE := "Didi needs help rehearsing her cabaret at Studio 69. A complimentary Studio 69 pass waits in the Lucky Chip casino's clean ashtray. Take a pass, then talk to Didi."

var room: String = "street"
var inventory: Array[String] = []
var flags: Dictionary = {}
var cash: int = 80
var score: int = 0
var turns: int = 0
var completed: bool = false
var journal: Array[String] = []
var rooms: Dictionary = {}
var items: Dictionary = {}
var _dialogue_target: String = ""
var profile: Dictionary = {"character": "larry", "orientation": "bisexual"}
var _pending_encounter: Dictionary = {}

const DATE_IDS := ["lounge_date", "casino_date", "garden_date"]
const DATE_ROOMS := {"lounge_date": "backroom", "casino_date": "casino", "garden_date": "garden"}
const DATE_CLUES := {"lounge_date": "screen_tag", "casino_date": "lucky_napkin", "garden_date": "lantern_card"}


func configure_profile(character: String, orientation: String) -> void:
	# Profiles are chosen only for a fresh evening, never midway through a relationship.
	if turns != 0 or not flags.is_empty() or completed: return
	profile = {"character": character if character in ["larry", "lisa"] else "larry", "orientation": orientation if orientation in ["bisexual", "heterosexual", "homosexual"] else "bisexual"}
	_refresh_profile_content()
	journal.assign([present("Get laid with {finale} before sunrise. Meet people, solve their predicaments, and try not to let your collar arrive first. Optional flings are detours, not the final goal.")])


func _refresh_profile_content() -> void:
	_build_content()
	for id in items: _present_record(items[id])
	for id in rooms: _present_record(rooms[id])


func player_name() -> String:
	return "Lisa" if profile.character == "lisa" else "Larry"


func player_gender() -> String:
	return "female" if profile.character == "lisa" else "male"


func finale_gender() -> String:
	if profile.orientation == "homosexual": return player_gender()
	return "male" if player_gender() == "female" else "female"


func finale_name() -> String:
	return "Adam" if finale_gender() == "male" else "Eve"


func present(text: String) -> String:
	var tokens := {"{player}": player_name(), "{PLAYER}": player_name().to_upper(), "{finale}": finale_name(), "{player_possessive}": "her" if player_gender() == "female" else "his", "{player_subject}": "she" if player_gender() == "female" else "he", "{player_object}": "her" if player_gender() == "female" else "him", "{player_person}": "woman" if player_gender() == "female" else "man", "{player_Person}": "Woman" if player_gender() == "female" else "Man", "{finale_subject}": "she" if finale_gender() == "female" else "he", "{finale_Subject}": "She" if finale_gender() == "female" else "He", "{finale_possessive}": "her" if finale_gender() == "female" else "his", "{finale_object}": "her" if finale_gender() == "female" else "him"}
	for token in tokens: text = text.replace(token, tokens[token])
	return text


func actor_profile(id: String) -> Dictionary:
	if id in ["larry", "lisa", "player"]: return {"name": player_name(), "gender": player_gender(), "role": profile.character}
	if id == "eve": return {"name": finale_name(), "gender": finale_gender(), "role": "adam" if finale_gender() == "male" else "eve"}
	if DATE_IDS.has(id):
		var gender := finale_gender()
		if profile.orientation == "bisexual" and id == "casino_date": gender = player_gender()
		var names := {"lounge_date": ["Velvet", "Vince"], "casino_date": ["Ruby", "Ruben"], "garden_date": ["Flora", "Florian"]}
		var roles := {"lounge_date": "cabaret costumier", "casino_date": "off-duty magician", "garden_date": "night photographer"}
		return {"name": names[id][0 if gender == "female" else 1], "gender": gender, "role": "romance_guest", "occupation": roles[id]}
	return {"name": {"dancer": "Didi", "bartender": "Lefty", "receptionist": "Receptionist", "busker": "Busker", "patron": "Regular", "bouncer": "Bouncer", "cashier": "Cashier", "clerk": "Clerk"}.get(id, id.capitalize()), "gender": "female" if id in ["dancer", "receptionist"] else "male", "role": id}


func is_eligible_partner(id: String) -> bool:
	if id != "eve" and not DATE_IDS.has(id): return false
	var gender: String = actor_profile(id).gender
	return profile.orientation == "bisexual" or (gender == player_gender() if profile.orientation == "homosexual" else gender != player_gender())


func consume_encounter() -> Dictionary:
	var event := _pending_encounter.duplicate(true)
	_pending_encounter.clear()
	return event


func _present_record(record: Dictionary) -> Dictionary:
	for key in record:
		if record[key] is String: record[key] = present(record[key])
		elif record[key] is Array:
			for value in record[key]:
				if value is Dictionary: _present_record(value)
	return record



func _init() -> void:
	_build_content()
	new_game()


func new_game() -> void:
	room = "street"
	inventory.clear()
	flags.clear()
	cash = 80
	score = 0
	turns = 0
	completed = false
	_dialogue_target = ""
	_pending_encounter.clear()
	profile = {"character": "larry", "orientation": "bisexual"}
	configure_profile("larry", "bisexual")


func _spot(id: String, label: String, x: float, y: float, kind: String = "object") -> Dictionary:
	return {"id": id, "label": label, "x": x, "y": y, "kind": kind}


func _add_room(id: String, title: String, subtitle: String, description: String, background: String, hotspots: Array, exits: Array) -> void:
	var exit_data: Array = []
	for destination in exits:
		exit_data.append({"id": destination, "label": _room_label(destination)})
	rooms[id] = {"name": title, "subtitle": subtitle, "description": description, "background": background, "hotspots": hotspots, "exits": exit_data}


func _room_label(id: String) -> String:
	return {"street": "Neon Strip", "bar": "Lefty's Bar", "bathroom": "Bar Restroom", "backroom": "Backstage Lounge", "casino": "Lucky Chip Casino", "disco": "Studio 69", "shop": "Quik-E-Mart", "alley": "Service Alley", "hotel": "Hotel Lobby", "balcony": "Fire Escape", "garden": "Moonlight Garden", "penthouse": "Penthouse", "rooftop": "{finale}'s Rooftop"}.get(id, id.capitalize())


func _build_content() -> void:
	items = {
		"newspaper": {"name": "Newspaper", "description": "The Lost Wages Bugle. INSTANT APPLES! The hotel garden's planter turns seeds and water into fruit. Its designer recommends seeds from apple cores; staff leave clean cores on the Service Alley bin lid. Take a core and use it to separate the seeds. Science declined to comment."},
		"flowers": {"name": "Flowers", "description": "A cheerful bouquet, guaranteed to outlast your opening line."},
		"whiskey": {"name": "Whiskey", "description": "A miniature bottle of Lefty's premium vintage: Thursday."},
		"remote": {"name": "TV remote", "description": "The channel 6 button is worn smooth. Competitive bowling: the thinking bouncer's sport."},
		"ring": {"name": "Costume ring", "description": "A plastic ruby from the restroom's FREE COSTUME JEWELRY dish. Big enough to impress someone standing very, very far away."},
		"candy": {"name": "Candy", "description": "Promotional chocolates from the cabaret. The centers are softer than your sales pitch."},
		"pass": {"name": "Disco pass", "description": "A complimentary Studio 69 pass. Valid for one optimist and one dangerously ambitious collar."},
		"wine": {"name": "Wine", "description": "A house red with a fuller body than your leisure suit and a considerably better finish."},
		"knife": {"name": "Pocket knife", "description": "A tiny folding stagecraft knife, suitable for string. Dramatic potential: strictly limited."},
		"hammer": {"name": "Rubber mallet", "description": "A rubber mallet. Its tag says: 'For sticking window frames.' Finally, a tool with a more specific purpose than your cologne."},
		"core": {"name": "Apple core", "description": "A discarded apple core with three intact seeds. Use it to separate the seeds."},
		"seeds": {"name": "Apple seeds", "description": "Three seeds with dreams of entering the produce industry. The newspaper explains a useful planter."},
		"rope": {"name": "Stage rope", "description": "A length of theatrical rope. Finally, a line that can support your weight. The backroom railing would make a good anchor."},
		"voucher": {"name": "Espresso voucher", "description": "One deluxe espresso at Quik-E-Mart. Someone wrote 'For the hotel night shift' on the back."},
		"coffee": {"name": "Espresso", "description": "Dark, hot, and astonishingly willing to go home with the receptionist."},
		"stool": {"name": "Folding stool", "description": "A sturdy little stool from the garden's loan rack. Useful for high cabinets, poor for tall tales."},
		"pitcher": {"name": "Water pitcher", "description": "A lightweight pitcher. Fill it at the penthouse sink, then water the garden planter."},
		"apple": {"name": "Perfect apple", "description": "An absurdly perfect apple, grown by dubious science and honest effort. {finale} might appreciate the joke."}
	}
	_add_room("street", "The Neon Strip", "LOST WAGES · 11:47 PM", "Pink neon, palm trees, and a city that charges extra for sincerity. A free newspaper and a flower cart offer a promising start.", "street", [
		_spot("newsbox", "Free newspaper", 0.17, 0.72), _spot("flowercart", "Flower cart · $10", 0.70, 0.72), _spot("taxi", "Taxi stand", 0.85, 0.72)
	], ["bar", "casino", "disco", "shop", "alley", "hotel"])
	_add_room("bar", "Lefty's Bar", "HAPPY HOUR IS A STATE OF DENIAL", "A bartender polishes the same glass history forgot. A thirsty regular guards a remote; a bouncer guards the backstage door. The television is losing an argument with static.", "bar", [
		_spot("bartender", "Lefty · bartender", 0.26, 0.46, "person"), _spot("patron", "Thirsty regular", 0.52, 0.64, "person"), _spot("television", "Television", 0.89, 0.22), _spot("bouncer", "Backstage bouncer", 0.84, 0.55, "person"), _spot("promotion", "Bowling-night promotion", 0.70, 0.37)
	], ["street", "bathroom", "backroom"])
	_add_room("bathroom", "The Restroom", "THE WRITING IS LITERALLY ON THE WALL", "Avocado tile, optimistic plumbing, and graffiti with unusually good information security. A dish beside the basin offers free costume jewelry.", "bathroom", [
		_spot("graffiti", "Wall graffiti", 0.35, 0.38), _spot("basin", "Basin & jewelry dish", 0.23, 0.57), _spot("ring", "Costume ring", 0.25, 0.65)
	], ["bar"])
	_add_room("backroom", "Backstage Lounge", "THE FEATHERS GET THEIR OWN DRESSING ROOM", "The cabaret is between shows. Chocolates wait on a table, outnumbered by feathers. The fire escape has lost a step; a rope tied to the railing could bridge the gap.", "backroom", [
		_spot("candy", "Promotional candy", 0.72, 0.83), _spot("railing", "Safety railing", 0.57, 0.28), _spot("poster", "Cabaret poster", 0.64, 0.14), _spot("lounge_date", "Costumier", 0.31, 0.67, "person"), _spot("screen_tag", "Dressing-screen tag", 0.18, 0.41)
	], ["bar", "balcony"])
	_add_room("casino", "The Lucky Chip", "YOUR LUCK HAS A COVER CHARGE", "Chrome, carpet, and the sound of wallets clearing their throats. A disco pass rests in a clean ashtray. The cashier offers a little comeback cash if your luck gets too personal.", "casino", [
		_spot("slots", "Demonstration slots · $5", 0.23, 0.49), _spot("blackjack", "Blackjack table", 0.88, 0.56), _spot("cashier", "Casino cashier", 0.54, 0.46, "person"), _spot("ashtray", "Clean ashtray", 0.77, 0.61), _spot("pass", "Studio 69 pass", 0.71, 0.69), _spot("casino_date", "Magician", 0.39, 0.71, "person"), _spot("lucky_napkin", "Lucky napkin", 0.38, 0.87)
	], ["street", "hotel"])
	_add_room("disco", "Studio 69", "THE BEAT IS HOT. THE COLLAR IS HOTTER.", "The bass line has a mortgage. Didi, a stage designer off the clock and on the beat, catches your eye. A wall phone and a tied coil of spare stage rope flank the DJ booth.", "disco", [
		_spot("dancer", "Didi · stage designer", 0.52, 0.59, "person"), _spot("dancefloor", "Dance floor", 0.34, 0.72), _spot("stage_marks", "Rehearsal marks", 0.45, 0.88), _spot("phone", "Wall telephone", 0.82, 0.34), _spot("rigging", "Spare stage rope", 0.16, 0.35)
	], ["street"])
	_add_room("shop", "Quik-E-Mart", "OPEN ALL NIGHT. FEELINGS NOT INCLUDED.", "Wine, postcards, and a deluxe espresso machine with a voucher slot. The clerk says the hotel's night receptionist is a particular fan of that coffee.", "shop", [
		_spot("clerk", "Shop clerk", 0.89, 0.39, "person"), _spot("wine_shelf", "Wine · $12", 0.21, 0.47), _spot("espresso", "Espresso machine", 0.82, 0.26), _spot("magazines", "Magazine rack", 0.65, 0.57)
	], ["street"])
	_add_room("alley", "The Service Alley", "EVERY GREAT ROMANCE HAS A LOADING DOCK", "A busker finishes a blues number that sounds suspiciously like your last date. An apple core sits on a bin lid; a maintenance rack holds a rubber mallet.", "alley", [
		_spot("busker", "Blues busker", 0.90, 0.65, "person"), _spot("bin", "Recycling bin", 0.32, 0.60), _spot("core", "Apple core", 0.295, 0.86), _spot("hammer", "Loaner rubber mallet", 0.74, 0.87)
	], ["street"])
	_add_room("hotel", "The Come-On Inn", "LUXURY, SUBJECT TO AVAILABILITY", "The night receptionist manages six ringing phones with one eyebrow. She is arranging a small rooftop gathering and could use a genuine coffee break.", "hotel", [
		_spot("receptionist", "Night receptionist", 0.61, 0.45, "person"), _spot("elevator", "Penthouse elevator", 0.18, 0.44), _spot("guestbook", "Guest book", 0.30, 0.68)
	], ["street", "casino", "garden", "penthouse"])
	_add_room("balcony", "The Fire Escape", "ONE FLIGHT ABOVE YOUR STATION", "Your rope spans the missing step. The service window is stuck tighter than your best trousers. A note recommends a gentle mallet tap; an espresso voucher waits beyond the glass.", "balcony", [
		_spot("window", "Sticking service window", 0.68, 0.27), _spot("voucher", "Espresso voucher", 0.665, 0.62)
	], ["backroom"])
	_add_room("garden", "Moonlight Garden", "PATENT PENDING. BOTANY OBJECTING.", "A hotel's experimental instant-fruit planter hums under moonlight. Its instructions are missing, but the local paper reviewed it. A folding stool waits on the equipment loan rack.", "garden", [
		_spot("planter", "Experimental planter", 0.49, 0.65), _spot("stool", "Loaner folding stool", 0.35, 0.77), _spot("tree", "Miniature apple tree", 0.49, 0.40), _spot("garden_date", "Photographer", 0.77, 0.60, "person"), _spot("lantern_card", "Lantern instruction card", 0.85, 0.80)
	], ["hotel"])
	_add_room("penthouse", "The Penthouse", "SOMEONE ELSE'S GOOD TASTE", "The receptionist's invitation gets you into the shared rooftop lounge. A water pitcher waits in a cabinet well above collar height. A sink and the roof stairs complete the picture.", "penthouse", [
		_spot("cabinet", "High cabinet", 0.90, 0.14), _spot("pitcher", "Water pitcher", 0.935, 0.10), _spot("sink", "Kitchenette sink", 0.74, 0.38), _spot("terrace_sign", "Rooftop gathering sign", 0.50, 0.4)
	], ["hotel", "rooftop"])
	_add_room("rooftop", "{finale}'s Rooftop", "THE CITY FINALLY LOWERS ITS VOICE", "The pool reflects a pink horizon. {finale}, tonight's host, has escaped the party for a moment. One raised eyebrow sizes up your suit. You try to look like someone who has been invited upstairs before.", "rooftop", [
		_spot("eve", "{finale} · rooftop host", 0.66, 0.56, "person"), _spot("pool", "Moonlit pool", 0.69, 0.70), _spot("skyline", "Lost Wages skyline", 0.43, 0.22)
	], ["penthouse"])


func get_room(id: String = "") -> Dictionary:
	var chosen := room if id.is_empty() else id
	if not rooms.has(chosen):
		return {}
	var result: Dictionary = rooms[chosen].duplicate(true)
	result.description = _room_description(chosen)
	var visible: Array = []
	for hotspot in result.hotspots:
		var key: String = hotspot.id
		if key in ["ring", "candy", "pass", "hammer", "core", "stool", "voucher", "pitcher"] and flags.get("taken_" + key, false):
			continue
		if key == "voucher" and not flags.get("window_open", false):
			continue
		if key == "pitcher" and not flags.get("stool_placed", false):
			continue
		if key == "tree" and not flags.get("apple_grown", false):
			continue
		if key == "patron" and flags.get("whiskey_given", false):
			hotspot.label = "Contented regular"
		if key == "window" and flags.get("window_open", false):
			hotspot.label = "Open service window"
		if key == "tree" and flags.get("taken_apple", false):
			hotspot.label = "Picked apple tree"
		if DATE_IDS.has(key):
			var person := actor_profile(key)
			hotspot.label = person.name + " · " + person.occupation
		visible.append(hotspot)
	result.hotspots = visible
	for destination in result.exits:
		destination["locked"] = not is_unlocked(destination.id)
	result["id"] = chosen
	for date_id in DATE_IDS:
		if DATE_ROOMS[date_id] == chosen:
			var person := actor_profile(date_id)
			result.description += " " + person.name + " · " + person.occupation + " · offers a knowing smile. TALK for an optional detour; no purchases required."
	return _present_record(result)


func _room_description(id: String) -> String:
	match id:
		"bar":
			var regular := "The regular raises the whiskey you brought him." if flags.get("whiskey_given", false) else "A thirsty regular guards a remote."
			var television := "Championship bowling fills the television; the bouncer follows every frame." if flags.get("tv_distracted", false) else "The television is losing an argument with static."
			var door := "The backstage door is open to you." if is_unlocked("backroom") else "The bouncer controls the backstage door."
			return "Lefty polishes the same glass history forgot. %s %s %s" % [regular, television, door]
		"bathroom":
			return "Avocado tile, optimistic plumbing, and unusually useful graffiti. " + ("The costume-jewelry dish is empty; you collected its ring." if flags.get("taken_ring", false) else "A dish beside the basin offers a free costume ring.")
		"backroom":
			var candy := "The promotional chocolates are gone; you collected them." if flags.get("taken_candy", false) else "Promotional chocolates wait on a table, outnumbered by feathers."
			var escape := "Your anchored rope makes the fire escape accessible." if flags.get("rope_anchored", false) else "The fire escape has lost a step; a rope tied to the railing could bridge the gap."
			var poster := " A cabaret poster says: " + DIDI_REHEARSAL_CLUE if not flags.get("dancer_met", false) else ""
			return "The cabaret is between shows. %s %s%s" % [candy, escape, poster]
		"casino":
			return "Chrome, carpet, and the sound of wallets clearing their throats. " + ("The clean ashtray is empty now that you have the disco pass." if flags.get("taken_pass", false) else "A disco pass rests in a clean ashtray.") + " The cashier offers comeback cash if your luck gets too personal."
		"disco":
			var didi := "Didi has her opening-night props and greets you with a grin." if _all_gifts() else "Didi, a stage designer off the clock and on the beat, catches your eye."
			if flags.get("rehearsal_done", false): didi = "Didi's volunteer rehearsal is ready; the taped X awaits your next public humiliation."
			if flags.get("show_completed", false): didi = "Didi is basking in the cabaret's applause and planning an after-show gathering."
			var rope := "You have collected the spare coil; the remaining stage rigging is in use." if flags.get("rope_taken", false) else "A tied coil of spare rope hangs beside the DJ booth."
			return "The bass line has a mortgage. %s A wall phone connects to the stage crew. %s" % [didi, rope]
		"alley":
			var busker := "The busker's picnic wine is packed; he plays you a grateful blues riff." if flags.get("wine_given", false) else "A busker finishes a blues number that sounds suspiciously like your last date."
			var core := "The bin lid is clear after you collected the apple core." if flags.get("taken_core", false) else "An apple core sits on a bin lid."
			var mallet := "The loan rack has an empty mallet hook." if flags.get("taken_hammer", false) else "A maintenance rack holds a rubber mallet."
			return "%s %s %s" % [busker, core, mallet]
		"hotel":
			if flags.get("penthouse_access", false):
				var greeting := "The receptionist sips your espresso between phone calls." if _coffee_delivered() else "The receptionist waves to the cabaret's newly credentialed volunteer."
				return greeting + " Your name is on {finale}'s guest list; the penthouse elevator is open to you. The garden is down the hall."
		"balcony":
			if flags.get("window_open", false):
				return "Your rope spans the missing step. The service window is open. " + ("You collected the night-shift voucher from its sill." if flags.get("taken_voucher", false) else "The espresso voucher on its sill is now within reach. Take it.")
		"garden":
			var planter := "The experimental planter awaits seeds and water; the newspaper has its instructions."
			if flags.get("seeds_planted", false): planter = "Your seeds are in the planter's starter tray, waiting for water."
			if flags.get("apple_grown", false): planter = "The experimental planter holds a miniature tree with one perfect apple."
			if flags.get("taken_apple", false): planter = "Your miniature tree is thriving. You have picked its one perfect apple."
			return "Moonlight shines on the garden. " + planter + (" The stool's place on the loan rack is empty." if flags.get("taken_stool", false) else " A folding stool waits on the equipment loan rack.")
		"penthouse":
			var cabinet := "A water pitcher waits in a cabinet well above collar height."
			if flags.get("stool_placed", false): cabinet = "Your folding stool makes the cabinet's water pitcher easy to reach."
			if flags.get("taken_pitcher", false): cabinet = "The high cabinet is empty; you collected its water pitcher."
			return "The receptionist's invitation gets you into the shared rooftop lounge. %s A kitchenette sink and the roof stairs complete the picture." % cabinet
	return str(rooms[id].description)


func get_hotspot(id: String) -> Dictionary:
	for hotspot in get_room().hotspots:
		if hotspot.id == id:
			return hotspot
	return {}


func get_inventory() -> Array:
	var result: Array = []
	for id in inventory:
		var entry: Dictionary = items[id].duplicate()
		entry["id"] = id
		if id == "pitcher" and flags.get("pitcher_filled", false):
			entry.name = "Pitcher of water"
		result.append(_present_record(entry))
	return result


func is_unlocked(destination: String) -> bool:
	if not rooms.has(destination):
		return false
	match destination:
		"backroom": return flags.get("backstage_social", false) or (flags.get("password_spoken", false) and flags.get("tv_distracted", false))
		"disco": return inventory.has("pass")
		"balcony": return flags.get("rope_anchored", false)
		"penthouse", "rooftop": return flags.get("penthouse_access", false)
	return true


func _gate_message(destination: String) -> String:
	match destination:
		"backroom":
			if not flags.get("password_spoken", false):
				return "The bouncer asks for the password. Restroom graffiti is famously terrible at keeping secrets."
			return "The password checks out, but the bouncer wants to finish his shift. A favorite television program might help."
		"disco": return "Studio 69 requires a pass. The casino gives them away; exclusivity has a generous marketing budget."
		"balcony": return "The fire escape is missing a step. Anchor a rope to the backroom railing before your evening takes a sudden downward turn."
		"penthouse", "rooftop": return "The receptionist controls invitations. Try talking to her about that coffee break."
	return "That way is unavailable."


func travel(destination: String) -> String:
	return present(_travel_text(destination))


func _travel_text(destination: String) -> String:
	var resolved := _resolve_room(destination)
	if not rooms.has(resolved):
		return "Lost Wages has many questionable addresses. That is not one of them."
	if resolved == room:
		return "You are already here. Your sense of direction takes a courtesy bow."
	var adjacent := false
	for route in rooms[room].exits:
		if route.id == resolved:
			adjacent = true
	if not adjacent:
		return "There is no direct route there. Use the exits; the Neon Strip connects the main venues."
	if not is_unlocked(resolved):
		return _gate_message(resolved)
	room = resolved
	_dialogue_target = ""
	turns += 1
	_observe_room()
	return str(get_room().description)


func _note(entry: String) -> void:
	entry = present(entry)
	if not journal.has(entry):
		journal.append(entry)


func _award(key: String, entry: String = "") -> void:
	if flags.get("award_" + key, false):
		return
	flags["award_" + key] = true
	score = mini(score + 4, max_score)
	if not entry.is_empty():
		_note(entry)


func _give(id: String) -> void:
	if not inventory.has(id):
		inventory.append(id)


func _take(id: String) -> String:
	if flags.get("taken_" + id, false):
		return "You already collected that. Leave some narrative for the next adventurer."
	flags["taken_" + id] = true
	_give(id)
	match id:
		"ring": _award("ring_taken", "Found a free costume ring in Lefty's restroom.")
		"candy": _award("candy_taken", "Collected promotional chocolates backstage.")
		"pass": _award("pass_taken", "The casino's complimentary pass opens Studio 69.")
		"pitcher": _award("pitcher_taken", "A pitcher, a sink, and an instant-fruit planter. Botany is about to get weird.")
	return "Taken: %s. Your pockets ignore the laws of tailoring." % items[id].name


func _buy(id: String, price: int) -> String:
	if inventory.has(id) or flags.get("spent_" + id, false):
		return "You already handled that purchase. Even this town draws the line at duplicate plot expenses."
	if cash < price:
		return "That costs $%d; you have $%d. The casino cashier offers a recovery grant below $10, and the demonstration slots can rebuild your wallet." % [price, cash]
	cash -= price
	_give(id)
	if id == "flowers":
		_award("flowers_bought", "Bought flowers. Generosity works best without a receipt attached.")
	return "You pay $%d for %s. Remaining funds: $%d." % [price, str(items[id].name).to_lower(), cash]


func _consume(id: String) -> void:
	inventory.erase(id)
	flags["spent_" + id] = true


func _valid_target(target: String) -> bool:
	if inventory.has(target):
		return true
	for hotspot in get_room().hotspots:
		if hotspot.id == target:
			return true
	for destination in rooms[room].exits:
		if destination.id == target:
			return true
	return false


func interact(target: String, verb: String = "look", item: String = "") -> String:
	return present(_interact_text(target, verb, item))


func _interact_text(target: String, verb: String = "look", item: String = "") -> String:
	var key := _resolve_target(target)
	var action := verb.strip_edges().to_lower()
	var held := _resolve_item(item)
	if action in ["read", "examine", "inspect"]:
		action = "look"
	if action in ["get", "pick", "buy", "order"]:
		action = "take"
	if action in ["give", "apply"]:
		action = "use"
	if action in ["go", "travel", "enter"]:
		return travel(key)
	if not action in ["look", "take", "talk", "use", "dance", "open", "fill", "water", "plant", "climb", "play"]:
		return "Try LOOK, TALK, TAKE, or USE. Your suit can improvise; the parser prefers clarity."
	if not held.is_empty() and not inventory.has(held):
		return "You are not carrying that. Wishful thinking is not an inventory system."
	if not _valid_target(key):
		return "You cannot see that here. Look around or check your inventory."
	interaction_started.emit(key, "use" if verb.strip_edges().to_lower() in ["buy", "order"] else action)
	if action == "look":
		return _look(key)
	for destination in rooms[room].exits:
		if destination.id == key:
			return travel(key)
	turns += 1
	if action == "talk":
		_dialogue_target = key
		return _talk(key)
	if action == "take" and not verb.strip_edges().to_lower() in ["buy", "order"]:
		if DATE_IDS.has(key) or key in ["bartender", "patron", "bouncer", "cashier", "dancer", "clerk", "busker", "receptionist", "eve"]:
			return "Lefty stays behind his bar. TALK to him and choose the $10 whiskey offer, or type BUY WHISKEY." if key == "bartender" else "People are not pocket-sized favors. TALK to them, or USE an item to offer it."
		if key in ["television", "dancefloor", "phone", "railing", "window", "espresso", "elevator", "cabinet", "sink", "planter", "slots", "blackjack"]:
			return "That belongs here. LOOK for a clue, or USE it. Your pockets have limits after all."
	if not held.is_empty():
		return _use_item(held, key)
	if DATE_IDS.has(key): return _date_talk(key)
	for date_id in DATE_IDS:
		if DATE_CLUES[date_id] == key: return _date_clue(date_id)
	match key:
		"newsbox":
			if inventory.has("newspaper"):
				return "One free newspaper is plenty. The city is already full of bad news."
			_give("newspaper")
			return "You take the free newspaper. Read it for local news and suspiciously convenient horticulture."
		"flowercart": return _buy("flowers", 10)
		"bartender": return _buy("whiskey", 10)
		"wine_shelf": return _buy("wine", 12)
		"ring", "candy", "pass", "hammer", "core", "stool", "voucher", "pitcher":
			if inventory.has(key):
				if key == "core": return _extract_seeds()
				if key == "pitcher" and room == "penthouse": return _fill_pitcher()
				return "You already have it. Try using it with something in the scene."
			return _take(key)
		"basin": return _look("basin")
		"graffiti": return _look("graffiti")
		"ashtray": return _look("ashtray")
		"bin": return _look("bin")
		"patron", "busker", "receptionist", "eve", "clerk": return _talk(key)
		"bouncer":
			if flags.get("backstage_social", false): return "Bouncer: 'Lefty vouched for you. You're on the list, collar and all. Head backstage.'"
			if flags.get("password_known", false): return _say_password(PASSWORD)
			if flags.get("tv_distracted", false):
				_note("The bouncer is watching bowling; he still needs the backstage password. Restroom graffiti may help.")
				return "Bouncer: 'Thanks for the bowling. Still need the password, pal. Try the restroom graffiti.'"
			return _talk(key)
		"television":
			if inventory.has("remote"): return _use_item("remote", "television")
			return "The set has no working controls. A remote would improve reception in every sense."
		"slots": return _play_slots()
		"cashier": return _recovery_grant()
		"dancer", "dancefloor": return _dance()
		"phone":
			if flags.get("phone_known", false): return _call(PHONE_NUMBER)
			return "You need a number. Didi knows the local stage crew."
		"rigging":
			if inventory.has("knife"): return _use_item("knife", "rigging")
			if flags.get("phone_called", false): return "The stage manager already cleared the spare rope. Its packaging cord still needs a small knife."
			return "The spare rope is tied with stubborn packaging cord. Call the stage manager about the coil, then find a small cutting tool."
		"railing":
			if inventory.has("rope"): return _use_item("rope", "railing")
			return "A sturdy anchor for a rope. Your belt volunteers; your trousers object."
		"window":
			if inventory.has("hammer"): return _use_item("hammer", "window")
			return "The note recommends a gentle rubber-mallet tap. Your fingertips are achieving nothing except fingerprints."
		"espresso":
			if inventory.has("voucher"): return _use_item("voucher", "espresso")
			return "The deluxe machine accepts espresso vouchers from Lefty's service window. Ordinary cash cannot charm it."
		"elevator": return travel("penthouse")
		"cabinet":
			if flags.get("taken_pitcher", false): return "The cabinet is empty. Your pitcher has already joined the evening."
			if inventory.has("stool"): return _use_item("stool", "cabinet")
			if flags.get("stool_placed", false): return "The folding stool makes the pitcher easy to reach. Take it."
			return "The cabinet is too high. The garden equipment rack has something made for this problem."
		"sink": return _fill_pitcher()
		"planter":
			if flags.get("apple_grown", false): return _look("planter")
			if flags.get("seeds_planted", false) and not inventory.has("pitcher"):
				return "The seeds are already planted; now add water. There is a water pitcher in the high penthouse cabinet. The garden's loan stool can help you reach it."
			if inventory.has("seeds"): return _use_item("seeds", "planter")
			if inventory.has("pitcher"): return _use_item("pitcher", "planter")
			return "The instant-fruit planter needs seeds, then water. Read the newspaper for operating instructions."
		"tree":
			if flags.get("taken_apple", false): return "The tree has completed its contractual obligation. One perfect apple per adventure."
			return _take("apple")
		"newspaper": return _look("newspaper")
		"taxi": return "The driver opens the door. 'Courtesy rides tonight, pal. Choose your stop on the City map. Tips are optional; pickup lines cost extra.'"
	return "That does not need doing. A rare bargain in this city."


func _look(key: String) -> String:
	if DATE_IDS.has(key):
		var person := actor_profile(key)
		return "%s, a grown-up %s with an indecently good sense of timing. TALK before deploying that pickup line." % [person.name, person.occupation]
	for date_id in DATE_IDS:
		if DATE_CLUES[date_id] == key: return _date_clue(date_id)
	_observe_room()
	if inventory.has(key) and items.has(key):
		if key == "newspaper":
			flags["newspaper_read"] = true
			_award("newspaper_read", "The Bugle explains the garden's instant-fruit planter: plant seeds, then add water.")
			_note(SEED_SOURCE_CLUE)
		if key == "pitcher":
			return "The pitcher is full of water. The experimental garden planter awaits." if flags.get("pitcher_filled", false) else str(items.pitcher.description)
		return str(items[key].description) + (" Its main job is done; you can keep it in your souvenir pocket." if item_status(key) == "souvenir" else "")
	match key:
		"newsbox": return "Free papers. Today's headline: INSTANT APPLES COME TO HOTEL GARDEN. Take a copy, then read it."
		"flowercart": return "Locally grown flowers, $10. Cash into slot; bouquet out. Romance has discovered vending machines."
		"taxi": return "The sign says COURTESY RIDES TONIGHT. USE the taxi stand to choose a destination. Nearby doors are a walk; the farther neon is a free ride. {player} briefly considers tipping with charm."
		"bartender": return "Lefty polishes a glass and nods at your satisfied trading partner." if flags.get("whiskey_given", false) else "Lefty sells whiskey miniatures for $10. The regular next to him is watching the bottle like it owes him dinner."
		"promotion":
			flags["prize_known"] = true
			_note("Lefty's bowling-night board advertises a golden bowling-pin keyring for winning ticket 37.")
			return "BOWLING NIGHT: winning ticket 37 claims a GOLDEN BOWLING-PIN KEYRING. Underneath: No cash value. Considerable emotional baggage. Ask Lefty about helping with the promotion."
		"stage_marks":
			flags["cue_known"] = true
			_note("Didi's rehearsal marks say: stand on the X; AUDIT is answered WRITE IT OFF.")
			return "A taped X and Didi's cue card: AUDIT / WRITE IT OFF. Underlined: DO NOT IMPROVISE A MARRIAGE PROPOSAL."
		"patron":
			flags["winner_known"] = true
			_note("The regular at Lefty's wears ticket 37 in his collar. He says losing it would be his first bad split tonight.")
			if flags.get("whiskey_given", false): return "The regular wears ticket 37 in his collar and cradles his whiskey. You have his remote; this relationship appears healthier for everyone."
			_note("The regular at Lefty's will trade his TV remote for a $10 whiskey from the bartender.")
			return "Ticket 37 sticks out of the regular's collar. He clutches a TV remote like a tiny plastic soulmate. A whiskey might persuade him to play the field."
		"television": return "Championship bowling is on channel 6. The bouncer is emotionally committed to frame seven." if flags.get("tv_distracted", false) else "Channel 6 carries championship bowling. The bouncer's shirt says ASK ME ABOUT MY SPLIT."
		"bouncer":
			if flags.get("backstage_social", false): return "Lefty vouched for you after the bowling promotion. The bouncer holds the door, visibly struggling with the concept of customer service."
			return "He has accepted your password and is absorbed in the bowling. Head backstage." if is_unlocked("backroom") else "The bouncer checks passwords and dreams of televised bowling. Two separate obstacles, one substantial person."
		"graffiti":
			flags["password_known"] = true
			_award("graffiti_read", "Restroom graffiti reveals the backstage password: BELLYBUTTON.")
			return "Between two questionable poems: 'BACKSTAGE PASSWORD: BELLYBUTTON.' You commit it to your least crowded brain cell."
		"basin": return "The FREE COSTUME JEWELRY dish is empty. You collected its plastic ruby ring." if flags.get("taken_ring", false) else "Beside the basin, a dish reads FREE COSTUME JEWELRY. A plastic ruby ring catches the fluorescent light."
		"ring", "candy", "pass", "hammer", "core", "stool", "voucher", "pitcher": return str(items[key].description)
		"railing": return "Your rope is securely knotted around the railing. The fire escape is accessible." if flags.get("rope_anchored", false) else "A sturdy railing beside the damaged fire escape. Tie a rope here to get across the gap."
		"poster":
			if flags.get("rehearsal_done", false): return "THE ACCOUNTANTS OF DESIRE. Tonight's assistant: {PLAYER}, THANKFULLY UNAUDITED. Didi has written your name in small lights, thanks to you volunteering."
			if _all_gifts(): return "THE ACCOUNTANTS OF DESIRE. Didi's opening now has its costume ring, flowers, and chocolates, thanks to you. Finally, an investment in the arts with visible returns."
			_note(DIDI_REHEARSAL_CLUE)
			return "THE ACCOUNTANTS OF DESIRE. Their books are open. Their expenses are intimate. Their matinee is tax-deductible. A handwritten notice adds: " + DIDI_REHEARSAL_CLUE
		"blackjack": return "Twenty-one, velvet felt, and a dealer with the expression of an unpaid invoice. Use the table to play blackjack."
		"slots": return "Demo slots cost $5 and pay $0, $15, $0, then $25 in a repeating cycle. The pattern is more reliable than your dating history."
		"cashier": return "The cashier offers a $20 recovery grant whenever your funds fall below $10. Ask or use the desk."
		"ashtray": return "The clean ashtray is empty. You already collected the complimentary disco pass." if flags.get("taken_pass", false) else "This ashtray has been retired from smoking and promoted to brochure storage. Take the complimentary disco pass."
		"dancer":
			if flags.get("show_completed", false): return "Didi grins after her curtain call. Talk to her about the after-show gathering."
			if flags.get("rehearsal_done", false): return "Didi's rehearsal is ready, thanks to her magnificently overdressed assistant. Talk to watch the show."
			return "Didi recognizes her magnificently overdressed dance partner. Her opening-night props are ready." if _all_gifts() else "Didi is planning her cabaret opening between songs. Talk about props or volunteering for her rehearsal." if flags.get("dancer_met", false) else "Didi designs cabaret sets and wears a smile that suggests she has already redesigned your opening line. Introduce yourself."
		"dancefloor": return "The floor is illuminated. Your dancing is not. Use it anyway; enthusiasm is the point."
		"phone":
			if flags.get("didi_message_delivered", false): return "The stage manager cleared the rope, and Didi has his message. Your brief career in theatrical communications is complete."
			if flags.get("phone_called", false): return "You reached Didi's stage manager here. He cleared the spare rope and asked you to pass along a dance invitation."
			return "Didi gave you 555-0987. Use the phone or type CALL 555-0987." if flags.get("phone_known", false) else "A wall phone. Didi knows the stage manager's number."
		"rigging": return "The spare coil is gone; you collected it. The remaining rigging is holding up the show, literally." if flags.get("rope_taken", false) else "An unused coil tied with packaging cord. A tag says CALL STAGE MANAGER. Even the rope has a better social calendar than you."
		"clerk": return "The clerk stocks wine and redeems the hotel's espresso vouchers. Their patience is not for sale."
		"wine_shelf": return "A bottle of red costs $12. The alley busker mentioned a picnic after his set; apparently the blues come with cheese."
		"espresso": return "A deluxe espresso machine with a voucher slot. The service window above Lefty's has a night-shift voucher."
		"magazines": return "Collar Weekly predicts next season's collars will need their own ZIP codes. The centerfold is a particularly daring lapel."
		"busker":
			if flags.get("wine_given", false): return "The picnic wine is packed. The busker gave you his spare knife and is warming up a much happier song."
			_note("The alley busker will trade his spare pocket knife for a $12 bottle of wine from Quik-E-Mart.")
			return "A blues musician packs for a midnight picnic. He'll trade his spare pocket knife for wine. At least one of you has plans that involve a blanket."
		"bin": return "The bin lid is clear. You collected its apple core." if flags.get("taken_core", false) else "A clean apple core rests on the bin lid. There are useful seeds inside; take it and use it."
		"receptionist":
			if _coffee_delivered(): return "The receptionist is enjoying the espresso you brought. Your rooftop invitation is on the guest list."
			if flags.get("penthouse_access", false): return "The receptionist knows you as Didi's cabaret helper. Your rooftop invitation is on the guest list."
			return "The receptionist is hosting friends upstairs after her shift. She knows the cabaret crew and has clearly earned a coffee break."
		"elevator": return "The penthouse elevator is unlocked for you. {finale}'s rooftop gathering is upstairs." if flags.get("penthouse_access", false) else "The penthouse elevator needs the receptionist's invitation. Being nice is a promising technology."
		"guestbook": return "Guest comment: 'Good pillows. Unsettlingly fast apples.' Five stars, with reservations."
		"window":
			if flags.get("taken_voucher", false): return "The window is open and its sill is empty. You collected the espresso voucher."
			if flags.get("window_open", false): return "The open window puts the espresso voucher within reach. Take it from the sill."
			return "A coffee voucher waits behind a sticking service window. The note says a gentle rubber-mallet tap will free the frame."
		"planter":
			if flags.get("taken_apple", false): return "The planter supports a healthy little tree. You have picked its single apple; the machine's work is done."
			if flags.get("apple_grown", false): return "Your watered seeds have become a miniature tree. One perfect apple is ready to take."
			if flags.get("seeds_planted", false): return "Your seeds are in the starter tray. Add a pitcher of water to start the growth cycle."
			_note(SEED_SOURCE_CLUE)
			return "The experimental planter grows an apple tree from seeds and water. A diagram shows seeds being separated from an apple core; its sticker reads STAFF CORE COLLECTION: SERVICE ALLEY BIN LID. The local newspaper explains the controls."
		"tree": return "The little tree is healthy but picked clean. You collected its one perfect apple." if flags.get("taken_apple", false) else "A tiny tree holds one perfect apple. Take the apple before science asks for it back."
		"cabinet":
			if flags.get("taken_pitcher", false): return "The cabinet is empty; you collected the water pitcher. The stool stays beneath it for the next short guest."
			if flags.get("stool_placed", false): return "Your folding stool makes the pitcher easy to reach. Take it from the cabinet."
			return "A water pitcher sits in a high cabinet, just beyond the reach of your charms. A folding stool would help."
		"sink": return "Clean tap water. Use the pitcher here, or use the sink while carrying it."
		"terrace_sign": return "ROOFTOP GATHERING — hosted by {finale}. Beneath it, someone has added: PLEASE KEEP THE SMALL TALK BELOW THE WATERLINE."
		"eve": return "{finale} has the skyline, the moonlight, and a mischievous smile. You have a white suit. Lead with your name."
		"pool": return "The pool is for invited guests. Tonight a conversation is more useful than another damp suit."
		"skyline": return "Lost Wages glows like a jukebox that learned urban planning. Dawn is on its way, at your own pace."
	if rooms.has(key):
		return "Exit to %s. %s" % [rooms[key].name, "The way is open." if is_unlocked(key) else _gate_message(key)]
	return "A perfectly serviceable piece of scenery."


func _talk(key: String) -> String:
	_dialogue_target = key
	if DATE_IDS.has(key): return _date_talk(key)
	match key:
		"dancefloor": return _talk("dancer")
		"phone":
			if flags.get("phone_called", false): return "Stage manager: 'Still here, {player}. " + _manager_followup() + "'"
			if flags.get("phone_known", false): return "Didi gave you 555-0987. USE the wall phone or CALL that number to reach her stage manager. The receiver is warm; in this town, even a telephone has an active social life."
			return "The receiver offers a dial tone. Didi knows the stage manager's number; ask her about the show before calling."
		"bartender": return "Lefty: 'Good trade. He's got his whiskey, you've got the remote, and I've got ten dollars. Everybody's an optimist.'" if flags.get("whiskey_given", false) else "Lefty: 'Whiskey's ten bucks. The regular has the remote. Or help with my bowling-night promotion and I'll vouch for you backstage. Choose a topic.'"
		"patron":
			if flags.get("whiskey_given", false): return "The regular raises his whiskey. 'Thanks, pal. That remote's yours. Let the big fellow have his bowling; he's a terrible loser.'"
			_note("The regular at Lefty's will trade his TV remote for a $10 whiskey from the bartender.")
			return "The regular: 'Whiskey, pal? I'll trade you this remote. My relationship with channel six has become unhealthy.'"
		"bouncer":
			if flags.get("backstage_social", false): return "Bouncer: 'Lefty vouched for you. You're on the list, collar and all. Head backstage.'"
			if flags.get("password_known", false): return _say_password(PASSWORD)
			if flags.get("tv_distracted", false):
				_note("The bouncer is watching bowling; he still needs the backstage password. Restroom graffiti may help.")
				return "Bouncer: 'Thanks for the bowling. Still need the password, pal. Try the restroom graffiti.'"
			_note("Lefty's bouncer needs the backstage password and wants to watch the bowling finals on channel six.")
			return "Bouncer: 'Password first. And if anyone finds the remote, the finals are on channel six.'"
		"cashier": return _recovery_grant()
		"dancer":
			if flags.get("phone_called", false):
				if not flags.get("didi_message_delivered", false):
					flags["didi_message_delivered"] = true
					_note("Passed along the stage manager's dance invitation. Didi says the opening's setup is ready, thanks to {player}; she will arrange the dance herself.")
					return "You pass on the stage manager's dance invitation. Didi laughs. 'He can have the next one. I'll tell him myself. The opening has its setup, thanks to you. Go enjoy your night, handsome.'"
				return "Didi: 'The show's ready, the manager gets his dance, and your name's in the thank-yous. Those small lights I promised? Consider them lit.'"
			if not flags.get("dancer_met", false):
				flags["dancer_met"] = true
				_award("dancer_met", "Met Didi, a stage designer. Her cabaret can use costume jewelry, flowers, chocolates and a dance, OR a willing assistant who follows her rehearsal cue.")
				return "Didi: 'Nice suit. Is the rest of the wedding missing? My opening needs either costume ring, flowers, chocolates and a dance rehearsal, OR a willing assistant. Choose a topic: bring props or volunteer for the cue. Both pay in applause.'"
			if _help_ready():
				return _share_number()
			if _all_gifts(): return "Didi: 'The props are perfect. Now how about that dance, handsome? That part's just for us.'"
			var missing: Array[String] = []
			if not flags.get("gift_ring", false): missing.append("a costume ring")
			if not flags.get("gift_flowers", false): missing.append("flowers")
			if not flags.get("gift_candy", false): missing.append("chocolates")
			return "Didi: 'Still needed for the show: %s. %s'" % [", ".join(missing), "Thanks for the props you've brought!" if missing.size() < 3 else "The dance? That part's just for us, handsome."]
		"clerk":
			if _coffee_delivered(): return "Clerk: 'The receptionist got her coffee? Good. I like a customer who finishes a delivery.'"
			if inventory.has("coffee"): return "Clerk: 'Your espresso's ready. The hotel receptionist will appreciate it while it's hot.'"
			_note("The hotel receptionist likes Quik-E-Mart's deluxe espresso. Its voucher waits at the service window above Lefty's.")
			return "Clerk: 'Wine is twelve. Deluxe espresso takes a voucher from the service window above Lefty's. The night receptionist loves it.'"
		"busker":
			if flags.get("wine_given", false): return "Busker: 'Wine's packed, and the knife's yours. One bottle for the picnic, one for my next act. Ask about the solo, if you dare.'"
			_note("The alley busker will trade his spare pocket knife for a $12 bottle of wine from Quik-E-Mart.")
			return "Busker: 'Bring me a red for my picnic and the spare knife is yours. Got a date after this set. Yes, even blues musicians get lucky.'"
		"receptionist":
			if completed: return "Receptionist: 'Sunrise survived. I'd call that a successful night. Thanks for helping the crew, {player}.'"
			if flags.get("penthouse_access", false): return "Receptionist: 'Thanks again! You're invited upstairs. {finale} hosts the rooftop gathering. The garden equipment is available to guests.'"
			if flags.get("manager_intro", false): return "Receptionist: 'The stage manager mentioned a helper. You must be the collar he described. Tell me your name and I'll put it on {finale}'s list.' Choose the introduction."
			if inventory.has("coffee"): return "Receptionist: 'Is that a deluxe espresso? If that's for me, hand it over before I answer this stapler.'"
			_note("The hotel receptionist likes Quik-E-Mart's deluxe espresso. Its voucher waits at the service window above Lefty's.")
			return "Receptionist: 'The deluxe espresso from Quik-E-Mart would make this shift human. Its voucher is at Lefty's service window. We're having friends upstairs later.'"
		"eve":
			if completed: return ending_text() + " THE END."
			if flags.get("apple_given", false):
				if flags.get("eve_choices_used", false): return "{finale} makes room on the chaise. 'Tell me what kind of evening you want, {player}.' Choose a story, ask a question, or decide how the night ends."
				if not flags.get("eve_story_shared", false): return _eve_story()
				if not flags.get("eve_heard", false): return _eve_gardens()
				return _finish_evening("ending_flirt")
			if flags.get("eve_met", false) and dialogue_options("eve").is_empty():
				if inventory.has("apple"): return "{finale} glances at the apple. 'You brought breakfast. Is that for sharing?' Offer the fresh apple from your pockets."
				if flags.get("apple_grown", false): return "{finale}: 'My planter only makes one apple. It deserves an audience, preferably a hungry one.' Take the ripe apple from Moonlight Garden and bring it back."
				if flags.get("seeds_planted", false): return "{finale}: 'Seeds in? Then it just needs water. There's a pitcher in the penthouse cabinet, and a loan stool in the garden for reaching it. Finally, a use for something with sensible legs.'"
				if inventory.has("seeds"): return "{finale}: 'Those apple seeds go in the garden planter. The newspaper explains the controls; then add water. I'll save you a chair with room for your collar.'"
				_note(SEED_SOURCE_CLUE)
				return "{finale}: 'For the apple, start with a core from the Service Alley bin lid. Take it and use it to separate the seeds. The newspaper explains the planter; seeds and water do the rest. I'll be here, conducting rigorous hunger research.'"
			flags["eve_met"] = true
			_note("{finale} missed dinner and asked for something fresh. The hotel's instant-fruit planter could provide an apple.")
			return "{finale}: '{player}, is it? That's quite a suit. Does it come with landing lights?' A smile. 'I missed dinner while building that garden experiment. An apple would be lovely, but tell me about yourself while we wait.' Choose a topic, or explore the garden."

	return "It offers no conversational opening. {player} recognizes the feeling."


func _all_gifts() -> bool:
	return flags.get("gift_ring", false) and flags.get("gift_flowers", false) and flags.get("gift_candy", false)


func _help_ready() -> bool:
	return flags.get("rehearsal_done", false) or (_all_gifts() and flags.get("danced", false))


func _coffee_delivered() -> bool:
	return flags.get("coffee_delivered", false) or flags.get("spent_coffee", false)


func _observe_room() -> void:
	# These are visible discoveries, never a walkthrough derived from hidden gates.
	var leads := {
		"street": "On the Neon Strip: free newspapers and a flower cart selling $10 bouquets.",
		"bathroom": "In Lefty's restroom: wall graffiti and a FREE COSTUME JEWELRY dish beside the basin.",
		"backroom": "In the Backstage Lounge: promotional chocolates and a damaged fire escape with a sturdy railing.",
		"casino": "At the Lucky Chip Casino: a complimentary Studio 69 pass in a clean ashtray.",
		"disco": "At Studio 69: Didi, a wall telephone, rehearsal marks on the floor, and a spare rope beside the booth.",
		"alley": "In the Service Alley: an apple core on a bin lid and a loaner rubber mallet on the maintenance rack.",
		"garden": "In Moonlight Garden: an experimental planter and a folding stool on the loan rack.",
		"penthouse": "In the Penthouse: a water pitcher in a high cabinet and a working kitchenette sink."
	}
	if leads.has(room):
		var key := "observed_" + room
		if not flags.get(key, false):
			flags[key] = true
			_note(leads[room])
	if room == "backroom" and not flags.get("dancer_met", false): _note(DIDI_REHEARSAL_CLUE)


func get_dialogue_target() -> String:
	return _dialogue_target


func dialogue_options(target: String = "") -> Array:
	var options := _dialogue_options_raw(target)
	for option in options: option.label = present(option.label)
	return options


func _dialogue_options_raw(target: String = "") -> Array:
	var key := _dialogue_target if target.is_empty() else _resolve_target(target)
	if key.is_empty() or not _valid_target(key): return []
	var options: Array = []
	if DATE_IDS.has(key): return _date_options(key)
	match key:
		"bartender":
			if not inventory.has("whiskey") and not flags.get("spent_whiskey", false): options.append({"id": "buy_whiskey", "label": "Buy a whiskey miniature · $10"})
			if not flags.get("backstage_social", false):
				if not flags.get("promotion_brief", false): options.append({"id": "promotion_brief", "label": "Ask how to help with bowling night"})
				else:
					options.append({"id": "promotion_regular", "label": "Name the regular as the prize winner"})
					options.append({"id": "promotion_larry", "label": "Claim the prize for my magnificent collar"})
					options.append({"id": "promotion_bouncer", "label": "Nominate the bouncer: he looks like a winner"})
			else: options.append({"id": "lefty_callback", "label": "Ask how the bowling promotion went"})
		"patron":
			options.append({"id": "regular_ticket", "label": "Ask about the ticket tucked in his collar"})
		"bouncer":
			if flags.get("backstage_social", false): options.append({"id": "bouncer_social", "label": "Enjoy being on an actual guest list"})
		"dancer", "dancefloor":
			if not flags.get("dancer_met", false): return []
			if flags.get("show_started", false) and not flags.get("show_completed", false):
				return [{"id": "show_next", "label": "Continue Didi's performance"}, {"id": "skip_show", "label": "Skip to the curtain call"}]
			if not _help_ready():
				if not flags.get("rehearsal_started", false): options.append({"id": "rehearsal_start", "label": "Volunteer as Didi's hilariously unqualified assistant"})
				else:
					options.append({"id": "rehearsal_correct", "label": "On AUDIT: stand on the X and shout WRITE IT OFF!"})
					options.append({"id": "rehearsal_wrong", "label": "On AUDIT: propose marriage to the accountant"})
				options.append({"id": "didi_props", "label": "Ask which props the elaborate version still needs"})
			if not flags.get("danced", false):
				options.append({"id": "dance_confident", "label": "Dance with catastrophic confidence"})
				options.append({"id": "dance_careful", "label": "Dance carefully: protect the deposit"})
				options.append({"id": "dance_copy", "label": "Let Didi lead and copy her steps"})
			if _help_ready():
				if not flags.get("show_completed", false): options.append({"id": "show_start", "label": "Watch Didi's Accountants of Desire"})
				else: options.append({"id": "didi_encore", "label": "Ask what happens after the applause"})
		"phone":
			if flags.get("phone_called", false):
				if not flags.get("manager_setup", false): options.append({"id": "manager_setup", "label": "Discuss Didi's show with the stage manager"})
				elif not flags.get("manager_intro", false): options.append({"id": "manager_intro", "label": "Ask for an introduction at the hotel"})
		"receptionist":
			if flags.get("manager_intro", false) and not flags.get("penthouse_access", false): options.append({"id": "hotel_introduction", "label": "Introduce myself as Didi's cabaret helper"})
			if inventory.has("coffee"): options.append({"id": "offer_coffee", "label": "Offer the espresso: no strings, just caffeine"})
		"busker":
			if flags.get("wine_given", false): options.append({"id": "busker_callback", "label": "Ask how the wine bottle fits into his act"})
		"eve":
			if not flags.get("eve_met", false) or completed: return []
			if not flags.get("eve_story_shared", false):
				options.append({"id": "eve_story", "label": "Tell {finale} what actually happened tonight"})
				options.append({"id": "eve_boast", "label": "Claim to be an international leisure consultant"})
			if not flags.get("eve_heard", false): options.append({"id": "eve_gardens", "label": "Ask {finale} about the garden experiment"})
			elif not flags.get("eve_followup", false): options.append({"id": "eve_followup", "label": "Ask what {finale} would grow if nobody were judging"})
			if not flags.get("eve_dinner", false): options.append({"id": "eve_dinner", "label": "Ask how a party host managed to miss dinner"})
			if not flags.get("cultivar_named", false): options.append({"id": "cultivar_midlife", "label": "Name the apple variety Midlife Crisps"})
			if flags.get("apple_given", false) and flags.get("eve_story_shared", false) and flags.get("eve_heard", false):
				options.append({"id": "ending_flirt", "label": "Ask {finale} to get laid: a private sunrise for two"})
				options.append({"id": "ending_friends", "label": "Stay friends for now · keep the night open"})
				options.append({"id": "ending_afterparty", "label": "Suggest Didi's after-party · decide later"})
	return options


func choose_dialogue(id: String) -> String:
	return present(_choose_dialogue_text(id))


func _choose_dialogue_text(id: String) -> String:
	# A stale/unknown option cannot execute, alter a save, or award a milestone.
	var available := false
	for option in dialogue_options():
		if option.id == id: available = true
	if not available: return "That conversation has moved on. TALK to someone here to see the current choices."
	turns += 1
	if id.begins_with("date_"): return _choose_date(id)
	if id.begins_with("eve_") or id == "cultivar_midlife": flags["eve_choices_used"] = true
	match id:
		"buy_whiskey": return _buy("whiskey", 10)
		"promotion_brief":
			flags["promotion_brief"] = true
			_note("Lefty needs the bowling promotion's advertised prize matched to its winning customer. The bar's promotion board and the regular's collar ticket are visible clues.")
			return "Lefty: 'I've got a golden bowling-pin keyring and three men claiming they've scored. Check the promotion board and the customers' tickets. Find the real winner and I'll put you on the backstage list.'"
		"regular_ticket":
			flags["winner_known"] = true
			_note("The regular at Lefty's wears ticket 37 in his collar. He says losing it would be his first bad split tonight.")
			return "He unfolds ticket 37 from his collar. 'Closest thing to a gold medal I've worn. Including my wedding ring.'"
		"promotion_regular":
			if not flags.get("prize_known", false) or not flags.get("winner_known", false): return "Lefty: 'Evidence, detective. Read the promotion board and check the regular's ticket. This is bowling, not a confidence trick with shoes.'"
			flags["backstage_social"] = true
			_award("promotion_solved", "Matched winning ticket 37 to the regular. Lefty vouched for {player} at the backstage door.")
			_note(DIDI_REHEARSAL_CLUE)
			return "You match ticket 37 to the regular. Lefty hands him the golden pin. 'You're my guest backstage. Didi could use a reliable fellow like you: she's rehearsing at Studio 69. Grab a complimentary pass from the casino's clean ashtray and talk to her.' The regular kisses his prize. 'At last, a relationship with a reliable release.'"
		"promotion_larry": return "Lefty: 'That collar could shelter a bowling team. It still isn't a winning ticket.' Nobody loses anything except a little air from {player}'s chest."
		"promotion_bouncer": return "The bouncer unfolds his empty pockets. 'I don't compete. I supervise disappointment.' Lefty suggests checking the printed ticket."
		"lefty_callback": return "Lefty: 'He calls that golden pin his little trophy wife. She's already asked for a separate keyring. Good work, {player}.'"
		"bouncer_social": return "Bouncer: 'Lefty's guest. First person tonight admitted on merit.' {player} straightens that collar. 'Do we get a stamp?' 'Let's not ruin the moment.'"
		"rehearsal_start":
			flags["rehearsal_started"] = true
			flags["cue_known"] = true
			_note("Didi's simple rehearsal: {player} stands on the taped X; when Didi calls AUDIT, you answer WRITE IT OFF. Props are an alternate elaborate version, not mandatory gifts.")
			return "Didi: 'Two versions: props for the big romantic swindle, or you as my assistant. Stand on the taped X. When I shout AUDIT, you shout WRITE IT OFF. No talent required. That's why I thought of you.'"
		"rehearsal_wrong": return "{player} kneels. Didi raises an imaginary ledger. 'An engagement is a long-term liability, darling. Try the cue: AUDIT gets WRITE IT OFF.' She helps you up; the role is still yours."
		"rehearsal_correct":
			flags["rehearsal_done"] = true
			_award("rehearsal_done", "Played Didi's assistant: answered AUDIT with WRITE IT OFF. Her cabaret can run with {player} instead of the three props.")
			return "'AUDIT!' 'WRITE IT OFF!' Didi snaps the ledger shut on your tie. 'Excellent. You look financially exposed.' The imaginary audience loses its imaginary minds. " + _share_number()
		"didi_props": return _didi_missing_props()
		"dance_confident", "dance_careful", "dance_copy":
			flags[id] = true
			return _dance()
		"show_start":
			flags["show_started"] = true
			_note("Attended Didi's Accountants of Desire. {player}'s earlier help became part of the act.")
			return "The house lights dim. Didi strides onto Studio 69's tiny stage with a ledger. 'Ladies, gentlemen, and deductible dependents: welcome to THE ACCOUNTANTS OF DESIRE. Keep your receipts. Some of you will want a refund.'"
		"show_next":
			if not flags.get("show_beat_1", false):
				flags["show_beat_1"] = true
				return "Didi points to your taped X. 'AUDIT!' You shout 'WRITE IT OFF!' She shuts her ledger on your tie. 'At last: someone who can be held accountable.' Your trousers file for an extension." if flags.get("rehearsal_done", false) else "Didi slips on your costume ring. 'He said he wanted a lifelong commitment. I offered quarterly installments.' She tosses your bouquet at an imaginary creditor and pays him in chocolates. Romance has never looked so solvent."
			if not flags.get("show_beat_2", false):
				flags["show_beat_2"] = true
				return "The regular waves his golden-pin keyring from the back: 'STRIKE!' Didi points to him. 'Sir, that's not a pickup line. That's your employment history.' Even the bouncer applauds; Lefty's promotion has acquired a health warning." if flags.get("backstage_social", false) else "Lefty's bowling broadcast booms through an open door: 'A seven-ten split!' Didi does a double take. 'My last divorce had the same score.' The bouncer forgets the television long enough to laugh. Your remote work finally has cultural value."
			flags["show_completed"] = true
			_note("Didi's curtain call paid off {player}'s backstage approach and the rehearsal help. She invited you to the after-show gathering.")
			return "Didi takes your hand for the bow. 'My assistant, {player}: depreciating gracefully.' The applause is real. She squeezes your fingers. 'We're gathering after the show. Bring a friend. Or a whole personality, if you find one.'"
		"skip_show":
			flags["show_completed"] = true
			flags["show_skipped"] = true
			_note("Skipped to Didi's curtain call. She thanked {player} for helping and invited you to the after-show gathering.")
			return "You catch the curtain call and a flying ledger. Didi thanks you for the help. 'After-show gathering later. Bring a friend. Preferably one with a better tie.' The invitation and every puzzle remain yours."
		"didi_encore": return "Didi: 'After the applause? We count the till, steal the remaining chocolates, and argue about art. Come back with a friend. Yours is the collar everyone can hide under.'"
		"manager_setup":
			flags["manager_setup"] = true
			_note("The stage manager knows the hotel receptionist. After discussing Didi's completed setup, {player} can ask him for an introduction.")
			return "Stage manager: 'Didi says you saved the setup. Props or pratfalls, a show needs someone who follows through. I know the hotel night receptionist; we're meeting on {finale}'s roof after the show. Need an introduction?'"
		"manager_intro":
			flags["manager_intro"] = true
			_note("Didi's stage manager put in a word with the Hotel Lobby receptionist. Introduce yourself there as the cabaret helper; no coffee delivery is required.")
			return "Stage manager: 'I've called the hotel. Tell the receptionist you're Didi's cabaret helper. Try not to describe yourself as the entertainment package. That costs extra.'"
		"hotel_introduction":
			flags["penthouse_access"] = true
			flags["hotel_social"] = true
			_award("hotel_introduction", "The receptionist welcomed Didi's cabaret helper upstairs after the stage manager's introduction.")
			return "Receptionist: 'The manager called. Apparently you can follow a cue without taking your trousers off. An uncommon reference in this town.' She adds you to {finale}'s list. 'The elevator's yours. Coffee later is welcome, never compulsory.'"
		"offer_coffee": return _use_item("coffee", "receptionist")
		"busker_callback":
			flags["busker_encore"] = true
			return "The busker blows across the empty prop bottle: one tender, ridiculous note. 'My solo's called Chateau Inadequate.' {player}: 'I've stayed there.' 'Pal, you had a suite.'"
		"eve_story": return _eve_story()
		"eve_boast":
			flags["eve_boasted"] = true
			flags["eve_story_shared"] = true
			_note("Claimed to be an international leisure consultant; admitted to {finale} that {player} was mostly consulting a map. {finale} appreciated the correction.")
			return "{player}: 'I'm an international leisure consultant.' {finale}: 'And tonight's findings?' 'Mostly that I need better shoes.' {finale} laughs. 'There you are. I wondered when you would catch up with the suit.'"
		"eve_gardens": return _eve_gardens()
		"eve_followup":
			flags["eve_followup"] = true
			_note("{finale} would grow a crooked old apple tree with no demonstration schedule. The host misses making things that can take their time.")
			return "{finale}: 'A crooked apple tree. Nothing instant. Somewhere to sit while it takes its time.' {player} loosens that collar. 'I may have been overdressed for agriculture.' 'You're learning.'"
		"eve_dinner":
			flags["eve_dinner"] = true
			return "{finale}: 'Fed the guests, checked the lights, demonstrated the fruit machine. Forgot the host.' {player}: 'A scandal. I shall form a committee.' 'One apple will do, chairperson.'"
		"cultivar_midlife":
			flags["cultivar_named"] = true
			flags["cultivar_midlife"] = true
			_note("{finale} and {player} named the experimental apple Midlife Crisps: a little late to blossom, surprisingly sweet.")
			return "'Midlife Crisps,' you suggest. {finale} considers it. 'Late to blossom. Excessive packaging. Surprisingly sweet.' 'Are we still talking apples?' 'For now.'"
		"ending_flirt", "ending_friends", "ending_afterparty": return _finish_evening(id)
	return "The conversation settles into a comfortable pause."


func _didi_missing_props() -> String:
	var missing: Array[String] = []
	if not flags.get("gift_ring", false): missing.append("a costume ring")
	if not flags.get("gift_flowers", false): missing.append("flowers")
	if not flags.get("gift_candy", false): missing.append("chocolates")
	if missing.is_empty(): return "Didi: 'All three props are here. A dance will shake the rehearsal nerves out.'"
	return "Didi: 'The elaborate version still needs %s. Or volunteer for the rehearsal: a willing idiot is theatre's most renewable resource.'" % ", ".join(missing)


func _eve_story() -> String:
	flags["eve_story_shared"] = true
	_note("Told {finale} about the evening without turning Didi into a conquest. {finale} liked that you could laugh at yourself.")
	if flags.get("rehearsal_done", false): return "{player}: 'I played a cabaret assistant. My tie was audited.' {finale}: 'Did it declare everything?' 'It asked for a private accountant.' {finale} laughs. 'Sounds like you helped someone have a good night.'"
	return "{player}: 'I danced with Didi. My knees filed separate tax returns.' {finale} laughs. 'And she kept dancing? Then your night was better than you think.' TALK again to listen, or choose another topic."


func _eve_gardens() -> String:
	flags["eve_heard"] = true
	_note("{finale} designs hotel gardens. The instant-fruit experiment fed the guests; its creator missed dinner.")
	_note(SEED_SOURCE_CLUE)
	return "{finale}: 'I design these gardens. My fruit planter takes seeds from apple cores. The staff leave clean cores on the Service Alley bin lid: take one and use it to separate the seeds.' {player}: 'So breakfast begins in an alley?' 'That's recycling, not your dating history. The newspaper explains the planter's controls.'"


func _finish_evening(tone: String) -> String:
	if completed: return ending_text()
	if not flags.get("apple_given", false) or not flags.get("eve_story_shared", false) or not flags.get("eve_heard", false): return "A little conversation before the proposition. Even this collar cannot skip chemistry."
	if tone == "ending_friends":
		flags["eve_choices_used"] = true
		flags["ending_friends"] = true
		_note("Chose friendly company with {finale} for now. The night stays open; a private invitation can wait.")
		return "'No pressure,' you say. {finale} smiles. 'Good. This chaise has enough of that from your collar.' You stay friends for now. TALK whenever you want to revisit the invitation; the evening continues."
	if tone == "ending_afterparty":
		flags["eve_choices_used"] = true
		flags["ending_afterparty"] = true
		_note("Suggested Didi's after-party to {finale}. You both agreed to decide after a little more rooftop time.")
		return "'Didi's throwing an after-party,' you say. {finale}: 'Lovely. Let's decide after a little more time up here.' The party can wait, and so can any proposition. You remain on the roof; the evening continues."
	if tone != "ending_flirt" or not is_eligible_partner("eve"): return "That invitation is unavailable."
	flags["ending_flirt"] = true
	flags["encounter_eve"] = true
	completed = true
	_award("ending", "Got laid with {finale}. Private company and a collar mercifully left outside.")
	_pending_encounter = {"partner": "eve", "name": finale_name(), "gender": finale_gender(), "title": "DO NOT DISTURB · THE GRAND FINALE", "caption": present("{finale}: 'Yes. Come with me. The collar can get its own room.' The door closes. Later: {player} and {finale} got laid. The city survived; the hairstyle may need professional help."), "finale": true}
	return ending_text() + " THE END. You can keep exploring or start a different evening."


func ending_title() -> String:
	return "YOU GOT LAID"


func ending_text() -> String:
	return present("'Want a private sunrise for two?' you ask. {finale} grins. 'Yes. Come with me. And leave the sales pitch with the collar.' The door closes; the neon tactfully looks away. Later: {player} and {finale} got laid. Two delighted adults, one spectacularly rumpled suit, and absolutely no dignity left in the hairdo. Mission accomplished.")


func epilogue() -> String:
	return present(_epilogue_text())


func _epilogue_text() -> String:
	var callbacks: Array[String] = []
	callbacks.append("Lefty's winner still wears the golden pin; the bouncer now checks tickets before biceps." if flags.get("backstage_social", false) else "The bouncer missed the final bowling score while applauding the cabaret. He blames channel six.")
	callbacks.append("Didi bills you as The {player_Person} Who Could Be Written Off. Your tie is considering representation." if flags.get("rehearsal_done", false) else "Didi's ring, flowers, and chocolates earn a standing ovation. The props demand a bigger dressing room.")
	callbacks.append("At the hotel, your name remains on the guest list under Useful Human, an unexpected promotion." if flags.get("hotel_social", false) else "The receptionist remembers the espresso. The service window has never opened so easily.")
	if flags.get("eve_boasted", false): callbacks.append("{finale} lists your new profession as Regional Honesty Consultant. The territory is small but growing.")
	if flags.get("cultivar_midlife", false): callbacks.append("Midlife Crisps becomes the hotel's official apple. The label says: Better late than leathery.")
	return "\n\n".join(callbacks)


func item_status(id: String) -> String:
	match id:
		"newspaper": return "souvenir" if flags.get("newspaper_read", false) else "active"
		"remote": return "souvenir" if flags.get("tv_distracted", false) else "active"
		"pass": return "souvenir" if flags.get("dancer_met", false) else "active"
		"knife": return "souvenir" if flags.get("rope_taken", false) else "active"
		"hammer": return "souvenir" if flags.get("window_open", false) else "active"
		"pitcher": return "souvenir" if flags.get("apple_grown", false) else "active"
	return "active"


func hint_level(level: int) -> String:
	return present(_hint_level_text(level))


func _hint_level_text(level: int) -> String:
	if level >= 2: return hint()
	if completed: return "Your evening is complete. The notebook remembers how your choices shaped it."
	if not is_unlocked("backroom"):
		return "Lefty's door has two routes: his bouncer's interests, or the bowling-night promotion." if level == 0 else "Ask Lefty about the promotion and compare the board with the regular's ticket; alternatively investigate the restroom and the TV remote."
	if not inventory.has("pass"):
		return "The casino gives something away besides optimism." if level == 0 else "Look around the casino's clean ashtray for entry to Studio 69."
	if not _help_ready():
		return "Didi needs help putting on a show. Props and a willing performer are two different answers." if level == 0 else "Talk to Didi: either bring the three requested props and dance, or volunteer and listen to the rehearsal cue."
	if not flags.get("phone_called", false):
		return "Didi mentioned someone who handles the practical side of the theatre." if level == 0 else "Her stage manager's number is in your notebook; Studio 69 has a wall phone."
	if not flags.get("penthouse_access", false):
		return "The hotel receptionist knows the stage crew and enjoys good coffee." if level == 0 else "Ask the stage manager about Didi's setup and an introduction, or follow the service-window voucher lead for a coffee favor."
	if not flags.get("eve_met", false):
		return "An invitation is only useful if you meet the host." if level == 0 else "Take the penthouse stairs to {finale}'s Rooftop and introduce yourself."
	if not flags.get("apple_given", false):
		return "{finale} missed dinner while building a very peculiar garden. Your earlier discoveries can help." if level == 0 else "The newspaper describes seeds and water. Check the alley's core, the garden's loan stool, and the penthouse's cabinet and sink."
	return "An honest story and a little listening beat a rehearsed line." if level == 0 else "Choose a story about your evening and ask about {finale}'s gardens. When you both want it, ask for a private sunrise for two."


func _share_number() -> String:
	flags["phone_known"] = true
	_note("Didi shared her stage manager's number: 555-0987. Call from the disco phone about the spare rope or a hotel introduction.")
	_note("Didi invited {player} to watch her show now or later, and to bring a friend to the after-show gathering.")
	return "Didi: 'Sweet, funny, and wonderfully overdressed. Call my stage manager at 555-0987 about the spare rope or a hotel introduction. Stay for the show if you like. Bring a friend to our after-show gathering; your help deserves a curtain call.'"


func _dance() -> String:
	if room != "disco": return "This is not the dance floor. The city thanks you for checking."
	_dialogue_target = "dancer"
	if not flags.get("dancer_met", false): return "You almost launch into a solo. Introduce yourself to Didi first; this move needs a witness."
	if flags.get("danced", false): return "You reprise The Nervous Accountant. The floor files no complaint."
	flags["danced"] = true
	_award("danced", "Danced with Didi. Neither of you will win a trophy; both had fun.")
	if _all_gifts(): return "Your enthusiastic shuffle earns a laugh. " + _share_number()
	if flags.get("dance_confident", false): return "You attempt a pelvic punctuation mark that should require planning permission. Didi catches your elbow. 'Love the confidence. Let's get the rest of you in time.' She laughs with you, then steals the move."
	if flags.get("dance_careful", false): return "You count the steps like they owe you money. Didi leans close. 'Nobody's grading your hips.' You loosen up; the dance improves immediately. Your accountant remains concerned."
	if flags.get("dance_copy", false): return "You let Didi lead. Left, turn, gloriously unnecessary shoulder. 'Good listener,' she says. You try not to look surprised that this works better than explaining disco to her."
	return "Didi takes your hand. 'Show me what those trousers can do.' Your signature move resembles a printer jam. She laughs and pulls you into the beat."


func _use_item(held: String, target: String) -> String:
	match held:
		"whiskey":
			if target == "patron":
				_consume(held)
				_give("remote")
				flags["whiskey_given"] = true
				_award("whiskey_given", "Traded a whiskey for the regular's TV remote.")
				return "The regular lifts the whiskey in a toast and hands you the remote. 'Channel six. Bowling. The pins fall for me, at least.'"
		"remote":
			if target == "television":
				if flags.get("tv_distracted", false): return "The bowling is already on. The bouncer is emotionally committed to frame seven."
				flags["tv_distracted"] = true
				_award("tv_distracted", "Tuned the television to bowling. The bouncer is happily distracted.")
				return "You select channel six. The bouncer gasps at a seven-ten split. " + ("Lefty already vouched for you; head backstage." if flags.get("backstage_social", false) else "He has your password; head backstage." if flags.get("password_spoken", false) else "Provide the password and the backstage door is yours.")
		"ring", "flowers", "candy":
			if target == "dancer":
				if not flags.get("dancer_met", false): return "Didi lifts an eyebrow. 'Usually I get a name before the presents, mystery collar.' Talk to her."
				_consume(held)
				flags["gift_" + held] = true
				_award(held + "_given", "Gave Didi %s for her cabaret opening." % str(items[held].name).to_lower())
				if _all_gifts() and flags.get("danced", false): return "Didi accepts the final prop with a grin. " + _share_number()
				return "Didi takes the %s with a smile. 'Perfect for the show. Keep this up and I'll put your name in lights. Small lights. Don't get cocky.'" % str(items[held].name).to_lower()
		"wine":
			if target == "busker":
				_consume(held)
				_give("knife")
				flags["wine_given"] = true
				_award("wine_given", "Traded the busker wine for his spare stagecraft knife.")
				return "The busker packs the wine for his picnic and gives you his spare pocket knife. 'For cord. Not critics.'"
		"knife":
			if target == "rigging":
				if flags.get("rope_taken", false): return "You already have the spare rope. The remaining rigging has a job."
				if not flags.get("phone_called", false): return "The coil's tag says RESERVED. Didi's stage manager can clear that up over the phone."
				flags["rope_taken"] = true
				_give("rope")
				_award("rope_taken", "The stage manager cleared the spare coil. Cut its packaging cord and collected the rope.")
				return "A quick snip through the packaging cord frees the rope. You coil it neatly, looking almost like someone with useful skills."
			if target == "core": return _extract_seeds()
		"core":
			if target == "core" or target == "bin": return _extract_seeds()
		"rope":
			if target == "railing":
				_consume(held)
				flags["rope_anchored"] = true
				journal.append("Tied the rope to the backstage railing. The fire escape is accessible.")
				return "You knot the rope around the railing and give it a tug. It holds. The fire escape beckons; your trousers request that you take your time."
		"hammer":
			if target == "window":
				if flags.get("window_open", false): return "The service window is open. The mallet has nothing more to prove."
				flags["window_open"] = true
				_award("window_open", "Tapped the stuck service window open and found the night-shift espresso voucher.")
				return "One neat tap frees the frame. The window slides open with a sigh more encouraging than anything you've heard all night. An espresso voucher waits inside."
		"voucher":
			if target in ["espresso", "clerk"]:
				_consume(held)
				_give("coffee")
				return "The machine accepts the voucher and produces a deluxe espresso. Hot, rich, and ready to go. Three qualities you've been advertising all evening."
		"coffee":
			if target == "receptionist":
				var already_invited: bool = flags.get("penthouse_access", false)
				_consume(held)
				flags["penthouse_access"] = true
				flags["coffee_delivered"] = true
				_award("coffee_given", "Brought the receptionist an espresso. She invited you to the rooftop gathering.")
				if already_invited: return "She inhales the aroma. 'You're already on the guest list, {player}. This is just considerate.' She raises the cup. 'Look at you, exceeding expectations without an expense account.'"
				return "She inhales the aroma. 'Someone who delivers. How refreshing.' She adds your name to the guest list. 'Join us upstairs. {finale} is hosting.' The elevator unlocks."
		"stool":
			if target == "cabinet":
				_consume(held)
				flags["stool_placed"] = true
				return "You unfold the stool beneath the cabinet. The pitcher is now within easy reach. A victory for sensible furniture."
		"pitcher":
			if target == "sink": return _fill_pitcher()
			if target in ["planter", "tree"]:
				if flags.get("apple_grown", false): return "The tree is thriving. It politely declines a second origin story."
				if not flags.get("seeds_planted", false): return "Plant apple seeds before watering. Otherwise you are merely making expensive mud."
				if not flags.get("pitcher_filled", false): return "The pitcher is empty. Fill it at the penthouse sink."
				flags["pitcher_filled"] = false
				flags["apple_grown"] = true
				_award("apple_grown", "Watered the experimental planter. A miniature tree produced one perfect apple.")
				return "You add water. The planter hums, shudders, and grows a tiny apple tree in seconds. Somewhere a botanist spills their coffee. Take the apple."
		"seeds":
			if target == "planter":
				if not flags.get("newspaper_read", false): return "The controls are baffling. Read the free newspaper's review of this instant-fruit planter first."
				_consume(held)
				flags["seeds_planted"] = true
				_award("seed_planted", "Planted the apple seeds using the newspaper's instructions. Just add water.")
				return "Following the newspaper, you place the seeds in the starter tray. Now add a pitcher of water."
		"apple":
			if target == "eve":
				if not flags.get("eve_met", false): return "You hover with an apple in your hand. This opening could use a little polish. Talk to {finale} first."
				_consume(held)
				flags["apple_given"] = true
				return "'An apple for {finale}?' Your host laughs. 'Bold of you to open with temptation.' One bite, then a pat on the adjoining chaise. 'Sit, {player}. Tell me something interesting.' Talk again."
	return "Your %s fails to make a connection. It takes the rejection rather better than you usually do." % str(items.get(held, {"name": held}).name).to_lower()


func _extract_seeds() -> String:
	if not inventory.has("core"):
		return "Take the apple core first."
	_consume("core")
	_give("seeds")
	flags["seeds_found"] = true
	_award("seeds_taken", "Separated viable apple seeds from the discarded core.")
	return "You separate three seeds from the core and recycle the rest. Tiny agricultural ambitions enter your pocket."


func _fill_pitcher() -> String:
	if room != "penthouse": return "The clean water tap is in the penthouse kitchenette."
	if not inventory.has("pitcher"): return "You need the pitcher from the high cabinet. A stool would make it reachable."
	if flags.get("pitcher_filled", false): return "The pitcher is already full. {player} has found a capacity for something useful."
	flags["pitcher_filled"] = true
	return "You fill the pitcher and turn the tap off. The garden planter is ready for its close-up."


func _say_password(value: String) -> String:
	if room != "bar": return "Only the backstage bouncer needs the password. Elsewhere it is merely an anatomical announcement."
	if value.to_lower().strip_edges() != PASSWORD: return "The bouncer shakes his head. The restroom graffiti might improve your vocabulary."
	if flags.get("password_spoken", false): return "The bouncer remembers your password. " + ("Head backstage." if flags.get("tv_distracted", false) else "Now if only the bowling were on television...")
	flags["password_spoken"] = true
	_award("password_spoken", "Gave the bouncer the backstage password.")
	return "'Bellybutton,' you say with improbable confidence. The password checks out. " + ("The bowling has his attention; head backstage." if flags.get("tv_distracted", false) else "He mentions missing the bowling on channel six.")


func _manager_followup() -> String:
	if flags.get("manager_intro", false): return "The hotel receptionist has your name. Tell her you're Didi's cabaret helper."
	if flags.get("manager_setup", false): return "If you want that hotel introduction, just ask."
	return "I can hear about Didi's setup before the next cue."


func _call(number: String) -> String:
	if room != "disco": return "The usable telephone is on Studio 69's wall."
	_dialogue_target = "phone"
	if not flags.get("phone_known", false): return "Didi has not shared the stage manager's number yet. Help with her show and ask her."
	if number.replace("-", "").replace(" ", "") != PHONE_NUMBER: return "That number reaches a recording about extended hovercraft warranties. Try the number Didi gave you."
	if flags.get("phone_called", false):
		if flags.get("rope_taken", false): return "Stage manager: 'You've got the rope. Thanks for helping Didi. " + _manager_followup() + "'"
		return "Stage manager: 'Yes, the spare coil is yours. Cut the packaging cord. " + _manager_followup() + "'"
	flags["phone_called"] = true
	_award("phone_called", "Called 555-0987. Didi's stage manager cleared the spare rope for you.")
	return "'Didi sent you? Lucky devil. Take the spare rope; a small knife will cut the packaging cord. Tell her I expect a dance at the opening. Ask me about the show's setup if you want an introduction at the hotel.'"


func _recovery_grant() -> String:
	if cash >= 10: return "Cashier: 'Below ten bucks? I'll stake you twenty. Until then, try the demo slots: same four-spin cycle every time. Occasionally the house forgets its manners.'"
	cash += 20
	return "The cashier slides you twenty. 'We call it customer retention. You can call it a comeback.' Balance: $%d." % cash


func _play_slots() -> String:
	if cash < 5: return "You need $5 to run the demonstration. Ask the cashier for the recovery grant."
	var spin: int = int(flags.get("slot_spins", 0))
	var payouts: Array[int] = [0, 15, 0, 25]
	var payout := payouts[spin % payouts.size()]
	cash = cash - 5 + payout
	flags["slot_spins"] = spin + 1
	_award("slots_played", "Tried the casino's demonstration slots. Learned the payout cycle before the carpet could hypnotize you.")
	return "The demo reels display %s. Stake: $5. Payout: $%d. Wallet: $%d. The cycle is always $0 / $15 / $0 / $25." % ["CHERRY · CHERRY · COLLAR" if payout > 0 else "LEMON · COLLAR · TAX AUDIT", payout, cash]


func objective() -> String:
	return present(_objective_text())


func _objective_text() -> String:
	if completed: return "Evening complete: %s. Keep exploring for optional discoveries, or try different choices next time." % ending_title().to_lower()
	if not is_unlocked("backroom"):
		if flags.get("promotion_brief", false): return "Match Lefty's bowling prize to its winning customer, or solve the bouncer's password and TV problem."
		if flags.get("tv_distracted", false): return "Bowling is on. Find and give the bouncer the backstage password."
		if flags.get("password_spoken", false): return "The password is accepted. Put bowling on Lefty's TV."
		return "Get laid with {finale}. First, get backstage: investigate the bouncer's interests or ask Lefty about his bowling promotion."
	if not inventory.has("pass"): return "Find a complimentary Studio 69 pass at the casino."
	if not flags.get("dancer_met", false): return "Meet Didi in Studio 69 and ask what her show needs."
	if not _help_ready():
		if flags.get("rehearsal_started", false): return "Rehearse Didi's cue: choose your response to AUDIT."
		var remaining: Array[String] = []
		if not flags.get("gift_ring", false): remaining.append("ring")
		if not flags.get("gift_flowers", false): remaining.append("flowers")
		if not flags.get("gift_candy", false): remaining.append("chocolates")
		if not flags.get("danced", false): remaining.append("dance")
		return "Help Didi: %s still needed for the props route. Or volunteer for her rehearsal." % ", ".join(remaining)
	if not flags.get("phone_called", false): return "Call Didi's stage manager from the disco phone. " + ("Her curtain-call invitation is in your notebook." if flags.get("show_completed", false) else "You can watch her show now or later.")
	if not flags.get("penthouse_access", false):
		if inventory.has("coffee"): return "Bring the espresso to the hotel receptionist."
		if flags.get("manager_intro", false): return "Introduce yourself to the hotel receptionist as Didi's cabaret helper."
		if flags.get("manager_setup", false): return "Ask the stage manager for a hotel introduction, or continue the coffee favor."
		if not flags.get("rope_taken", false):
			if inventory.has("knife"): return "Cut the spare stage rope at Studio 69 with your pocket knife, or ask the stage manager for a hotel introduction."
			return "For the hotel: ask the stage manager about an introduction, or get a knife for the spare rope and coffee-voucher route."
		if not flags.get("rope_anchored", false): return "Tie the stage rope to Lefty's backstage railing, or ask the manager for a hotel introduction."
		if not flags.get("window_open", false): return "Use a rubber mallet to free the fire escape's service window."
		if not flags.get("taken_voucher", false): return "Take the espresso voucher from the open service window."
		return "Redeem the voucher at Quik-E-Mart's espresso machine."
	if flags.get("apple_grown", false) and not flags.get("taken_apple", false): return "Take the ripe apple from the garden's miniature tree."
	if not flags.get("eve_met", false): return "Join the rooftop gathering and introduce yourself to {finale}."
	if not flags.get("apple_grown", false): return "Grow a fresh apple in the hotel's experimental garden planter. You can chat with {finale} first."
	if not flags.get("apple_given", false): return "Bring {finale} the fresh apple on the rooftop."
	if flags.get("eve_heard", false) and flags.get("eve_story_shared", false): return "Get laid with {finale}: ask for a private sunrise for two, or keep things friendly for now."
	if flags.get("eve_story_shared", false): return "Ask about {finale}'s gardens. Give your host a turn to tell a story."
	return "Share a story about your evening with {finale}."


func hint() -> String:
	return present(_hint_text())


func _hint_text() -> String:
	if completed: return "You finished! %d / %d exploration points. The remaining props, coffee favor, and casino demo are optional discoveries." % [score, max_score]
	if not is_unlocked("backroom"):
		if flags.get("promotion_brief", false): return "LOOK at the bowling-night promotion and TALK to the regular about his ticket. TALK to Lefty and name the regular as the winner. Alternatively finish the password/TV route."
		if not flags.get("whiskey_given", false):
			if inventory.has("whiskey"): return "Give the whiskey to the regular at Lefty's for his remote. Or TALK to Lefty about his bowling promotion for another route."
			return "TALK to Lefty and choose Buy whiskey for $10, then give it to the regular. Or choose his bowling promotion, inspect its board and the regular's ticket, and identify the regular."
		if not flags.get("tv_distracted", false): return "Use the TV remote on Lefty's television. The bouncer loves channel six."
		if not flags.get("password_known", false): return "Visit Lefty's restroom and LOOK at the graffiti."
		return "TALK to the bouncer after reading the graffiti, or type BELLYBUTTON in the bar."
	if not inventory.has("pass"): return "Take the Studio 69 pass from the casino's clean ashtray."
	if not flags.get("dancer_met", false): return "Enter Studio 69 and TALK to Didi."
	if not _help_ready():
		if flags.get("rehearsal_started", false): return "TALK to Didi and choose: On AUDIT, stand on the X and shout WRITE IT OFF."
		if not flags.get("taken_candy", false): return "Either TALK to Didi and volunteer for rehearsal, or collect the costume ring in Lefty's restroom, candy backstage, and $10 flowers on the Strip, then give them to Didi and dance."
		if not flags.get("gift_ring", false): return "Take the free costume ring beside Lefty's restroom basin and give it to Didi. Or volunteer for her rehearsal instead."
		if not flags.get("gift_candy", false): return "Use the promotional candy on Didi. Or volunteer for her rehearsal instead."
		if not flags.get("gift_flowers", false): return "Buy a $10 bouquet at the Strip's flower cart, then give it to Didi. Or volunteer for her rehearsal instead."
		return "USE the dance floor or choose a dance style with Didi."
	if not flags.get("phone_called", false): return "Use the Studio 69 phone or CALL 555-0987. The stage manager can release rope and arrange a hotel introduction."
	if not flags.get("penthouse_access", false):
		if flags.get("manager_intro", false): return "TALK to the hotel receptionist and choose Introduce myself as Didi's cabaret helper."
		if inventory.has("coffee"): return "Give the espresso to the hotel receptionist. She will invite you upstairs."
		if inventory.has("voucher"): return "Use the espresso voucher on Quik-E-Mart's coffee machine."
		if not flags.get("rope_taken", false): return "For a social route, USE the phone, discuss Didi's setup, and ask for a hotel introduction. For the coffee caper, trade $12 wine to the alley busker for his knife, then use it on the disco's spare rope."
		if not flags.get("rope_anchored", false): return "Use the stage rope on the railing in Lefty's backstage lounge."
		if not inventory.has("hammer"): return "Take the loaner rubber mallet from the Service Alley."
		if not flags.get("window_open", false): return "Go from the backstage lounge to the Fire Escape. Use the rubber mallet on the sticking window."
		return "Take the espresso voucher inside the open service window."
	if flags.get("apple_grown", false) and not flags.get("taken_apple", false): return "TAKE the apple from the miniature tree in the garden."
	if not flags.get("eve_met", false): return "Go through the penthouse to the rooftop and TALK to {finale}. Find out what your host would enjoy before planning a grand gesture."
	if not flags.get("newspaper_read", false): return "Take the free newspaper on the Strip, then LOOK at it in your inventory. It explains the instant-fruit planter."
	if not flags.get("seeds_found", false):
		if inventory.has("core"): return "USE the apple core in your inventory to separate its seeds."
		return "Take the apple core from the alley bin lid, then USE it to extract the seeds."
	if not flags.get("seeds_planted", false): return "Use the apple seeds on the hotel's garden planter."
	if not flags.get("stool_placed", false):
		if inventory.has("stool"): return "Use the folding stool on the high penthouse cabinet."
		return "Take the loaner folding stool from the hotel garden."
	if not flags.get("taken_pitcher", false): return "Take the pitcher from the now-reachable penthouse cabinet."
	if not flags.get("apple_grown", false):
		if not flags.get("pitcher_filled", false): return "Use the pitcher on the penthouse sink to fill it with water."
		return "Use the full pitcher on the garden planter to grow an apple tree."
	if not flags.get("apple_given", false): return "Offer {finale} the fresh apple by using it on your host."
	return "TALK to {finale}. Share a story, ask about the gardens, then ask for a private sunrise for two to finish the evening. Friendship and the party leave that invitation open."


func _resolve_room(value: String) -> String:
	var key := value.strip_edges().to_lower().replace("_", " ")
	var aliases := {"adam's rooftop": "rooftop", "strip": "street", "neon strip": "street", "outside": "street", "lefty's": "bar", "leftys": "bar", "lefty's bar": "bar", "restroom": "bathroom", "bar restroom": "bathroom", "backstage": "backroom", "backstage lounge": "backroom", "lounge": "backroom", "lucky chip": "casino", "lucky chip casino": "casino", "studio 69": "disco", "store": "shop", "quik-e-mart": "shop", "service alley": "alley", "lobby": "hotel", "hotel lobby": "hotel", "fire escape": "balcony", "moonlight garden": "garden", "roof": "rooftop", "eve's rooftop": "rooftop"}
	return str(aliases.get(key, key))


func _resolve_item(value: String) -> String:
	var key := value.strip_edges().to_lower()
	var aliases := {"paper": "newspaper", "bouquet": "flowers", "drink": "whiskey", "whisky": "whiskey", "tv remote": "remote", "controller": "remote", "costume ring": "ring", "chocolates": "candy", "chocolate": "candy", "passcard": "pass", "disco pass": "pass", "bottle": "wine", "pocket knife": "knife", "mallet": "hammer", "rubber mallet": "hammer", "apple core": "core", "apple seeds": "seeds", "safety rope": "rope", "stage rope": "rope", "espresso voucher": "voucher", "espresso": "coffee", "folding stool": "stool", "water": "pitcher", "pitcher of water": "pitcher", "water pitcher": "pitcher", "perfect apple": "apple"}
	if aliases.has(key): return aliases[key]
	for id in items:
		if str(items[id].name).to_lower() == key: return id
	return key


func _resolve_target(value: String) -> String:
	var key := value.strip_edges().to_lower()
	if key.begins_with("the "): key = key.substr(4)
	# Resolve visible labels before item aliases: the espresso machine is not a cup.
	for spot in get_room().hotspots:
		if str(spot.id) == key or str(spot.label).to_lower() == key: return spot.id
	var aliases := {"lefty": "bartender", "drunk": "patron", "regular": "patron", "thirsty regular": "patron", "tv": "television", "wall": "graffiti", "graffiti": "graffiti", "sink basin": "basin", "dish": "basin", "door": "bouncer", "didi": "dancer", "girl": "dancer" if room == "disco" else "eve", "dance floor": "dancefloor", "floor": "dancefloor", "telephone": "phone", "spare rope": "rigging", "stage rope": "rigging" if room == "disco" else "rope", "slot machine": "slots", "slot": "slots", "21": "blackjack", "blackjack": "blackjack", "wine shelf": "wine_shelf", "machine": "espresso" if room == "shop" else "slots", "coffee machine": "espresso", "espresso machine": "espresso", "bum": "busker", "musician": "busker", "garbage": "bin", "trash": "bin", "reception": "receptionist", "service window": "window", "plot": "planter", "bushes": "planter", "apple tree": "tree", "high cabinet": "cabinet", "news": "newsbox", "flower cart": "flowercart", "railing": "railing"}
	if key == finale_name().to_lower(): return "eve"
	for date_id in DATE_IDS:
		if key == str(actor_profile(date_id).name).to_lower(): return date_id
	if aliases.has(key): return aliases[key]
	var item_key := _resolve_item(key)
	if inventory.has(item_key): return item_key
	# Natural commands target the source when an item has not been bought yet.
	if item_key == "flowers" and room == "street": return "flowercart"
	if item_key == "newspaper" and room == "street": return "newsbox"
	if item_key == "whiskey" and room == "bar": return "bartender"
	if item_key == "wine" and room == "shop": return "wine_shelf"
	if item_key == "apple" and room == "garden" and flags.get("apple_grown", false): return "tree"
	if items.has(item_key): return item_key
	return _resolve_room(key)


func command(text: String) -> String:
	return present(_command_text(text))


func _command_text(text: String) -> String:
	var input := text.strip_edges().to_lower()
	if input.is_empty(): return "Try LOOK, TALK TO LEFTY, TAKE NEWSPAPER, USE REMOTE ON TV, GO CASINO, INVENTORY, or HINT."
	if input == PASSWORD: return _say_password(input)
	if input in ["555-0987", "5550987"]: return _call(input)
	if input in ["look", "l", "look around"]:
		_observe_room()
		return str(get_room().description)
	if input in ["inventory", "i", "take inventory"]:
		var names: Array[String] = []
		for id in inventory: names.append(str(items[id].name))
		return "Pockets: %s. Wallet: $%d." % [", ".join(names) if not names.is_empty() else "just lint and ambition", cash]
	if input == "score": return "Score: %d / %d. Actions: %d. Cash: $%d." % [score, max_score, turns, cash]
	if input in ["hint", "help me"]: return hint_level(0)
	if input in ["hint 1", "hint 2", "hint 3"]: return hint_level(int(input.right(1)) - 1)
	if input.begins_with("choose "): return choose_dialogue(input.substr(7))
	if input in ["objective", "quest"]: return objective()
	if input in ["help", "?"]: return "LOOK [thing] · TALK [person] · TAKE [thing] · USE [item] ON [thing] · GIVE [item] TO [person] · GO [exit] · DANCE · CALL [number] · INVENTORY · JOURNAL · HINT · SAVE · LOAD. Click scene targets for the same actions."
	if input in ["journal", "notes"]: return "\n".join(journal)
	if input in ["save", "save game"]: return save_game()
	if input in ["load", "load game", "restore"]: return load_game()
	if input in ["dance", "dance with didi"]: return _dance() if room == "disco" else "Save that move for Studio 69."
	if input.begins_with("call ") or input.begins_with("dial "): return _call(input.substr(5))
	if input.begins_with("say "): return _say_password(input.substr(4))
	if input in ["channel 6", "turn on tv", "turn on television", "watch tv"]: return interact("television", "use")
	if input.begins_with("go ") or input.begins_with("enter ") or input.begins_with("travel "):
		return travel(input.substr(input.find(" ") + 1))
	if input in ["up", "north", "south", "east", "west", "down"]:
		return "Use a named exit such as GO BAR or GO STREET. The exit buttons show the routes from here."
	var space := input.find(" ")
	if space == -1: return "I couldn't place that command. Try HELP for examples, or HINT for your next puzzle."
	var verb := input.substr(0, space)
	var rest := input.substr(space + 1).strip_edges()
	if verb in ["look", "talk"] and (rest.begins_with("at ") or rest.begins_with("to ")): rest = rest.substr(3)
	if verb in ["use", "give", "apply", "water", "plant", "cut", "break", "fill", "unlock"]:
		for separator in [" on ", " to ", " with ", " in "]:
			var pos: int = rest.find(separator)
			if pos != -1:
				var first := rest.substr(0, pos)
				var second := rest.substr(pos + separator.length())
				if separator == " with " or verb in ["cut", "break", "unlock"]: return interact(first, "use", second)
				return interact(second, "use", first)
		if verb == "fill": return interact("sink", "use", rest)
		if verb == "water": return interact(rest, "use", "pitcher")
		if verb == "plant": return interact("planter", "use", rest)
		return interact(rest, "use")
	if verb in ["look", "read", "examine", "inspect", "talk", "take", "get", "buy", "order", "open", "climb", "play"]:
		return interact(rest, verb)
	return "{player} tries to parse that and wrinkles a forehead. Try HELP for examples."


func save_game(path: String = "user://savegame.json") -> String:
	var file := FileAccess.open(path, FileAccess.WRITE)
	if file == null: return "Could not save the game: %s." % error_string(FileAccess.get_open_error())
	file.store_string(JSON.stringify({"version": SAVE_VERSION, "profile": profile, "room": room, "inventory": inventory, "flags": flags, "cash": cash, "score": score, "turns": turns, "completed": completed, "journal": journal}, "\t"))
	file.close()
	return "Game saved. Even your questionable decisions deserve a backup."


func load_game(path: String = "user://savegame.json") -> String:
	if not FileAccess.file_exists(path): return "No saved game found yet. Use SAVE after making a little progress."
	var file := FileAccess.open(path, FileAccess.READ)
	if file == null: return "Could not read the save file. Your current evening is unchanged."
	var parser := JSON.new()
	var parse_error := parser.parse(file.get_as_text())
	file.close()
	if parse_error != OK: return "That save file is unreadable. Your current evening is unchanged."
	var parsed: Variant = parser.data
	if not parsed is Dictionary: return "That save file is unreadable. Your current evening is unchanged."
	var data: Dictionary = parsed
	if int(data.get("version", -1)) not in [1, SAVE_VERSION] or not rooms.has(data.get("room", "")):
		return "That save belongs to an incompatible adventure. Your current evening is unchanged."
	if not data.get("inventory") is Array or not data.get("flags") is Dictionary or not data.get("journal") is Array:
		return "That save is incomplete. Your current evening is unchanged."
	for id in data.inventory:
		if not id is String or not items.has(id): return "That save has an unknown item. Your current evening is unchanged."
	for entry in data.journal:
		if not entry is String: return "That save has an invalid journal. Your current evening is unchanged."
	for key in data.flags:
		if not key is String: return "That save has invalid progress flags. Your current evening is unchanged."
		if key == "slot_spins":
			if not (data.flags[key] is int or data.flags[key] is float): return "That save has an invalid casino counter. Your current evening is unchanged."
		elif not data.flags[key] is bool:
			return "That save has invalid progress flags. Your current evening is unchanged."
	for key in ["cash", "score", "turns"]:
		if not (data.get(key) is int or data.get(key) is float): return "That save has invalid numbers. Your current evening is unchanged."
	if not data.get("completed") is bool: return "That save has an invalid ending. Your current evening is unchanged."
	var saved_profile: Variant = data.get("profile", {"character": "larry", "orientation": "bisexual"} if int(data.version) == 1 else {})
	if not saved_profile is Dictionary or saved_profile.get("character") not in ["larry", "lisa"] or saved_profile.get("orientation") not in ["bisexual", "heterosexual", "homosexual"]:
		return "That save has an invalid character profile. Your current evening is unchanged."
	if int(data.version) == SAVE_VERSION and data.completed and not data.flags.get("encounter_eve", false):
		return "That save has an invalid ending. Your current evening is unchanged."
	profile = {"character": saved_profile.character, "orientation": saved_profile.orientation}
	_refresh_profile_content()
	room = data.room
	inventory.clear()
	for id in data.inventory:
		if not inventory.has(id): inventory.append(id)
	flags = data.flags.duplicate(true)
	if flags.has("slot_spins"): flags.slot_spins = maxi(0, int(flags.slot_spins))
	cash = maxi(0, int(data.cash))
	score = clampi(int(data.score), 0, max_score)
	turns = maxi(0, int(data.turns))
	completed = data.completed
	# Legacy endings did not depict the new finale; reopen it without deleting progress or points.
	if int(data.version) == 1 and completed:
		completed = false
		flags["eve_choices_used"] = true
	journal.assign(data.journal)
	_pending_encounter.clear()
	_dialogue_target = ""
	return "Game restored. Your suit is exactly as you left it, for better or worse."


func _date_clue(id: String) -> String:
	flags["date_clue_" + id] = true
	var clue: String = {
		"lounge_date": "The dressing-screen care tag reads: PRIVACY LATCH — TURN THE RHINESTONE. THE FEATHER IS DECORATIVE. Repair manual, or the world's most disappointing striptease?",
		"casino_date": "The magician's napkin says: MY MISSING FINALE IS THE SUIT THAT BEATS WITHOUT A PULSE: HEARTS. Underneath: Never palm a collar. It bites back.",
		"garden_date": "The lantern card reads: MOONLIGHT PORTRAITS — AMBER FILTER. WHITE FLOODLIGHTS ARE FOR INTERROGATIONS AND FAILED FIRST DATES."
	}[id]
	_note(actor_profile(id).name + "'s puzzle clue: " + clue)
	return clue + " TALK to " + actor_profile(id).name + " and suggest the fix."


func _date_talk(id: String) -> String:
	_dialogue_target = id
	var person := actor_profile(id)
	if not is_eligible_partner(id): return person.name + ": 'Good company, no sparks. Nothing wrong with that.'"
	if flags.get("encounter_" + id, false):
		return person.name + ": 'That was a lovely detour. Let's keep the good memory; your grand rooftop adventure still awaits.' Your collar flutters with remembered embarrassment."
	flags["date_met_" + id] = true
	if flags.get("date_invited_" + id, false): return person.name + ": 'My invitation stands, if you still fancy it. Or we can keep talking with all this perfectly serviceable clothing on.' Choose whether to accept."
	if flags.get("date_solved_" + id, false): return person.name + ": 'You listened and made me laugh. Dangerous combination in a suit like that.' That eyebrow is practically sending semaphore."
	var setup: String = {
		"lounge_date": "'I'm Velvet, after my favorite fabric. This dressing screen won't stay closed; the care tag knows its secret. Fix the latch before the whole bar sees my emergency sequins.'",
		"casino_date": "'I do close-up magic. Tonight the final card disappeared from my memory, which is rude. My lucky napkin has the clue. Help me finish the trick?'",
		"garden_date": "'I'm trying to take a flattering night portrait, not interrogate the rhododendrons. The lantern has two settings. Its instruction card should rescue my lighting.'"
	}[id]
	if id == "lounge_date": setup = "'I make the cabaret costumes. This dressing screen won't stay closed; the care tag knows its secret. Fix the latch before the whole bar sees my emergency sequins.'"
	_note(person.name + " has an optional puzzle in " + present(str(rooms[room].name)) + ". Examine " + {"lounge_date": "the dressing-screen tag", "casino_date": "the lucky napkin", "garden_date": "the lantern instruction card"}[id] + ", then TALK again.")
	return person.name + ": " + setup + " Choose a topic, or LOOK at the clue nearby."


func _date_options(id: String) -> Array:
	if not flags.get("date_met_" + id, false) or not is_eligible_partner(id): return []
	if flags.get("encounter_" + id, false): return [{"id": "date_remember_" + id, "label": "Share a fond, thoroughly unprintable in-joke"}]
	if flags.get("date_invited_" + id, false):
		return [{"id": "date_accept_" + id, "label": "Yes — let’s get laid"}, {"id": "date_decline_" + id, "label": "Rain check — keep it friendly"}]
	if flags.get("date_solved_" + id, false): return [{"id": "date_flirt_" + id, "label": "Flirt: ask whether the attraction is mutual"}, {"id": "date_decline_" + id, "label": "Enjoy the company and leave it there"}]
	return [{"id": "date_solve_" + id, "label": {"lounge_date": "Turn the dressing-screen rhinestone latch", "casino_date": "Suggest the hearts card for the finale", "garden_date": "Set the portrait lantern to amber"}[id]}, {"id": "date_wrong_" + id, "label": {"lounge_date": "Yank the decorative feather with confidence", "casino_date": "Suggest a collar: the fifth suit", "garden_date": "Try the white interrogation floodlight"}[id]}, {"id": "date_clue_" + id, "label": "Ask where to find the puzzle clue"}]


func _choose_date(choice: String) -> String:
	var id := ""
	for candidate in DATE_IDS:
		if choice.ends_with("_" + candidate): id = candidate
	if id.is_empty() or DATE_ROOMS[id] != room or not is_eligible_partner(id): return "That invitation is unavailable."
	var person := actor_profile(id)
	if choice.begins_with("date_clue_"): return person.name + ": 'LOOK at " + {"lounge_date": "the dressing-screen tag", "casino_date": "the lucky napkin", "garden_date": "the lantern instruction card"}[id] + ". Then tell me your idea.'"
	if choice.begins_with("date_wrong_"):
		return person.name + ": 'Beautiful confidence. Entirely wrong answer. Read the clue before either of us needs a repair bill.' Nothing is broken; try again."
	if choice.begins_with("date_solve_"):
		if not flags.get("date_clue_" + id, false): return person.name + ": 'Show me where you got that idea. LOOK at the clue first; I like confidence with footnotes.'"
		flags["date_solved_" + id] = true
		_note("Helped " + person.name + ": " + {"lounge_date": "the dressing-screen latch now stays shut", "casino_date": "the missing hearts card completes the trick", "garden_date": "amber light makes the portrait work"}[id] + ". The repair worked; that smile might be a separate invitation.")
		return person.name + ": " + {"lounge_date": "'It closes! My sequins can keep their scandal private. You're rather good with a tiny, clearly labeled problem.'", "casino_date": "'Hearts! Of course.' The card reappears in your collar. 'My, you have storage. And a surprisingly attractive attention span.'", "garden_date": "'Amber. Gorgeous.' A portrait appears: flattering light, outrageous lapels. 'Would you like a copy, or shall we skip straight to questioning your tailor?'"}[id] + " Choose whether to flirt."
	if choice.begins_with("date_flirt_"):
		flags["date_invited_" + id] = true
		_note(person.name + " returned your flirtation and offered a private fling. Accept or decline; either choice is welcome.")
		return "You: 'Is this flirting, or have I overdosed on aftershave?' " + person.name + ": 'Definitely flirting. I'd like to get laid with you. I've got a private room and dreadful wallpaper. Care to help me ignore it?' Apparently your collar has finally made a useful introduction."
	if choice.begins_with("date_decline_"):
		flags.erase("date_invited_" + id)
		_note("Kept things friendly with " + person.name + ". No penalty, no debt, and the conversation remains open.")
		return person.name + ": 'Lovely meeting you. No hard feelings; those trousers do enough of that.' You stay friends. If your mood changes, a fresh flirtation can reopen the invitation."
	if choice.begins_with("date_accept_"):
		flags["encounter_" + id] = true
		flags.erase("date_invited_" + id)
		var title: String = {"lounge_date": "BEHIND THE VELVET CURTAIN", "casino_date": "THE DISAPPEARING SUIT", "garden_date": "EXPOSURE: STRICTLY PRIVATE"}[id]
		var aftermath: String = {"lounge_date": "The repaired screen closes. Later, two pleased adults reappear. A feather has applied for witness protection.", "casino_date": "You both slip into the magician's guest suite. Later, the suit reappears with one inexplicable playing card. The magician refuses to reveal the trick.", "garden_date": "You head to the photographer's private guest room. Later, two smiling adults return. Your portrait has better composure than your collar."}[id]
		var caption := present("You and %s got laid. %s Your final goal is still a night with {finale}." % [person.name, aftermath])
		_note("Shared a private fling with " + person.name + ". A happy detour; the rooftop goal remains.")
		_pending_encounter = {"partner": id, "name": person.name, "gender": person.gender, "title": title, "caption": caption, "finale": false}
		return person.name + ": 'Yes. Come with me.' " + caption
	return person.name + ": 'Our little secret. That collar, however, is everybody's business.'"
