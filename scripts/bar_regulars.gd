extends RefCounted
## Authored optional stories. Randomness chooses an evening, never a rule or consent.
## This module owns the whole saved bar night; GameState owns location and money.
const IDS := ["bar_kit", "bar_rox", "bar_bo", "bar_jazz", "bar_red"]
const ROLES := ["bar_quiff", "bar_curls", "bar_round", "bar_hat", "bar_biker"]
const NAMES := [["Kit", "Kitty"], ["Rex", "Roxanne"], ["Bo", "Bonnie"], ["Jax", "Jazz"], ["Red", "Reddie"]]
const JOBS := ["jukebox Romeo", "independent escort", "midnight cook", "session musician", "rally captain"]
const SOURCES := ["my folded jukebox slip — ask to read it here", "the public guestbook in the Come-On Inn's hotel lobby", "the zero-proof recipe column in Quik-E-Mart's magazine rack", "the busker's rhythm card in the Service Alley — LOOK at the busker", "the rally notice in the free newspaper on the Neon Strip"]
const STEPS := [2, 2, 3, 3, 2]
const PUZZLES := {
	"bar_kit": [
		{"clue": "JUKEBOX SLIP: 'Play the blues. Let it crawl, not sprint.' The pencilled dedication says: FOR SOMEONE WHO CAN KEEP IT UP — A CONVERSATION, THAT IS.", "answer": ["blues", "slow"]},
		{"clue": "JUKEBOX SLIP: 'A mambo, quick enough to make the ice cubes nervous.' The dedication says: SHAKE SOMETHING THAT ISN'T YOUR CREDIT RATING.", "answer": ["mambo", "quick"]},
		{"clue": "JUKEBOX SLIP: 'Swing. A steady walking pace, neither a crawl nor a sprint.' The dedication says: MY OTHER PICKUP LINE HAS A HORN SECTION.", "answer": ["swing", "steady"]}
	],
	"bar_rox": [
		{"clue": "PUBLIC GUESTBOOK: The private Salon uses the alias M. Satin. Its discreet signal is a folded BLUE napkin. No room numbers or guests' real names are listed.", "answer": ["satin", "blue"]},
		{"clue": "PUBLIC GUESTBOOK: The private Salon uses the alias P. Velvet. Its discreet signal is a folded GOLD napkin. No room numbers or guests' real names are listed.", "answer": ["velvet", "gold"]},
		{"clue": "PUBLIC GUESTBOOK: The private Salon uses the alias J. Silk. Its discreet signal is a folded RED napkin. No room numbers or guests' real names are listed.", "answer": ["silk", "red"]}
	],
	"bar_bo": [
		{"clue": "ZERO-PROOF RECIPE: The Virgin Alibi — pour LIME, add GINGER, finish with SODA. In that order. No booze, no purchase. Finally, a virgin with a convincing backstory.", "answer": ["lime", "ginger", "soda"]},
		{"clue": "ZERO-PROOF RECIPE: The Blushing Witness — pour CHERRY, add LIME, finish with SODA. In that order. No booze, no purchase. Looks guilty; remembers everything.", "answer": ["cherry", "lime", "soda"]},
		{"clue": "ZERO-PROOF RECIPE: The Ginger Tease — pour GINGER, add CHERRY, finish with SODA. In that order. No booze, no purchase. All the bite, none of the morning excuses.", "answer": ["ginger", "cherry", "soda"]}
	],
	"bar_jazz": [
		{"clue": "BUSKER'S RHYTHM CARD: tonight's audition cue is TAP, TAP, REST. Three beats. A rest is silence, not a trip to the restroom.", "answer": ["tap", "tap", "rest"]},
		{"clue": "BUSKER'S RHYTHM CARD: tonight's audition cue is HOLD, REST, TAP. Three beats. Hold one long note; let the silence do its own flirting.", "answer": ["hold", "rest", "tap"]},
		{"clue": "BUSKER'S RHYTHM CARD: tonight's audition cue is REST, TAP, HOLD. Three beats. Start with silence. Your tailor could learn from this.", "answer": ["rest", "tap", "hold"]}
	],
	"bar_red": [
		{"clue": "RALLY NOTICE: Coast road flooded; mountain pass closed. Desert road open. Rally badge: the creature that flies at night, NOT the one that stings or crawls.", "answer": ["desert", "bat"]},
		{"clue": "RALLY NOTICE: Desert road closed by sand; mountain pass under repair. Coast road open. Rally badge: the creature with a sting, NOT wings or a forked tongue.", "answer": ["coast", "scorpion"]},
		{"clue": "RALLY NOTICE: Coast road flooded; desert road buried in sand. Mountain pass open. Rally badge: the creature with a forked tongue, NOT wings or a sting.", "answer": ["mountain", "snake"]}
	]
}
var night: Dictionary = {}

func new_night(seed_value: int = -1) -> void:
	var rng := RandomNumberGenerator.new()
	if seed_value < 0: rng.randomize()
	else: rng.seed = seed_value
	# JSON numbers preserve this range exactly, across native and Web builds.
	var seed_number := rng.randi_range(0, 2147483646) if seed_value < 0 else seed_value % 2147483647
	rng.seed = seed_number
	night = {"seed": seed_number, "seating": IDS.duplicate(), "variants": {}, "progress": {}}
	for i in range(IDS.size() - 1, 0, -1):
		var j := rng.randi_range(0, i)
		var swap: String = night.seating[i]
		night.seating[i] = night.seating[j]
		night.seating[j] = swap
	for id in IDS:
		night.variants[id] = rng.randi_range(0, 2)
		night.progress[id] = {"met": false, "clue": false, "step": 0, "solved": false, "invited": false, "encounter": false}

func snapshot() -> Dictionary:
	return night.duplicate(true)

func restore(data: Variant) -> bool:
	# Validate fully before replacing a live night. Unknown/missing patrons and
	# impossible half-encounters must not turn a load into free money or consent.
	if not data is Dictionary or data.size() != 4: return false
	if not _integer(data.get("seed"), 0, 2147483646): return false
	if not data.get("seating") is Array or data.seating.size() != IDS.size(): return false
	var seen: Array = []
	for id in data.seating:
		if not IDS.has(id) or seen.has(id): return false
		seen.append(id)
	for field in ["variants", "progress"]:
		if not data.get(field) is Dictionary or data[field].size() != IDS.size(): return false
	for i in IDS.size():
		var id: String = IDS[i]
		if not _integer(data.variants.get(id), 0, 2): return false
		var p: Variant = data.progress.get(id)
		if not p is Dictionary or p.size() != 6 or not _integer(p.get("step"), 0, STEPS[i]): return false
		for field in ["met", "clue", "solved", "invited", "encounter"]:
			if not p.get(field) is bool: return false
		if (p.clue or p.step > 0 or p.solved or p.invited or p.encounter) and not p.met: return false
		if (p.step > 0 or p.solved) and not p.clue: return false
		if p.solved != (int(p.step) == STEPS[i]): return false
		if (p.invited or p.encounter) and not p.solved: return false
		if p.invited and p.encounter: return false
	night = data.duplicate(true)
	night.seed = int(night.seed)
	for id in IDS:
		night.variants[id] = int(night.variants[id])
		night.progress[id].step = int(night.progress[id].step)
	return true

static func _integer(value: Variant, low: int, high: int) -> bool:
	return (value is int or value is float) and is_finite(float(value)) and float(value) == floorf(float(value)) and value >= low and value <= high

func actor_profile(id: String, profile: Dictionary) -> Dictionary:
	var i := IDS.find(id)
	var player_gender := "female" if profile.character == "lisa" else "male"
	var gender: String = ["male", "female", "male", "female", "male"][i]
	if profile.orientation == "homosexual": gender = player_gender
	elif profile.orientation == "heterosexual": gender = "male" if player_gender == "female" else "female"
	return {"name": NAMES[i][0 if gender == "male" else 1], "gender": gender, "role": ROLES[i], "occupation": JOBS[i], "skin": "a8673d" if i == 3 else "dca483", "adult": true}

func hotspots(profile: Dictionary) -> Array:
	var result: Array = []
	for seat in night.seating.size():
		var id: String = night.seating[seat]
		var person := actor_profile(id, profile)
		result.append({"id": id, "label": person.name, "x": 0.085 + seat * 0.139, "y": 0.70, "kind": "person", "seated": true, "scale": 0.76})
	return result

func look(id: String, profile: Dictionary) -> String:
	var person := actor_profile(id, profile)
	var details: String = ["A towering blond quiff, white shirt and a drink held like an Oscar.", "Brown curls, purple satin, crossed legs and a very direct smile.", "A broad frame, white shirt, blue trousers and the calm of someone who has fed a riot.", "A black hat, turquoise shirt and purple trousers. Even the shoes seem syncopated.", "Red hair, a blue club vest and shoulders built to support a very large punchline."][IDS.find(id)]
	return "%s · adult %s. %s TALK for an optional story and a little after-hours company." % [person.name, person.occupation, details]

func talk(id: String, profile: Dictionary) -> String:
	var p: Dictionary = night.progress[id]
	p.met = true
	var name: String = actor_profile(id, profile).name
	if p.encounter:
		return name + ": " + ["'Our song came on again. Your collar tried to take a bow.' A private smile does the rest.", "'A pleasure, darling. My discretion is impeccable. Your hair is a terrible witness.'", "'I've named the drink The Alibi. Ours needs work.' The grin could curdle your innocence.", "'Lovely encore. Next time, tell your lapels to stop conducting.'", "'Best detour all night. The cab driver wants your tailor's number — for a police sketch.'"][IDS.find(id)]
	if p.invited: return invitation(id, name)
	if p.solved: return name + ": 'You came through. And that collar has finally stopped doing all the talking.' Choose whether to flirt or keep it friendly."
	var setup: String = {
		"bar_kit": "'The jukebox ate my dedication, and I refuse to be outperformed by furniture. Read my slip, choose the style, then the tempo. Impress me with something other than those lapels.'",
		"bar_rox": "'I'm an independent escort. I choose my clients; tonight I fancy your company. A private appointment is $20, if we both say yes. First, help me recover the Salon's public alias and discreet napkin signal from the Come-On Inn's lobby guestbook. My privacy matters more than your pickup line.'",
		"bar_bo": "'I cook after midnight. Tonight I'm inventing a zero-proof drink that doesn't taste like punishment. The magazine rack at Quik-E-Mart has tonight's recipe. Read it, then mix three ingredients here in order. Ingredients are on me. So is the terrible name.'",
		"bar_jazz": "'Session musician. My audition partner sent a three-beat cue to the Service Alley busker. LOOK at the busker's rhythm card, then tap it out here. Show me you can listen before you tell me what else you're good at.'",
		"bar_red": "'I run the midnight rally. Our route card got used as a beer mat. Read the free newspaper's rally notice on the Neon Strip. Find the open road and identify our creature badge. No riding after drinking; we take the courtesy cab tonight.'"
	}[id]
	return name + ": " + setup + (" Your notes have the clue. " + step_prompt(id) if p.clue else " Nothing is timed; you can leave and return.")

func clue(id: String) -> String:
	return PUZZLES[id][int(night.variants[id])].clue

func observe(target: String, profile: Dictionary) -> String:
	var result: Array[String] = []
	for id in IDS:
		if not night.progress[id].met: continue
		var sources: Array = {"bar_kit": [], "bar_rox": ["guestbook"], "bar_bo": ["magazines"], "bar_jazz": ["busker"], "bar_red": ["newsbox", "newspaper"]}[id]
		if not sources.has(target): continue
		night.progress[id].clue = true
		result.append(actor_profile(id, profile).name + "'s clue: " + clue(id) + " Return to Lefty's and TALK to " + actor_profile(id, profile).name + ".")
	return "\n\n".join(result)

func step_prompt(id: String) -> String:
	var step := int(night.progress[id].step)
	if night.progress[id].solved: return "The favor is complete."
	return {
		"bar_kit": ["Choose the music style.", "Now choose the tempo."],
		"bar_rox": ["Which public Salon alias?", "Which folded napkin signals the Salon?"],
		"bar_bo": ["Pour ingredient 1 of 3.", "Add ingredient 2 of 3.", "Finish with ingredient 3 of 3."],
		"bar_jazz": ["Play beat 1 of 3.", "Play beat 2 of 3.", "Play beat 3 of 3."],
		"bar_red": ["Which rally road is open?", "Which creature belongs on the rally patch?"]
	}[id][step]

func options(id: String) -> Array:
	var p: Dictionary = night.progress[id]
	if not p.met: return []
	if p.encounter: return [_option(id, "remember", "Share our private in-joke")]
	if p.invited: return [_option(id, "accept", "Yes — $20 for our agreed private appointment" if id == "bar_rox" else "Yes — let's get laid"), _option(id, "decline", "Rain check — keep it friendly")]
	if p.solved: return [_option(id, "flirt", "Flirt: ask if the attraction is mutual"), _option(id, "decline", "Enjoy the company and leave it there")]
	var result: Array = [_option(id, "clue", "Read the jukebox slip" if id == "bar_kit" else "Review the clue in my notes" if p.clue else "Remind me where to find the clue")]
	if not p.clue: return result
	var step := int(p.step)
	var picks: Array = {
		"bar_kit": [["blues", "mambo", "swing"], ["slow", "quick", "steady"]],
		"bar_rox": [["satin", "velvet", "silk"], ["blue", "gold", "red"]],
		"bar_bo": [["lime", "ginger", "cherry", "soda"], ["lime", "ginger", "cherry", "soda"], ["lime", "ginger", "cherry", "soda"]],
		"bar_jazz": [["tap", "rest", "hold"], ["tap", "rest", "hold"], ["tap", "rest", "hold"]],
		"bar_red": [["coast", "mountain", "desert"], ["bat", "scorpion", "snake"]]
	}[id][step]
	var labels := {"satin": "M. Satin", "velvet": "P. Velvet", "silk": "J. Silk", "slow": "Slow crawl", "quick": "Quick and lively", "steady": "Steady walking pace", "tap": "Tap · one short beat", "rest": "Rest · one silent beat", "hold": "Hold · one long beat"}
	for pick in picks: result.append(_option(id, "pick_" + pick, str(labels.get(pick, pick.capitalize()))))
	return result

func _option(id: String, action: String, label: String) -> Dictionary:
	return {"id": "bar|" + id + "|" + action, "label": label}

func invitation(id: String, name: String) -> String:
	if id == "bar_rox": return name + ": 'Yes, I'm interested. A private appointment is $20, as agreed; either of us can say no. No charge unless you accept. Still fancy getting laid?'"
	var line: String = {"bar_kit": "'You've tuned in. So have I. My place has a record player and mercifully thick curtains. Want to get laid?'", "bar_bo": "'You can cook, and you make me laugh. Fancy a private midnight special? I'd like to get laid with you. Dishes can wait.'", "bar_jazz": "'Good rhythm. Better company. Fancy a private encore? I'd like to get laid with you. The neighbors get earplugs.'", "bar_red": "'You fixed my route; now I'm inviting you on a detour. Cab to my room? I'd like to get laid with you. My bike has the night off.'"}[id]
	return name + ": " + line + " Choose yes or a rain check."

func choose(id: String, choice: String, profile: Dictionary, cash: int, evening_complete: bool = false) -> Dictionary:
	# Defend the module as well as the UI: only current choices are executable.
	var offered := false
	for option in options(id):
		if option.id == choice: offered = true
	if not offered: return {"text": "That conversation has moved on."}
	var action := choice.get_slice("|", 2)
	var p: Dictionary = night.progress[id]
	var name: String = actor_profile(id, profile).name
	if action == "clue":
		if id == "bar_kit": p.clue = true
		if not p.clue: return {"text": name + ": 'LOOK at " + SOURCES[IDS.find(id)] + ". Then come back and TALK to me.'"}
		return {"text": clue(id) + " " + step_prompt(id), "note": name + "'s clue: " + clue(id)}
	if action.begins_with("pick_"):
		var pick := action.trim_prefix("pick_")
		var answer: Array = PUZZLES[id][int(night.variants[id])].answer
		if pick != answer[int(p.step)]:
			p.step = 0
			return {"text": name + ": 'That doesn't match the clue. Let's start again; nothing lost except a little swagger.' " + step_prompt(id) + " Use the clue button to read it again. No money or ingredients lost."}
		p.step += 1
		if int(p.step) < answer.size(): return {"text": name + ": 'That's it.' " + step_prompt(id), "note": name + ": step " + str(p.step) + " — " + pick + "."}
		p.solved = true
		var payoff: String = {
			"bar_kit": "The jukebox croons the dedication. A whole bar of bad decisions briefly finds the beat. 'That is how you turn me on — the jukebox, darling. For now.'",
			"bar_rox": "'Right alias, right signal. Discreet and attentive. That is much sexier than guessing my room number.' The appointment details are sorted; nothing is booked or charged.",
			"bar_bo": "A sip, a raised eyebrow, then a grin. 'Delicious. And I can remember every terrible line you try next.' The new drink joins the menu.",
			"bar_jazz": "The rhythm clicks. A little improvised duet makes the glasses rattle. 'Good ears. I was worried your hair would get in the way.'",
			"bar_red": "'Open road, right badge. Rally saved. You're more than a decorative fire hazard.' A finger taps the club badge on that blue vest. The courtesy cab awaits; the motorbike stays parked."
		}[id]
		return {"text": name + ": " + payoff + " Choose whether to flirt.", "note": "Helped " + name + " finish an optional bar story. The favor is complete; flirting is a separate choice."}
	if action == "flirt":
		p.invited = true
		return {"text": invitation(id, name), "note": name + " returned your flirtation. An optional invitation awaits your answer."}
	if action == "decline":
		p.invited = false
		return {"text": name + ": 'No problem. Your company was the good bit; the rest was an optional extra.' No charge, no penalty. You can flirt again later."}
	if action == "accept":
		var fee := 20 if id == "bar_rox" else 0
		if cash < fee: return {"text": name + ": 'Keep your rent money, sweetheart. It's $20 when you're ready; our conversation costs nothing.' Nothing charged. You can return later or take a rain check."}
		p.encounter = true
		p.invited = false
		var titles := ["JUKEBOX AFTER HOURS", "THE SATIN APPOINTMENT", "THE MIDNIGHT SPECIAL", "A VERY PRIVATE ENCORE", "THE RIDE HOME"]
		var aftermath: String = ["Later, the jukebox needs a rest and your collar needs an alibi.", "Later, two happy adults part with a smile. Discretion survives. Your hair does not.", "Later, you both agree the zero-proof drink deserves a very dirty name.", "Later, the encore earns a standing ovation from one badly creased leisure suit.", "Later, the cab driver adjusts the mirror. Apparently your collar is a blind spot."][IDS.find(id)]
		var remaining := " Your rooftop ending with {finale} is already complete. Consider this the after-party." if evening_complete else " Your final goal is still a night with {finale}."
		var caption := "You and " + name + " got laid. " + aftermath + remaining
		return {"text": caption, "charge": fee, "note": "Shared a consensual private fling with " + name + ". " + ("The agreed $20 was paid once. " if fee > 0 else "") + ("An after-party following the completed rooftop ending." if evening_complete else "A happy detour; the rooftop goal remains."), "encounter": {"partner": id, "name": name, "gender": actor_profile(id, profile).gender, "appearance": actor_profile(id, profile), "title": titles[IDS.find(id)], "caption": caption, "finale": false}}
	return {"text": name + ": 'Our little secret. Though that collar could do with a gag order.'"}
