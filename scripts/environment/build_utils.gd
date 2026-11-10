extends RefCounted

## Utilidades para armar escenarios por codigo con las texturas del museo
## (assets/environment/): piedra, marmol, alfombra y banda de jeroglificos.
## Los materiales de textura se guardan en cache y se comparten entre cuartos.

const TEX := "res://assets/environment/"

var _cache := {}


func tex(file: String) -> Texture2D:
	var path := TEX + file
	if ResourceLoader.exists(path):
		return load(path) as Texture2D
	return null


# ---------------------------------------------------------------- materiales

## Material liso (nuevo cada vez: seguro para objetos con contorno / emision propia).
func mat(color: Color, rough: float = 0.8, metal: float = 0.0, emis: Color = Color.BLACK, emis_e: float = 1.0) -> StandardMaterial3D:
	var m := StandardMaterial3D.new()
	m.albedo_color = color
	m.roughness = rough
	m.metallic = metal
	if emis != Color.BLACK:
		m.emission_enabled = true
		m.emission = emis
		m.emission_energy_multiplier = emis_e
	return m


func glass(color: Color = Color(0.65, 0.8, 0.95, 0.12)) -> StandardMaterial3D:
	var m := StandardMaterial3D.new()
	m.albedo_color = color
	m.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	m.roughness = 0.04
	m.metallic_specular = 1.0
	return m


## Piedra del museo (wall_stone.png + normal map), triplanar en coordenadas del mundo.
func stone(tint: Color = Color(1, 1, 1), scale: float = 0.25) -> StandardMaterial3D:
	var key := "stone:%s:%s" % [tint.to_html(), str(scale)]
	if _cache.has(key):
		return _cache[key]
	var m := StandardMaterial3D.new()
	m.albedo_texture = tex("wall_stone.png")
	m.albedo_color = tint
	var n := tex("wall_stone_n.png")
	if n:
		m.normal_enabled = true
		m.normal_texture = n
		m.normal_scale = 1.0
	m.roughness = 0.85
	m.uv1_triplanar = true
	m.uv1_world_triplanar = true
	m.uv1_scale = Vector3(scale, scale, scale)
	_cache[key] = m
	return m


## Marmol del museo (floor_marble.png + normal map).
func marble(tint: Color = Color(1, 1, 1), scale: float = 0.125) -> StandardMaterial3D:
	var key := "marble:%s:%s" % [tint.to_html(), str(scale)]
	if _cache.has(key):
		return _cache[key]
	var m := StandardMaterial3D.new()
	m.albedo_texture = tex("floor_marble.png")
	m.albedo_color = tint
	var n := tex("floor_marble_n.png")
	if n:
		m.normal_enabled = true
		m.normal_texture = n
		m.normal_scale = 0.45
	m.roughness = 0.32
	m.metallic_specular = 0.6
	m.uv1_triplanar = true
	m.uv1_world_triplanar = true
	m.uv1_scale = Vector3(scale, scale, scale)
	_cache[key] = m
	return m


## Alfombra del museo (carpet.png). Para plano de largo L y ancho W, usa uv_y = L / (W * 2).
func carpet(uv_y: float = 1.0) -> StandardMaterial3D:
	var m := StandardMaterial3D.new()
	var t := tex("carpet.png")
	m.albedo_texture = t
	if t == null:
		m.albedo_color = Color(0.4, 0.06, 0.07)
	m.roughness = 1.0
	m.uv1_scale = Vector3(1, uv_y, 1)
	return m


func wood() -> StandardMaterial3D:
	if _cache.has("wood"):
		return _cache["wood"]
	var m := mat(Color(0.12, 0.075, 0.05), 0.55)
	_cache["wood"] = m
	return m


func wood_light() -> StandardMaterial3D:
	if _cache.has("wood_light"):
		return _cache["wood_light"]
	var m := mat(Color(0.34, 0.20, 0.11), 0.5)
	_cache["wood_light"] = m
	return m


func gold() -> StandardMaterial3D:
	if _cache.has("gold"):
		return _cache["gold"]
	var m := mat(Color(0.86, 0.66, 0.27), 0.32, 0.65, Color(0.55, 0.36, 0.08), 0.35)
	_cache["gold"] = m
	return m


func metal(color: Color = Color(0.30, 0.30, 0.30)) -> StandardMaterial3D:
	var key := "metal:%s" % color.to_html()
	if _cache.has(key):
		return _cache[key]
	var m := mat(color, 0.4, 0.75)
	_cache[key] = m
	return m


func dark() -> StandardMaterial3D:
	if _cache.has("dark"):
		return _cache["dark"]
	var m := mat(Color(0.07, 0.07, 0.08), 0.5, 0.3)
	_cache["dark"] = m
	return m


# ---------------------------------------------------------------- formas

func node3d(parent: Node, nombre: String, pos: Vector3, rot_y_deg: float = 0.0) -> Node3D:
	var n := Node3D.new()
	n.name = nombre
	n.position = pos
	n.rotation_degrees.y = rot_y_deg
	parent.add_child(n)
	return n


## Caja. Si solid = true lleva colision (StaticBody3D hijo, hereda la rotacion).
func box(parent: Node, pos: Vector3, size: Vector3, m: Material, solid: bool = false, rot_deg: Vector3 = Vector3.ZERO, nombre: String = "") -> MeshInstance3D:
	var mi := MeshInstance3D.new()
	var bm := BoxMesh.new()
	bm.size = size
	mi.mesh = bm
	mi.material_override = m
	mi.position = pos
	mi.rotation_degrees = rot_deg
	if nombre != "":
		mi.name = nombre
	parent.add_child(mi)
	if solid:
		var body := StaticBody3D.new()
		var cs := CollisionShape3D.new()
		var bs := BoxShape3D.new()
		bs.size = size
		cs.shape = bs
		body.add_child(cs)
		mi.add_child(body)
	return mi


func cyl(parent: Node, pos: Vector3, r_top: float, r_bot: float, h: float, m: Material, rot_deg: Vector3 = Vector3.ZERO, seg: int = 16, solid: bool = false) -> MeshInstance3D:
	var mi := MeshInstance3D.new()
	var cm := CylinderMesh.new()
	cm.top_radius = r_top
	cm.bottom_radius = r_bot
	cm.height = h
	cm.radial_segments = seg
	mi.mesh = cm
	mi.material_override = m
	mi.position = pos
	mi.rotation_degrees = rot_deg
	parent.add_child(mi)
	if solid:
		var body := StaticBody3D.new()
		var cs := CollisionShape3D.new()
		var sh := CylinderShape3D.new()
		sh.radius = maxf(r_top, r_bot)
		sh.height = h
		cs.shape = sh
		body.add_child(cs)
		mi.add_child(body)
	return mi


func sphere(parent: Node, pos: Vector3, r: float, m: Material, scl: Vector3 = Vector3.ONE) -> MeshInstance3D:
	var mi := MeshInstance3D.new()
	var sm := SphereMesh.new()
	sm.radius = r
	sm.height = r * 2.0
	sm.radial_segments = 16
	sm.rings = 8
	mi.mesh = sm
	mi.material_override = m
	mi.position = pos
	mi.scale = scl
	parent.add_child(mi)
	return mi


## Plano / cuadro (QuadMesh) mirando a +z (usa rot_y_deg para orientarlo).
func quad(parent: Node, pos: Vector3, size: Vector2, m: Material, rot_y_deg: float = 0.0) -> MeshInstance3D:
	var mi := MeshInstance3D.new()
	var qm := QuadMesh.new()
	qm.size = size
	mi.mesh = qm
	mi.material_override = m
	mi.position = pos
	mi.rotation_degrees.y = rot_y_deg
	parent.add_child(mi)
	return mi


func text3d(parent: Node, txt: String, pos: Vector3, rot_y_deg: float, font_px: int, color: Color, pixel_size: float = 0.004) -> Label3D:
	var f := SystemFont.new()
	f.font_names = PackedStringArray(["Arial", "Helvetica", "Roboto", "sans-serif"])
	f.font_weight = 700
	var t := Label3D.new()
	t.text = txt
	t.font = f
	t.font_size = font_px
	t.pixel_size = pixel_size
	t.modulate = color
	t.outline_size = 0
	t.double_sided = false
	t.position = pos
	t.rotation_degrees.y = rot_y_deg
	parent.add_child(t)
	return t


# ---------------------------------------------------------------- luces

func omni(parent: Node, pos: Vector3, color: Color, energy: float, rng: float, shadow: bool = false) -> OmniLight3D:
	var l := OmniLight3D.new()
	l.position = pos
	l.light_color = color
	l.light_energy = energy
	l.omni_range = rng
	l.omni_attenuation = 1.4
	l.shadow_enabled = shadow
	parent.add_child(l)
	return l


func spot(parent: Node, pos: Vector3, rot_deg: Vector3, color: Color, energy: float, rng: float, angle: float, shadow: bool = false) -> SpotLight3D:
	var l := SpotLight3D.new()
	l.position = pos
	l.rotation_degrees = rot_deg
	l.light_color = color
	l.light_energy = energy
	l.spot_range = rng
	l.spot_angle = angle
	l.spot_attenuation = 0.8
	l.shadow_enabled = shadow
	parent.add_child(l)
	return l
