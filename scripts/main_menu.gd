extends Control

## Menu principal: Jugar / Opciones / Controles / Creditos / Salir.
## Todo se conecta por codigo en _ready(), no hace falta tocar
## señales a mano en el editor.
##
## Resaltado de opciones: en vez de un recuadro de foco, la opcion
## activa (mouse encima O seleccionada con teclado) se pone dorada
## y un poco mas grande. Las demas quedan en blanco.
##
## Navegacion con WASD: reusa las acciones "move_forward"/"move_back"
## que ya existen en el proyecto (mapeadas a W y S), ademas de las
## flechas/Tab que Godot maneja solo.

const OptionsPanel = preload("res://scripts/ui/options_panel.gd")

const COLOR_NORMAL := Color(0.92, 0.92, 0.88, 1)
const COLOR_RESALTADO := Color(1.0, 0.82, 0.22, 1)
const ESCALA_NORMAL := Vector2.ONE
const ESCALA_RESALTADA := Vector2(1.12, 1.12)

@onready var jugar_button: Button = $MenuOpciones/JugarButton
@onready var opciones_button: Button = $MenuOpciones/OpcionesButton
@onready var controles_button: Button = $MenuOpciones/ControlesButton
@onready var creditos_button: Button = $MenuOpciones/CreditosButton
@onready var salir_button: Button = $MenuOpciones/SalirButton

@onready var overlay_opciones: Panel = $OverlayOpciones
@onready var overlay_controles: Panel = $OverlayControles
@onready var overlay_creditos: Panel = $OverlayCreditos

@onready var contenido_opciones: VBoxContainer = $OverlayOpciones/Contenido
@onready var volver_opciones: Button = $OverlayOpciones/Contenido/VolverButton
@onready var volver_controles: Button = $OverlayControles/Contenido/VolverButton
@onready var volver_creditos: Button = $OverlayCreditos/Contenido/VolverButton

var botones_menu: Array[Button] = []


func _ready() -> void:
	_cerrar_overlays()

	botones_menu = [jugar_button, opciones_button, controles_button, creditos_button, salir_button]
	for boton in botones_menu:
		boton.pivot_offset = Vector2(0, boton.custom_minimum_size.y / 2.0)
		boton.mouse_entered.connect(_actualizar_resaltado.bind(boton))
		boton.mouse_exited.connect(_actualizar_resaltado.bind(boton))
		boton.focus_entered.connect(_actualizar_resaltado.bind(boton))
		boton.focus_exited.connect(_actualizar_resaltado.bind(boton))
		_actualizar_resaltado(boton)

	jugar_button.pressed.connect(_start_game)
	opciones_button.pressed.connect(func(): _abrir_overlay(overlay_opciones))
	controles_button.pressed.connect(func(): _abrir_overlay(overlay_controles))
	creditos_button.pressed.connect(func(): _abrir_overlay(overlay_creditos))
	salir_button.pressed.connect(func(): get_tree().quit())

	volver_opciones.pressed.connect(_cerrar_overlays)
	volver_controles.pressed.connect(_cerrar_overlays)
	volver_creditos.pressed.connect(_cerrar_overlays)

	_construir_opciones()

	jugar_button.grab_focus()


func _unhandled_input(event: InputEvent) -> void:
	# WASD ademas de flechas/Tab para moverse por el menu.
	if event.is_action_pressed("move_forward"):
		_mover_foco(-1)
	elif event.is_action_pressed("move_back"):
		_mover_foco(1)


func _mover_foco(direccion: int) -> void:
	var actual := get_viewport().gui_get_focus_owner()
	if actual == null:
		botones_menu[0].grab_focus()
		return
	var siguiente: Control = actual.find_next_valid_focus() if direccion > 0 else actual.find_prev_valid_focus()
	if siguiente:
		siguiente.grab_focus()


func _actualizar_resaltado(boton: Button) -> void:
	var resaltado := boton.is_hovered() or boton.has_focus()
	if resaltado:
		boton.add_theme_color_override("font_color", COLOR_RESALTADO)
		boton.scale = ESCALA_RESALTADA
	else:
		boton.add_theme_color_override("font_color", COLOR_NORMAL)
		boton.scale = ESCALA_NORMAL


func _start_game() -> void:
	Engine.set_meta("next_scene", "res://scenes/museum.tscn")
	get_tree().change_scene_to_file("res://scenes/loading_screen.tscn")


func _abrir_overlay(overlay: Panel) -> void:
	_cerrar_overlays()
	overlay.visible = true


func _cerrar_overlays() -> void:
	overlay_opciones.visible = false
	overlay_controles.visible = false
	overlay_creditos.visible = false


## Reemplaza los dos controles sueltos por el panel completo de opciones
## (pantalla completa, VSync, volumen, sensibilidad, FOV, brillo, calidad, FPS).
## Todo se aplica al instante y se guarda en user://settings.cfg.
func _construir_opciones() -> void:
	$OverlayOpciones/Contenido/FilaVolumen.queue_free()
	$OverlayOpciones/Contenido/FilaPantalla.queue_free()
	contenido_opciones.offset_left = -270.0
	contenido_opciones.offset_right = 270.0
	contenido_opciones.offset_top = -270.0
	contenido_opciones.offset_bottom = 270.0
	contenido_opciones.add_theme_constant_override("separation", 12)
	var panel := OptionsPanel.new()
	contenido_opciones.add_child(panel)
	contenido_opciones.move_child(panel, 1)
