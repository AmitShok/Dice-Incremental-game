class_name AudioService
extends Node
## Plays imported WAV cues on the Sfx bus and a looping track on the Music bus.
## Buses come from res://default_bus_layout.tres (never created at runtime) and every
## stream is an imported asset, which keeps Web exports using sample playback reliable.
## Sounds regenerate with tools/generate_audio.gd.

const CUES: Dictionary = {
	"roll": preload("res://assets/audio/sfx/roll.wav"),
	"land": preload("res://assets/audio/sfx/land.wav"),
	"max": preload("res://assets/audio/sfx/max.wav"),
	"buy": preload("res://assets/audio/sfx/buy.wav"),
	"sell": preload("res://assets/audio/sfx/sell.wav"),
	"combo": preload("res://assets/audio/sfx/combo.wav"),
	"streak": preload("res://assets/audio/sfx/streak.wav"),
	"arc": preload("res://assets/audio/sfx/arc.wav"),
	"blast": preload("res://assets/audio/sfx/blast.wav"),
	"gild": preload("res://assets/audio/sfx/gild.wav"),
	"capsule": preload("res://assets/audio/sfx/capsule.wav"),
	"click": preload("res://assets/audio/sfx/click.wav"),
}
const MUSIC: AudioStream = preload("res://assets/audio/music/table_loop.wav")
## Per-cue trims so frequent cues sit under rarer celebratory ones.
const LEVELS: Dictionary = {"roll": -10.0, "land": -9.0, "click": -8.0, "max": -4.0, "buy": -5.0, "sell": -5.0}

var settings: Dictionary
var voices: Array[AudioStreamPlayer] = []
var music: AudioStreamPlayer
var cursor: int = 0
var last_played: Dictionary = {}

func _ready() -> void:
	for index in 12:
		var voice := AudioStreamPlayer.new()
		voice.bus = &"Sfx"
		add_child(voice)
		voices.append(voice)
	music = AudioStreamPlayer.new()
	music.bus = &"Music"
	music.stream = MUSIC
	add_child(music)
	music.finished.connect(func(): if _music_wanted(): music.play())
	apply_settings()

func _music_wanted() -> bool:
	return settings != null and bool(settings.get("music", true)) and not OS.get_cmdline_user_args().has("--test")

## Call after any settings change; starts/stops music and applies volume.
func apply_settings() -> void:
	if settings == null:
		return
	var volume: float = float(settings.get("volume", 0.55))
	music.volume_db = linear_to_db(maxf(0.001, volume)) - 8.0
	if _music_wanted() and not music.playing:
		music.play()
	elif not _music_wanted() and music.playing:
		music.stop()

func play(cue: String) -> void:
	if settings == null or not settings.get("sound", true) or not CUES.has(cue) or voices.is_empty():
		return
	# Large tables can land dozens of dice per frame; one voice per cue per 40 ms is plenty.
	var now: int = Time.get_ticks_msec()
	if now - int(last_played.get(cue, -1000)) < 40:
		return
	last_played[cue] = now
	var voice: AudioStreamPlayer = voices[cursor]
	cursor = (cursor + 1) % voices.size()
	voice.stream = CUES[cue]
	voice.volume_db = linear_to_db(maxf(0.001, float(settings.get("volume", 0.55)))) + float(LEVELS.get(cue, -6.0))
	voice.pitch_scale = randf_range(0.94, 1.06)
	voice.play()
