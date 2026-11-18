extends Control

## Pantalla de carga: muestra la imagen, "CARGANDO NIVEL" y una barra que
## avanza mientras se carga la escena de destino en segundo plano.
##
## Quien quiera usarla solo debe hacer, antes de cambiar a esta escena:
##     Engine.set_meta("next_scene", "res://scenes/museum.tscn")
##     get_tree().change_scene_to_file("res://scenes/loading_screen.tscn")

const DEFAULT_TARGET := "res://scenes/museum.tscn"

## Tiempo minimo (segundos) que tarda la barra en llegar al 100 %.
## Si el nivel carga casi instantaneo, la pantalla igual se ve este tiempo.
## Cambialo a 0.0 para entrar en cuanto termine de cargar.
const MIN_TIME := 3.0

## Velocidad maxima a la que se mueve la barra (1.0 = 100 % por segundo).
const BAR_SPEED := 1.5

## Hasta donde llega la barra mientras el nivel todavia no termina de cargar.
const WAIT_CAP := 0.9

@onready var bar: ProgressBar = $ProgressBar
@onready var percent_label: Label = $PercentLabel
@onready var loading_label: Label = $LoadingLabel

var target_path := DEFAULT_TARGET
var elapsed := 0.0
var shown := 0.0
var finished := false


func _ready() -> void:
	Input.mouse_mode = Input.MOUSE_MODE_VISIBLE
	if Engine.has_meta("next_scene"):
		target_path = str(Engine.get_meta("next_scene"))
		Engine.remove_meta("next_scene")

	bar.min_value = 0.0
	bar.max_value = 100.0
	bar.value = 0.0

	if ResourceLoader.load_threaded_request(target_path) != OK:
		push_error("No se pudo iniciar la carga de: " + target_path)
		set_process(false)
		get_tree().change_scene_to_file.call_deferred(target_path)


func _process(delta: float) -> void:
	if finished:
		return
	elapsed += delta

	var progress: Array = []
	var status := ResourceLoader.load_threaded_get_status(target_path, progress)
	if status == ResourceLoader.THREAD_LOAD_FAILED or status == ResourceLoader.THREAD_LOAD_INVALID_RESOURCE:
		push_error("Fallo al cargar: " + target_path)
		finished = true
		get_tree().change_scene_to_file.call_deferred(target_path)
		return

	var loaded := status == ResourceLoader.THREAD_LOAD_LOADED

	# La barra avanza con el tiempo. Mientras el nivel siga cargando se detiene
	# en 90 %; cuando termina de cargar, puede llegar al 100 %.
	shown = 1.0 if loaded else (float(progress[0]) if not progress.is_empty() else 0.0)

	bar.value = shown * 100.0
	percent_label.text = "%d%%" % int(round(shown * 100.0))
	loading_label.text = "CARGANDO NIVEL" + ".".repeat(int(elapsed * 2.5) % 4)

	if loaded:
		finished = true
		_enter_level()


func _enter_level() -> void:
	shown = 1.0
	bar.value = 100.0
	percent_label.text = "100%"
	loading_label.text = "PREPARANDO LAS SALAS..."
	var packed := ResourceLoader.load_threaded_get(target_path) as PackedScene
	var cover := CanvasLayer.new()
	cover.layer = 128
	cover.set_script(load("res://scripts/ui/loading_cover.gd"))
	var fondo := TextureRect.new()
	fondo.set_anchors_preset(Control.PRESET_FULL_RECT)
	fondo.texture = load("res://assets/loading/loading_screen.png") as Texture2D
	fondo.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	fondo.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_COVERED
	cover.add_child(fondo)
	var preparando := Label.new()
	preparando.text = "PREPARANDO LAS SALAS..."
	preparando.set_anchors_preset(Control.PRESET_CENTER_BOTTOM)
	preparando.offset_left = 70.0
	preparando.offset_top = -112.0
	preparando.offset_right = 540.0
	preparando.offset_bottom = -72.0
	preparando.add_theme_color_override("font_color", Color(0.95, 0.75, 0.32))
	preparando.add_theme_font_size_override("font_size", 24)
	cover.add_child(preparando)
	get_tree().root.add_child(cover)
	await get_tree().process_frame
	get_tree().change_scene_to_packed(packed)
