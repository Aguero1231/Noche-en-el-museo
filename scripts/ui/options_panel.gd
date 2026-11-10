extends VBoxContainer

## Panel de opciones reutilizable (menu principal y menu de pausa).
## Todo lo que se mueva aqui se aplica al instante y se guarda (ver scripts/settings.gd).

const COLOR_TEXTO := Color(0.85, 0.83, 0.78)
const COLOR_VALOR := Color(0.92, 0.85, 0.66)

var _rows: Dictionary = {}          # key -> Control
var _value_labels: Dictionary = {}  # key -> Label
var _building := true


func _ready() -> void:
	add_theme_constant_override("separation", 10)
	_add_check("Pantalla completa  (F11)", "fullscreen")
	_add_check("Sincronización vertical (VSync)", "vsync")
	_add_slider("Volumen general", "volume", 0.0, 1.0, 0.05)
	_add_slider("Sensibilidad del mouse", "sensitivity", 0.03, 0.30, 0.01)
	_add_slider("Campo de visión (FOV)", "fov", 60.0, 100.0, 1.0)
	_add_slider("Brillo", "brightness", 0.6, 1.6, 0.05)
	_add_quality()
	_add_check("Mostrar FPS", "show_fps")

	var reset := Button.new()
	reset.text = "Restablecer valores"
	reset.pressed.connect(func(): Settings.reset_defaults())
	add_child(reset)

	Settings.changed.connect(_on_settings_changed)
	visibility_changed.connect(_refresh_all)
	_refresh_all()
	_building = false


func _label(texto: String) -> Label:
	var l := Label.new()
	l.text = texto
	l.custom_minimum_size = Vector2(230, 0)
	l.add_theme_color_override("font_color", COLOR_TEXTO)
	return l


func _add_check(texto: String, key: String) -> void:
	var row := HBoxContainer.new()
	row.add_theme_constant_override("separation", 14)
	row.add_child(_label(texto))
	var check := CheckButton.new()
	check.toggled.connect(func(on: bool): _on_user_changed(key, on))
	row.add_child(check)
	add_child(row)
	_rows[key] = check


func _add_slider(texto: String, key: String, vmin: float, vmax: float, step: float) -> void:
	var row := HBoxContainer.new()
	row.add_theme_constant_override("separation", 14)
	row.add_child(_label(texto))
	var slider := HSlider.new()
	slider.min_value = vmin
	slider.max_value = vmax
	slider.step = step
	slider.custom_minimum_size = Vector2(170, 0)
	slider.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	slider.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	slider.value_changed.connect(func(v: float): _on_user_changed(key, v))
	row.add_child(slider)
	var val := Label.new()
	val.custom_minimum_size = Vector2(52, 0)
	val.add_theme_color_override("font_color", COLOR_VALOR)
	val.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
	row.add_child(val)
	add_child(row)
	_rows[key] = slider
	_value_labels[key] = val


func _add_quality() -> void:
	var row := HBoxContainer.new()
	row.add_theme_constant_override("separation", 14)
	row.add_child(_label("Calidad gráfica"))
	var opt := OptionButton.new()
	opt.add_item("Baja", 0)
	opt.add_item("Media", 1)
	opt.add_item("Alta", 2)
	opt.item_selected.connect(func(i: int): _on_user_changed("quality", i))
	row.add_child(opt)
	add_child(row)
	_rows["quality"] = opt


func _on_user_changed(key: String, value: Variant) -> void:
	if _building:
		return
	Settings.set_setting(key, value)
	Settings.save_settings()


func _on_settings_changed(_key: String) -> void:
	_refresh_all()


func _refresh_all() -> void:
	if _rows.is_empty():
		return
	_set_check("fullscreen", Settings.fullscreen)
	_set_check("vsync", Settings.vsync)
	_set_check("show_fps", Settings.show_fps)
	_set_slider("volume", Settings.volume, "%d%%" % int(round(Settings.volume * 100.0)))
	_set_slider("sensitivity", Settings.sensitivity, "%.2f" % Settings.sensitivity)
	_set_slider("fov", Settings.fov, "%d°" % int(Settings.fov))
	_set_slider("brightness", Settings.brightness, "%d%%" % int(round(Settings.brightness * 100.0)))
	var opt := _rows["quality"] as OptionButton
	if opt.selected != Settings.quality:
		opt.select(Settings.quality)


func _set_check(key: String, value: bool) -> void:
	var c := _rows[key] as CheckButton
	if c.button_pressed != value:
		c.set_pressed_no_signal(value)


func _set_slider(key: String, value: float, texto: String) -> void:
	var s := _rows[key] as HSlider
	if not is_equal_approx(s.value, value):
		s.set_value_no_signal(value)
	(_value_labels[key] as Label).text = texto
