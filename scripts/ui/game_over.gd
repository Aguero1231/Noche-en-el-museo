extends CanvasLayer

## Pantalla de "TE ATRAPARON": fundido a rojo, frase y botones para reintentar o volver al menu.

var _titulo: Label
var _causa: Label
var _caja: VBoxContainer
var _fondo: ColorRect


func _ready() -> void:
	layer = 40
	process_mode = Node.PROCESS_MODE_ALWAYS
	visible = false
	_construir()


func mostrar(causa: String) -> void:
	_causa.text = causa
	visible = true
	_fondo.color.a = 0.0
	_caja.modulate.a = 0.0
	Input.mouse_mode = Input.MOUSE_MODE_VISIBLE
	get_tree().paused = true
	var tw := create_tween()
	tw.tween_property(_fondo, "color:a", 0.88, 0.8)
	tw.tween_property(_caja, "modulate:a", 1.0, 0.6)


func _reintentar() -> void:
	get_tree().paused = false
	get_tree().reload_current_scene()


func _al_menu() -> void:
	get_tree().paused = false
	get_tree().change_scene_to_file("res://scenes/main_menu.tscn")


func _construir() -> void:
	_fondo = ColorRect.new()
	_fondo.color = Color(0.25, 0.0, 0.0, 0.0)
	_fondo.set_anchors_preset(Control.PRESET_FULL_RECT)
	add_child(_fondo)
	var centro := CenterContainer.new()
	centro.set_anchors_preset(Control.PRESET_FULL_RECT)
	add_child(centro)
	_caja = VBoxContainer.new()
	_caja.add_theme_constant_override("separation", 16)
	centro.add_child(_caja)

	_titulo = Label.new()
	_titulo.text = "TE ATRAPARON"
	_titulo.add_theme_font_size_override("font_size", 56)
	_titulo.add_theme_color_override("font_color", Color(0.9, 0.12, 0.1))
	_titulo.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_caja.add_child(_titulo)

	_causa = Label.new()
	_causa.add_theme_font_size_override("font_size", 20)
	_causa.add_theme_color_override("font_color", Color(0.85, 0.8, 0.75))
	_causa.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_causa.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	_causa.custom_minimum_size = Vector2(560, 0)
	_caja.add_child(_causa)

	var lema := Label.new()
	lema.text = "«Lo que no miras, se mueve.»"
	lema.add_theme_font_size_override("font_size", 16)
	lema.add_theme_color_override("font_color", Color(0.6, 0.55, 0.5))
	lema.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_caja.add_child(lema)

	var b1 := Button.new()
	b1.text = "REINTENTAR"
	b1.custom_minimum_size = Vector2(300, 52)
	b1.pressed.connect(_reintentar)
	_caja.add_child(b1)
	var b2 := Button.new()
	b2.text = "MENÚ PRINCIPAL"
	b2.custom_minimum_size = Vector2(300, 52)
	b2.pressed.connect(_al_menu)
	_caja.add_child(b2)
