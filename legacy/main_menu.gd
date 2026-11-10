extends Control

## Menu principal: Jugar / Opciones / Controles / Creditos / Salir.
## Las conexiones de los botones se hacen por codigo en _ready(),
## no hace falta conectarlas a mano en el editor.

@onready var jugar_button: Button = $MenuOpciones/JugarButton
@onready var opciones_button: Button = $MenuOpciones/OpcionesButton
@onready var controles_button: Button = $MenuOpciones/ControlesButton
@onready var creditos_button: Button = $MenuOpciones/CreditosButton
@onready var salir_button: Button = $MenuOpciones/SalirButton

@onready var overlay_opciones: Panel = $OverlayOpciones
@onready var overlay_controles: Panel = $OverlayControles
@onready var overlay_creditos: Panel = $OverlayCreditos

@onready var volumen_slider: HSlider = $OverlayOpciones/Contenido/FilaVolumen/VolumenSlider
@onready var fullscreen_check: CheckBox = $OverlayOpciones/Contenido/FilaPantalla/FullscreenCheck
@onready var volver_opciones: Button = $OverlayOpciones/Contenido/VolverButton
@onready var volver_controles: Button = $OverlayControles/Contenido/VolverButton
@onready var volver_creditos: Button = $OverlayCreditos/Contenido/VolverButton


func _ready() -> void:
	_cerrar_overlays()

	jugar_button.pressed.connect(_start_game)
	opciones_button.pressed.connect(func(): _abrir_overlay(overlay_opciones))
	controles_button.pressed.connect(func(): _abrir_overlay(overlay_controles))
	creditos_button.pressed.connect(func(): _abrir_overlay(overlay_creditos))
	salir_button.pressed.connect(func(): get_tree().quit())

	volver_opciones.pressed.connect(_cerrar_overlays)
	volver_controles.pressed.connect(_cerrar_overlays)
	volver_creditos.pressed.connect(_cerrar_overlays)

	volumen_slider.value_changed.connect(_on_volumen_changed)
	fullscreen_check.toggled.connect(_on_fullscreen_toggled)

	# Reflejar el estado actual del audio/pantalla en los controles de Opciones.
	var bus_index := AudioServer.get_bus_index("Master")
	volumen_slider.value = db_to_linear(AudioServer.get_bus_volume_db(bus_index))
	fullscreen_check.button_pressed = (
		DisplayServer.window_get_mode() == DisplayServer.WINDOW_MODE_FULLSCREEN
	)

	jugar_button.grab_focus()


func _start_game() -> void:
	get_tree().change_scene_to_file("res://scenes/museum.tscn")


func _abrir_overlay(overlay: Panel) -> void:
	_cerrar_overlays()
	overlay.visible = true


func _cerrar_overlays() -> void:
	overlay_opciones.visible = false
	overlay_controles.visible = false
	overlay_creditos.visible = false


func _on_volumen_changed(valor: float) -> void:
	var bus_index := AudioServer.get_bus_index("Master")
	AudioServer.set_bus_volume_db(bus_index, linear_to_db(valor))


func _on_fullscreen_toggled(activado: bool) -> void:
	if activado:
		DisplayServer.window_set_mode(DisplayServer.WINDOW_MODE_FULLSCREEN)
	else:
		DisplayServer.window_set_mode(DisplayServer.WINDOW_MODE_WINDOWED)
