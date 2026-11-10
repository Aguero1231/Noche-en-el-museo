extends Node

## Configuracion global del juego (autoload "Settings").
## - Se guarda en user://settings.cfg y se aplica al iniciar.
## - La usan el menu principal y el menu de pausa (scripts/ui/options_panel.gd).
## - F11 alterna pantalla completa en cualquier momento.
## Calidad: 0 = baja (PCs modestas), 1 = media, 2 = alta.

signal changed(key: String)

const PATH := "user://settings.cfg"
const WINDOWED_SIZE := Vector2i(1280, 720)

var fullscreen := false
var vsync := true
var volume := 1.0
var sensitivity := 0.10
var fov := 70.0
var brightness := 1.0
var show_fps := false
var quality := 1

var _fps_layer: CanvasLayer
var _fps_label: Label


func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	_build_fps_label()
	load_settings()
	apply_all()


func _process(_delta: float) -> void:
	if show_fps:
		_fps_label.text = "%d FPS" % Engine.get_frames_per_second()


func _input(event: InputEvent) -> void:
	if event is InputEventKey:
		var key := event as InputEventKey
		if key.pressed and not key.echo and key.keycode == KEY_F11:
			set_setting("fullscreen", not fullscreen)
			save_settings()
			get_viewport().set_input_as_handled()


## Cambia un valor, lo aplica y avisa a quien escuche (los paneles de opciones).
func set_setting(key: String, value: Variant) -> void:
	match key:
		"fullscreen":
			fullscreen = bool(value)
		"vsync":
			vsync = bool(value)
		"volume":
			volume = clampf(float(value), 0.0, 1.0)
		"sensitivity":
			sensitivity = clampf(float(value), 0.02, 0.4)
		"fov":
			fov = clampf(float(value), 50.0, 110.0)
		"brightness":
			brightness = clampf(float(value), 0.5, 1.8)
		"show_fps":
			show_fps = bool(value)
		"quality":
			quality = clampi(int(value), 0, 2)
		_:
			return
	_apply(key)
	changed.emit(key)


func reset_defaults() -> void:
	set_setting("fullscreen", false)
	set_setting("vsync", true)
	set_setting("volume", 1.0)
	set_setting("sensitivity", 0.10)
	set_setting("fov", 70.0)
	set_setting("brightness", 1.0)
	set_setting("show_fps", false)
	set_setting("quality", 1)
	save_settings()


func apply_all() -> void:
	for k in ["fullscreen", "vsync", "volume", "show_fps", "quality"]:
		_apply(k)


func save_settings() -> void:
	var cfg := ConfigFile.new()
	cfg.set_value("settings", "fullscreen", fullscreen)
	cfg.set_value("settings", "vsync", vsync)
	cfg.set_value("settings", "volume", volume)
	cfg.set_value("settings", "sensitivity", sensitivity)
	cfg.set_value("settings", "fov", fov)
	cfg.set_value("settings", "brightness", brightness)
	cfg.set_value("settings", "show_fps", show_fps)
	cfg.set_value("settings", "quality", quality)
	cfg.save(PATH)


func load_settings() -> void:
	var cfg := ConfigFile.new()
	if cfg.load(PATH) != OK:
		return
	fullscreen = bool(cfg.get_value("settings", "fullscreen", fullscreen))
	vsync = bool(cfg.get_value("settings", "vsync", vsync))
	volume = clampf(float(cfg.get_value("settings", "volume", volume)), 0.0, 1.0)
	sensitivity = clampf(float(cfg.get_value("settings", "sensitivity", sensitivity)), 0.02, 0.4)
	fov = clampf(float(cfg.get_value("settings", "fov", fov)), 50.0, 110.0)
	brightness = clampf(float(cfg.get_value("settings", "brightness", brightness)), 0.5, 1.8)
	show_fps = bool(cfg.get_value("settings", "show_fps", show_fps))
	quality = clampi(int(cfg.get_value("settings", "quality", quality)), 0, 2)


func _apply(key: String) -> void:
	match key:
		"fullscreen":
			_aplicar_pantalla_completa()
		"vsync":
			if not ventana_incrustada():
				DisplayServer.window_set_vsync_mode(DisplayServer.VSYNC_ENABLED if vsync else DisplayServer.VSYNC_DISABLED)
		"volume":
			var bus := AudioServer.get_bus_index("Master")
			AudioServer.set_bus_mute(bus, volume <= 0.001)
			AudioServer.set_bus_volume_db(bus, linear_to_db(maxf(volume, 0.001)))
		"show_fps":
			_fps_layer.visible = show_fps
		"quality":
			var vp := get_viewport()
			vp.msaa_3d = Viewport.MSAA_2X if quality >= 2 else Viewport.MSAA_DISABLED


## Cuando el juego corre incrustado en el editor de Godot ("Embed Game"), la ventana no se puede
## mover, cambiar de tamano ni poner en pantalla completa (solo en el juego exportado o con
## "Embed Game" desactivado). En ese caso no se toca la ventana para no llenar la consola de avisos.
func ventana_incrustada() -> bool:
	return DisplayServer.get_name() == "embedded"


func _aplicar_pantalla_completa() -> void:
	if ventana_incrustada() or DisplayServer.get_name() == "headless":
		return
	var actual := DisplayServer.window_get_mode()
	var es_completa := actual == DisplayServer.WINDOW_MODE_FULLSCREEN or actual == DisplayServer.WINDOW_MODE_EXCLUSIVE_FULLSCREEN
	if fullscreen and not es_completa:
		DisplayServer.window_set_mode(DisplayServer.WINDOW_MODE_FULLSCREEN)
	elif not fullscreen and es_completa:
		DisplayServer.window_set_mode(DisplayServer.WINDOW_MODE_WINDOWED)
		DisplayServer.window_set_size(WINDOWED_SIZE)
		var screen := DisplayServer.screen_get_size()
		DisplayServer.window_set_position((screen - WINDOWED_SIZE) / 2)


func _build_fps_label() -> void:
	_fps_layer = CanvasLayer.new()
	_fps_layer.layer = 100
	_fps_layer.visible = false
	add_child(_fps_layer)
	_fps_label = Label.new()
	_fps_label.set_anchors_preset(Control.PRESET_TOP_RIGHT)
	_fps_label.offset_left = -120
	_fps_label.offset_right = -14
	_fps_label.offset_top = 8
	_fps_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
	_fps_label.add_theme_font_size_override("font_size", 16)
	_fps_label.add_theme_color_override("font_color", Color(0.6, 1.0, 0.6))
	_fps_label.add_theme_color_override("font_outline_color", Color.BLACK)
	_fps_label.add_theme_constant_override("outline_size", 5)
	_fps_label.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_fps_layer.add_child(_fps_label)
