extends SceneTree
## Synthesizes the game's original sound effects and music loop into WAV assets.
## Run:  GODOT --headless --path . --script res://tools/generate_audio.gd
## Output: res://assets/audio/sfx/*.wav and res://assets/audio/music/table_loop.wav
## Shipping real files (instead of building AudioStreamWAVs at runtime) keeps Web exports,
## which use sample playback, reliable.

const RATE: int = 22050
var rng := RandomNumberGenerator.new()

func _initialize() -> void:
	rng.seed = 38
	DirAccess.make_dir_recursive_absolute("res://assets/audio/sfx")
	DirAccess.make_dir_recursive_absolute("res://assets/audio/music")
	var cues: Dictionary = {
		"roll": _roll(), "land": _land(), "max": _chime([1318.5, 1975.5], 0.45),
		"buy": _coin([1567.98, 2093.0]), "sell": _coin([1760.0, 1318.5]),
		"combo": _arpeggio([523.25, 659.25, 783.99, 1046.5], 0.07, 0.5),
		"streak": _sweep(380.0, 980.0, 0.28), "arc": _zap(), "blast": _blast(),
		"gild": _shimmer(), "capsule": _capsule(), "click": _click(),
	}
	for id in cues:
		_save(cues[id], "res://assets/audio/sfx/%s.wav" % id)
	_save(_music(), "res://assets/audio/music/table_loop.wav")
	print("AUDIO: wrote %d effects and one music loop" % cues.size())
	quit()

# --- helpers -------------------------------------------------------------------

func _buffer(seconds: float) -> PackedFloat32Array:
	var data := PackedFloat32Array()
	data.resize(int(seconds * RATE))
	return data

func _save(samples: PackedFloat32Array, path: String) -> void:
	var peak: float = 0.0001
	for value in samples:
		peak = maxf(peak, absf(value))
	var gain: float = 0.89 / peak
	var bytes := PackedByteArray()
	bytes.resize(samples.size() * 2)
	for index in samples.size():
		bytes.encode_s16(index * 2, int(clampf(samples[index] * gain, -1.0, 1.0) * 32767.0))
	var wave := AudioStreamWAV.new()
	wave.format = AudioStreamWAV.FORMAT_16_BITS
	wave.mix_rate = RATE
	wave.data = bytes
	wave.save_to_wav(path)

func _env(t: float, attack: float, decay: float) -> float:
	return minf(1.0, t / maxf(attack, 0.0001)) * exp(-t / decay)

func _bell(data: PackedFloat32Array, start: float, freq: float, length: float, amp: float) -> void:
	# Inharmonic partials give a small, glassy bell.
	var partials: Array = [[1.0, 1.0], [2.76, 0.4], [5.4, 0.18], [8.93, 0.07]]
	for index in range(int(start * RATE), mini(data.size(), int((start + length) * RATE))):
		var t: float = float(index) / RATE - start
		var value: float = 0.0
		for p in partials:
			value += sin(TAU * freq * p[0] * t) * p[1] * exp(-t * (3.0 + p[0]))
		data[index] += value * amp * minf(1.0, t * 400.0)

func _noise_burst(data: PackedFloat32Array, start: float, length: float, amp: float, brightness: float) -> void:
	var low: float = 0.0
	for index in range(int(start * RATE), mini(data.size(), int((start + length) * RATE))):
		var t: float = float(index) / RATE - start
		var white: float = rng.randf_range(-1.0, 1.0)
		low += (white - low) * brightness
		data[index] += low * amp * exp(-t / (length * 0.35))

# --- effects --------------------------------------------------------------------

func _roll() -> PackedFloat32Array:
	var data := _buffer(0.32)
	var t: float = 0.0
	while t < 0.26:
		_noise_burst(data, t, 0.025, rng.randf_range(0.5, 1.0), 0.55)
		_bell(data, t, rng.randf_range(900, 1400), 0.03, 0.08)
		t += rng.randf_range(0.025, 0.06)
	return data

func _land() -> PackedFloat32Array:
	var data := _buffer(0.22)
	for index in data.size():
		var t: float = float(index) / RATE
		var freq: float = 190.0 * exp(-t * 6.0) + 120.0
		data[index] = sin(TAU * freq * t) * _env(t, 0.002, 0.05)
	_noise_burst(data, 0.0, 0.03, 0.6, 0.7)
	return data

func _chime(notes: Array, length: float) -> PackedFloat32Array:
	var data := _buffer(length + 0.1 * notes.size())
	for index in notes.size():
		_bell(data, index * 0.07, notes[index], length, 0.8)
	return data

func _coin(notes: Array) -> PackedFloat32Array:
	var data := _buffer(0.5)
	_noise_burst(data, 0.0, 0.02, 0.4, 0.9)
	for index in notes.size():
		_bell(data, 0.01 + index * 0.075, notes[index], 0.4, 0.7)
	return data

func _arpeggio(notes: Array, step: float, tail: float) -> PackedFloat32Array:
	var data := _buffer(step * notes.size() + tail)
	for index in notes.size():
		_bell(data, index * step, notes[index], tail, 0.6)
	return data

func _sweep(from: float, to: float, length: float) -> PackedFloat32Array:
	var data := _buffer(length + 0.05)
	var phase: float = 0.0
	for index in data.size():
		var t: float = float(index) / RATE
		var k: float = clampf(t / length, 0.0, 1.0)
		phase += TAU * lerpf(from, to, k * k) / RATE
		data[index] = (sin(phase) + 0.3 * sin(phase * 2.0)) * _env(t, 0.02, length * 0.6)
	return data

func _zap() -> PackedFloat32Array:
	var data := _buffer(0.3)
	var phase: float = 0.0
	for index in data.size():
		var t: float = float(index) / RATE
		phase += TAU * (520.0 + 380.0 * sin(TAU * 31.0 * t)) / RATE
		var buzz: float = signf(sin(phase)) * 0.5 + sin(phase * 3.0) * 0.2
		data[index] = (buzz + rng.randf_range(-0.4, 0.4)) * _env(t, 0.003, 0.08)
	return data

func _blast() -> PackedFloat32Array:
	var data := _buffer(0.6)
	var phase: float = 0.0
	for index in data.size():
		var t: float = float(index) / RATE
		phase += TAU * (40.0 + 110.0 * exp(-t * 9.0)) / RATE
		data[index] = sin(phase) * _env(t, 0.004, 0.18)
	_noise_burst(data, 0.0, 0.4, 0.8, 0.25)
	return data

func _shimmer() -> PackedFloat32Array:
	var data := _buffer(0.8)
	for index in 7:
		_bell(data, index * 0.05, 1567.98 * pow(1.122, index % 4) * (1.0 + 0.5 * int(index / 4)), 0.5, 0.35)
	return data

func _capsule() -> PackedFloat32Array:
	var data := _buffer(0.7)
	for index in int(0.06 * RATE):
		var t: float = float(index) / RATE
		data[index] = sin(TAU * (300.0 + 2500.0 * t) * t) * _env(t, 0.002, 0.03)
	for index in 3:
		_bell(data, 0.12 + index * 0.08, [1046.5, 1318.5, 2093.0][index], 0.45, 0.5)
	return data

func _click() -> PackedFloat32Array:
	var data := _buffer(0.05)
	_noise_burst(data, 0.0, 0.015, 0.7, 0.9)
	_bell(data, 0.0, 2400.0, 0.04, 0.2)
	return data

# --- music ----------------------------------------------------------------------
## A warm 8-bar loop at 84 BPM: soft electric-piano chords, round bass, a plucked
## arpeggio and brushed off-beats. Fmaj7 – Em7 – Dm7 – Cmaj7, twice; the second pass
## lifts the melody an octave. The tail wraps into the start so the loop is seamless.

func _music() -> PackedFloat32Array:
	var bpm: float = 84.0
	var beat: float = 60.0 / bpm
	var bars: int = 8
	var data := _buffer(bars * 4 * beat)
	var chords: Array = [
		[53, [65, 69, 72, 76]], [52, [64, 67, 71, 74]], [50, [62, 65, 69, 72]], [48, [60, 64, 67, 71]]]
	for bar in bars:
		var chord: Array = chords[bar % 4]
		var start: float = bar * 4 * beat
		for note in chord[1]:
			_pad(data, start, 4 * beat, _hz(note), 0.11)
		_bass(data, start, 1.6 * beat, _hz(chord[0] - 12), 0.32)
		_bass(data, start + 2 * beat, 1.6 * beat, _hz(chord[0] - 12 + (7 if bar % 2 == 0 else 12)), 0.24)
		var arp: Array = chord[1]
		for step in 8:
			var note: int = arp[[0, 1, 2, 3, 2, 1, 2, 3][step]] + (12 if bar >= 4 else 0)
			if step == 7 and bar % 2 == 1:
				continue
			_pluck(data, start + step * 0.5 * beat, 0.9 * beat, _hz(note), 0.12 if step % 2 == 0 else 0.08)
		for step in 4:
			_noise_burst(data, start + (step + 0.5) * beat, 0.09, 0.05, 0.35)
	# Fade the first and last 20 ms against each other so the loop point is click-free.
	var fade: int = int(0.02 * RATE)
	for index in fade:
		var k: float = float(index) / fade
		data[index] *= k
		data[data.size() - 1 - index] *= k
	return data

func _hz(midi: int) -> float:
	return 440.0 * pow(2.0, (midi - 69) / 12.0)

func _pad(data: PackedFloat32Array, start: float, length: float, freq: float, amp: float) -> void:
	for index in range(int(start * RATE), mini(data.size(), int((start + length) * RATE))):
		var t: float = float(index) / RATE - start
		var env: float = minf(1.0, t / 0.08) * minf(1.0, (length - t) / 0.25) * (0.7 + 0.3 * exp(-t * 1.5))
		var tremolo: float = 1.0 + 0.06 * sin(TAU * 4.5 * t)
		data[index] += (sin(TAU * freq * t) + 0.25 * sin(TAU * freq * 2.0 * t) + 0.08 * sin(TAU * freq * 3.0 * t)) * env * tremolo * amp

func _bass(data: PackedFloat32Array, start: float, length: float, freq: float, amp: float) -> void:
	for index in range(int(start * RATE), mini(data.size(), int((start + length) * RATE))):
		var t: float = float(index) / RATE - start
		var env: float = minf(1.0, t / 0.01) * exp(-t / (length * 0.7))
		data[index] += (sin(TAU * freq * t) + 0.15 * sin(TAU * freq * 2.0 * t)) * env * amp

func _pluck(data: PackedFloat32Array, start: float, length: float, freq: float, amp: float) -> void:
	for index in range(int(start * RATE), mini(data.size(), int((start + length) * RATE))):
		var t: float = float(index) / RATE - start
		var phase: float = fmod(freq * t, 1.0)
		var triangle: float = 4.0 * absf(phase - 0.5) - 1.0
		data[index] += (triangle * 0.6 + sin(TAU * freq * t) * 0.4) * _env(t, 0.003, 0.18) * amp
