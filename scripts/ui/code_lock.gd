extends CanvasLayer

## Candado de combinacion numerica. Se escribe con el teclado (0-9, Borrar, Enter)
## o con los botones. Al acertar llama a la funcion "al_resolver" que le pasaron.

signal intento(correcto: bool)

var abierto := false

var _correcto := ""
var _longitud := 4
var _escrito := ""
var _al_resolver: Callable
var _titulo: Label
var _pista: Label
var _digitos: Array[Label] = []
var _estado: Label
var _panel: PanelContainer


func _ready() -> void:
	layer = 21
	process_mode = Node.PROCESS_MODE_ALWAYS
	visible = false
	_construir()


func abrir(datos: Dictionary) -> void:
	_correcto = String(datos.get("correcto", "0000"))
	_longitud = _correcto.length()
	_escrito = ""
	_al_resolver = datos.get("al_resolver", Callable()) as Callable
	_titulo.text = String(datos.get("titulo", "CANDADO"))
	_pista.text = String(datos.get("pista", ""))
	_estado.text = "Escribe la combinación y presiona Enter"
	_estado.add_theme_color_override("font_color", Color(0.85, 0.83, 0.78))
	_refrescar()
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


func _unhandled_input(event: InputEvent) -> void:
	if not abierto or not (event is InputEventKey):
		return
	var k := event as InputEventKey
	if not k.pressed or k.echo:
		return
	get_viewport().set_input_as_handled()
	if k.keycode == KEY_ESCAPE:
		cerrar()
	elif k.keycode == KEY_BACKSPACE:
		_borrar()
	elif k.keycode == KEY_ENTER or k.keycode == KEY_KP_ENTER:
		_confirmar()
	else:
		# Solo digitos (fila superior y teclado numerico); el resto de teclas se ignora
		var d := -1
		if k.keycode >= KEY_0 and k.keycode <= KEY_9:
			d = k.keycode - KEY_0
		elif k.keycode >= KEY_KP_0 and k.keycode <= KEY_KP_9:
			d = k.keycode - KEY_KP_0
		if d >= 0:
			_escribir(str(d))


func _escribir(c: String) -> void:
	if _escrito.length() >= _longitud:
		return
	_escrito += c
	_sonar("tecla")
	_refrescar()


func _borrar() -> void:
	if _escrito.length() > 0:
		_escrito = _escrito.substr(0, _escrito.length() - 1)
		_refrescar()


func _confirmar() -> void:
	if _escrito.length() < _longitud:
		return
	if _escrito == _correcto:
		_estado.text = "¡Click! El candado se abre."
		_estado.add_theme_color_override("font_color", Color(0.5, 1.0, 0.55))
		_sonar("beep_ok")
		intento.emit(true)
		var cb := _al_resolver
		cerrar()
		if cb.is_valid():
			cb.call()
	else:
		_estado.text = "Combinación incorrecta."
		_estado.add_theme_color_override("font_color", Color(1.0, 0.4, 0.35))
		_sonar("beep_no")
		_escrito = ""
		_refrescar()
		intento.emit(false)


func _sonar(nombre: String) -> void:
	Sfx.tocar(nombre)


func _refrescar() -> void:
	for i in _digitos.size():
		var d := _digitos[i]
		d.visible = i < _longitud
		d.text = _escrito[i] if i < _escrito.length() else "_"


func _construir() -> void:
	var fondo := ColorRect.new()
	fondo.color = Color(0, 0, 0, 0.7)
	fondo.set_anchors_preset(Control.PRESET_FULL_RECT)
	add_child(fondo)
	var centro := CenterContainer.new()
	centro.set_anchors_preset(Control.PRESET_FULL_RECT)
	add_child(centro)
	_panel = PanelContainer.new()
	var st := StyleBoxFlat.new()
	st.bg_color = Color(0.09, 0.08, 0.07)
	st.border_color = Color(0.66, 0.51, 0.24)
	st.set_border_width_all(3)
	st.set_corner_radius_all(8)
	st.set_content_margin_all(26)
	_panel.add_theme_stylebox_override("panel", st)
	centro.add_child(_panel)
	var caja := VBoxContainer.new()
	caja.add_theme_constant_override("separation", 14)
	_panel.add_child(caja)

	_titulo = Label.new()
	_titulo.add_theme_font_size_override("font_size", 24)
	_titulo.add_theme_color_override("font_color", Color(0.92, 0.85, 0.66))
	_titulo.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	caja.add_child(_titulo)

	_pista = Label.new()
	_pista.add_theme_font_size_override("font_size", 15)
	_pista.add_theme_color_override("font_color", Color(0.7, 0.68, 0.62))
	_pista.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_pista.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	_pista.custom_minimum_size = Vector2(380, 0)
	caja.add_child(_pista)

	var fila := HBoxContainer.new()
	fila.alignment = BoxContainer.ALIGNMENT_CENTER
	fila.add_theme_constant_override("separation", 12)
	for i in 6:
		var d := Label.new()
		d.custom_minimum_size = Vector2(54, 70)
		d.add_theme_font_size_override("font_size", 44)
		d.add_theme_color_override("font_color", Color(1.0, 0.82, 0.22))
		d.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		d.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
		fila.add_child(d)
		_digitos.append(d)
	caja.add_child(fila)

	_estado = Label.new()
	_estado.add_theme_font_size_override("font_size", 16)
	_estado.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	caja.add_child(_estado)

	var grid := GridContainer.new()
	grid.columns = 5
	grid.add_theme_constant_override("h_separation", 8)
	grid.add_theme_constant_override("v_separation", 8)
	for n in [1, 2, 3, 4, 5, 6, 7, 8, 9, 0]:
		var b := Button.new()
		b.text = str(n)
		b.custom_minimum_size = Vector2(62, 46)
		b.focus_mode = Control.FOCUS_NONE
		b.pressed.connect(_escribir.bind(str(n)))
		grid.add_child(b)
	caja.add_child(grid)

	var fila2 := HBoxContainer.new()
	fila2.alignment = BoxContainer.ALIGNMENT_CENTER
	fila2.add_theme_constant_override("separation", 10)
	var bb := Button.new()
	bb.text = "Borrar"
	bb.focus_mode = Control.FOCUS_NONE
	bb.pressed.connect(_borrar)
	fila2.add_child(bb)
	var bo := Button.new()
	bo.text = "Abrir"
	bo.focus_mode = Control.FOCUS_NONE
	bo.pressed.connect(_confirmar)
	fila2.add_child(bo)
	var bc := Button.new()
	bc.text = "Cancelar"
	bc.focus_mode = Control.FOCUS_NONE
	bc.pressed.connect(cerrar)
	fila2.add_child(bc)
	caja.add_child(fila2)
