extends RefCounted
## Presentation and invitation copy for the city's three adult party hosts.
## Party rules, round state and saves belong to the deterministic game model.

const IDS := ["party_cabbie", "party_host", "party_shark"]
const ROOMS := {"party_cabbie": "street", "party_host": "hotel", "party_shark": "disco"}
const MODES := {"party_cabbie": "poker", "party_host": "never", "party_shark": "pool"}
const NAMES := [["Max", "Moxie"], ["Chaz", "Chloe"], ["Ace", "Dee"]]
const JOBS := ["off-duty cabbie", "night-lounge host", "billiards regular"]
const TITLES := {"poker": "Strip Poker", "never": "Strip Never Have I Ever", "pool": "Strip Pool"}

static func mode_for(id: String) -> String:
	return MODES.get(id, "")

static func actor_profile(id: String, profile: Dictionary) -> Dictionary:
	var index := IDS.find(id)
	if index < 0: return {}
	var player_gender := "female" if profile.get("character", "larry") == "lisa" else "male"
	var gender: String = ["male", "female", "male"][index]
	match profile.get("orientation", "bisexual"):
		"heterosexual": gender = "male" if player_gender == "female" else "female"
		"homosexual": gender = player_gender
	return {"name": NAMES[index][0 if gender == "male" else 1], "gender": gender, "role": id, "skin": ["dca483", "a86c48", "cf936f"][index], "adult": true, "occupation": JOBS[index]}

static func hotspots(room: String, profile: Dictionary) -> Array:
	var result: Array = []
	for id in IDS:
		if ROOMS[id] != room: continue
		var index := IDS.find(id)
		var point: Vector2 = [Vector2(0.80, 0.80), Vector2(0.82, 0.69), Vector2(0.83, 0.77)][index]
		var person := actor_profile(id, profile)
		var job: String = ["cabbie", "party host", "pool shark"][index]
		result.append({"id": id, "label": person.name + " · " + job, "kind": "person", "x": point.x, "y": point.y, "scale": 0.94, "approach_x": point.x - 0.15})
	return result

static func look(id: String, profile: Dictionary) -> String:
	if not IDS.has(id): return "Nobody is hosting a party game here."
	var person := actor_profile(id, profile)
	var description: String = {
		"party_cabbie": "Checkerboard cap, saffron jacket, and a deck of cards balanced on a folding table beside the parked cab. The OFF DUTY sign is the only thing here with boundaries printed in capitals.",
		"party_host": "A plum lounge blazer, gold earrings and a pocket square folded like a surrender flag. Beside the lobby sofa, a stack of confession cards threatens several respectable reputations.",
		"party_shark": "A teal billiards waistcoat, rolled sleeves and a cue held with suspicious confidence. Studio 69's pocket billiards nook: finally, some balls with a clearly explained purpose."
	}[id]
	return "%s · adult %s. %s TALK to play %s." % [person.name, person.occupation, description, TITLES[mode_for(id)]]

static func talk(id: String, profile: Dictionary) -> String:
	if not IDS.has(id): return "Nobody is hosting a party game here."
	var name: String = actor_profile(id, profile).name
	var line: String = {
		"party_cabbie": "'Meter's off, fly's up, cards are out. Fancy Strip Poker? It's the Neon Strip — even our traffic cones are exhibitionists. Free rounds, costume accessories for stakes. We finish in ridiculous robes. No fare, no pressure; leave whenever you like.'",
		"party_host": "'Welcome to Strip Never Have I Ever. The hotel tried Strip Continental Breakfast, but nobody could find the tiny sausage. Free rounds; your character confesses, fibs or passes. We trade costume accessories, never real-life secrets. You can quit with your dignity mostly accounted for.'",
		"party_shark": "'Strip Pool. Yes, even billiards has a dress code in reverse. Aim, choose your power and put those hands to something useful. Free rounds, costume accessories only; the final humiliation is a hotel robe. Leave any time. I'll keep my hands on my own cue.'"
	}[id]
	return name + ": " + line

static func table_intro(id: String, profile: Dictionary) -> String:
	if not IDS.has(id): return "The party table is ready."
	var name: String = actor_profile(id, profile).name
	return {
		"party_cabbie": name + " flips the OFF DUTY sign and unfolds a tiny card table. A passing cab honks. 'That's applause in my profession.'",
		"party_host": name + " draws the lounge curtain. The bellhop delivers two emergency robes without making eye contact. A consummate professional.",
		"party_shark": name + " chalks the cue. The disco ball spins over the felt; your lapels briefly qualify as a lighting rig."
	}[id]

static func wardrobe(id: String, loss_count: int) -> String:
	var stage := clampi(loss_count, 0, 3)
	var stages: Array = {
		"party_cabbie": ["cap, neckerchief and cab jacket", "cap retired", "neckerchief surrendered", "cab jacket traded for a courtesy robe"],
		"party_host": ["pocket square, ascot and plum blazer", "pocket square surrendered", "ascot retired", "blazer traded for a deluxe robe"],
		"party_shark": ["wristband, bow tie and billiards waistcoat", "lucky wristband retired", "bow tie surrendered", "waistcoat traded for a champion's robe"],
		"party_player": ["borrowed bow tie, leisure jacket and full outfit", "borrowed bow tie surrendered", "leisure jacket retired; shirt and trousers remain", "outfit covered by an emergency disco robe"]
	}.get(id, ["fully dressed", "fully dressed", "fully dressed", "fully dressed"])
	return stages[stage]

static func round_outro(id: String, loss_count: int, profile: Dictionary) -> String:
	if not IDS.has(id): return "The costumes settle. Your dignity requests a recount."
	var name: String = actor_profile(id, profile).name
	return name + ": " + {
		"party_cabbie": ["'All dressed and nowhere to fold.'", "'There goes the cap. The union is going to hear about this.'", "'That scarf was holding my reputation together.'", "'Complimentary robe. Complimentary ride. Dignity priced separately.'"],
		"party_host": ["'The pocket square has asked for its own room.'", "'A silk surrender. Very continental.'", "'Without the ascot, I'm dangerously close to approachable.'", "'Our deluxe robe has two pockets: one for shame, one for room service.'"],
		"party_shark": ["'My outfit is undefeated. So far.'", "'Lucky wristband. Obviously a manufacturing defect.'", "'The bow tie has conceded gracefully.'", "'You beat the waistcoat. The robe is playing a longer game.'"]
	}[id][clampi(loss_count, 0, 3)]
