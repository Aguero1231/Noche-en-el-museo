extends CanvasLayer

## Visor de cartas, notas, diarios y pantallas de computadora.
## Estilos: "papel" (hoja amarillenta), "terminal" (texto verde sobre negro) y "credencial".
## Pausa el juego mientras esta abierto; se cierra con E, Esc, Enter o clic.

signal cerrado

var abierto := false

var _panel: PanelContainer
var _titulo: Label
var _cuerpo: RichTextLabel
var _pie: Label
var _firma: Label
var _foto: Control
var _estilo_papel: StyleBoxFlat
var _estilo_terminal: StyleBoxFlat
var _fuente_papel: SystemFont
var _fuente_terminal: SystemFont
var _negrita_papel: SystemFont
var _cursiva_papel: SystemFont
var _negrita_terminal: SystemFont
var _cursiva_terminal: SystemFont


func _ready() -> void:
	layer = 20
	process_mode = Node.PROCESS_MODE_ALWAYS
	visible = false
	_construir()


func abrir(datos: Dictionary) -> void:
	var estilo := String(datos.get("estilo", "papel"))
	var terminal := estilo == "terminal"
	_panel.add_theme_stylebox_override("panel", _estilo_terminal if terminal else _estilo_papel)
	var tinta := Color(0.35, 1.0, 0.5) if terminal else Color(0.16, 0.09, 0.04)
	var fuente := _fuente_terminal if terminal else _fuente_papel
	_titulo.text = String(datos.get("titulo", ""))
	_titulo.add_theme_color_override("font_color", tinta)
	_titulo.add_theme_font_override("font", fuente)
	_cuerpo.clear()
	_cuerpo.add_theme_font_override("normal_font", fuente)
	_cuerpo.add_theme_font_override("bold_font", _negrita_terminal if terminal else _negrita_papel)
	_cuerpo.add_theme_font_override("italics_font", _cursiva_terminal if terminal else _cursiva_papel)
	_cuerpo.push_font(fuente)
	_cuerpo.push_color(tinta)
	_cuerpo.append_text(String(datos.get("texto", "")))
	_cuerpo.pop_all()
	_cuerpo.scroll_to_line(0)
	_firma.text = String(datos.get("firma", ""))
	_firma.add_theme_color_override("font_color", tinta)
	_firma.visible = _firma.text != ""
	_foto.visible = estilo == "credencial"
	_pie.add_theme_color_override("font_color", tinta * Color(1, 1, 1, 0.6))
	visible = true
	abierto = true
	Input.mouse_mode = Input.MOUSE_MODE_VISIBLE
	get_tree().paused = true


func cerrar() -> void:
	if not abierto:
		return
	visible = false
	abierto = false
	get_tree().paused = false
	Input.mouse_mode = Input.MOUSE_MODE_CAPTURED
	cerrado.emit()


func _unhandled_input(event: InputEvent) -> void:
	if not abierto:
		return
	var cerrar_ya := false
	if event is InputEventKey:
		var k := event as InputEventKey
		if k.pressed and not k.echo and (k.keycode == KEY_E or k.keycode == KEY_ESCAPE or k.keycode == KEY_ENTER or k.keycode == KEY_SPACE):
			cerrar_ya = true
	elif event is InputEventMouseButton:
		var mb := event as InputEventMouseButton
		if mb.pressed and mb.button_index == MOUSE_BUTTON_LEFT:
			cerrar_ya = true
	if cerrar_ya:
		get_viewport().set_input_as_handled()
		cerrar()


func _variante(base: SystemFont, negrita: bool, cursiva: bool) -> SystemFont:
	var f := SystemFont.new()
	f.font_names = base.font_names
	f.font_weight = 700 if negrita else 400
	f.font_italic = cursiva
	return f


func _construir() -> void:
	var fondo := ColorRect.new()
	fondo.color = Color(0, 0, 0, 0.62)
	fondo.set_anchors_preset(Control.PRESET_FULL_RECT)
	fondo.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(fondo)

	_fuente_papel = SystemFont.new()
	_fuente_papel.font_names = PackedStringArray(["Georgia", "Palatino Linotype", "Times New Roman", "serif"])
	_fuente_terminal = SystemFont.new()
	_fuente_terminal.font_names = PackedStringArray(["Consolas", "Courier New", "monospace"])
	_negrita_papel = _variante(_fuente_papel, true, false)
	_cursiva_papel = _variante(_fuente_papel, false, true)
	_negrita_terminal = _variante(_fuente_terminal, true, false)
	_cursiva_terminal = _variante(_fuente_terminal, false, true)

	_estilo_papel = StyleBoxFlat.new()
	_estilo_papel.bg_color = Color(0.83, 0.74, 0.55)
	_estilo_papel.border_color = Color(0.45, 0.32, 0.16)
	_estilo_papel.set_border_width_all(3)
	_estilo_papel.set_corner_radius_all(3)
	_estilo_papel.set_content_margin_all(28)
	_estilo_papel.shadow_color = Color(0, 0, 0, 0.6)
	_estilo_papel.shadow_size = 14

	_estilo_terminal = StyleBoxFlat.new()
	_estilo_terminal.bg_color = Color(0.02, 0.05, 0.03)
	_estilo_terminal.border_color = Color(0.25, 0.7, 0.4)
	_estilo_terminal.set_border_width_all(3)
	_estilo_terminal.set_corner_radius_all(10)
	_estilo_terminal.set_content_margin_all(28)

	var centro := CenterContainer.new()
	centro.set_anchors_preset(Control.PRESET_FULL_RECT)
	centro.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(centro)

	_panel = PanelContainer.new()
	_panel.custom_minimum_size = Vector2(700, 0)
	centro.add_child(_panel)

	var caja := VBoxContainer.new()
	caja.add_theme_constant_override("separation", 12)
	_panel.add_child(caja)

	_titulo = Label.new()
	_titulo.add_theme_font_size_override("font_size", 26)
	_titulo.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	caja.add_child(_titulo)

	var linea := ColorRect.new()
	linea.color = Color(0, 0, 0, 0.35)
	linea.custom_minimum_size = Vector2(0, 2)
	caja.add_child(linea)

	# Foto de credencial (retrato simple con formas)
	_foto = Control.new()
	_foto.custom_minimum_size = Vector2(0, 110)
	var marco := ColorRect.new()
	marco.color = Color(0.55, 0.62, 0.7)
	marco.position = Vector2(0, 0)
	marco.size = Vector2(90, 110)
	_foto.add_child(marco)
	var cuerpo_f := ColorRect.new()
	cuerpo_f.color = Color(0.15, 0.2, 0.3)
	cuerpo_f.position = Vector2(10, 78)
	cuerpo_f.size = Vector2(70, 32)
	_foto.add_child(cuerpo_f)
	var cuello := ColorRect.new()
	cuello.color = Color(0.74, 0.55, 0.44)
	cuello.position = Vector2(38, 66)
	cuello.size = Vector2(14, 14)
	_foto.add_child(cuello)
	var cara := ColorRect.new()
	cara.color = Color(0.78, 0.6, 0.48)
	cara.position = Vector2(26, 28)
	cara.size = Vector2(38, 42)
	_foto.add_child(cara)
	var pelo := ColorRect.new()
	pelo.color = Color(0.12, 0.07, 0.05)
	pelo.position = Vector2(22, 20)
	pelo.size = Vector2(46, 18)
	_foto.add_child(pelo)
	caja.add_child(_foto)

	_cuerpo = RichTextLabel.new()
	_cuerpo.bbcode_enabled = true
	_cuerpo.fit_content = true
	_cuerpo.scroll_active = false
	_cuerpo.custom_minimum_size = Vector2(640, 0)
	_cuerpo.add_theme_font_size_override("normal_font_size", 19)
	_cuerpo.add_theme_font_size_override("bold_font_size", 19)
	caja.add_child(_cuerpo)

	_firma = Label.new()
	_firma.add_theme_font_size_override("font_size", 20)
	_firma.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
	caja.add_child(_firma)

	_pie = Label.new()
	_pie.text = "[E / Esc]  Cerrar"
	_pie.add_theme_font_size_override("font_size", 14)
	_pie.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	caja.add_child(_pie)
