extends Node3D

## Construye toda la parte visual del museo: suelo de marmol, paredes de piedra,
## columnas, claraboyas con luz de luna, vitrinas con reliquias, antorchas,
## estatuas, niebla, brillo (glow) y particulas de polvo.
##
## Todo se arma por codigo con formas basicas + texturas de assets/environment/,
## asi que se puede ir reemplazando pieza por pieza por modelos 3D reales.
## Las colisiones se mantienen simples (cajas) para no afectar al jugador.

const TEX := "res://assets/environment/"
const HALF := 16.0            # la sala mide 32 x 32
const INNER := 15.75          # cara interior de las paredes
const WALL_H := 8.0

# El vestibulo principal (room_lobby.gd) se une a la pared sur por un arco en x = 0.
const RoomLobby = preload("res://scripts/environment/room_lobby.gd")
const GameState = preload("res://scripts/game/game_state.gd")
const Interactables = preload("res://scripts/game/interactables.gd")
const EstatuaEnemiga = preload("res://scripts/enemies/estatua_enemiga.gd")
const Modelos = preload("res://scripts/environment/estatua_modelos.gd")
const BuildUtils = preload("res://scripts/environment/build_utils.gd")
const DOOR_HALF := RoomLobby.ARCH_HALF   # medio ancho del arco
const DOOR_H := RoomLobby.ARCH_H         # alto del arco

# Los interactivos (placas, diarios, pedestal) los registra museum.gd antes de build().
var registry: Interactables
var estado: GameState
var environment: Environment
var _altar_slots: Array[MeshInstance3D] = []
var _altar_luz: OmniLight3D

# Luces de antorcha que parpadean: [{light, base, phase, speed}]
var _flicker: Array = []
var _t := 0.0
var _cache := {}


func build() -> void:
	_build_environment()
	_build_shell()
	_build_carpet()
	_build_columns()
	_build_skylights()
	_build_wall_decor()
	_build_cases()
	_build_centerpiece()
	_build_benches()
	_build_enemies()
	_build_dust()
	_build_sealing_altar()
	_build_hall_notes()


func _process(delta: float) -> void:
	_t += delta
	for f in _flicker:
		var l: OmniLight3D = f["light"]
		var s: float = f["speed"]
		var p: float = f["phase"]
		var k := 1.0 + 0.10 * sin(_t * s + p) + 0.06 * sin(_t * s * 2.7 + p * 1.7) + 0.04 * sin(_t * 11.3 + p)
		l.light_energy = float(f["base"]) * k


# ---------------------------------------------------------------- materiales

func _tex(file: String) -> Texture2D:
	var path := TEX + file
	if ResourceLoader.exists(path):
		return load(path) as Texture2D
	return null


func _mat(color: Color, rough := 0.8, metal := 0.0) -> StandardMaterial3D:
	var m := StandardMaterial3D.new()
	m.albedo_color = color
	m.roughness = rough
	m.metallic = metal
	return m


func _emissive(color: Color, energy: float) -> StandardMaterial3D:
	var m := StandardMaterial3D.new()
	m.albedo_color = color.darkened(0.6)
	m.emission_enabled = true
	m.emission = color
	m.emission_energy_multiplier = energy
	return m


func _stone() -> StandardMaterial3D:
	if _cache.has("stone"):
		return _cache["stone"]
	var m := StandardMaterial3D.new()
	m.albedo_texture = _tex("wall_stone.png")
	m.albedo_color = Color(0.8, 0.78, 0.82)
	var n := _tex("wall_stone_n.png")
	if n:
		m.normal_enabled = true
		m.normal_texture = n
		m.normal_scale = 1.0
	m.roughness = 0.85
	m.uv1_triplanar = true
	m.uv1_world_triplanar = true
	m.uv1_scale = Vector3(0.25, 0.25, 0.25)
	_cache["stone"] = m
	return m


func _stone_dark() -> StandardMaterial3D:
	if _cache.has("stone_dark"):
		return _cache["stone_dark"]
	var m: StandardMaterial3D = _stone().duplicate()
	m.albedo_color = Color(0.32, 0.30, 0.34)
	_cache["stone_dark"] = m
	return m


func _floor_mat() -> StandardMaterial3D:
	if _cache.has("floor"):
		return _cache["floor"]
	var m := StandardMaterial3D.new()
	m.albedo_texture = _tex("floor_marble.png")
	var n := _tex("floor_marble_n.png")
	if n:
		m.normal_enabled = true
		m.normal_texture = n
		m.normal_scale = 0.45
	m.roughness = 0.32
	m.metallic_specular = 0.6
	m.uv1_triplanar = true
	m.uv1_world_triplanar = true
	m.uv1_scale = Vector3(0.125, 0.125, 0.125)
	_cache["floor"] = m
	return m


func _gold() -> StandardMaterial3D:
	if _cache.has("gold"):
		return _cache["gold"]
	# Oro mas satinado: evita reflejos especulares blancos al cambiar el angulo de camara.
	var m := _mat(Color(0.86, 0.66, 0.27), 0.44, 0.5)
	m.emission_enabled = true
	m.emission = Color(0.55, 0.36, 0.08)
	m.emission_energy_multiplier = 0.35
	_cache["gold"] = m
	return m


func _bronze() -> StandardMaterial3D:
	if _cache.has("bronze"):
		return _cache["bronze"]
	var m := _mat(Color(0.34, 0.29, 0.24), 0.5, 0.25)
	_cache["bronze"] = m
	return m


func _wood() -> StandardMaterial3D:
	if _cache.has("wood"):
		return _cache["wood"]
	var m := _mat(Color(0.12, 0.075, 0.05), 0.55)
	_cache["wood"] = m
	return m


func _cloth_red() -> StandardMaterial3D:
	if _cache.has("red"):
		return _cache["red"]
	var m := _mat(Color(0.55, 0.05, 0.07), 1.0)
	_cache["red"] = m
	return m


func _glass() -> StandardMaterial3D:
	if _cache.has("glass"):
		return _cache["glass"]
	var m := StandardMaterial3D.new()
	m.albedo_color = Color(0.65, 0.8, 0.95, 0.10)
	m.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	m.roughness = 0.12
	m.metallic_specular = 0.75
	m.cull_mode = BaseMaterial3D.CULL_BACK
	_cache["glass"] = m
	return m


# ---------------------------------------------------------------- utilidades

func _add(parent: Node, mesh: Mesh, pos: Vector3, mat: Material, rot := Vector3.ZERO, scl := Vector3.ONE) -> MeshInstance3D:
	var mi := MeshInstance3D.new()
	mi.mesh = mesh
	mi.material_override = mat
	mi.position = pos
	mi.rotation_degrees = rot
	mi.scale = scl
	parent.add_child(mi)
	return mi


func _box(parent: Node, pos: Vector3, size: Vector3, mat: Material, rot := Vector3.ZERO) -> MeshInstance3D:
	var m := BoxMesh.new()
	m.size = size
	return _add(parent, m, pos, mat, rot)


func _cyl(parent: Node, pos: Vector3, r_top: float, r_bot: float, h: float, mat: Material, rot := Vector3.ZERO, seg := 24) -> MeshInstance3D:
	var m := CylinderMesh.new()
	m.top_radius = r_top
	m.bottom_radius = r_bot
	m.height = h
	m.radial_segments = seg
	m.rings = 1
	return _add(parent, m, pos, mat, rot)


func _sphere(parent: Node, pos: Vector3, r: float, mat: Material, scl := Vector3.ONE) -> MeshInstance3D:
	var m := SphereMesh.new()
	m.radius = r
	m.height = r * 2.0
	m.radial_segments = 20
	m.rings = 10
	return _add(parent, m, pos, mat, Vector3.ZERO, scl)


func _capsule(parent: Node, pos: Vector3, r: float, h: float, mat: Material, rot := Vector3.ZERO) -> MeshInstance3D:
	var m := CapsuleMesh.new()
	m.radius = r
	m.height = h
	m.radial_segments = 16
	m.rings = 6
	return _add(parent, m, pos, mat, rot)


func _torus(parent: Node, pos: Vector3, inner: float, outer: float, mat: Material, rot := Vector3.ZERO, scl := Vector3.ONE) -> MeshInstance3D:
	var m := TorusMesh.new()
	m.inner_radius = inner
	m.outer_radius = outer
	m.rings = 24
	m.ring_segments = 10
	return _add(parent, m, pos, mat, rot, scl)


func _collider(pos: Vector3, size: Vector3) -> StaticBody3D:
	var body := StaticBody3D.new()
	body.position = pos
	var shape := CollisionShape3D.new()
	var box := BoxShape3D.new()
	box.size = size
	shape.shape = box
	body.add_child(shape)
	add_child(body)
	return body


func _omni(parent: Node, pos: Vector3, color: Color, energy: float, rng: float, shadow := false) -> OmniLight3D:
	var l := OmniLight3D.new()
	l.position = pos
	l.light_color = color
	l.light_energy = energy
	l.omni_range = rng
	l.omni_attenuation = 1.4
	l.shadow_enabled = shadow
	parent.add_child(l)
	return l


func _spot(parent: Node, pos: Vector3, rot: Vector3, color: Color, energy: float, rng: float, angle: float, shadow := false) -> SpotLight3D:
	var l := SpotLight3D.new()
	l.position = pos
	l.rotation_degrees = rot
	l.light_color = color
	l.light_energy = energy
	l.spot_range = rng
	l.spot_angle = angle
	l.spot_attenuation = 0.8
	l.shadow_enabled = shadow
	parent.add_child(l)
	return l


# ---------------------------------------------------------------- ambiente

func _build_environment() -> void:
	var we := WorldEnvironment.new()
	we.name = "WorldEnvironment"
	var e := Environment.new()
	e.background_mode = Environment.BG_COLOR
	e.background_color = Color("04060b")
	e.ambient_light_source = Environment.AMBIENT_SOURCE_COLOR
	e.ambient_light_color = Color("3a4670")
	e.ambient_light_energy = 0.65
	e.tonemap_mode = Environment.TONE_MAPPER_FILMIC
	e.tonemap_exposure = 0.95
	e.glow_enabled = true
	e.glow_intensity = 0.5
	e.glow_strength = 0.8
	e.glow_bloom = 0.035
	e.glow_hdr_threshold = 1.3
	e.fog_enabled = true
	e.fog_light_color = Color("0b1326")
	e.fog_density = 0.018
	e.adjustment_enabled = true
	e.adjustment_contrast = 1.12
	e.adjustment_saturation = 1.08
	we.environment = e
	environment = e
	add_child(we)


# ---------------------------------------------------------------- estructura

func _build_shell() -> void:
	# Colisiones (simples, iguales a las del prototipo original)
	_collider(Vector3(0, -0.25, 0), Vector3(32, 0.5, 32))
	_collider(Vector3(0, 4.0, -16), Vector3(32, 8, 0.5))
	# Pared sur con el arco hacia el vestibulo
	var seg_w := 16.0 - DOOR_HALF
	_collider(Vector3(-(16.0 + DOOR_HALF) / 2.0, 4.0, 16), Vector3(seg_w, 8, 0.5))
	_collider(Vector3((16.0 + DOOR_HALF) / 2.0, 4.0, 16), Vector3(seg_w, 8, 0.5))
	_collider(Vector3(0, DOOR_H + (8.0 - DOOR_H) / 2.0, 16), Vector3(DOOR_HALF * 2.0, 8.0 - DOOR_H, 0.5))
	_collider(Vector3(-16, 4.0, 0), Vector3(0.5, 8, 32))
	_collider(Vector3(16, 4.0, 0), Vector3(0.5, 8, 32))

	var shell := Node3D.new()
	shell.name = "Shell"
	add_child(shell)

	# Suelo en losetas de 8 x 8 (asi cada trozo recibe pocas luces)
	for cx in [-12.0, -4.0, 4.0, 12.0]:
		for cz in [-12.0, -4.0, 4.0, 12.0]:
			_box(shell, Vector3(cx, -0.25, cz), Vector3(8, 0.5, 8), _floor_mat())

	# Paredes en segmentos de 4 m
	for i in range(8):
		var c := -14.0 + i * 4.0
		_box(shell, Vector3(c, 4.0, -16), Vector3(4, WALL_H, 0.5), _stone())
		if absf(c) > 3.0:   # los dos tramos centrales de la pared sur llevan la puerta
			_box(shell, Vector3(c, 4.0, 16), Vector3(4, WALL_H, 0.5), _stone())
		_box(shell, Vector3(-16, 4.0, c), Vector3(0.5, WALL_H, 4), _stone())
		_box(shell, Vector3(16, 4.0, c), Vector3(0.5, WALL_H, 4), _stone())

	# Techo con tres claraboyas (huecos) sobre el eje central
	var ceil_mat := _stone_dark()
	_box(shell, Vector3(-9.75, 8.2, 0), Vector3(12.5, 0.4, 32), ceil_mat)
	_box(shell, Vector3(9.75, 8.2, 0), Vector3(12.5, 0.4, 32), ceil_mat)
	var segs := [[-16.0, -10.25], [-7.75, -1.25], [1.25, 7.75], [10.25, 16.0]]
	for s in segs:
		var z0: float = s[0]
		var z1: float = s[1]
		_box(shell, Vector3(0, 8.2, (z0 + z1) * 0.5), Vector3(7, 0.4, z1 - z0), ceil_mat)
	# Vigas de madera
	for z in [-13.0, -5.0, 4.5, 13.0]:
		_box(shell, Vector3(0, 7.72, z), Vector3(32, 0.5, 0.6), _wood())

	_build_office_doorway(shell)


## Arco en la pared sur que une la Sala Egipcia con el Vestibulo Principal:
## dos tramos de pared, dintel, marco dorado y un letrero encima (visto desde la sala).
func _build_office_doorway(shell: Node3D) -> void:
	var seg_w := 4.0 - DOOR_HALF
	var seg_c := (4.0 + DOOR_HALF) / 2.0
	for side in [-1.0, 1.0]:
		_box(shell, Vector3(side * seg_c, 4.0, 16), Vector3(seg_w, WALL_H, 0.5), _stone())
	_box(shell, Vector3(0, DOOR_H + (WALL_H - DOOR_H) / 2.0, 16), Vector3(DOOR_HALF * 2.0, WALL_H - DOOR_H, 0.5), _stone())
	# Marco dorado del arco (lado sala)
	var oro := _gold()
	for side in [-1.0, 1.0]:
		_box(shell, Vector3(side * (DOOR_HALF + 0.1), DOOR_H / 2.0, INNER - 0.12), Vector3(0.2, DOOR_H, 0.24), oro)
	_box(shell, Vector3(0, DOOR_H + 0.1, INNER - 0.12), Vector3(DOOR_HALF * 2.0 + 0.4, 0.2, 0.24), oro)

	# Letrero dorado sobre el arco
	var plate := _box(shell, Vector3(0, DOOR_H + 0.7, INNER - 0.04), Vector3(4.4, 0.55, 0.06), oro)
	plate.name = "LetreroVestibulo"
	var f := SystemFont.new()
	f.font_names = PackedStringArray(["Arial", "Helvetica", "Roboto", "sans-serif"])
	f.font_weight = 700
	var t := Label3D.new()
	t.text = "VESTÍBULO PRINCIPAL"
	t.font = f
	t.font_size = 64
	t.pixel_size = 0.0032
	t.modulate = Color(0.10, 0.06, 0.02)
	t.outline_size = 0
	t.double_sided = false
	t.position = Vector3(0, DOOR_H + 0.7, INNER - 0.08)
	t.rotation_degrees.y = 180.0
	shell.add_child(t)


func _build_carpet() -> void:
	var m := StandardMaterial3D.new()
	m.albedo_texture = _tex("carpet.png")
	m.roughness = 1.0
	m.uv1_scale = Vector3(1, 5.475, 1)
	var plane := PlaneMesh.new()
	plane.size = Vector2(4, 43.8)    # sigue por el arco hasta las puertas del vestibulo
	_add(self, plane, Vector3(0, 0.012, 7.9), m)


func _build_columns() -> void:
	var col_root := Node3D.new()
	col_root.name = "Columns"
	add_child(col_root)
	var stone := _stone()
	var gold := _gold()
	for side in [-1.0, 1.0]:
		for z in [-12.0, -6.0, 0.0, 6.0, 12.0]:
			var x: float = 9.0 * side
			_collider(Vector3(x, 3, z), Vector3(0.8, 6, 0.8))
			var c := Node3D.new()
			c.position = Vector3(x, 0, z)
			col_root.add_child(c)
			_box(c, Vector3(0, 0.18, 0), Vector3(1.15, 0.36, 1.15), stone)
			_cyl(c, Vector3(0, 0.5, 0), 0.5, 0.58, 0.28, stone)
			_cyl(c, Vector3(0, 3.1, 0), 0.40, 0.44, 5.2, stone, Vector3.ZERO, 20)
			_cyl(c, Vector3(0, 1.0, 0), 0.455, 0.455, 0.07, gold)
			_cyl(c, Vector3(0, 4.9, 0), 0.455, 0.455, 0.07, gold)
			_cyl(c, Vector3(0, 5.55, 0), 0.62, 0.42, 0.55, stone)
			_box(c, Vector3(0, 5.92, 0), Vector3(1.3, 0.24, 1.3), stone)
			# Antorcha en la cara que mira al centro de la sala
			var nx: float = -side
			var sconce := Node3D.new()
			sconce.position = Vector3(nx * 0.52, 3.3, 0)
			c.add_child(sconce)
			_box(sconce, Vector3(nx * 0.04, 0, 0), Vector3(0.14, 0.3, 0.14), gold)
			_cyl(sconce, Vector3(nx * 0.12, 0.2, 0), 0.09, 0.05, 0.14, gold)
			_sphere(sconce, Vector3(nx * 0.12, 0.34, 0), 0.085, _emissive(Color(1.0, 0.55, 0.16), 5.0), Vector3(1, 1.5, 1))
			var l := _omni(sconce, Vector3(nx * 0.3, 0.4, 0), Color(1.0, 0.6, 0.28), 1.7, 10.0)
			_flicker.append({"light": l, "base": 1.7, "phase": randf() * 6.28, "speed": randf_range(6.0, 9.0)})


func _build_skylights() -> void:
	var window_mat := _emissive(Color(0.48, 0.58, 0.82), 0.5)
	var bar_mat := _mat(Color(0.03, 0.03, 0.04), 0.7)
	for z in [-9.0, 0.0, 9.0]:
		# Cristal luminoso encima del hueco + marco
		_box(self, Vector3(0, 8.45, z), Vector3(7, 0.05, 2.5), window_mat)
		_box(self, Vector3(0, 8.1, z), Vector3(7.1, 0.1, 0.14), bar_mat)
		_box(self, Vector3(-1.75, 8.1, z), Vector3(0.14, 0.1, 2.5), bar_mat)
		_box(self, Vector3(1.75, 8.1, z), Vector3(0.14, 0.1, 2.5), bar_mat)
		# Luz de luna que cae hasta el suelo y proyecta sombras
		# La luz real permanece, pero el volumen aditivo se elimina: en Compatibility
		# se expandia a un plano blanco al acercarse y mirar hacia abajo.
		_spot(self, Vector3(0, 7.9, z), Vector3(-90, 0, 0), Color(0.62, 0.74, 1.0), 1.7, 13.0, 34.0, true)


func _build_wall_decor() -> void:
	var deco := Node3D.new()
	deco.name = "WallDecor"
	add_child(deco)

	var gold_trim := _mat(Color(0.7, 0.52, 0.2), 0.4, 0.5)
	gold_trim.emission_enabled = true
	gold_trim.emission = Color(0.6, 0.4, 0.1)
	gold_trim.emission_energy_multiplier = 0.3

	# Tiras que recorren las cuatro paredes: [altura, alto, profundidad, material]
	var strips := [
		[0.65, 1.3, 0.16, _wood()],
		[0.09, 0.18, 0.22, _stone_dark()],
		[1.33, 0.07, 0.2, gold_trim],
		[5.02, 0.06, 0.05, gold_trim],
		[6.18, 0.06, 0.05, gold_trim],
		[7.7, 0.55, 0.32, _stone_dark()],
	]
	for s in strips:
		var y: float = s[0]
		var h: float = s[1]
		var d: float = s[2]
		var mat: Material = s[3]
		var off := INNER - d * 0.5
		var len_x := 2.0 * INNER
		var len_z := 2.0 * INNER - 2.0 * d
		_box(deco, Vector3(0, y, -off), Vector3(len_x, h, d), mat)
		if y + h * 0.5 < DOOR_H + 0.2:
			# Las tiras bajas de la pared sur se parten en dos para dejar libre la puerta
			var half_len := INNER - DOOR_HALF
			var cx := (INNER + DOOR_HALF) * 0.5
			_box(deco, Vector3(-cx, y, off), Vector3(half_len, h, d), mat)
			_box(deco, Vector3(cx, y, off), Vector3(half_len, h, d), mat)
		else:
			_box(deco, Vector3(0, y, off), Vector3(len_x, h, d), mat)
		_box(deco, Vector3(-off, y, 0), Vector3(d, h, len_z), mat)
		_box(deco, Vector3(off, y, 0), Vector3(d, h, len_z), mat)

	# Banda de jeroglifos (brilla suavemente en dorado)
	var band := StandardMaterial3D.new()
	band.albedo_texture = _tex("hiero_band.png")
	band.roughness = 0.7
	var bt := _tex("hiero_band.png")
	if bt:
		band.emission_enabled = true
		band.emission_texture = bt
		band.emission_energy_multiplier = 0.85
	var q := QuadMesh.new()
	q.size = Vector2(8, 1)
	var o := INNER - 0.01
	for c in [-12.0, -4.0, 4.0, 12.0]:
		_add(deco, q, Vector3(c, 5.6, -o), band, Vector3(0, 0, 0))
		_add(deco, q, Vector3(c, 5.6, o), band, Vector3(0, 180, 0))
		_add(deco, q, Vector3(-o, 5.6, c), band, Vector3(0, 90, 0))
		_add(deco, q, Vector3(o, 5.6, c), band, Vector3(0, -90, 0))

	# Estandartes rojos en las paredes laterales
	var red := _cloth_red()
	var gold := _gold()
	for side in [-1.0, 1.0]:
		for z in [-12.0, -4.0, 4.0, 12.0]:
			var bx: float = (INNER - 0.06) * side
			var b := Node3D.new()
			b.position = Vector3(bx, 0, z)
			deco.add_child(b)
			_box(b, Vector3(0, 3.5, 0), Vector3(0.05, 3.1, 1.3), red)
			_box(b, Vector3(-side * 0.04, 5.08, 0), Vector3(0.1, 0.1, 1.55), gold)
			_box(b, Vector3(-side * 0.03, 1.93, 0), Vector3(0.08, 0.1, 1.3), gold)
			_box(b, Vector3(-side * 0.03, 3.7, 0), Vector3(0.03, 0.52, 0.52), gold, Vector3(45, 0, 0))
			_box(b, Vector3(-side * 0.04, 3.7, 0), Vector3(0.03, 0.3, 0.3), red, Vector3(45, 0, 0))


# ---------------------------------------------------------------- vitrinas

const CASES := [
	{"pos": Vector3(-5, 1.1, -5), "kind": 0},
	{"pos": Vector3(5, 1.1, -9), "kind": 1},
	{"pos": Vector3(-5, 1.1, 5), "kind": 2},
	{"pos": Vector3(5, 1.1, 7), "kind": 3},
]


func _build_cases() -> void:
	for c in CASES:
		_build_case(c["pos"], c["kind"])


func _build_case(pos: Vector3, kind: int) -> void:
	_collider(pos, Vector3(3.2, 2.2, 1.2))
	var root := Node3D.new()
	root.name = "Vitrina_%d" % kind
	root.position = Vector3(pos.x, 0, pos.z)
	add_child(root)

	var stone := _stone_dark()
	var gold := _gold()
	var frame := _mat(Color(0.05, 0.05, 0.06), 0.4, 0.6)
	var velvet := _mat(Color(0.20, 0.02, 0.04), 1.0)

	# Pedestal de piedra oscura con cornisa dorada
	_box(root, Vector3(0, 0.5, 0), Vector3(3.2, 1.0, 1.2), stone)
	_box(root, Vector3(0, 0.03, 0), Vector3(3.3, 0.1, 1.3), stone)
	_box(root, Vector3(0, 1.0, 0), Vector3(3.24, 0.06, 1.24), gold)
	_box(root, Vector3(0, 0.6, 0.605), Vector3(2.6, 0.5, 0.02), gold)
	_box(root, Vector3(0, 0.6, 0.61), Vector3(2.5, 0.4, 0.02), stone)
	# Terciopelo interior
	_box(root, Vector3(0, 1.04, 0), Vector3(3.0, 0.03, 1.0), velvet)
	# Vidrio
	_box(root, Vector3(0, 1.62, 0), Vector3(3.0, 1.1, 1.0), _glass())
	# Marco metalico
	var yb := 1.07
	var yt := 2.17
	for sx in [-1.5, 1.5]:
		for sz in [-0.5, 0.5]:
			_box(root, Vector3(sx, 1.62, sz), Vector3(0.05, 1.1, 0.05), frame)
	for y in [yb, yt]:
		_box(root, Vector3(0, y, -0.5), Vector3(3.05, 0.05, 0.05), frame)
		_box(root, Vector3(0, y, 0.5), Vector3(3.05, 0.05, 0.05), frame)
		_box(root, Vector3(-1.5, y, 0), Vector3(0.05, 0.05, 1.05), frame)
		_box(root, Vector3(1.5, y, 0), Vector3(0.05, 0.05, 1.05), frame)
	# Tapa superior con luz integrada
	_box(root, Vector3(0, 2.2, 0), Vector3(3.2, 0.08, 1.2), stone)
	_box(root, Vector3(0, 2.15, 0), Vector3(2.4, 0.03, 0.06), _emissive(Color(1.0, 0.82, 0.5), 1.8))
	_spot(root, Vector3(0, 2.1, 0), Vector3(-90, 0, 0), Color(1.0, 0.8, 0.52), 2.4, 3.4, 48.0)

	# Reliquia dentro de la vitrina
	var item := Node3D.new()
	item.position = Vector3(0, 1.07, 0)
	root.add_child(item)
	match kind:
		0: _item_sarcophagus(item)
		1: _item_ankh(item)
		2: _item_canopic(item)
		3: _item_mask(item)
	_registrar_placa(root, kind)


func _item_sarcophagus(p: Node3D) -> void:
	var gold := _gold()
	var blue := _mat(Color(0.05, 0.12, 0.35), 0.5, 0.2)
	_box(p, Vector3(0, 0.06, 0), Vector3(1.9, 0.12, 0.6), _wood())
	_capsule(p, Vector3(0, 0.42, 0), 0.26, 1.75, gold, Vector3(0, 0, 90))
	_sphere(p, Vector3(-0.72, 0.5, 0), 0.22, gold, Vector3(1, 1.15, 1))
	_box(p, Vector3(-0.72, 0.5, 0.2), Vector3(0.18, 0.05, 0.04), _mat(Color(0.02, 0.02, 0.03), 0.5))
	_torus(p, Vector3(-0.42, 0.42, 0), 0.22, 0.29, blue, Vector3(0, 0, 90))
	for i in range(4):
		_torus(p, Vector3(-0.05 + i * 0.28, 0.42, 0), 0.245, 0.275, blue, Vector3(0, 0, 90))


func _item_ankh(p: Node3D) -> void:
	var gold := _gold()
	_cyl(p, Vector3(0, 0.05, 0), 0.3, 0.36, 0.1, _stone())
	_cyl(p, Vector3(0, 0.36, 0), 0.02, 0.04, 0.5, _wood())
	# Medallon con ankh dorado
	_cyl(p, Vector3(0, 0.55, 0), 0.36, 0.36, 0.05, gold, Vector3(90, 0, 0), 32)
	_torus(p, Vector3(0, 0.66, 0.03), 0.06, 0.11, gold, Vector3(90, 0, 0))
	_box(p, Vector3(0, 0.46, 0.03), Vector3(0.05, 0.25, 0.03), gold)
	_box(p, Vector3(0, 0.53, 0.03), Vector3(0.22, 0.05, 0.03), gold)
	_torus(p, Vector3(0, 0.55, 0.03), 0.28, 0.32, gold, Vector3(90, 0, 0))
	# Fragmentos sueltos
	for i in range(3):
		_box(p, Vector3(-0.85 + i * 0.28, 0.05, 0.15 - i * 0.12), Vector3(0.26, 0.1, 0.16), gold, Vector3(0, 20 + i * 35, 0))
	for i in range(3):
		_box(p, Vector3(0.6 + i * 0.28, 0.05, -0.1 + i * 0.1), Vector3(0.24, 0.1, 0.18), gold, Vector3(0, -30 + i * 25, 0))


func _item_canopic(p: Node3D) -> void:
	var alabaster := _mat(Color(0.72, 0.66, 0.55), 0.45)
	var gold := _gold()
	var xs := [-0.95, -0.32, 0.32, 0.95]
	for i in range(4):
		var x: float = xs[i]
		_cyl(p, Vector3(x, 0.03, 0), 0.2, 0.22, 0.06, _stone())
		_cyl(p, Vector3(x, 0.32, 0), 0.15, 0.17, 0.5, alabaster)
		_cyl(p, Vector3(x, 0.6, 0), 0.13, 0.15, 0.08, gold)
		if i % 2 == 0:
			_sphere(p, Vector3(x, 0.72, 0), 0.14, alabaster, Vector3(1, 1.05, 1))
		else:
			_sphere(p, Vector3(x, 0.7, 0.02), 0.12, alabaster, Vector3(1, 1, 1.1))
			_cyl(p, Vector3(x, 0.7, 0.16), 0.0, 0.06, 0.16, alabaster, Vector3(90, 0, 0), 10)
			for e in [-1.0, 1.0]:
				_cyl(p, Vector3(x + e * 0.07, 0.86, 0), 0.0, 0.035, 0.2, alabaster, Vector3(0, 0, -e * 8), 8)
		_torus(p, Vector3(x, 0.34, 0), 0.155, 0.185, gold)


func _item_mask(p: Node3D) -> void:
	var gold := _gold()
	var blue := _mat(Color(0.04, 0.10, 0.32), 0.5, 0.2)
	var dark := _mat(Color(0.015, 0.015, 0.02), 0.4)
	_cyl(p, Vector3(0, 0.05, 0), 0.32, 0.38, 0.1, _stone())
	_cyl(p, Vector3(0, 0.3, 0), 0.06, 0.09, 0.4, _wood())
	_sphere(p, Vector3(0, 0.66, 0), 0.24, gold, Vector3(0.9, 1.15, 0.8))
	# Nemes (tocado a rayas azul y oro)
	for s in [-1.0, 1.0]:
		_box(p, Vector3(s * 0.27, 0.55, -0.02), Vector3(0.12, 0.5, 0.26), blue, Vector3(0, 0, s * 6))
		_box(p, Vector3(s * 0.32, 0.55, -0.02), Vector3(0.03, 0.5, 0.27), gold, Vector3(0, 0, s * 6))
	_box(p, Vector3(0, 0.93, -0.02), Vector3(0.5, 0.06, 0.34), blue)
	# Cara
	for s in [-1.0, 1.0]:
		_box(p, Vector3(s * 0.09, 0.7, 0.17), Vector3(0.11, 0.035, 0.03), dark)
	_box(p, Vector3(0, 0.6, 0.19), Vector3(0.05, 0.13, 0.05), gold)
	_box(p, Vector3(0, 0.5, 0.17), Vector3(0.14, 0.03, 0.03), dark)
	_box(p, Vector3(0, 0.36, 0.14), Vector3(0.06, 0.2, 0.05), blue, Vector3(-10, 0, 0))


# ---------------------------------------------------------------- estatua principal

func _build_centerpiece() -> void:
	var gold := _gold()
	var stone := _stone_dark()
	# Disco solar detras de la estatua
	var sun := _emissive(Color(1.0, 0.5, 0.18), 0.35)
	_cyl(self, Vector3(0, 4.6, -15.68), 2.7, 2.7, 0.06, sun, Vector3(90, 0, 0), 48)
	_torus(self, Vector3(0, 4.6, -15.62), 2.7, 2.9, gold, Vector3(90, 0, 0))
	# Pedestal
	_collider(Vector3(0, 0.5, -14.2), Vector3(4.6, 1.0, 2.6))
	_box(self, Vector3(0, 0.45, -14.2), Vector3(4.4, 0.9, 2.4), stone)
	_box(self, Vector3(0, 0.95, -14.2), Vector3(4.6, 0.12, 2.6), gold)
	# Estatua de Anubis
	var st := Node3D.new()
	st.name = "AnubisGrande"
	st.position = Vector3(0, 1.0, -14.2)
	st.scale = Vector3(1.05, 1.05, 1.05)
	add_child(st)
	_build_anubis(st)
	# Luces desde el suelo que la iluminan
	_spot(self, Vector3(-1.9, 0.15, -12.3), Vector3(55, -8, 0), Color(1.0, 0.68, 0.34), 2.8, 9.0, 38.0)
	_spot(self, Vector3(1.9, 0.15, -12.3), Vector3(55, 8, 0), Color(1.0, 0.68, 0.34), 2.8, 9.0, 38.0)
	_omni(self, Vector3(0, 5.2, -12.8), Color(0.35, 0.5, 1.0), 0.45, 7.0)


func _build_anubis(p: Node3D, enemigo: Node3D = null) -> void:
	var body := _bronze()
	var gold := _gold()
	var lapis := _mat(Color(0.025, 0.07, 0.16), 0.5, 0.45)
	var amber := _emissive(Color(1.0, 0.18, 0.025), 0.0)
	# Grebas y sandalias de metal con filetes dorados.
	for s in [-1.0, 1.0]:
		_box(p, Vector3(s * 0.2, 0.5, 0), Vector3(0.30, 1.0, 0.32), body)
		_box(p, Vector3(s * 0.2, 0.06, 0.1), Vector3(0.33, 0.12, 0.5), body)
		_box(p, Vector3(s * 0.2, 0.34, 0.17), Vector3(0.24, 0.055, 0.025), gold)
		_sphere(p, Vector3(s * 0.2, 0.80, 0.17), 0.10, gold, Vector3(1.0, 0.55, 0.25))
	# Faldón ceremonial, placas superpuestas y cinturón con sello.
	_cyl(p, Vector3(0, 1.15, 0), 0.36, 0.45, 0.55, body)
	_cyl(p, Vector3(0, 1.5, 0), 0.37, 0.37, 0.07, gold)
	_box(p, Vector3(0, 1.18, 0.34), Vector3(0.38, 0.33, 0.035), body, Vector3(-12, 0, 0))
	_box(p, Vector3(0, 1.16, 0.365), Vector3(0.04, 0.28, 0.018), gold)
	for s in [-1.0, 1.0]:
		_box(p, Vector3(s * 0.29, 1.13, 0.18), Vector3(0.12, 0.32, 0.025), gold, Vector3(0, 0, s * 12))
	# Peto ancho y hombros de guardián real.
	_box(p, Vector3(0, 1.9, 0), Vector3(0.74, 0.8, 0.4), body)
	_sphere(p, Vector3(0, 1.91, 0.205), 0.25, body, Vector3(1.15, 1.45, 0.48))
	for s in [-1.0, 1.0]:
		_sphere(p, Vector3(s * 0.44, 2.17, 0), 0.20, body, Vector3(1.15, 0.82, 1.0))
		_cyl(p, Vector3(s * 0.46, 2.17, 0.025), 0.18, 0.15, 0.12, gold, Vector3(0, 0, s * 5))
		_capsule(p, Vector3(s * 0.5, 1.75, 0.02), 0.095, 0.86, body, Vector3(0, 0, s * 7))
		_cyl(p, Vector3(s * 0.5, 1.49, 0.04), 0.11, 0.11, 0.09, gold)
		_sphere(p, Vector3(s * 0.5, 1.30, 0.12), 0.11, body, Vector3(0.85, 0.8, 0.7))
	# Collar de oro y lapislázuli con ankh pectoral.
	_torus(p, Vector3(0, 2.28, 0), 0.16, 0.42, gold, Vector3.ZERO, Vector3(1, 0.45, 1))
	_torus(p, Vector3(0, 2.22, 0.015), 0.18, 0.38, lapis, Vector3.ZERO, Vector3(1, 0.4, 1))
	_torus(p, Vector3(0, 2.15, 0.03), 0.20, 0.34, gold, Vector3.ZERO, Vector3(1, 0.35, 1))
	_cyl(p, Vector3(0, 1.91, 0.205), 0.18, 0.23, 0.12, gold, Vector3(90, 0, 0), 24)
	_cyl(p, Vector3(0, 1.94, 0.278), 0.07, 0.07, 0.025, lapis, Vector3(90, 0, 0), 20)
	_torus(p, Vector3(0, 2.00, 0.295), 0.045, 0.058, gold, Vector3(90, 0, 0))
	_box(p, Vector3(0, 1.88, 0.30), Vector3(0.055, 0.20, 0.025), gold)
	_box(p, Vector3(0, 1.87, 0.30), Vector3(0.14, 0.035, 0.025), gold)
	# Lanza ceremonial y brazalete de la mano que la sostiene.
	_cyl(p, Vector3(0.58, 1.75, 0.14), 0.022, 0.022, 3.0, gold)
	_cyl(p, Vector3(0.58, 3.4, 0.14), 0.0, 0.07, 0.3, gold, Vector3.ZERO, 12)
	_cyl(p, Vector3(0.58, 2.85, 0.14), 0.035, 0.035, 0.09, lapis)
	# Cabeza de chacal, hocico, cejas, orejas largas y nemes a rayas.
	_cyl(p, Vector3(0, 2.45, 0), 0.09, 0.11, 0.2, body)
	_sphere(p, Vector3(0, 2.66, 0), 0.2, body, Vector3(0.95, 1.1, 1.05))
	_cyl(p, Vector3(0, 2.59, 0.30), 0.065, 0.12, 0.48, body, Vector3(90, 0, 0), 18)
	_sphere(p, Vector3(0, 2.58, 0.55), 0.06, _mat(Color(0.015, 0.012, 0.012), 0.4))
	_box(p, Vector3(0, 2.76, 0.12), Vector3(0.20, 0.035, 0.10), gold, Vector3(-12, 0, 0))
	for s in [-1.0, 1.0]:
		_box(p, Vector3(s * 0.19, 2.43, -0.035), Vector3(0.15, 0.62, 0.25), lapis, Vector3(0, 0, s * 7))
		for k in 3:
			_box(p, Vector3(s * (0.19 + k * 0.012), 2.43, 0.10), Vector3(0.025, 0.55, 0.018), gold, Vector3(0, 0, s * 7))
		_cyl(p, Vector3(s * 0.11, 3.03, -0.02), 0.0, 0.075, 0.62, body, Vector3(0, 0, -s * 7), 12)
		_sphere(p, Vector3(s * 0.09, 2.70, 0.175), 0.035, amber)
	_torus(p, Vector3(0, 2.79, -0.005), 0.11, 0.19, gold, Vector3.ZERO, Vector3(1, 0.5, 0.72))
	if enemigo != null:
		enemigo.set_meta("ojos", [amber])


# ---------------------------------------------------------------- bancas

func _build_benches() -> void:
	var leather := _mat(Color(0.09, 0.05, 0.04), 0.6)
	for side in [-1.0, 1.0]:
		for z in [-2.5, 2.5]:
			var x: float = 12.0 * side
			_collider(Vector3(x, 0.25, z), Vector3(0.6, 0.5, 2.0))
			var b := Node3D.new()
			b.position = Vector3(x, 0, z)
			add_child(b)
			_box(b, Vector3(0, 0.44, 0), Vector3(0.55, 0.1, 2.0), leather)
			_box(b, Vector3(0, 0.38, 0), Vector3(0.6, 0.06, 2.05), _wood())
			for dz in [-0.85, 0.85]:
				_box(b, Vector3(0, 0.18, dz), Vector3(0.5, 0.36, 0.08), _wood())


# ---------------------------------------------------------------- enemigos

func _build_enemies() -> void:
	_make_enemy(Vector3(0, 1.3, -10), "ESTATUA")
	_make_enemy(Vector3(-6, 1.3, 2), "ARMADURA")
	_make_enemy(Vector3(7, 1.3, 10), "MOMIA")


func _make_enemy(pos: Vector3, label: String) -> void:
	# CharacterBody3D con el comportamiento de estatua (scripts/enemies/estatua_enemiga.gd): solo se
	# mueve cuando nadie la observa. La ARMADURA es del Nivel 2 y por ahora no se mueve.
	var enemy := EstatuaEnemiga.new()
	enemy.name = label.capitalize()
	enemy.position = Vector3(pos.x, 0.0, pos.z)
	enemy.set_meta("enemy_type", label)
	enemy.tipo = label
	enemy.region = Rect2(-15.3, -15.3, 30.6, 30.6)
	enemy.add_to_group("wake_sala")
	match label:
		"ESTATUA":
			enemy.velocidad = 1.0
		"MOMIA":
			enemy.velocidad = 1.5
		_:
			enemy.velocidad = 0.0
	add_child(enemy)
	var vis: Node3D
	if label == "ARMADURA":
		vis = Modelos.armadura(enemy, BuildUtils.new(), Color(0.45, 0.07, 0.09))
	else:
		vis = Node3D.new()
		vis.name = "Visual"
		enemy.add_child(vis)
	_registrar_enemigo(enemy, vis, label)
	match label:
		"ESTATUA":
			_box(vis, Vector3(0, 0.15, 0), Vector3(1.4, 0.3, 1.4), _stone_dark())
			var s := Node3D.new()
			s.position = Vector3(0, 0.3, 0)
			s.scale = Vector3(0.62, 0.62, 0.62)
			vis.add_child(s)
			_build_anubis(s, vis)
		"MOMIA":
			_build_mummy(vis)


func _build_mummy(p: Node3D) -> void:
	var wrap := _mat(Color(0.48, 0.39, 0.27), 1.0)
	var wrap2 := _mat(Color(0.28, 0.22, 0.16), 1.0)
	var bronze := _mat(Color(0.25, 0.18, 0.095), 0.72, 0.58)
	var gold := _gold()
	var eye := _emissive(Color(0.12, 1.0, 0.52), 0.0)
	var m := Node3D.new()
	m.rotation_degrees = Vector3(-11, 0, 0)
	p.add_child(m)
	_capsule(m, Vector3(0, 1.0, 0), 0.29, 1.55, wrap)
	# Piernas desiguales y encorvadas.
	for s in [-1.0, 1.0]:
		_capsule(m, Vector3(s * 0.15, 0.36, 0.015), 0.13, 0.72, wrap2, Vector3(0, 0, s * 8))
		_capsule(m, Vector3(s * 0.16, 0.12, 0.13), 0.095, 0.28, wrap, Vector3(72, 0, 0))
		_torus(m, Vector3(s * 0.15, 0.42, 0.05), 0.105, 0.135, wrap, Vector3(8, 0, s * 8))
	# Vendas cruzadas sobre el torso, con pliegues y manchas oscuras.
	for i in range(12):
		var y := 0.28 + i * 0.125
		var r := 0.29 if i < 8 else 0.25
		var banda := _torus(m, Vector3(0, y, 0), r - 0.025, r + 0.022, wrap2 if i % 3 == 0 else wrap, Vector3(randf_range(-12, 12), randf_range(-8, 8), randf_range(-10, 10)))
		banda.scale = Vector3(1.0 + 0.06 * sin(float(i)), 1.0, 0.88)
	# Brazos largos hacia delante y dedos huesudos bajo las vendas.
	for s in [-1.0, 1.0]:
		_capsule(m, Vector3(s * 0.31, 1.43, 0.08), 0.105, 0.55, wrap, Vector3(-38, 0, s * 18))
		_capsule(m, Vector3(s * 0.43, 1.16, 0.34), 0.09, 0.55, wrap2, Vector3(-64, 0, s * 12))
		_sphere(m, Vector3(s * 0.44, 0.93, 0.57), 0.105, wrap, Vector3(0.85, 0.72, 1.25))
		for k in 4:
			_capsule(m, Vector3(s * (0.44 + (k - 1.5) * 0.035), 0.86, 0.66), 0.022, 0.16, wrap2, Vector3(-20, 0, (k - 1.5) * 8))
		for j in 3:
			_torus(m, Vector3(s * (0.34 + j * 0.035), 1.31 - j * 0.11, 0.22 + j * 0.08), 0.075, 0.095, wrap2, Vector3(-55, 0, s * 18))
	# Máscara funeraria antigua que asoma entre las vendas.
	_sphere(m, Vector3(0, 1.88, 0.12), 0.19, bronze, Vector3(0.95, 1.12, 0.58))
	_box(m, Vector3(0, 1.91, 0.225), Vector3(0.23, 0.075, 0.035), _mat(Color(0.045, 0.035, 0.025), 0.7))
	_box(m, Vector3(0, 1.82, 0.22), Vector3(0.09, 0.10, 0.05), gold)
	_box(m, Vector3(0, 1.75, 0.21), Vector3(0.15, 0.018, 0.025), bronze)
	for s in [-1.0, 1.0]:
		_sphere(m, Vector3(s * 0.073, 1.91, 0.248), 0.025, eye)
		_sphere(m, Vector3(s * 0.15, 1.83, 0.17), 0.045, gold, Vector3(0.35, 1.0, 0.45))
		_box(m, Vector3(s * 0.19, 0.72, 0.20), Vector3(0.07, 0.46, 0.025), wrap, Vector3(0, 0, s * 11))
		_torus(m, Vector3(s * 0.31, 1.44, 0.08), 0.095, 0.12, wrap2, Vector3(-38, 0, s * 18))
	for s in [-1.0, 1.0]:
		_torus(m, Vector3(s * 0.085, 1.97, 0.06), 0.13, 0.16, wrap, Vector3(randf_range(-9, 9), 0, randf_range(-9, 9)))
	p.set_meta("ojos", [eye])


# ---------------------------------------------------------------- polvo

func _build_dust() -> void:
	var dust := CPUParticles3D.new()
	dust.name = "Polvo"
	dust.position = Vector3(0, 3.6, 0)
	dust.amount = 260
	dust.lifetime = 14.0
	dust.preprocess = 14.0
	dust.emission_shape = CPUParticles3D.EMISSION_SHAPE_BOX
	dust.emission_box_extents = Vector3(14.5, 3.6, 14.5)
	dust.direction = Vector3(0.3, 0.1, 0.1)
	dust.spread = 180.0
	dust.gravity = Vector3.ZERO
	dust.initial_velocity_min = 0.03
	dust.initial_velocity_max = 0.12
	dust.scale_amount_min = 0.5
	dust.scale_amount_max = 1.1
	dust.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	var sm := SphereMesh.new()
	sm.radius = 0.014
	sm.height = 0.028
	sm.radial_segments = 6
	sm.rings = 3
	var dm := StandardMaterial3D.new()
	dm.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	dm.albedo_color = Color(1.0, 0.9, 0.7, 0.45)
	dm.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	dm.distance_fade_mode = BaseMaterial3D.DISTANCE_FADE_PIXEL_ALPHA
	dm.distance_fade_min_distance = 1.2
	dm.distance_fade_max_distance = 3.0
	sm.material = dm
	dust.mesh = sm
	add_child(dust)


# ---------------------------------------------------------------- interacciones de la Sala Egipcia

func _registrar_placa(root: Node3D, kind: int) -> void:
	if registry == null:
		return
	var titulos := ["Sarcófago de escriba", "Ankh de oro", "Vasos canopos", "Máscara funeraria"]
	var textos := [
		"[b]SARCÓFAGO DE ESCRIBA[/b]\nMadera policromada · Dinastía XXVI (c. 600 a. C.)\n\nPerteneció a un escriba de los templos de Menfis. Las inscripciones piden a los dioses que «guarden su nombre».\n\nDonación: Fundación Hallman, 1987.\n\n[i]Etiqueta de seguridad pegada con cinta: «Reubicada por la Dra. Torres, 12/10. No mover.»[/i]",
		"[b]ANKH DE ORO[/b]\nOro laminado · Imperio Nuevo (c. 1350 a. C.)\n\nSímbolo egipcio de la vida. Hallado en una tumba tebana junto a los restos de un sacerdote de Osiris.\n\n[i]Alex: «Qué raro... esta vitrina está tibia.»[/i]",
		"[b]VASOS CANOPOS[/b]\nCaliza · Dinastía XIX\n\nCuatro vasos que guardaban los órganos del difunto, cada uno con la cabeza de un hijo de Horus: Imseti, Hapi, Duamutef y Qebehsenuef.\n\n[i]Un vaso está ligeramente girado hacia la puerta de entrada.[/i]",
		"[b]MÁSCARA FUNERARIA[/b]\nCartonaje dorado · Periodo Ptolemaico\n\nSu mirada fue pintada para vigilar al difunto durante el viaje al inframundo.\n\n[i]Alex: «Siento que me mira... no, es solo la luz.»[/i]",
	]
	var nota_d: Dictionary = {"titulo": titulos[kind], "texto": textos[kind], "estilo": "papel", "firma": ""}
	registry.registrar(root, self, "nota", "Leer placa de la vitrina", 4.2, Vector3(0, 1.4, 0), {"nota": nota_d}, null)


func _registrar_enemigo(enemy: Node3D, vis: Node3D, label: String) -> void:
	if registry == null:
		return
	var msg := ""
	match label:
		"ESTATUA":
			msg = "Estatua de Anubis, granito gris y oro desgastado. Juraría que ayer miraba hacia el otro lado."
		"ARMADURA":
			msg = "Armadura de placas medievales, vacía. Alex: «Esto no debería estar en la Sala Egipcia...»"
		"MOMIA":
			msg = "Una momia vendada. Alex: «Perfecto. Justo lo que necesitaba.»"
	registry.registrar(enemy, self, "examinar", "Examinar " + label.to_lower(), 4.0, Vector3(0, 1.6, 0), {"mensaje": msg}, vis)


func _build_sealing_altar() -> void:
	# Pedestal de Sellado: aqui se colocan los 4 fragmentos del amuleto (frente al gran Anubis)
	var a := Node3D.new()
	a.name = "PedestalSellado"
	a.position = Vector3(0, 0, -6.5)
	add_child(a)
	_collider(Vector3(0, 0.5, -6.5), Vector3(1.5, 1.0, 1.5))
	_box(a, Vector3(0, 0.12, 0), Vector3(1.6, 0.24, 1.6), _stone_dark())
	_box(a, Vector3(0, 0.58, 0), Vector3(1.2, 0.7, 1.2), _stone())
	_box(a, Vector3(0, 0.96, 0), Vector3(1.45, 0.1, 1.45), _gold())
	_cyl(a, Vector3(0, 1.025, 0), 0.12, 0.12, 0.03, _gold())
	_box(a, Vector3(0, 0.58, 0.62), Vector3(0.7, 0.4, 0.03), _gold())
	for i in 4:
		var ang := i * PI / 2.0 + PI / 4.0
		var pos := Vector3(cos(ang) * 0.46, 1.02, sin(ang) * 0.46)
		var m := _mat(Color(0.05, 0.08, 0.09), 0.4)
		_altar_slots.append(_box(a, pos, Vector3(0.22, 0.03, 0.15), m, Vector3(0, -rad_to_deg(ang), 0)))
	_altar_luz = _omni(a, Vector3(0, 1.5, 0), Color(0.25, 1.0, 0.85), 0.0, 5.0)
	if registry:
		registry.registrar(a, self, "altar", "Pedestal de Sellado", 3.0, Vector3(0, 1.0, 0), {}, a)   # alcance menor que el de las tarjetas que salen de el


func _usar_altar() -> void:
	var colocados := estado.cantidad("fragmento_colocado")
	if estado.cantidad("fragmento") > 0:
		estado.quitar("fragmento")
		estado.dar("fragmento_colocado")
		var m := _altar_slots[colocados].material_override as StandardMaterial3D
		m.albedo_color = Color(0.05, 0.3, 0.28)
		m.emission_enabled = true
		m.emission = Color(0.2, 1.0, 0.85)
		m.emission_energy_multiplier = 2.5
		_altar_luz.light_energy = 0.8 + 0.5 * (colocados + 1)
		Sfx.tocar("beep_ok")
		Sfx.tocar("golpe")
		var n := colocados + 1
		estado.mensaje.emit("Fragmento colocado (%d/%d). El pedestal vibra y se abre un compartimento." % [n, GameState.FRAGMENTOS_TOTALES])
		if n == 1:
			_aparecer_tarjeta_azul()
			estado.radio_una_vez("altar", "ROBERTO (radio): «Alex, las cámaras de la sala acaban de parpadear todas a la vez. ¿Qué hiciste? Tranquilo... toma lo que salga del pedestal.»")
		elif n == 3:
			# Recompensa del Nivel 2: tarjeta roja y bateria de linterna ampliada
			_aparecer_tarjeta_roja()
			estado.poner_flag("bateria_ampliada")
			estado.recargar_bateria.emit(100.0)
			estado.mensaje.emit("Recompensa del Nivel 2: batería de linterna ampliada y tarjeta Nivel 2 (roja).")
			estado.radio_una_vez("altar3", "ROBERTO (radio): «Tres de cuatro... Alex, la linterna se ve más fuerte desde aquí. Y esa tarjeta roja... abre algo en el piso de arriba.»")
	elif colocados > 0:
		var altar := get_node("PedestalSellado") as Node3D
		if altar.has_node("TarjetaAzul") or altar.has_node("TarjetaRoja"):
			estado.mensaje.emit("Hay una tarjeta sobre el pedestal: acércate un paso y tómala con E.")
		else:
			estado.mensaje.emit("El pedestal espera los fragmentos restantes (%d/%d)." % [colocados, GameState.FRAGMENTOS_TOTALES])
	else:
		estado.mensaje.emit("Un pedestal con cuatro huecos de forma irregular. Alex: «Aquí van los fragmentos del amuleto.»")


func _aparecer_tarjeta_azul() -> void:
	var altar := get_node("PedestalSellado") as Node3D
	var tarjeta := Node3D.new()
	tarjeta.name = "TarjetaAzul"
	tarjeta.position = Vector3(0, 1.075, 0)
	tarjeta.rotation_degrees.y = 25.0
	altar.add_child(tarjeta)
	var azul := _mat(Color(0.1, 0.3, 0.8), 0.3, 0.6)
	azul.emission_enabled = true
	azul.emission = Color(0.2, 0.5, 1.0)
	azul.emission_energy_multiplier = 1.0
	_box(tarjeta, Vector3.ZERO, Vector3(0.16, 0.006, 0.1), azul)
	_box(tarjeta, Vector3(0.035, 0.005, 0), Vector3(0.04, 0.002, 0.04), _mat(Color(0.9, 0.9, 1.0), 0.4))
	if registry:
		registry.registrar(tarjeta, self, "recoger", "Tomar tarjeta de acceso Nivel 1", 4.0, Vector3.ZERO, {"item": "tarjeta_azul", "mensaje": "Tarjeta de acceso Nivel 1 (azul). Abre la escalera de servicio."}, tarjeta)


func _aparecer_tarjeta_roja() -> void:
	var altar := get_node("PedestalSellado") as Node3D
	var tarjeta := Node3D.new()
	tarjeta.name = "TarjetaRoja"
	tarjeta.position = Vector3(0, 1.075, -0.30)
	tarjeta.rotation_degrees.y = -15.0
	altar.add_child(tarjeta)
	var rojo := _mat(Color(0.8, 0.1, 0.1), 0.3, 0.6)
	rojo.emission_enabled = true
	rojo.emission = Color(1.0, 0.2, 0.2)
	rojo.emission_energy_multiplier = 1.0
	_box(tarjeta, Vector3.ZERO, Vector3(0.16, 0.006, 0.1), rojo)
	_box(tarjeta, Vector3(0.035, 0.005, 0), Vector3(0.04, 0.002, 0.04), _mat(Color(0.95, 0.9, 0.9), 0.4))
	if registry:
		registry.registrar(tarjeta, self, "recoger", "Tomar tarjeta de acceso Nivel 2", 4.0, Vector3.ZERO, {"item": "tarjeta_roja", "mensaje": "Tarjeta de acceso Nivel 2 (roja). Abre la escalera al piso 3."}, tarjeta)


func _build_hall_notes() -> void:
	if registry == null:
		return
	# Diario 3: sobre una banca (cerca de los altares)
	var d3 := _papel(Vector3(12.0, 0.505, 2.3), 20.0)
	var t3 := "[b]DIARIO DE LA DRA. ELENA TORRES - 3[/b]\n\n"
	t3 += "Sobre los [b]reflectores de exhibición[/b]: los focos orientables del techo y del suelo no son solo iluminación. La luz intensa paraliza a las estatuas igual que una mirada. Si se fija un reflector sobre una de ellas, quedará inmóvil para siempre.\n\n"
	t3 += "En la Galería Medieval hay una armería de pasillos estrechos. Allí los reflectores estarán dañados; habrá que alinearlos.\n\n"
	t3 += "[i]Las armaduras son más ruidosas y más rápidas que las estatuas de piedra. No corran; retrocedan.[/i]"
	_nota_papel(d3, "Leer diario", "Diario de la Dra. Torres (3)", t3)
	# Diario 4: en la base del gran Anubis
	var d4 := _papel(Vector3(1.5, 1.03, -13.4), -30.0)
	var t4 := "[b]DIARIO DE LA DRA. ELENA TORRES - 4[/b]\n\n"
	t4 += "El [b]Pedestal de Sellado[/b] está frente al gran Anubis. Cuando los cuatro fragmentos estén en su lugar, la energía de la reliquia quedará neutralizada y las estatuas caerán inertes.\n\n"
	t4 += "Pero la puerta de la bóveda de contención sigue abierta mientras falte uno solo. Y el gran Anubis de esta sala... no es una estatua más. Es el guardián.\n\n"
	t4 += "[i]Reúnan los fragmentos antes de que amanezca.[/i]"
	_nota_papel(d4, "Leer diario", "Diario de la Dra. Torres (4)", t4)


func _papel(pos: Vector3, rot_y: float) -> MeshInstance3D:
	var p := _box(self, pos, Vector3(0.21, 0.006, 0.3), _mat(Color(0.86, 0.8, 0.62), 0.95))
	p.rotation_degrees.y = rot_y
	return p


func _nota_papel(nodo: Node3D, prompt: String, titulo: String, cuerpo: String) -> void:
	var nota_d: Dictionary = {"titulo": titulo, "texto": cuerpo, "estilo": "papel", "firma": ""}
	registry.registrar(nodo, self, "nota", prompt, 3.2, Vector3.ZERO, {"nota": nota_d}, nodo)


func interactuar(it: Dictionary) -> void:
	match String(it["tipo"]):
		"nota":
			Sfx.tocar("papel")
			estado.nota.emit(it["nota"] as Dictionary)
		"examinar":
			estado.mensaje.emit(String(it["mensaje"]))
		"altar":
			_usar_altar()
		"recoger":
			var raiz := it["resaltar"] as Node
			registry.quitar(it)
			if raiz and is_instance_valid(raiz):
				raiz.queue_free()
			estado.recoger(String(it["item"]), 1, String(it["mensaje"]))
