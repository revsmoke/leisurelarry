extends Node
## Short original synthesized cues. No files, network, looping audio, or gameplay rules.
## Every cue accompanies visible UI feedback; muted play retains all information.
const SAMPLE_RATE := 22050
const CUE_NOTES := {
	"pickup": [523.25, 659.25, 783.99],
	"refusal": [220.0, 185.0],
	"transition": [329.63, 440.0],
	"punchline": [392.0, 523.25, 349.23]
}
var enabled := true
var volume := 0.5
var _player: AudioStreamPlayer
var _streams: Dictionary = {}

func _ready() -> void:
	_player = AudioStreamPlayer.new()
	_player.volume_db = linear_to_db(volume) - 12.0
	add_child(_player)
	for cue in CUE_NOTES:
		_streams[cue] = _make_stream(CUE_NOTES[cue])

func set_enabled(value: bool) -> void:
	enabled = value
	if not enabled and is_instance_valid(_player):
		_player.stop()

func set_volume(value: float) -> void:
	volume = clampf(value, 0.0, 1.0)
	if is_instance_valid(_player):
		_player.volume_db = linear_to_db(maxf(volume, 0.00001)) - 12.0
		if volume == 0.0:
			_player.stop()

func play_cue(cue: String) -> void:
	if not enabled or volume <= 0.0 or not is_instance_valid(_player) or not _streams.has(cue):
		return
	_player.stream = _streams[cue]
	_player.play()

func _make_stream(notes: Array) -> AudioStreamWAV:
	var samples_per_note := int(SAMPLE_RATE * 0.065)
	var data := PackedByteArray()
	data.resize(samples_per_note * notes.size() * 2)
	for note_index in range(notes.size()):
		var frequency := float(notes[note_index])
		for index in range(samples_per_note):
			var progress := float(index) / float(samples_per_note)
			var envelope := minf(progress * 20.0, 1.0) * pow(1.0 - progress, 1.6)
			var phase := TAU * frequency * float(index) / SAMPLE_RATE
			var wave := (sin(phase) + 0.15 * sin(phase * 2.0)) * 0.4 * envelope
			var pcm := clampi(roundi(wave * 32767.0), -32768, 32767)
			data.encode_s16((note_index * samples_per_note + index) * 2, pcm)
	var stream := AudioStreamWAV.new()
	stream.format = AudioStreamWAV.FORMAT_16_BITS
	stream.mix_rate = SAMPLE_RATE
	stream.stereo = false
	stream.data = data
	return stream
