extends RefCounted
## Short, deterministic performance cues. No game state, RNG, timers or rewards.
var clip := ""
var elapsed := 0.0
var duration := 0.0
var hover_index := 0

func active() -> bool:
	return elapsed < duration

func hover(role: String) -> bool:
	# Crossing between the sprite and its label cannot restart an active gesture.
	if active(): return false
	var choices := ["wave", "nod", "shrug"]
	if role in ["eve", "adam", "dancer", "romance_guest"]: choices = ["wave", "preen", "wink"]
	elif role == "bartender": choices = ["polish", "nod", "wave"]
	elif role == "bouncer": choices = ["fold", "brow", "shrug"]
	elif role == "busker": choices = ["tip", "wave", "nod"]
	elif role in ["bar_quiff", "bar_curls"]: choices = ["preen", "wink", "wave"]
	elif role == "bar_hat": choices = ["tip", "nod", "wink"]
	elif role == "bar_round": choices = ["nod", "polish", "wave"]
	elif role == "bar_biker": choices = ["fold", "wink", "shrug"]
	_start(choices[hover_index % choices.size()], 1.6)
	hover_index += 1
	return true

func interact(action: String) -> void:
	match action:
		"talk": _start("talk", 2.4)
		"take": _start("recoil", 1.6)
		"use": _start("offer", 1.8)
		"look": _start("brow", 1.4)

func _start(name: String, seconds: float) -> void:
	clip = name
	elapsed = 0.0
	duration = seconds

func advance(delta: float) -> void:
	elapsed = minf(duration, elapsed + maxf(0.0, delta))
	if not active(): clip = ""

func pose(reduced: bool) -> Dictionary:
	if not active(): return {}
	# Reduced motion holds one expressive pose, then returns to idle.
	var progress := 0.45 if reduced else elapsed / duration
	var envelope := 1.0 if reduced else sin(progress * PI)
	var beat := 1.0 if reduced else sin(elapsed * 9.0)
	var result := {"offset": Vector2.ZERO, "head": Vector2.ZERO, "left": 0.0, "right": 0.0, "blink": false, "mouth": 1.0, "brow": false, "cloth": false}
	match clip:
		"wave", "tip":
			result.right = (-140.0 + beat * 18.0) * envelope
			result.head = Vector2(0, 0.5 * envelope)
		"preen":
			result.left = 35.0 * envelope
			result.right = -155.0 * envelope
			result.head = Vector2(-1.0, -0.5) * envelope
		"wink":
			result.left = 30.0 * envelope
			result.right = -35.0 * envelope
			result.blink = reduced or progress > 0.25 and progress < 0.75
			result.head = Vector2(1, 0) * envelope
		"polish":
			result.left = -58.0 * envelope
			result.right = (58.0 + beat * 15.0) * envelope
			result.cloth = true
		"fold":
			result.left = -80.0 * envelope
			result.right = 80.0 * envelope
			result.brow = true
		"shrug":
			result.left = 105.0 * envelope
			result.right = -105.0 * envelope
			result.head = Vector2(0, -envelope)
			result.brow = true
		"nod": result.head = Vector2(0, (1.0 if reduced else beat) * envelope)
		"brow":
			result.head = Vector2(-1.0, 0) * envelope
			result.brow = true
		"talk":
			result.right = (-55.0 + beat * 20.0) * envelope
			result.left = 15.0 * envelope
			result.head = Vector2(0, beat * 0.5 * envelope)
			result.mouth = 2.0 if reduced else 3.0 if beat > 0.0 else 1.0
		"recoil":
			result.offset = Vector2(-9.0, 0) * envelope
			result.left = 120.0 * envelope
			result.right = -120.0 * envelope
			result.head = Vector2((-1.0 if reduced else beat), 0) * envelope
			result.brow = true
		"offer":
			result.right = -78.0 * envelope
			result.head = Vector2(0, beat * 0.5 * envelope)
	return result
