extends SceneTree
## Deterministic visual-state contracts; --capture-props also renders native before/after images.
## These tests do not measure artistic quality or replace browser playtesting.
const Effects = preload("res://scripts/world_effects.gd")
const Actor = preload("res://scripts/actor.gd")
const Sounds = preload("res://scripts/sound_effects.gd")
var failures: Array[String] = []
var assertions := 0

func _init() -> void:
	_run.call_deferred()

func check(value: bool, message: String) -> void:
	assertions += 1
	if not value:
		failures.append(message)
		printerr("FAIL: " + message)

func _run() -> void:
	var effects := Effects.new()
	root.add_child(effects)
	await process_frame
	var cases := [
		["garden", "stool_on_rack", "taken_stool"],
		["alley", "core", "taken_core"],
		["alley", "mallet", "taken_hammer"],
		["bathroom", "ring", "taken_ring"],
		["backroom", "candy", "taken_candy"],
		["penthouse", "pitcher", "taken_pitcher"],
		["disco", "spare_rope", "rope_taken"]
	]
	for entry in cases:
		effects.sync_state(entry[0], {})
		check(effects.visible and effects.visual_state()[entry[1]], "%s has its uncollected %s" % [entry[0], entry[1]])
		effects.sync_state(entry[0], {entry[2]: true})
		check(not effects.visual_state()[entry[1]], "Collecting %s removes its world visual" % entry[1])
		effects.sync_state("street", {entry[2]: true})
		check(not effects.visible and not effects.visual_state()[entry[1]], "%s cannot leak into another room" % entry[1])
	effects.sync_state("balcony", {})
	check(not effects.visual_state().voucher and not effects.visual_state().window_open, "Voucher is not visible through stuck window")
	effects.sync_state("balcony", {"window_open": true, "rope_anchored": true})
	check(effects.visual_state().voucher and effects.visual_state().window_open and effects.visual_state().anchored_rope, "Open window exposes voucher and anchored rope")
	effects.sync_state("balcony", {"window_open": true, "rope_anchored": true, "taken_voucher": true})
	check(not effects.visual_state().voucher and effects.visual_state().window_open, "Taking voucher preserves open window")
	effects.sync_state("penthouse", {"stool_placed": true})
	check(effects.visual_state().stool_at_cabinet and effects.visual_state().cabinet_open and effects.visual_state().pitcher, "Placed stool opens cabinet with pitcher")
	effects.sync_state("penthouse", {"stool_placed": true, "taken_pitcher": true})
	check(effects.visual_state().stool_at_cabinet and effects.visual_state().cabinet_open and not effects.visual_state().pitcher, "Empty cabinet retains stool for future guests")
	effects.sync_state("garden", {"seeds_planted": true})
	effects.sync_state("garden", {"seeds_planted": true, "apple_grown": true})
	check(effects.growth == 0.0 and effects.is_processing(), "Tree growth begins only on new watered state")
	effects.set_reduced_motion(true)
	check(effects.growth == 1.0 and effects.water_glimmer == 0.0 and not effects.is_processing() and effects.visual_state().tree_apple, "Reduced motion shows mature tree and apple immediately")
	effects.sync_state("garden", {"seeds_planted": true, "apple_grown": true, "taken_apple": true})
	check(effects.visual_state().tree and not effects.visual_state().tree_apple, "Harvested tree remains without fruit")
	effects.sync_state("hotel", {"hotel_social": true})
	check(not effects.visual_state().coffee, "Social admission alone does not fabricate coffee")
	effects.sync_state("hotel", {"coffee_delivered": true})
	check(effects.visual_state().coffee, "New coffee flag shows delivered cup")
	effects.sync_state("hotel", {"award_coffee_given": true})
	check(effects.visual_state().coffee, "Legacy coffee award shows delivered cup")
	effects.sync_state("disco", {"show_started": true})
	check(effects.visual_state().show and effects.visual_state().show_beat == 0, "Show has a visible opening")
	for beat in [1, 2]:
		effects.sync_state("disco", {"show_started": true, "show_beat_%d" % beat: true})
		check(effects.visual_state().show_beat == beat, "Player advances show beat %d" % beat)
	effects.sync_state("disco", {"show_started": true, "show_completed": true})
	check(effects.visual_state().show_beat == 3, "Completed show retains encore staging")
	var actor := Actor.new()
	root.add_child(actor)
	await process_frame
	check(not actor.is_processing(), "Idle actor does not redraw every frame")
	for style in ["confident", "careful", "copy"]:
		actor.set_dance_style(style)
		actor.dance(0.5)
		check(actor.dance_style == style and actor.dance_time_left == 0.5 and actor.is_processing(), "Dance style %s starts without changing stage position" % style)
		actor.stop_dance()
		check(not actor.is_processing() and actor.dance_time_left == 0.0, "Stopping %s cancels animation processing" % style)
	actor.set_dance_style("unsafe-unknown-style")
	check(actor.dance_style == "confident", "Unknown dance style has a known fallback")
	actor.set_reduced_motion(true)
	actor.dance(0.5)
	actor._process(0.5)
	check(actor.dance_time_left == 0.0 and not actor.is_processing(), "Reduced motion dance duration still completes")
	actor.walking = true
	check(actor.is_processing(), "Walking enables actor processing")
	actor.walking = false
	check(not actor.is_processing(), "Arriving disables actor processing")
	var source := {"apple_given": true}
	actor.sync_reaction(source)
	source.clear()
	check(actor.reaction.get("apple_given", false), "Actor reaction keeps an isolated snapshot")
	var sounds := Sounds.new()
	sounds.enabled = false
	root.add_child(sounds)
	await process_frame
	check(sounds._streams.size() == 10, "Gameplay and travel audio cues are prepared offline")
	for mode in ["door", "walk", "taxi", "elevator", "rope", "terrace"]:
		check(sounds._streams.has("travel_" + mode), "Travel mode has a prepared cue: " + mode)
	for cue in sounds._streams:
		var stream: AudioStreamWAV = sounds._streams[cue]
		check(stream.mix_rate == 22050 and not stream.stereo and stream.get_length() < 0.3, "%s cue is short mono PCM" % cue)
		sounds.play_cue(cue)
		check(not sounds._player.playing, "Disabled effects cannot play %s cue" % cue)
	sounds.set_volume(-1.0)
	check(sounds.volume == 0.0, "Negative volume clamps to silence")
	sounds.set_volume(2.0)
	check(sounds.volume == 1.0, "Effect volume clamps to full scale")
	sounds.set_enabled(true)
	sounds.set_volume(0.0)
	sounds.play_cue("pickup")
	check(not sounds._player.playing, "Zero-volume effect never starts playback")
	sounds.play_cue("invalid")
	check(not sounds._player.playing, "Unknown cue is ignored safely")
	if "--capture-props" in OS.get_cmdline_user_args():
		await _capture(effects)
	effects.queue_free()
	actor.queue_free()
	sounds.queue_free()
	await process_frame
	print("Upgrade visuals: %d passed, %d failed" % [assertions - failures.size(), failures.size()])
	quit(0 if failures.is_empty() else 1)

func _capture(effects: Control) -> void:
	root.size = Vector2i(1140, 553)
	root.content_scale_size = Vector2i(1140, 553)
	var background := TextureRect.new()
	background.size = Vector2(1140, 553)
	background.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	background.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_COVERED
	root.add_child(background)
	root.move_child(background, 0)
	effects.size = Vector2(1140, 553)
	effects.set_reduced_motion(true)
	var finished := {"taken_stool": true, "stool_placed": true, "taken_core": true, "taken_hammer": true, "taken_pitcher": true, "taken_ring": true, "taken_candy": true, "taken_voucher": true, "window_open": true, "rope_taken": true, "rope_anchored": true, "tv_distracted": true, "coffee_delivered": true, "apple_given": true, "show_started": true, "show_beat_2": true, "gift_ring": true, "gift_flowers": true, "gift_candy": true}
	DirAccess.make_dir_recursive_absolute("res://exports/prop-captures")
	for room in Effects.PROP_ROOMS:
		for phase in ["before", "after"]:
			background.texture = load(Effects.background_path_for(room, finished if phase == "after" else {}))
			effects.sync_state(room, finished if phase == "after" else {})
			await process_frame
			await RenderingServer.frame_post_draw
			root.get_texture().get_image().save_png("res://exports/prop-captures/%s-%s.png" % [room, phase])
	background.queue_free()
