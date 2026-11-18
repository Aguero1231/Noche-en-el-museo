extends "res://scripts/enemies/estatua_enemiga.gd"

## Jefe final: conserva la regla de mirada de las estatuas y lanza varillas telegrafiadas.

signal golpe_por_varilla
signal inicio_descarga
signal derrotado

const VEL_VARILLA := 8.5
const VIDA_VARILLA := 3.4

var _espera_ataque := 2.8
var _varillas_pendientes := 0
var _retraso_varilla := 0.0
var _varillas: Array[Dictionary] = []


func _ready() -> void:
	super._ready()
	# El jefe está oculto hasta el ritual y no debe bloquear el pasillo mientras es estatua.
	collision_layer = 0
	var bloqueo := get_node_or_null("Bloqueo") as StaticBody3D
	if bloqueo:
		bloqueo.collision_layer = 0


func activar_encuentro() -> void:
	visible = true
	activa = true
	fijada = false
	collision_layer = 2
	var bloqueo := get_node_or_null("Bloqueo") as StaticBody3D
	if bloqueo:
		bloqueo.collision_layer = 1
	_espera_ataque = 2.8


func _physics_process(delta: float) -> void:
	super._physics_process(delta)
	_actualizar_varillas(delta)
	if not activa or fijada or _jugador == null:
		return
	if _varillas_pendientes > 0:
		_retraso_varilla -= delta
		if _retraso_varilla <= 0.0:
			_lanzar_varilla(_varillas_pendientes)
			_varillas_pendientes -= 1
			_retraso_varilla = 0.34
		return
	_espera_ataque -= delta
	if _espera_ataque <= 0.0 and global_position.distance_to(_jugador.global_position) < 22.0:
		_espera_ataque = 4.8
		_varillas_pendientes = 3
		_retraso_varilla = 0.55
		inicio_descarga.emit()


func _lanzar_varilla(indice: int) -> void:
	if _jugador == null or not is_instance_valid(_jugador):
		return
	var origen := global_position + global_transform.basis.z * 1.0 + Vector3(0.0, 1.7, 0.0)
	var direccion := (_jugador.global_position + Vector3(0.0, 1.0, 0.0) - origen).normalized()
	var lateral := global_transform.basis.x * (float(indice - 1) * 0.09)
	direccion = (direccion + lateral).normalized()
	var vara := Area3D.new()
	vara.name = "VaraDeAnubis"
	vara.collision_layer = 0
	vara.collision_mask = 1
	vara.monitoring = true
	var forma := CollisionShape3D.new()
	var esfera := SphereShape3D.new()
	esfera.radius = 0.17
	forma.shape = esfera
	vara.add_child(forma)
	var malla := MeshInstance3D.new()
	var caja := BoxMesh.new()
	caja.size = Vector3(0.10, 0.10, 1.0)
	malla.mesh = caja
	var metal := StandardMaterial3D.new()
	metal.albedo_color = Color(0.28, 0.18, 0.08)
	metal.metallic = 0.72
	metal.roughness = 0.3
	metal.emission_enabled = true
	metal.emission = Color(0.24, 0.55, 1.0)
	metal.emission_energy_multiplier = 1.2
	malla.material_override = metal
	vara.add_child(malla)
	var bloqueo := get_node_or_null("Bloqueo") as StaticBody3D
	if bloqueo:
		vara.add_collision_exception_with(bloqueo)
	vara.body_entered.connect(_al_chocar_varilla.bind(vara))
	get_tree().current_scene.add_child(vara)
	vara.global_position = origen
	vara.look_at(origen + direccion, Vector3.UP)
	_varillas.append({"nodo": vara, "direccion": direccion, "vida": VIDA_VARILLA})


func _al_chocar_varilla(cuerpo: Node3D, vara: Area3D) -> void:
	if cuerpo.is_in_group("jugador"):
		golpe_por_varilla.emit()
	if is_instance_valid(vara):
		vara.queue_free()


func _actualizar_varillas(delta: float) -> void:
	for i in range(_varillas.size() - 1, -1, -1):
		var dato: Dictionary = _varillas[i]
		var vara := dato["nodo"] as Area3D
		if not is_instance_valid(vara):
			_varillas.remove_at(i)
			continue
		var direccion: Vector3 = dato["direccion"]
		vara.global_position += direccion * VEL_VARILLA * delta
		dato["vida"] = float(dato["vida"]) - delta
		if float(dato["vida"]) <= 0.0:
			vara.queue_free()
			_varillas.remove_at(i)
		else:
			_varillas[i] = dato


func cerrar_encuentro() -> void:
	activa = false
	fijada = true
	visible = false
	collision_layer = 0
	var bloqueo := get_node_or_null("Bloqueo") as StaticBody3D
	if bloqueo:
		bloqueo.collision_layer = 0
	velocity = Vector3.ZERO
	for dato in _varillas:
		var vara := dato["nodo"] as Area3D
		if is_instance_valid(vara):
			vara.queue_free()
	_varillas.clear()
	derrotado.emit()
