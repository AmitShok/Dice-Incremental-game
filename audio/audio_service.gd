class_name AudioService
extends Node
var settings: Dictionary
var voices: Array[AudioStreamPlayer] = []
var bank: Dictionary = {}
var cursor: int = 0

func _ready() -> void:
	for bus_name in ["Music", "Ambience", "Dice", "UI", "Money", "Helpers", "Machines", "Effects"]:
		if AudioServer.get_bus_index(bus_name) < 0:
			AudioServer.add_bus()
			AudioServer.set_bus_name(AudioServer.bus_count - 1, bus_name)
	for index in 12:
		var voice := AudioStreamPlayer.new()
		add_child(voice)
		voices.append(voice)
	bank["roll"] = _tone(210.0, 0.09, 0.5)
	bank["land"] = _tone(135.0, 0.12, 0.75)
	bank["max"] = _tone(880.0, 0.22, 0.08)
	bank["buy"] = _tone(660.0, 0.16, 0.03)
	bank["combo"] = _tone(1100.0, 0.35, 0.1)

func _tone(frequency: float, duration: float, noise_amount: float) -> AudioStreamWAV:
	var wave := AudioStreamWAV.new()
	wave.format = AudioStreamWAV.FORMAT_16_BITS
	wave.mix_rate = 22050
	var samples: int = int(duration * wave.mix_rate)
	var bytes := PackedByteArray()
	bytes.resize(samples * 2)
	var rng := RandomNumberGenerator.new()
	rng.seed = int(frequency)
	for index in samples:
		var t: float = float(index) / wave.mix_rate
		var envelope: float = pow(1.0 - float(index) / samples, 3.0) * minf(1, t * 900)
		var signal_value: float = (sin(TAU * frequency * t) + sin(TAU * frequency * 1.5 * t) * 0.3) * (1 - noise_amount) + rng.randf_range(-1, 1) * noise_amount
		bytes.encode_s16(index * 2, int(signal_value * envelope * 10000))
	wave.data = bytes
	return wave

func play(cue: String) -> void:
	if not settings.get("sound", true) or not bank.has(cue) or voices.is_empty():
		return
	var voice: AudioStreamPlayer = voices[cursor]
	cursor = (cursor + 1) % voices.size()
	voice.stream = bank[cue]
	voice.bus = "Dice" if cue in ["roll", "land"] else "Effects"
	voice.volume_db = linear_to_db(maxf(0.001, float(settings.get("volume", 0.55)))) - 7
	voice.pitch_scale = randf_range(0.94, 1.06)
	voice.play()
