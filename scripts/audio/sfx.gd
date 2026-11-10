extends Node

## Efectos de sonido generados por codigo (no necesita archivos de audio):
## bips de tarjeta, estatica de radio, recoger objetos, puertas y el zumbido de las luces.
## Todo suena por el bus "Master", asi que el volumen de Opciones lo controla.

const RATE := 22050

var _streams: Dictionary = {}
var _players: Array[AudioStreamPlayer] = []
var _hum: AudioStreamPlayer


func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	_streams["pickup"] = _tonos([[660.0, 0.07], [990.0, 0.10]], 0.35)
	_streams["beep_ok"] = _tonos([[880.0, 0.10], [1320.0, 0.16]], 0.4)
	_streams["beep_no"] = _tonos([[180.0, 0.28]], 0.45, true)
	_streams["tecla"] = _tonos([[1200.0, 0.04]], 0.25)
	_streams["static"] = _ruido(0.65, 0.5)
	_streams["papel"] = _ruido(0.22, 0.25, 0.35)
	_streams["puerta"] = _golpe(0.35)
	_streams["golpe"] = _golpe(0.6)
	_streams["paso_jugador"] = _golpe(0.16)
	_streams["latido"] = _latido()
	_streams["radio_in"] = _squelch(0.16, 0.5)
	_streams["radio_out"] = _squelch_con_pitido()
	_streams["clank"] = _metal()
	_streams["pitido"] = _tonos([[1900.0, 0.06], [0.0, 0.05], [1900.0, 0.06]], 0.35)
	_streams["chispa"] = _ruido(0.25, 0.5, 0.0)
	_streams["arrastre"] = _ruido(0.7, 0.55, 0.93)
	for i in 6:
		var p := AudioStreamPlayer.new()
		add_child(p)
		_players.append(p)
	_hum = AudioStreamPlayer.new()
	_hum.stream = _zumbido()
	_hum.volume_db = -26.0
	add_child(_hum)


## Enciende / apaga el zumbido ambiental de las luces (solo se usa dentro del museo).
func zumbido(activo: bool) -> void:
	if activo and not _hum.playing:
		_hum.play()
	elif not activo:
		_hum.stop()


func tocar(nombre: String, volumen_db: float = 0.0) -> void:
	if not _streams.has(nombre):
		return
	for p in _players:
		if not p.playing:
			p.stream = _streams[nombre]
			p.volume_db = volumen_db
			p.play()
			return


# ---------------------------------------------------------------- generadores

func _a_stream(muestras: PackedFloat32Array, loop: bool = false) -> AudioStreamWAV:
	var s := AudioStreamWAV.new()
	s.format = AudioStreamWAV.FORMAT_16_BITS
	s.mix_rate = RATE
	s.stereo = false
	var bytes := PackedByteArray()
	bytes.resize(muestras.size() * 2)
	for i in muestras.size():
		bytes.encode_s16(i * 2, int(clampf(muestras[i], -1.0, 1.0) * 32767.0))
	s.data = bytes
	if loop:
		s.loop_mode = AudioStreamWAV.LOOP_FORWARD
		s.loop_begin = 0
		s.loop_end = muestras.size()
	return s


## Serie de tonos [[frecuencia, duracion], ...]; cuadrada = sonido "buzzer".
func _tonos(tonos: Array, amp: float, cuadrada: bool = false) -> AudioStreamWAV:
	var m := PackedFloat32Array()
	for t in tonos:
		var f: float = t[0]
		var dur: float = t[1]
		var n := int(dur * RATE)
		for i in n:
			var fase := float(i) / RATE
			var env := minf(1.0, float(n - i) / (RATE * 0.03)) * minf(1.0, float(i) / (RATE * 0.005))
			var v := sin(TAU * f * fase)
			if cuadrada:
				v = signf(v) * 0.6
			m.append(v * amp * env)
	return _a_stream(m)


func _ruido(dur: float, amp: float, suavizado: float = 0.0) -> AudioStreamWAV:
	var rng := RandomNumberGenerator.new()
	rng.seed = 7
	var m := PackedFloat32Array()
	var n := int(dur * RATE)
	var prev := 0.0
	for i in n:
		var env := sin(PI * float(i) / n)
		var r := rng.randf_range(-1.0, 1.0)
		prev = lerpf(r, prev, suavizado)
		m.append(prev * amp * env)
	return _a_stream(m)


func _golpe(dur: float) -> AudioStreamWAV:
	var rng := RandomNumberGenerator.new()
	rng.seed = 3
	var m := PackedFloat32Array()
	var n := int(dur * RATE)
	for i in n:
		var t := float(i) / RATE
		var env := exp(-t * 14.0)
		var v := sin(TAU * 70.0 * t) * 0.8 + rng.randf_range(-1.0, 1.0) * 0.2
		m.append(v * env * 0.7)
	return _a_stream(m)


## Rafaga de ruido de radio: se abre / se cierra el canal del walkie.
func _squelch(dur: float, amp: float) -> AudioStreamWAV:
	var rng := RandomNumberGenerator.new()
	rng.seed = 11
	var m := PackedFloat32Array()
	var n := int(dur * RATE)
	var prev := 0.0
	for i in n:
		var env := minf(1.0, float(i) / (RATE * 0.01)) * minf(1.0, float(n - i) / (RATE * 0.08))
		var r := rng.randf_range(-1.0, 1.0)
		prev = lerpf(r, prev, 0.2)
		m.append(prev * amp * env)
	return _a_stream(m)


func _squelch_con_pitido() -> AudioStreamWAV:
	var rng := RandomNumberGenerator.new()
	rng.seed = 5
	var m := PackedFloat32Array()
	var n := int(0.2 * RATE)
	var prev := 0.0
	for i in n:
		var env := minf(1.0, float(n - i) / (RATE * 0.12))
		prev = lerpf(rng.randf_range(-1.0, 1.0), prev, 0.2)
		m.append(prev * 0.45 * env)
	var np := int(0.06 * RATE)
	for i in np:
		m.append(sin(TAU * 1900.0 * float(i) / RATE) * 0.2 * minf(1.0, float(np - i) / (RATE * 0.02)))
	return _a_stream(m)


## Choque de metal (armaduras): varios armonicos inarmonicos con caida rapida.
func _metal() -> AudioStreamWAV:
	var m := PackedFloat32Array()
	var n := int(0.35 * RATE)
	var rng := RandomNumberGenerator.new()
	rng.seed = 21
	for i in n:
		var t := float(i) / RATE
		var v := sin(TAU * 830.0 * t) * 0.4 + sin(TAU * 1370.0 * t) * 0.3 + sin(TAU * 2310.0 * t) * 0.2 + rng.randf_range(-0.25, 0.25)
		m.append(v * exp(-t * 14.0) * 0.8)
	return _a_stream(m)


## Latido del corazon: dos golpes graves (sube la tension cuando una estatua se acerca).
func _latido() -> AudioStreamWAV:
	var m := PackedFloat32Array()
	var n := int(0.55 * RATE)
	for i in n:
		var t := float(i) / RATE
		var g1 := exp(-t * 16.0) * sin(TAU * 58.0 * t)
		var t2 := t - 0.2
		var g2 := 0.0
		if t2 > 0.0:
			g2 = 0.8 * exp(-t2 * 16.0) * sin(TAU * 52.0 * t2)
		m.append((g1 + g2) * 0.9)
	return _a_stream(m)


## Zumbido grave de luces fluorescentes (loop de 1 s: 60, 120 y 180 Hz, enteros -> sin clic).
func _zumbido() -> AudioStreamWAV:
	var m := PackedFloat32Array()
	for i in RATE:
		var t := float(i) / RATE
		var v := sin(TAU * 60.0 * t) * 0.5 + sin(TAU * 120.0 * t) * 0.3 + sin(TAU * 180.0 * t) * 0.12
		m.append(v * 0.35)
	return _a_stream(m, true)
