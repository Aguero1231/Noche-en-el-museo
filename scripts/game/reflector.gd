extends Node3D

## REFLECTOR DE EXHIBICION (mecanismo del Nivel 2): foco orientable montado en el techo.
## Un panel (palanca) lo gira entre 4 rumbos (N, E, S, O). Si el haz toca a una estatua o armadura,
## la FIJA para siempre: queda inmovilizada. Solo un rumbo apunta a la estatua; hay que descubrirlo.

signal fijo_estatua(estatua: Node3D)

const RUMBOS := ["NORTE", "ESTE", "SUR", "OESTE"]

## 0 = norte (-z), 1 = este (+x), 2 = sur (+z), 3 = oeste (-x)
@export var rumbo := 0
@export var inclinacion := -50.0       # grados bajo la horizontal
@export var semiangulo := 22.0
@export var alcance := 9.0

var _foco: SpotLight3D
var _t := 0.0
var _hecho := false


func _ready() -> void:
	var metal := StandardMaterial3D.new()
	metal.albedo_color = Color(0.16, 0.16, 0.18)
	metal.metallic = 0.7
	metal.roughness = 0.4
	# Soporte y carcasa del foco
	var cable := MeshInstance3D.new()
	var cm := CylinderMesh.new()
	cm.top_radius = 0.02
	cm.bottom_radius = 0.02
	cm.height = 0.5
	cable.mesh = cm
	cable.material_override = metal
	cable.position = Vector3(0, 0.25, 0)
	add_child(cable)
	var carcasa := MeshInstance3D.new()
	var cc := CylinderMesh.new()
	cc.top_radius = 0.12
	cc.bottom_radius = 0.2
	cc.height = 0.34
	carcasa.mesh = cc
	carcasa.material_override = metal
	add_child(carcasa)

	_foco = SpotLight3D.new()
	_foco.name = "Foco"
	_foco.spot_range = alcance + 1.0
	_foco.spot_angle = semiangulo
	_foco.spot_attenuation = 0.6
	_foco.light_energy = 7.0
	_foco.light_color = Color(1.0, 0.93, 0.75)
	add_child(_foco)

	# Cristal del foco (brilla) y haz visible (cono translucido aditivo)
	var cristal := MeshInstance3D.new()
	var sm := SphereMesh.new()
	sm.radius = 0.1
	sm.height = 0.12
	cristal.mesh = sm
	var mc := StandardMaterial3D.new()
	mc.albedo_color = Color(1, 0.95, 0.7)
	mc.emission_enabled = true
	mc.emission = Color(1, 0.9, 0.6)
	mc.emission_energy_multiplier = 3.0
	cristal.material_override = mc
	cristal.position = Vector3(0, 0, -0.17)
	_foco.add_child(cristal)

	var haz := MeshInstance3D.new()
	var hm := CylinderMesh.new()
	hm.top_radius = 0.04
	hm.bottom_radius = alcance * tan(deg_to_rad(semiangulo))
	hm.height = alcance
	hm.radial_segments = 20
	haz.mesh = hm
	var mh := StandardMaterial3D.new()
	mh.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	mh.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	mh.blend_mode = BaseMaterial3D.BLEND_MODE_ADD
	mh.cull_mode = BaseMaterial3D.CULL_DISABLED
	mh.albedo_color = Color(1.0, 0.93, 0.72, 0.05)
	haz.material_override = mh
	haz.position = Vector3(0, 0, -alcance / 2.0)
	haz.rotation_degrees = Vector3(90, 0, 0)
	_foco.add_child(haz)
	_aplicar()


func _aplicar() -> void:
	rotation_degrees.y = -rumbo * 90.0
	if _foco:
		_foco.rotation_degrees.x = inclinacion


## Gira al siguiente rumbo. Devuelve el nombre del rumbo para mostrarlo.
func rotar() -> String:
	rumbo = (rumbo + 1) % 4
	_aplicar()
	revisar()
	return RUMBOS[rumbo]


func _process(delta: float) -> void:
	_t += delta
	if _t >= 0.5:
		_t = 0.0
		revisar()


## Fija a toda estatua dentro del haz (y a la vista del foco).
func revisar() -> void:
	if _foco == null or not is_inside_tree():
		return
	var origen := _foco.global_position
	var dir := -_foco.global_transform.basis.z
	for n in get_tree().get_nodes_in_group("enemigos"):
		var e := n as Node3D
		if bool(e.get("fijada")):
			continue
		var objetivo := e.global_position + Vector3(0, 1.0, 0)
		var hacia := objetivo - origen
		if hacia.length() > alcance + 1.0 or dir.angle_to(hacia) > deg_to_rad(semiangulo):
			continue
		var q := PhysicsRayQueryParameters3D.create(origen, objetivo)
		q.collision_mask = 1
		var excl: Array[RID] = []
		var r = e.get("rid_bloqueo")
		if r is RID:
			excl.append(r)
		q.exclude = excl
		var hit := get_world_3d().direct_space_state.intersect_ray(q)
		if hit.is_empty() or origen.distance_to(hit["position"] as Vector3) > hacia.length() - 0.9:
			e.call("fijar")
			fijo_estatua.emit(e)
