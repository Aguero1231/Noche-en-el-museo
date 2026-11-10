extends Node3D

## Camaras de seguridad reales: cada camara es un SubViewport que renderiza el museo
## y los monitores (oficina de seguridad y sala de control) muestran esa imagen con
## efecto CRT: scanlines, ruido, desfase de color y glitch. Las camaras sin senal
## (pisos superiores) muestran estatica.
##
## Para cuidar el rendimiento solo se redibujan las camaras que algun monitor cercano
## al jugador esta mostrando, a pocos cuadros por segundo (como un CCTV de verdad).

const GameState = preload("res://scripts/game/game_state.gd")
const BuildUtils = preload("res://scripts/environment/build_utils.gd")

const SHADER_CODE := """
shader_type spatial;
render_mode unshaded, cull_back;

uniform sampler2D feed : source_color, filter_linear;
uniform bool tiene_senal = true;
uniform vec4 tinte : source_color = vec4(0.80, 1.0, 0.86, 1.0);
uniform float brillo = 1.0;
uniform float semilla = 0.0;

float hash(vec2 p) {
	return fract(sin(dot(p, vec2(12.9898, 78.233))) * 43758.5453);
}

void fragment() {
	vec2 c = UV * 2.0 - 1.0;
	float r2 = dot(c, c);
	c *= 1.0 + 0.05 * r2;
	vec2 uv = c * 0.5 + 0.5;
	float dentro = step(0.0, uv.x) * step(uv.x, 1.0) * step(0.0, uv.y) * step(uv.y, 1.0);
	vec3 col = vec3(0.0);
	if (tiene_senal) {
		float linea = floor(uv.y * 150.0);
		float g = hash(vec2(linea, floor(TIME * 5.0) + semilla)) > 0.988 ? 0.014 : 0.0;
		vec3 s;
		s.r = texture(feed, uv + vec2(g + 0.0016, 0.0)).r;
		s.g = texture(feed, uv + vec2(g, 0.0)).g;
		s.b = texture(feed, uv + vec2(g - 0.0016, 0.0)).b;
		float luma = dot(s, vec3(0.3, 0.59, 0.11));
		col = mix(s, vec3(luma), 0.5) * tinte.rgb * 1.35;
	} else {
		float n = hash(floor(uv * vec2(140.0, 100.0)) + vec2(floor(TIME * 24.0), semilla));
		col = vec3(n * 0.6) * tinte.rgb;
	}
	col += (hash(uv * vec2(300.0, 220.0) + TIME) - 0.5) * 0.06;
	col *= 0.84 + 0.16 * sin(uv.y * 220.0 * 3.14159);
	float barra = smoothstep(0.0, 0.1, fract(uv.y - TIME * 0.12)) * 0.07;
	col *= 1.0 - barra;
	col *= 1.0 - 0.5 * pow(r2, 2.0);
	ALBEDO = col * brillo * dentro;
}
"""

var estado: GameState
var feeds: Array[Dictionary] = []
var monitores: Array[Dictionary] = []

var _u := BuildUtils.new()
var _shader: Shader
var _acc := 0.0
var _idx := 0
var _jugador := Vector3(0, 0, 1000)
var _leds: Array[MeshInstance3D] = []
var _t := 0.0


func _ready() -> void:
	_shader = Shader.new()
	_shader.code = SHADER_CODE
	Settings.changed.connect(_on_settings_changed)


# ---------------------------------------------------------------- camaras

func _tam_feed() -> Vector2i:
	match Settings.quality:
		0:
			return Vector2i(160, 120)
		2:
			return Vector2i(320, 240)
	return Vector2i(224, 168)


func _renders_por_segundo() -> float:
	match Settings.quality:
		0:
			return 4.0
		2:
			return 15.0
	return 8.0


## defs: [{nombre, pos, mira, fov}] en coordenadas del mundo. Devuelve el indice de cada feed en orden.
func crear_camaras(defs: Array) -> void:
	for d in defs:
		var def: Dictionary = d
		var vp := SubViewport.new()
		vp.size = _tam_feed()
		vp.render_target_update_mode = SubViewport.UPDATE_DISABLED
		vp.msaa_3d = Viewport.MSAA_DISABLED
		add_child(vp)

		var pos: Vector3 = def["pos"]
		var mira: Vector3 = def["mira"]
		var dir := (mira - pos).normalized()
		var cam := Camera3D.new()
		cam.fov = float(def.get("fov", 70.0))
		cam.near = 0.1
		vp.add_child(cam)
		cam.look_at_from_position(pos + dir * 0.35, mira)
		cam.current = true

		var f_nombre := _label_feed(String(def["nombre"]), Vector2(8, 6), Color(1, 1, 1))
		vp.add_child(f_nombre)
		var f_rec := _label_feed("● REC", Vector2(vp.size.x - 62, 6), Color(1.0, 0.25, 0.2))
		vp.add_child(f_rec)
		var f_hora := _label_feed("", Vector2(8, vp.size.y - 24), Color(1, 1, 1))
		vp.add_child(f_hora)

		feeds.append({"nombre": def["nombre"], "vp": vp, "hora": f_hora, "rec": f_rec})
		_crear_prop_camara(pos, mira)
		_redibujar(feeds.size() - 1)


func _label_feed(texto: String, pos: Vector2, color: Color) -> Label:
	var l := Label.new()
	l.text = texto
	l.position = pos
	l.add_theme_font_size_override("font_size", 13)
	l.add_theme_color_override("font_color", color)
	l.add_theme_color_override("font_outline_color", Color.BLACK)
	l.add_theme_constant_override("outline_size", 4)
	return l


func _crear_prop_camara(pos: Vector3, mira: Vector3) -> void:
	var raiz := Node3D.new()
	raiz.position = pos
	add_child(raiz)
	raiz.look_at(mira, Vector3.UP)
	_u.box(raiz, Vector3(0, 0, 0), Vector3(0.14, 0.14, 0.36), _u.mat(Color(0.12, 0.12, 0.13), 0.4, 0.5))
	_u.cyl(raiz, Vector3(0, 0, -0.2), 0.05, 0.05, 0.06, _u.mat(Color(0.02, 0.02, 0.03), 0.1, 0.8), Vector3(90, 0, 0))
	var led := _u.sphere(raiz, Vector3(0.05, 0.06, -0.12), 0.012, _u.mat(Color(0.3, 0.0, 0.0), 0.5, 0.0, Color(1.0, 0.05, 0.05), 3.0))
	_leds.append(led)
	_u.box(raiz, Vector3(0, 0.1, 0.12), Vector3(0.05, 0.12, 0.05), _u.metal())


func _on_settings_changed(key: String) -> void:
	if key == "quality":
		for f in feeds:
			(f["vp"] as SubViewport).size = _tam_feed()


# ---------------------------------------------------------------- monitores

## Monitor de pared / escritorio. feed = indice de camara, o -1 para "SIN SEÑAL".
## Devuelve {raiz, mat, feed, pos}. Mira hacia +z local.
func crear_monitor(parent: Node3D, pos: Vector3, rot_y_deg: float, ancho: float, feed: int) -> Dictionary:
	var raiz := Node3D.new()
	raiz.position = pos
	raiz.rotation_degrees.y = rot_y_deg
	parent.add_child(raiz)
	var alto := ancho * 0.75
	var carcasa := _u.mat(Color(0.20, 0.19, 0.17), 0.6, 0.2)
	_u.box(raiz, Vector3(0, 0, -0.15), Vector3(ancho + 0.1, alto + 0.1, 0.3), carcasa, false, Vector3.ZERO, "Carcasa")
	var m := ShaderMaterial.new()
	m.shader = _shader
	m.set_shader_parameter("semilla", float(monitores.size()) * 3.7)
	var pantalla := _u.quad(raiz, Vector3(0, 0, 0.003), Vector2(ancho, alto), m)
	pantalla.name = "Pantalla"
	# Botoncito de encendido
	_u.box(raiz, Vector3(ancho * 0.5 - 0.02, -alto * 0.5 - 0.02, 0.01), Vector3(0.03, 0.015, 0.01), _u.mat(Color(0.1, 0.9, 0.2), 0.5, 0.0, Color(0.1, 0.9, 0.2), 2.0))
	var mon: Dictionary = {"raiz": raiz, "mat": m, "feed": feed}
	monitores.append(mon)
	asignar_feed(mon, feed)
	return mon


func asignar_feed(mon: Dictionary, feed: int) -> void:
	mon["feed"] = feed
	var m := mon["mat"] as ShaderMaterial
	if feed >= 0 and feed < feeds.size():
		m.set_shader_parameter("tiene_senal", true)
		m.set_shader_parameter("feed", (feeds[feed]["vp"] as SubViewport).get_texture())
	else:
		m.set_shader_parameter("tiene_senal", false)


func siguiente_feed(mon: Dictionary) -> String:
	var n := feeds.size()
	if n == 0:
		return ""
	var nuevo := (int(mon["feed"]) + 1) % n
	asignar_feed(mon, nuevo)
	_redibujar(nuevo)
	return String(feeds[nuevo]["nombre"])


# ---------------------------------------------------------------- actualizacion

func set_jugador(pos: Vector3) -> void:
	_jugador = pos


func _redibujar(i: int) -> void:
	var f := feeds[i]
	if estado:
		(f["hora"] as Label).text = "VIE 13/10/2026  " + estado.hora_con_segundos()
	(f["vp"] as SubViewport).render_target_update_mode = SubViewport.UPDATE_ONCE


func _feed_visible(i: int) -> bool:
	for mon in monitores:
		if int(mon["feed"]) == i:
			var p := (mon["raiz"] as Node3D).global_position
			if p.distance_to(_jugador) < 16.0:
				return true
	return false


func _process(delta: float) -> void:
	_t += delta
	# LED rojo parpadeante de las camaras
	var on := fmod(_t, 1.2) < 0.6
	for led in _leds:
		(led.material_override as StandardMaterial3D).emission_energy_multiplier = 3.0 if on else 0.2
	for f in feeds:
		(f["rec"] as Label).visible = on

	if feeds.is_empty():
		return
	_acc += delta
	var intervalo := 1.0 / _renders_por_segundo()
	if _acc < intervalo:
		return
	_acc = 0.0
	# Siguiente camara que algun monitor cercano este mostrando
	for k in feeds.size():
		_idx = (_idx + 1) % feeds.size()
		if _feed_visible(_idx):
			_redibujar(_idx)
			return
