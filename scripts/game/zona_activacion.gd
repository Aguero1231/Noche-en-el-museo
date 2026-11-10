@tool
extends Area3D

## ZONA DE ACTIVACION (componente reutilizable).
##
## Es un Area3D con una CollisionShape3D en forma de caja. Cuando el JUGADOR entra a la zona:
##   1. el motor emite la senal "body_entered"            -> EVENTO
##   2. se revisa que el cuerpo sea el jugador y que la
##      zona siga activa                                  -> CONDICION (if)
##   3. se emite "zona_activada" y se imprime en consola  -> ACCION
##
## Se coloca en el editor: mueve el nodo, cambia "Tamano" en el Inspector y listo.
## En el juego, museum.gd escucha "zona_activada" para que Roberto hable por radio.

signal zona_activada(id_zona: String, mensaje: String)
signal zona_abandonada(id_zona: String)

@export var id_zona := "zona"
@export_multiline var mensaje_radio := ""
@export var una_sola_vez := true
@export var activa := true
## Medidas de la caja de deteccion (ancho, alto, largo). Se actualiza al cambiarlo en el Inspector.
@export var tamano := Vector3(4.0, 3.0, 4.0):
	set(valor):
		tamano = valor
		_actualizar_forma()

# VARIABLES de estado de la zona
var veces_activada := 0
var jugador_dentro := false


func _ready() -> void:
	_actualizar_forma()
	if Engine.is_editor_hint():
		return
	collision_layer = 0     # la zona no es un obstaculo
	collision_mask = 1      # solo detecta cuerpos de la capa 1 (el jugador esta ahi)
	body_entered.connect(_on_body_entered)
	body_exited.connect(_on_body_exited)


func _actualizar_forma() -> void:
	var cs := get_node_or_null("CollisionShape3D") as CollisionShape3D
	if cs == null:
		return
	var forma := BoxShape3D.new()
	forma.size = tamano
	cs.shape = forma


# EVENTO: el motor avisa que un cuerpo entro a la zona
func _on_body_entered(body: Node3D) -> void:
	# CONDICION: solo cuenta el jugador (las paredes tambien son cuerpos)
	if not body.is_in_group("jugador"):
		return
	jugador_dentro = true
	if not activa:
		return
	if una_sola_vez and veces_activada > 0:
		return
	veces_activada += 1
	# ACCION: avisar a todo el que escuche y dejar registro en la consola (Output)
	print("[ZONA] '%s' activada por %s (veces: %d)" % [id_zona, body.name, veces_activada])
	zona_activada.emit(id_zona, mensaje_radio)


func _on_body_exited(body: Node3D) -> void:
	if body.is_in_group("jugador"):
		jugador_dentro = false
		zona_abandonada.emit(id_zona)
