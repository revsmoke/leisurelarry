extends RefCounted
## The entire adventure lives here, independent of scenes or rendering.
## Every irreversible trade has a renewable source or a permanent reward.

const SAVE_VERSION := 1
const max_score := 100
const PASSWORD := "bellybutton"
const PHONE_NUMBER := "5550987"

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
	journal.assign(["Find a little connection before sunrise. Your white suit has already done enough networking."])


func _spot(id: String, label: String, x: float, y: float, kind: String = "object") -> Dictionary:
	return {"id": id, "label": label, "x": x, "y": y, "kind": kind}


func _add_room(id: String, title: String, subtitle: String, description: String, background: String, hotspots: Array, exits: Array) -> void:
	var exit_data: Array = []
	for destination in exits:
		exit_data.append({"id": destination, "label": _room_label(destination)})
	rooms[id] = {"name": title, "subtitle": subtitle, "description": description, "background": background, "hotspots": hotspots, "exits": exit_data}


func _room_label(id: String) -> String:
	return {"street": "Neon Strip", "bar": "Lefty's Bar", "bathroom": "Bar Restroom", "backroom": "Backstage Lounge", "casino": "Lucky Chip Casino", "disco": "Studio 69", "shop": "Quik-E-Mart", "alley": "Service Alley", "hotel": "Hotel Lobby", "balcony": "Fire Escape", "garden": "Moonlight Garden", "penthouse": "Penthouse", "rooftop": "Eve's Rooftop"}.get(id, id.capitalize())


func _build_content() -> void:
	items = {
		"newspaper": {"name": "Newspaper", "description": "The Lost Wages Bugle. Front page: INSTANT APPLES! The hotel garden's experimental planter turns seeds and water into fruit. Science declined to comment."},
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
		"apple": {"name": "Perfect apple", "description": "An absurdly perfect apple, grown by dubious science and honest effort. Eve might appreciate the joke."}
	}
	_add_room("street", "The Neon Strip", "LOST WAGES · 11:47 PM", "Pink neon, palm trees, and a city that charges extra for sincerity. A free newspaper and a flower cart offer a promising start.", "street", [
		_spot("newsbox", "Free newspaper", 0.17, 0.72), _spot("flowercart", "Flower cart · $10", 0.70, 0.72), _spot("taxi", "Taxi stand", 0.85, 0.72)
	], ["bar", "casino", "disco", "shop", "alley", "hotel"])
	_add_room("bar", "Lefty's Bar", "HAPPY HOUR IS A STATE OF DENIAL", "A bartender polishes the same glass history forgot. A thirsty regular guards a remote; a bouncer guards the backstage door. The television is losing an argument with static.", "bar", [
		_spot("bartender", "Lefty · whiskey $10", 0.26, 0.46, "person"), _spot("patron", "Thirsty regular", 0.52, 0.64, "person"), _spot("television", "Television", 0.89, 0.22), _spot("bouncer", "Backstage bouncer", 0.84, 0.55, "person")
	], ["street", "bathroom", "backroom"])
	_add_room("bathroom", "The Restroom", "THE WRITING IS LITERALLY ON THE WALL", "Avocado tile, optimistic plumbing, and graffiti with unusually good information security. A dish beside the basin offers free costume jewelry.", "bathroom", [
		_spot("graffiti", "Wall graffiti", 0.35, 0.38), _spot("basin", "Basin & jewelry dish", 0.23, 0.57), _spot("ring", "Costume ring", 0.25, 0.65)
	], ["bar"])
	_add_room("backroom", "Backstage Lounge", "THE FEATHERS GET THEIR OWN DRESSING ROOM", "The cabaret is between shows. Chocolates wait on a table, outnumbered by feathers. The fire escape has lost a step; a rope tied to the railing could bridge the gap.", "backroom", [
		_spot("candy", "Promotional candy", 0.72, 0.83), _spot("railing", "Safety railing", 0.57, 0.28), _spot("poster", "Cabaret poster", 0.64, 0.14)
	], ["bar", "balcony"])
	_add_room("casino", "The Lucky Chip", "YOUR LUCK HAS A COVER CHARGE", "Chrome, carpet, and the sound of wallets clearing their throats. A disco pass rests in a clean ashtray. The cashier offers a little comeback cash if your luck gets too personal.", "casino", [
		_spot("slots", "Demonstration slots · $5", 0.23, 0.49), _spot("blackjack", "Blackjack table", 0.88, 0.56), _spot("cashier", "Casino cashier", 0.54, 0.46, "person"), _spot("ashtray", "Clean ashtray", 0.77, 0.61), _spot("pass", "Studio 69 pass", 0.71, 0.69)
	], ["street", "hotel"])
	_add_room("disco", "Studio 69", "THE BEAT IS HOT. THE COLLAR IS HOTTER.", "The bass line has a mortgage. Didi, a stage designer off the clock and on the beat, catches your eye. A wall phone and a tied coil of spare stage rope flank the DJ booth.", "disco", [
		_spot("dancer", "Didi · stage designer", 0.52, 0.59, "person"), _spot("dancefloor", "Dance floor", 0.34, 0.72), _spot("phone", "Wall telephone", 0.82, 0.34), _spot("rigging", "Spare stage rope", 0.16, 0.35)
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
		_spot("planter", "Experimental planter", 0.49, 0.65), _spot("stool", "Loaner folding stool", 0.35, 0.68), _spot("tree", "Miniature apple tree", 0.49, 0.40)
	], ["hotel"])
	_add_room("penthouse", "The Penthouse", "SOMEONE ELSE'S GOOD TASTE", "The receptionist's invitation gets you into the shared rooftop lounge. A water pitcher waits in a cabinet well above collar height. A sink and the roof stairs complete the picture.", "penthouse", [
		_spot("cabinet", "High cabinet", 0.90, 0.14), _spot("pitcher", "Water pitcher", 0.94, 0.04), _spot("sink", "Kitchenette sink", 0.74, 0.38), _spot("terrace_sign", "Rooftop gathering sign", 0.50, 0.4)
	], ["hotel", "rooftop"])
	_add_room("rooftop", "Eve's Rooftop", "THE CITY FINALLY LOWERS ITS VOICE", "The pool reflects a pink horizon. Eve, tonight's host, has escaped her own party for a moment by the water. She notices you trying to look like a man who belongs on a rooftop.", "rooftop", [
		_spot("eve", "Eve · rooftop host", 0.66, 0.56, "person"), _spot("pool", "Moonlit pool", 0.69, 0.70), _spot("skyline", "Lost Wages skyline", 0.43, 0.22)
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
		visible.append(hotspot)
	result.hotspots = visible
	for destination in result.exits:
		destination["locked"] = not is_unlocked(destination.id)
	result["id"] = chosen
	return result


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
			return "The cabaret is between shows. %s %s" % [candy, escape]
		"casino":
			return "Chrome, carpet, and the sound of wallets clearing their throats. " + ("The clean ashtray is empty now that you have the disco pass." if flags.get("taken_pass", false) else "A disco pass rests in a clean ashtray.") + " The cashier offers comeback cash if your luck gets too personal."
		"disco":
			var didi := "Didi has her opening-night props and greets you with a grin." if _all_gifts() else "Didi, a stage designer off the clock and on the beat, catches your eye."
			var rope := "You have collected the spare coil; the remaining stage rigging is in use." if flags.get("rope_taken", false) else "A tied coil of spare rope hangs beside the DJ booth."
			return "The bass line has a mortgage. %s A wall phone connects to the stage crew. %s" % [didi, rope]
		"alley":
			var busker := "The busker's picnic wine is packed; he plays you a grateful blues riff." if flags.get("wine_given", false) else "A busker finishes a blues number that sounds suspiciously like your last date."
			var core := "The bin lid is clear after you collected the apple core." if flags.get("taken_core", false) else "An apple core sits on a bin lid."
			var mallet := "The loan rack has an empty mallet hook." if flags.get("taken_hammer", false) else "A maintenance rack holds a rubber mallet."
			return "%s %s %s" % [busker, core, mallet]
		"hotel":
			if flags.get("penthouse_access", false): return "The receptionist sips your espresso between phone calls. Your name is on Eve's guest list; the penthouse elevator is open to you. The garden is down the hall."
		"balcony":
			if flags.get("window_open", false):
				return "Your rope spans the missing step. The service window is open. " + ("You collected the night-shift voucher from its sill." if flags.get("taken_voucher", false) else "The espresso voucher on its sill is now within reach. Take it.")
		"garden":
			var planter := "The experimental planter awaits seeds and water; the newspaper has its instructions."
			if flags.get("seeds_planted", false): planter = "Your seeds are in the planter's starter tray, waiting for water."
			if flags.get("apple_grown", false): planter = "The experimental planter holds a miniature tree with one perfect apple."
			if flags.get("taken_apple", false): planter = "Your miniature tree is thriving. You have picked its one perfect apple."
			return "Moonlight shines on the garden. " + planter + (" The stool's place on the loan rack is empty." if flags.get("taken_stool", false) else "A folding stool waits on the equipment loan rack.")
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
		result.append(entry)
	return result


func is_unlocked(destination: String) -> bool:
	if not rooms.has(destination):
		return false
	match destination:
		"backroom": return flags.get("password_spoken", false) and flags.get("tv_distracted", false)
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
	turns += 1
	return _room_description(room)


func _note(entry: String) -> void:
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
	if action == "look":
		return _look(key)
	for destination in rooms[room].exits:
		if destination.id == key:
			return travel(key)
	turns += 1
	if action == "talk":
		return _talk(key)
	if action == "take" and not verb.strip_edges().to_lower() in ["buy", "order"]:
		if key in ["bartender", "patron", "bouncer", "cashier", "dancer", "clerk", "busker", "receptionist", "eve"]:
			return "Lefty stays behind his bar. USE him to buy the $10 whiskey, or type BUY WHISKEY." if key == "bartender" else "People are not pocket-sized favors. TALK to them, or USE an item to offer it."
		if key in ["television", "dancefloor", "phone", "railing", "window", "espresso", "elevator", "cabinet", "sink", "planter", "slots", "blackjack"]:
			return "That belongs here. LOOK for a clue, or USE it. Your pockets have limits after all."
	if not held.is_empty():
		return _use_item(held, key)
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
			if flags.get("password_known", false): return _say_password(PASSWORD)
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
			if inventory.has("seeds"): return _use_item("seeds", "planter")
			if inventory.has("pitcher"): return _use_item("pitcher", "planter")
			return "The instant-fruit planter needs seeds, then water. Read the newspaper for operating instructions."
		"tree":
			if flags.get("taken_apple", false): return "The tree has completed its contractual obligation. One perfect apple per adventure."
			return _take("apple")
		"newspaper": return _look("newspaper")
		"taxi": return "The driver points out that every main venue is a short walk from the Strip. You keep your fare and a little dignity."
	return "That does not need doing. A rare bargain in this city."


func _look(key: String) -> String:
	if inventory.has(key) and items.has(key):
		if key == "newspaper":
			flags["newspaper_read"] = true
			_award("newspaper_read", "The Bugle explains the garden's instant-fruit planter: plant seeds, then add water.")
		if key == "pitcher":
			return "The pitcher is full of water. The experimental garden planter awaits." if flags.get("pitcher_filled", false) else str(items.pitcher.description)
		return str(items[key].description)
	match key:
		"newsbox": return "Free papers. Today's headline: INSTANT APPLES COME TO HOTEL GARDEN. Take a copy, then read it."
		"flowercart": return "Locally grown flowers, $10. Cash into slot; bouquet out. Romance has discovered vending machines."
		"taxi": return "A helpful sign says: EVERYTHING IS WALKABLE. The taxi driver is taking this personally."
		"bartender": return "Lefty polishes a glass and nods at your satisfied trading partner." if flags.get("whiskey_given", false) else "Lefty sells whiskey miniatures for $10. The regular next to him is watching the bottle like it owes him dinner."
		"patron":
			if flags.get("whiskey_given", false): return "The regular cradles his whiskey. You have his remote; this relationship appears healthier for everyone."
			_note("The regular at Lefty's will trade his TV remote for a $10 whiskey from the bartender.")
			return "The regular clutches a TV remote like a tiny plastic soulmate. A whiskey might persuade him to play the field."
		"television": return "Championship bowling is on channel 6. The bouncer is emotionally committed to frame seven." if flags.get("tv_distracted", false) else "Channel 6 carries championship bowling. The bouncer's shirt says ASK ME ABOUT MY SPLIT."
		"bouncer": return "He has accepted your password and is absorbed in the bowling. Head backstage." if is_unlocked("backroom") else "The bouncer checks passwords and dreams of televised bowling. Two separate obstacles, one substantial person."
		"graffiti":
			flags["password_known"] = true
			_award("graffiti_read", "Restroom graffiti reveals the backstage password: BELLYBUTTON.")
			return "Between two questionable poems: 'BACKSTAGE PASSWORD: BELLYBUTTON.' You commit it to your least crowded brain cell."
		"basin": return "The FREE COSTUME JEWELRY dish is empty. You collected its plastic ruby ring." if flags.get("taken_ring", false) else "Beside the basin, a dish reads FREE COSTUME JEWELRY. A plastic ruby ring catches the fluorescent light."
		"ring", "candy", "pass", "hammer", "core", "stool", "voucher", "pitcher": return str(items[key].description)
		"railing": return "Your rope is securely knotted around the railing. The fire escape is accessible." if flags.get("rope_anchored", false) else "A sturdy railing beside the damaged fire escape. Tie a rope here to get across the gap."
		"poster":
			if _all_gifts(): return "THE ACCOUNTANTS OF DESIRE. Didi's opening now has its costume ring, flowers, and chocolates, thanks to you. Finally, an investment in the arts with visible returns."
			return "Tonight: THE ACCOUNTANTS OF DESIRE. Their books are open. Their expenses are intimate. Their matinee is tax-deductible."
		"blackjack": return "Twenty-one, velvet felt, and a dealer with the expression of an unpaid invoice. Use the table to play blackjack."
		"slots": return "Demo slots cost $5 and pay $0, $15, $0, then $25 in a repeating cycle. The pattern is more reliable than your dating history."
		"cashier": return "The cashier offers a $20 recovery grant whenever your funds fall below $10. Ask or use the desk."
		"ashtray": return "The clean ashtray is empty. You already collected the complimentary disco pass." if flags.get("taken_pass", false) else "This ashtray has been retired from smoking and promoted to brochure storage. Take the complimentary disco pass."
		"dancer": return "Didi recognizes her magnificently overdressed dance partner. Her opening-night props are ready." if _all_gifts() else "Didi is planning her cabaret opening between songs. Talk to her about the props." if flags.get("dancer_met", false) else "Didi designs cabaret sets and wears a smile that suggests she has already redesigned your opening line. Introduce yourself."
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
		"receptionist": return "The receptionist is enjoying the espresso you brought. Your rooftop invitation is on the guest list." if flags.get("penthouse_access", false) else "The receptionist is hosting friends upstairs after her shift. She has clearly earned a coffee break."
		"elevator": return "The penthouse elevator is unlocked for you. Eve's rooftop gathering is upstairs." if flags.get("penthouse_access", false) else "The penthouse elevator needs the receptionist's invitation. Being nice is a promising technology."
		"guestbook": return "Guest comment: 'Good pillows. Unsettlingly fast apples.' Five stars, with reservations."
		"window":
			if flags.get("taken_voucher", false): return "The window is open and its sill is empty. You collected the espresso voucher."
			if flags.get("window_open", false): return "The open window puts the espresso voucher within reach. Take it from the sill."
			return "A coffee voucher waits behind a sticking service window. The note says a gentle rubber-mallet tap will free the frame."
		"planter":
			if flags.get("taken_apple", false): return "The planter supports a healthy little tree. You have picked its single apple; the machine's work is done."
			if flags.get("apple_grown", false): return "Your watered seeds have become a miniature tree. One perfect apple is ready to take."
			if flags.get("seeds_planted", false): return "Your seeds are in the starter tray. Add a pitcher of water to start the growth cycle."
			return "The experimental planter grows a mature apple tree from seeds and water. The local newspaper has the instructions."
		"tree": return "The little tree is healthy but picked clean. You collected its one perfect apple." if flags.get("taken_apple", false) else "A tiny tree holds one perfect apple. Take the apple before science asks for it back."
		"cabinet":
			if flags.get("taken_pitcher", false): return "The cabinet is empty; you collected the water pitcher. The stool stays beneath it for the next short guest."
			if flags.get("stool_placed", false): return "Your folding stool makes the pitcher easy to reach. Take it from the cabinet."
			return "A water pitcher sits in a high cabinet, just beyond the reach of your charms. A folding stool would help."
		"sink": return "Clean tap water. Use the pitcher here, or use the sink while carrying it."
		"terrace_sign": return "ROOFTOP GATHERING — hosted by Eve. Beneath it, someone has added: PLEASE KEEP THE SMALL TALK BELOW THE WATERLINE."
		"eve": return "Eve has the skyline, the moonlight, and a mischievous smile. You have a white suit. Lead with your name."
		"pool": return "The pool is for invited guests. Tonight a conversation is more useful than another damp suit."
		"skyline": return "Lost Wages glows like a jukebox that learned urban planning. Dawn is on its way, at your own pace."
	if rooms.has(key):
		return "Exit to %s. %s" % [rooms[key].name, "The way is open." if is_unlocked(key) else _gate_message(key)]
	return "A perfectly serviceable piece of scenery."


func _talk(key: String) -> String:
	match key:
		"bartender": return "Lefty: 'Good trade. He's got his whiskey, you've got the remote, and I've got ten dollars. Everybody's an optimist.'" if flags.get("whiskey_given", false) else "Lefty: 'Whiskey's ten bucks. The regular has the remote. Restroom wisdom is complimentary.'"
		"patron":
			if flags.get("whiskey_given", false): return "The regular raises his whiskey. 'Thanks, pal. That remote's yours. Let the big fellow have his bowling; he's a terrible loser.'"
			_note("The regular at Lefty's will trade his TV remote for a $10 whiskey from the bartender.")
			return "The regular: 'Whiskey, pal? I'll trade you this remote. My relationship with channel six has become unhealthy.'"
		"bouncer":
			if flags.get("password_known", false): return _say_password(PASSWORD)
			_note("Lefty's bouncer needs the backstage password and wants to watch the bowling finals on channel six.")
			return "Bouncer: 'Password first. And if anyone finds the remote, the finals are on channel six.'"
		"cashier": return _recovery_grant()
		"dancer":
			if flags.get("phone_called", false):
				if not flags.get("didi_message_delivered", false):
					flags["didi_message_delivered"] = true
					_note("Passed along the stage manager's dance invitation. Didi says the opening's props are ready, thanks to Larry; she will arrange the dance herself.")
					return "You pass on the stage manager's dance invitation. Didi laughs. 'He can have the next one. I'll tell him myself. The opening has all its props, thanks to you. Go enjoy your night, handsome.'"
				return "Didi: 'The show's ready, the manager gets his dance, and your name's in the thank-yous. Those small lights I promised? Consider them lit.'"
			if not flags.get("dancer_met", false):
				flags["dancer_met"] = true
				_award("dancer_met", "Met Didi, a stage designer. She needs costume jewelry, flowers, and chocolates for a cabaret opening.")
				return "Didi: 'Nice suit. Is the rest of the wedding missing? I'm dressing a cabaret opening: costume ring, flowers, chocolates... and I could use a dance partner.'"
			if _all_gifts() and flags.get("danced", false):
				return _share_number()
			if _all_gifts(): return "Didi: 'The props are perfect. Now how about that dance, handsome? That part's just for us.'"
			var missing: Array[String] = []
			if not flags.get("gift_ring", false): missing.append("a costume ring")
			if not flags.get("gift_flowers", false): missing.append("flowers")
			if not flags.get("gift_candy", false): missing.append("chocolates")
			return "Didi: 'Still needed for the show: %s. %s'" % [", ".join(missing), "Thanks for the props you've brought!" if missing.size() < 3 else "The dance? That part's just for us, handsome."]
		"clerk":
			if flags.get("penthouse_access", false): return "Clerk: 'The receptionist got her coffee? Good. I like a customer who finishes a delivery.'"
			if inventory.has("coffee"): return "Clerk: 'Your espresso's ready. The hotel receptionist will appreciate it while it's hot.'"
			_note("The hotel receptionist likes Quik-E-Mart's deluxe espresso. Its voucher waits at the service window above Lefty's.")
			return "Clerk: 'Wine is twelve. Deluxe espresso takes a voucher from the service window above Lefty's. The night receptionist loves it.'"
		"busker":
			if flags.get("wine_given", false): return "Busker: 'Wine's packed, and the knife's yours. I'm playing one last number for the gentleman in the heroic trousers. Thanks, pal.'"
			_note("The alley busker will trade his spare pocket knife for a $12 bottle of wine from Quik-E-Mart.")
			return "Busker: 'Bring me a red for my picnic and the spare knife is yours. Got a date after this set. Yes, even blues musicians get lucky.'"
		"receptionist":
			if completed: return "Receptionist: 'Coffee delivered, sunrise survived. I'd call that a successful night. Thanks again, Larry.'"
			if flags.get("penthouse_access", false): return "Receptionist: 'Thanks again! You're invited upstairs. Eve hosts the rooftop gathering. The garden equipment is available to guests.'"
			if inventory.has("coffee"): return "Receptionist: 'Is that a deluxe espresso? If that's for me, hand it over before I answer this stapler.'"
			_note("The hotel receptionist likes Quik-E-Mart's deluxe espresso. Its voucher waits at the service window above Lefty's.")
			return "Receptionist: 'The deluxe espresso from Quik-E-Mart would make this shift human. Its voucher is at Lefty's service window. We're having friends upstairs later.'"
		"eve":
			if completed: return "Eve: 'Stay for sunrise?' You do. For once, the next line can wait. THE END."
			if flags.get("apple_given", false):
				if not flags.get("eve_story_shared", false):
					flags["eve_story_shared"] = true
					_note("Told Eve about the Nervous Accountant dance. She liked that Didi laughed with Larry, not at him.")
					return "Larry: 'I danced with Didi. My knees filed separate tax returns.' Eve laughs. 'And she kept dancing? Then your night was better than you think.' TALK again to listen."
				if not flags.get("eve_heard", false):
					flags["eve_heard"] = true
					_note("Eve designs hotel gardens. Her instant-fruit experiment was supposed to feed guests; she forgot to feed herself.")
					return "Eve: 'I design these gardens. Spent all day on that ridiculous fruit planter, then forgot dinner.' Larry: 'So I brought you your own homework?' 'Best delivery all night.' TALK again."
				completed = true
				_award("ending", "Shared an apple and a laugh with Eve. She invited you to stay for sunrise. The suit finally earned its keep.")
				return "Eve pulls her chair close. 'Stay for sunrise, Larry. I like a man who brings breakfast.' You grin. For once, you have absolutely nothing rehearsed to say. THE END — the night is over. Your luck may be just beginning."
			flags["eve_met"] = true
			_note("Eve missed dinner and asked for something fresh. The hotel's instant-fruit planter could provide an apple.")
			return "Eve: 'Larry, is it? That's quite a suit. Does it come with landing lights?' She smiles. 'I missed dinner. Bring me something fresh, then tell me how your night went.'"
	return "It offers no conversational opening. Larry recognizes the feeling."


func _all_gifts() -> bool:
	return flags.get("gift_ring", false) and flags.get("gift_flowers", false) and flags.get("gift_candy", false)


func _share_number() -> String:
	flags["phone_known"] = true
	_note("Didi shared her stage manager's number: 555-0987. Call from the disco phone about the spare rope.")
	return "Didi: 'Sweet, funny, and wonderfully overdressed. Call my stage manager at 555-0987 about that spare rope. Tell him you're with me. He'll be jealous.'"


func _dance() -> String:
	if room != "disco": return "This is not the dance floor. The city thanks you for checking."
	if not flags.get("dancer_met", false): return "You almost launch into a solo. Introduce yourself to Didi first; this move needs a witness."
	if flags.get("danced", false): return "You reprise The Nervous Accountant. The floor files no complaint."
	flags["danced"] = true
	_award("danced", "Danced with Didi. Neither of you will win a trophy; both had fun.")
	if _all_gifts(): return "Your enthusiastic shuffle earns a laugh. " + _share_number()
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
				return "You select channel six. The bouncer gasps at a seven-ten split. " + ("He has your password; head backstage." if flags.get("password_spoken", false) else "Provide the password and the backstage door is yours.")
		"ring", "flowers", "candy":
			if target == "dancer":
				if not flags.get("dancer_met", false): return "Didi lifts an eyebrow. 'Usually I get a name before the presents, mystery man.' Talk to her."
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
				return "A quick snip through the packaging cord frees the rope. You coil it neatly, looking almost like a man with useful skills."
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
				_consume(held)
				flags["penthouse_access"] = true
				_award("coffee_given", "Brought the receptionist an espresso. She invited you to the rooftop gathering.")
				return "She inhales the aroma. 'A man who delivers. How refreshing.' She adds your name to the guest list. 'Join us upstairs. Eve is hosting.' The elevator unlocks."
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
				if not flags.get("eve_met", false): return "You hover with an apple in your hand. This opening could use a little polish. Talk to Eve first."
				_consume(held)
				flags["apple_given"] = true
				return "'An apple for Eve?' She laughs. 'Bold of you to open with temptation.' She takes a bite and pats the chair beside hers. 'Sit, Larry. Tell me something interesting.' Talk to her."
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
	if flags.get("pitcher_filled", false): return "The pitcher is already full. Larry has found his capacity."
	flags["pitcher_filled"] = true
	return "You fill the pitcher and turn the tap off. The garden planter is ready for its close-up."


func _say_password(value: String) -> String:
	if room != "bar": return "Only the backstage bouncer needs the password. Elsewhere it is merely an anatomical announcement."
	if value.to_lower().strip_edges() != PASSWORD: return "The bouncer shakes his head. The restroom graffiti might improve your vocabulary."
	if flags.get("password_spoken", false): return "The bouncer remembers your password. " + ("Head backstage." if flags.get("tv_distracted", false) else "Now if only the bowling were on television...")
	flags["password_spoken"] = true
	_award("password_spoken", "Gave the bouncer the backstage password.")
	return "'Bellybutton,' you say with improbable confidence. The password checks out. " + ("The bowling has his attention; head backstage." if flags.get("tv_distracted", false) else "He mentions missing the bowling on channel six.")


func _call(number: String) -> String:
	if room != "disco": return "The usable telephone is on Studio 69's wall."
	if not flags.get("phone_known", false): return "Didi has not shared the stage manager's number yet. Help with her show and ask her."
	if number.replace("-", "").replace(" ", "") != PHONE_NUMBER: return "That number reaches a recording about extended hovercraft warranties. Try the number Didi gave you."
	if flags.get("phone_called", false):
		if flags.get("rope_taken", false): return "Stage manager: 'You've got the rope. I've got a show to run. Thanks for helping Didi; we're ready for opening night.'"
		return "Stage manager: 'Yes, the spare coil is yours. Cut the packaging cord. Thanks for helping Didi with the show.'"
	flags["phone_called"] = true
	_award("phone_called", "Called 555-0987. Didi's stage manager cleared the spare rope for you.")
	return "'Didi sent you? Lucky devil. Take the spare rope; a small knife will cut the packaging cord. Tell her I expect a dance at the opening.'"


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
	if completed: return "You made it to sunrise with good company. For a man in that suit, this is a spectacular result."
	if not flags.get("whiskey_given", false): return "Explore the Strip and make a useful trade at Lefty's."
	if not is_unlocked("backroom"): return "Find the backstage password and put bowling on Lefty's TV."
	if not flags.get("taken_candy", false): return "Collect the promotional chocolates backstage."
	if not inventory.has("pass"): return "Find a complimentary Studio 69 pass at the casino."
	if not flags.get("phone_known", false): return "Meet Didi, dance, and help collect props for her cabaret."
	if not flags.get("phone_called", false): return "Call Didi's stage manager from the disco phone."
	if not flags.get("rope_taken", false): return "Get a small knife and release the spare stage rope."
	if not flags.get("rope_anchored", false): return "Tie the stage rope to Lefty's backstage railing."
	if not flags.get("window_open", false): return "Use a rubber mallet to free the fire escape's service window."
	if not flags.get("taken_voucher", false): return "Take the espresso voucher from the open service window."
	if not flags.get("penthouse_access", false):
		if inventory.has("coffee"): return "Bring the espresso to the hotel receptionist."
		return "Redeem the voucher at Quik-E-Mart's espresso machine."
	if flags.get("apple_grown", false) and not flags.get("taken_apple", false): return "Take the ripe apple from the garden's miniature tree."
	if not flags.get("eve_met", false): return "Join the rooftop gathering and introduce yourself to Eve."
	if not flags.get("apple_grown", false): return "Grow a fresh apple in the hotel's experimental garden planter."
	if not flags.get("apple_given", false): return "Bring Eve the fresh apple on the rooftop."
	if flags.get("eve_heard", false): return "Enjoy the moment with Eve. Talk once more."
	if flags.get("eve_story_shared", false): return "Ask about Eve's night. Keep the conversation going."
	return "Share an honest conversation with Eve on the rooftop."


func hint() -> String:
	if completed: return "You finished! %d / %d points. A casino demo spin and every curious LOOK can round out your evening." % [score, max_score]
	if not inventory.has("newspaper") and not flags.get("newspaper_read", false): return "Take the free newspaper on the Strip, then LOOK at it in your inventory. Its garden story will matter later."
	if not flags.get("newspaper_read", false): return "Read the newspaper in your inventory. It explains the hotel's instant-fruit planter."
	if not flags.get("whiskey_given", false):
		if inventory.has("whiskey"): return "Give the whiskey to the thirsty regular at Lefty's. He will trade his remote."
		return "At Lefty's, USE the bartender to buy a $10 whiskey, or type BUY WHISKEY. Give it to the regular."
	if not flags.get("password_known", false): return "Visit Lefty's restroom and LOOK at the graffiti. Take the costume ring while you are there."
	if not flags.get("taken_ring", false): return "Take the free costume ring beside the restroom basin."
	if not flags.get("tv_distracted", false): return "Use the TV remote on Lefty's television. The bouncer loves channel six."
	if not flags.get("password_spoken", false): return "Talk to the bouncer after reading the graffiti, or type BELLYBUTTON while in the bar."
	if not flags.get("taken_candy", false): return "Enter Lefty's backstage lounge and take the free promotional candy."
	if not inventory.has("pass"): return "Take the Studio 69 pass from the casino's clean ashtray."
	if not flags.get("dancer_met", false): return "Enter Studio 69 and TALK to Didi. She is gathering props for a cabaret opening."
	if not flags.get("danced", false): return "USE the dance floor after meeting Didi, or type DANCE."
	if not flags.get("gift_ring", false): return "Give Didi the costume ring for her cabaret opening."
	if not flags.get("gift_candy", false): return "Use the promotional candy on Didi."
	if not flags.get("gift_flowers", false):
		if inventory.has("flowers"): return "Use the flowers on Didi to complete her cabaret props."
		return "Buy a $10 bouquet at the Strip's flower cart, then give it to Didi."
	if not flags.get("phone_known", false): return "Talk to Didi after dancing and giving all three props."
	if not flags.get("phone_called", false): return "Use the disco phone, or type CALL 555-0987. The stage manager can release the spare rope."
	if not inventory.has("knife"):
		if inventory.has("wine"): return "Give the wine to the alley busker. He trades a pocket knife."
		return "Buy a $12 wine at Quik-E-Mart and trade it to the alley busker for a pocket knife."
	if not flags.get("rope_taken", false): return "Use the pocket knife on Studio 69's spare stage rope to cut its packaging cord."
	if not flags.get("rope_anchored", false): return "Use the stage rope on the railing in Lefty's backstage lounge."
	if not inventory.has("hammer"): return "Take the loaner rubber mallet from the service alley's maintenance rack."
	if not flags.get("window_open", false): return "Go from the backstage lounge to the fire escape. Use the rubber mallet on the sticking window."
	if not flags.get("taken_voucher", false): return "Take the espresso voucher inside the open service window."
	if not flags.get("penthouse_access", false):
		if inventory.has("voucher"): return "Use the espresso voucher on Quik-E-Mart's coffee machine."
		return "Give the espresso to the hotel receptionist. She will invite you upstairs."
	if flags.get("apple_grown", false) and not flags.get("taken_apple", false): return "TAKE the apple from the miniature tree in the garden."
	if not flags.get("eve_met", false): return "Go through the penthouse to the rooftop and TALK to Eve. Find out what she would enjoy before planning a grand gesture."
	if not flags.get("seeds_found", false):
		if inventory.has("core"): return "USE the apple core in your inventory to separate its seeds."
		return "Take the apple core from the alley bin lid, then USE it to extract the seeds."
	if not flags.get("seeds_planted", false): return "Use the apple seeds on the hotel's garden planter. Read the newspaper first."
	if not flags.get("stool_placed", false):
		if inventory.has("stool"): return "Use the folding stool on the high penthouse cabinet."
		return "Take the loaner folding stool from the hotel garden."
	if not flags.get("taken_pitcher", false): return "Take the pitcher from the now-reachable penthouse cabinet."
	if not flags.get("apple_grown", false):
		if not flags.get("pitcher_filled", false): return "Use the pitcher on the penthouse sink to fill it with water."
		return "Use the full pitcher on the garden planter to grow an apple tree."
	if not flags.get("taken_apple", false): return "TAKE the apple from the miniature tree in the garden."
	if not flags.get("apple_given", false): return "Offer Eve the fresh apple by using it on her."
	return "TALK to Eve to continue the conversation. Share your night, listen to hers, then stay for sunrise."


func _resolve_room(value: String) -> String:
	var key := value.strip_edges().to_lower().replace("_", " ")
	var aliases := {"strip": "street", "neon strip": "street", "outside": "street", "lefty's": "bar", "leftys": "bar", "lefty's bar": "bar", "restroom": "bathroom", "bar restroom": "bathroom", "backstage": "backroom", "backstage lounge": "backroom", "lounge": "backroom", "lucky chip": "casino", "lucky chip casino": "casino", "studio 69": "disco", "store": "shop", "quik-e-mart": "shop", "service alley": "alley", "lobby": "hotel", "hotel lobby": "hotel", "fire escape": "balcony", "moonlight garden": "garden", "roof": "rooftop", "eve's rooftop": "rooftop"}
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
	var input := text.strip_edges().to_lower()
	if input.is_empty(): return "Try LOOK, TALK TO LEFTY, TAKE NEWSPAPER, USE REMOTE ON TV, GO CASINO, INVENTORY, or HINT."
	if input == PASSWORD: return _say_password(input)
	if input in ["555-0987", "5550987"]: return _call(input)
	if input in ["look", "l", "look around"]: return str(get_room().description)
	if input in ["inventory", "i", "take inventory"]:
		var names: Array[String] = []
		for id in inventory: names.append(str(items[id].name))
		return "Pockets: %s. Wallet: $%d." % [", ".join(names) if not names.is_empty() else "just lint and ambition", cash]
	if input == "score": return "Score: %d / %d. Actions: %d. Cash: $%d." % [score, max_score, turns, cash]
	if input in ["hint", "help me"]: return hint()
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
	return "Larry tries to parse that and wrinkles his forehead. Try HELP for examples."


func save_game(path: String = "user://savegame.json") -> String:
	var file := FileAccess.open(path, FileAccess.WRITE)
	if file == null: return "Could not save the game: %s." % error_string(FileAccess.get_open_error())
	file.store_string(JSON.stringify({"version": SAVE_VERSION, "room": room, "inventory": inventory, "flags": flags, "cash": cash, "score": score, "turns": turns, "completed": completed, "journal": journal}, "\t"))
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
	if int(data.get("version", -1)) != SAVE_VERSION or not rooms.has(data.get("room", "")):
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
	journal.assign(data.journal)
	return "Game restored. Your suit is exactly as you left it, for better or worse."
