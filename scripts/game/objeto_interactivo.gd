extends Area3D

## OBJETO INTERACTIVO (componente reutilizable): un interruptor con LED.
##
## Un Area3D delante del panel detecta al JUGADOR:
##   - body_entered / body_exited (EVENTOS del motor) marcan si el jugador esta cerca
##   - el objeto se registra en el registro de interactivos del juego (grupo "registro_interactivos"),
##     que elige UN solo objetivo y muestra su texto en pantalla. Si el elegido es este interruptor
##     y presionas E, el registro llama a interactuar() -> usar().
##   - usar(): cambia la variable "encendido", el LED y emite "interactuado" (ACCION).
## museum.gd escucha "interactuado" y prende / apaga las luces de la sala indicada en "id_luces".
## Los interruptores tienen la prioridad mas baja: si hay un objeto para agarrar al lado, gana ese
## (y con Tab se puede cambiar de objetivo).

signal interactuado(nombre: String, encendido: bool, id_luces: String)

@export var nombre_objeto := "Interruptor"
## Sala cuyas luces controla: "vestibulo", "control", "oficina_dra" o "restauracion".
@export var id_luces := ""
@export var texto_aviso := "Usar interruptor"
@export var empieza_encendido := true
## Interruptor dañado (Nivel 2): solo chispea y no hace nada.
@export var danado := false
@export var color_encendido := Color(0.2, 1.0, 0.3)
@export var color_apagado := Color(1.0, 0.15, 0.1)

# VARIABLES de estado del objeto
var encendido := true
var jugador_cerca := false

@onready var led: MeshInstance3D = $Led


func _ready() -> void:
	collision_layer = 0
	collision_mask = 1
	encendido = empieza_encendido
	led.material_override = StandardMaterial3D.new()
	_actualizar_led()
	body_entered.connect(_on_body_entered)
	body_exited.connect(_on_body_exited)
	var registro := get_tree().get_first_node_in_group("registro_interactivos")
	if registro:
		registro.registrar(self, self, "interruptor_area", texto_aviso, 3.4, Vector3.ZERO, {}, self)


# EVENTO: el jugador entro al area del objeto
func _on_body_entered(body: Node3D) -> void:
	if body.is_in_group("jugador"):
		jugador_cerca = true
		print("[DETECCION] El jugador se acerco a: %s" % nombre_objeto)


# EVENTO: el jugador se alejo
func _on_body_exited(body: Node3D) -> void:
	if body.is_in_group("jugador"):
		jugador_cerca = false


## El registro ya valida distancia, direccion de vista y que no haya obstaculos antes de llamar aqui.
func interactuar(_it: Dictionary) -> void:
	usar()


## ACCION: alterna el objeto, actualiza el LED y avisa a quien escuche.
func usar() -> void:
	if danado:
		Sfx.tocar("chispa")
		print("[INTERACCION] %s -> DAÑADO (chispea)" % nombre_objeto)
		interactuado.emit(nombre_objeto, encendido, "danado")
		return
	encendido = not encendido
	_actualizar_led()
	Sfx.tocar("beep_ok")
	print("[INTERACCION] %s -> %s" % [nombre_objeto, "ENCENDIDO" if encendido else "APAGADO"])
	interactuado.emit(nombre_objeto, encendido, id_luces)


## Cambia el estado sin avisar (cuando las luces se apagan "solas", por una estatua).
func forzar(valor: bool) -> void:
	encendido = valor
	_actualizar_led()


func _actualizar_led() -> void:
	var m := led.material_override as StandardMaterial3D
	var c := color_encendido if encendido else color_apagado
	m.albedo_color = c
	m.emission_enabled = true
	m.emission = c
	m.emission_energy_multiplier = 2.5
