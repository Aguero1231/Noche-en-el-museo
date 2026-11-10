extends CanvasLayer

## HUD del juego: texto de interaccion ("[E] Recoger linterna"), mensajes cortos,
## objetivo actual y barras de bateria (BAT) y energia para correr (STA).
## Lo maneja museum.gd; aqui solo se dibuja.

var _prompt: Label
var _mensaje: Label
var _objetivo: Label
var _objetivo_titulo: Label
var _progreso: Label
var _barra_bateria: ProgressBar
var _barra_energia: ProgressBar
var _valor_bateria: Label
var _valor_energia: Label
var _relleno_bateria: StyleBoxFlat
var _relleno_energia: StyleBoxFlat
var _bateria_baja := false
var _energia_baja := false
var _tween: Tween
var _radio: Label
var _radio_titulo: Label
var _radio_contenedor: Control
var _tween_radio: Tween
var _ayuda: Label
var _reloj: Label
var _peligro: ColorRect
var _espejo: Control
var _espejo_vista: TextureRect


func _ready() -> void:
	layer = 5
	_construir()
	var ayuda_tween := create_tween()
	ayuda_tween.tween_interval(14.0)
	ayuda_tween.tween_property(_ayuda, "modulate:a", 0.0, 0.7)


# ---------------------------------------------------------------- API

## Texto que aparece junto al objeto con el que se puede interactuar ("" lo oculta).
func set_prompt(texto: String) -> void:
	_prompt.text = texto
	_prompt.visible = texto != ""


## Mensaje temporal abajo al centro (se desvanece solo).
func show_message(texto: String) -> void:
	_mensaje.text = texto
	_mensaje.modulate.a = 1.0
	if _tween and _tween.is_valid():
		_tween.kill()
	_tween = create_tween()
	_tween.tween_interval(2.8)
	_tween.tween_property(_mensaje, "modulate:a", 0.0, 0.8)


func set_objetivo_texto(texto: String) -> void:
	var lineas := texto.split("\n", false)
	var tarea := lineas[0].trim_prefix("OBJETIVO:").strip_edges() if not lineas.is_empty() else texto
	_objetivo.text = tarea
	if lineas.size() > 1:
		var estado := lineas[1]
		estado = estado.replace("[x] Linterna", "LINTERNA ✓").replace("[ ] Linterna", "LINTERNA ·")
		estado = estado.replace("[x] Espejo", "ESPEJO ✓").replace("[ ] Espejo", "ESPEJO ·")
		estado = estado.replace("[x] Walkie", "RADIO ✓").replace("[ ] Walkie", "RADIO ·")
		estado = estado.replace("Fragmentos:", "FRAG.").strip_edges()
		_progreso.text = estado
		_progreso.visible = true
	else:
		_progreso.visible = false


## Subtitulo de lo que dice Roberto por radio (se desvanece solo).
func show_radio(texto: String, duracion: float = 5.5) -> void:
	var separador := texto.find(":")
	if separador >= 0:
		var voz := texto.substr(0, separador).strip_edges().to_upper()
		_radio_titulo.text = "ROBERTO · RADIO" if voz.contains("ROBERTO") else voz
		_radio.text = texto.substr(separador + 1).strip_edges().trim_prefix("«").trim_suffix("»").strip_edges()
	else:
		_radio_titulo.text = "RADIO"
		_radio.text = texto
	_radio_contenedor.visible = true
	_radio_contenedor.modulate.a = 1.0
	if _tween_radio and _tween_radio.is_valid():
		_tween_radio.kill()
	_tween_radio = create_tween()
	_tween_radio.tween_interval(maxf(duracion, 4.0))
	_tween_radio.tween_property(_radio_contenedor, "modulate:a", 0.0, 0.8)
	_tween_radio.tween_callback(func(): _radio_contenedor.hide())


func set_reloj(texto: String) -> void:
	_reloj.text = texto


## 0.0 - 1.0: borde rojo que late cuando una estatua se acerca.
func set_peligro(v: float) -> void:
	_peligro.color.a = clampf(v, 0.0, 1.0) * 0.55
	_peligro.visible = v > 0.02


## Espejo de inspeccion: muestra la vista de atras (volteada como un espejo de verdad).
func set_espejo(visible_: bool, textura: Texture2D = null) -> void:
	_espejo.visible = visible_
	if visible_ and textura:
		_espejo_vista.texture = textura


func set_bateria(valor: float) -> void:
	var carga := clampf(valor, 0.0, 100.0)
	_barra_bateria.value = carga
	var texto := "%02d%%" % roundi(carga)
	if _valor_bateria.text != texto:
		_valor_bateria.text = texto
	var baja := carga <= 20.0
	if baja != _bateria_baja:
		_bateria_baja = baja
		_relleno_bateria.bg_color = Color(0.92, 0.24, 0.18) if baja else Color(0.92, 0.68, 0.24)
		_valor_bateria.add_theme_color_override("font_color", Color(1.0, 0.43, 0.34) if baja else Color(1.0, 0.89, 0.64))


func set_energia(valor: float) -> void:
	var energia := clampf(valor, 0.0, 100.0)
	_barra_energia.value = energia
	var texto := "%02d%%" % roundi(energia)
	if _valor_energia.text != texto:
		_valor_energia.text = texto
	var baja := energia <= 22.0
	if baja != _energia_baja:
		_energia_baja = baja
		_relleno_energia.bg_color = Color(0.95, 0.48, 0.22) if baja else Color(0.28, 0.78, 0.69)
		_valor_energia.add_theme_color_override("font_color", Color(1.0, 0.57, 0.32) if baja else Color(0.66, 0.96, 0.88))


# ---------------------------------------------------------------- construccion

func _label(texto: String, padre: Control, tam: int) -> Label:
	var l := Label.new()
	l.text = texto
	l.add_theme_font_size_override("font_size", tam)
	l.add_theme_color_override("font_outline_color", Color.BLACK)
	l.add_theme_constant_override("outline_size", 6)
	l.mouse_filter = Control.MOUSE_FILTER_IGNORE
	padre.add_child(l)
	return l


func _barra(pos: Vector2, tam: Vector2, color: Color, padre: Control) -> ProgressBar:
	var b := ProgressBar.new()
	b.show_percentage = false
	b.max_value = 100.0
	b.value = 100.0
	b.position = pos
	b.custom_minimum_size = tam
	b.size = tam
	b.mouse_filter = Control.MOUSE_FILTER_IGNORE
	var fondo := StyleBoxFlat.new()
	fondo.bg_color = Color(0.015, 0.025, 0.03, 0.88)
	fondo.set_corner_radius_all(4)
	var relleno := StyleBoxFlat.new()
	relleno.bg_color = color
	relleno.set_corner_radius_all(4)
	b.add_theme_stylebox_override("background", fondo)
	b.add_theme_stylebox_override("fill", relleno)
	padre.add_child(b)
	return b


func _estilo_tarjeta(acento: Color) -> StyleBoxFlat:
	var estilo := StyleBoxFlat.new()
	estilo.bg_color = Color(0.015, 0.025, 0.035, 0.78)
	estilo.border_color = acento.darkened(0.25)
	estilo.set_border_width_all(1)
	estilo.border_width_left = 3
	estilo.set_corner_radius_all(5)
	estilo.set_content_margin_all(9)
	return estilo


func _crear_fila_recurso(nombre: String, color: Color, padre: Control) -> Dictionary:
	var fila := VBoxContainer.new()
	fila.add_theme_constant_override("separation", 2)
	padre.add_child(fila)
	var encabezado := HBoxContainer.new()
	encabezado.add_theme_constant_override("separation", 6)
	fila.add_child(encabezado)
	var titulo := _label(nombre, encabezado, 11)
	titulo.add_theme_color_override("font_color", color.lightened(0.12))
	var espacio := Control.new()
	espacio.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	encabezado.add_child(espacio)
	var valor := _label("100%", encabezado, 11)
	valor.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
	valor.add_theme_color_override("font_color", Color(0.94, 0.93, 0.86))
	var barra := _barra(Vector2.ZERO, Vector2(0, 7), color, fila)
	barra.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	return {"barra": barra, "valor": valor, "relleno": barra.get_theme_stylebox("fill") as StyleBoxFlat}


func _construir() -> void:
	var raiz := Control.new()
	raiz.set_anchors_preset(Control.PRESET_FULL_RECT)
	raiz.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(raiz)

	# Vineta suave en los bordes
	var vig := ColorRect.new()
	vig.set_anchors_preset(Control.PRESET_FULL_RECT)
	vig.mouse_filter = Control.MOUSE_FILTER_IGNORE
	var sv := Shader.new()
	sv.code = "shader_type canvas_item;\nvoid fragment(){ vec2 uv = UV - 0.5; float v = smoothstep(0.35, 0.85, length(uv * vec2(1.1, 1.0))); COLOR = vec4(0.0, 0.0, 0.0, v * 0.45); }"
	var mv := ShaderMaterial.new()
	mv.shader = sv
	vig.material = mv
	raiz.add_child(vig)

	# Borde rojo de peligro
	_peligro = ColorRect.new()
	_peligro.set_anchors_preset(Control.PRESET_FULL_RECT)
	_peligro.mouse_filter = Control.MOUSE_FILTER_IGNORE
	var sp := Shader.new()
	sp.code = "shader_type canvas_item;\nvoid fragment(){ vec2 uv = UV - 0.5; float v = smoothstep(0.25, 0.8, length(uv)); COLOR = vec4(0.8, 0.0, 0.0, v * COLOR.a * 2.0); }"
	var mp := ShaderMaterial.new()
	mp.shader = sp
	_peligro.material = mp
	_peligro.color = Color(1, 0, 0, 0)
	_peligro.visible = false
	raiz.add_child(_peligro)

	# Marco auxiliar para tercera persona; en primera persona el espejo se sostiene en la mano.
	_espejo = Control.new()
	_espejo.set_anchors_preset(Control.PRESET_CENTER_TOP)
	_espejo.offset_left = -120
	_espejo.offset_right = 120
	_espejo.offset_top = 12
	_espejo.offset_bottom = 286
	_espejo.mouse_filter = Control.MOUSE_FILTER_IGNORE
	var marco := Panel.new()
	marco.set_anchors_preset(Control.PRESET_FULL_RECT)
	marco.mouse_filter = Control.MOUSE_FILTER_IGNORE
	var estilo_marco := StyleBoxFlat.new()
	estilo_marco.bg_color = Color(0.035, 0.027, 0.02, 0.97)
	estilo_marco.border_color = Color(0.72, 0.51, 0.22, 0.98)
	estilo_marco.set_border_width_all(3)
	estilo_marco.set_corner_radius_all(9)
	estilo_marco.shadow_color = Color(0.0, 0.0, 0.0, 0.52)
	estilo_marco.shadow_size = 12
	marco.add_theme_stylebox_override("panel", estilo_marco)
	_espejo.add_child(marco)
	var filete := Panel.new()
	filete.position = Vector2(7, 7)
	filete.size = Vector2(226, 260)
	filete.mouse_filter = Control.MOUSE_FILTER_IGNORE
	var estilo_filete := StyleBoxFlat.new()
	estilo_filete.bg_color = Color(0.29, 0.19, 0.075, 1.0)
	estilo_filete.border_color = Color(0.89, 0.70, 0.34, 0.95)
	estilo_filete.set_border_width_all(1)
	estilo_filete.set_corner_radius_all(6)
	filete.add_theme_stylebox_override("panel", estilo_filete)
	_espejo.add_child(filete)
	var fondo_cristal := ColorRect.new()
	fondo_cristal.position = Vector2(34, 23)
	fondo_cristal.size = Vector2(172, 222)
	fondo_cristal.color = Color(0.018, 0.027, 0.034, 1.0)
	fondo_cristal.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_espejo.add_child(fondo_cristal)
	_espejo_vista = TextureRect.new()
	_espejo_vista.flip_h = false
	_espejo_vista.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	_espejo_vista.stretch_mode = TextureRect.STRETCH_SCALE
	_espejo_vista.position = Vector2(38, 25)
	_espejo_vista.size = Vector2(164, 218)
	_espejo_vista.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_espejo.add_child(_espejo_vista)
	# Remate geométrico y filetes de latón; el espejo queda sin rótulos.
	var gema := ColorRect.new()
	gema.position = Vector2(113, 7)
	gema.size = Vector2(14, 14)
	gema.pivot_offset = Vector2(7, 7)
	gema.rotation = deg_to_rad(45.0)
	gema.color = Color(0.92, 0.72, 0.34, 1.0)
	gema.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_espejo.add_child(gema)
	var centro_gema := ColorRect.new()
	centro_gema.position = Vector2(117, 11)
	centro_gema.size = Vector2(6, 6)
	centro_gema.color = Color(0.14, 0.09, 0.035, 1.0)
	centro_gema.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_espejo.add_child(centro_gema)
	for marca in [Vector2(84, 254), Vector2(111, 254), Vector2(138, 254)]:
		var linea := ColorRect.new()
		linea.position = marca
		linea.size = Vector2(18, 2)
		linea.color = Color(0.84, 0.63, 0.29, 0.9)
		linea.mouse_filter = Control.MOUSE_FILTER_IGNORE
		_espejo.add_child(linea)
	_espejo.visible = false
	raiz.add_child(_espejo)

	# Texto de interaccion, debajo del centro de la pantalla
	_prompt = _label("", raiz, 20)
	_prompt.set_anchors_preset(Control.PRESET_CENTER)
	_prompt.offset_left = -240
	_prompt.offset_right = 240
	_prompt.offset_top = 168
	_prompt.offset_bottom = 198
	_prompt.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_prompt.add_theme_color_override("font_color", Color(0.55, 1.0, 0.6))
	_prompt.hide()

	# Mensajes
	_mensaje = _label("", raiz, 18)
	_mensaje.set_anchors_preset(Control.PRESET_CENTER_TOP)
	_mensaje.offset_left = -440
	_mensaje.offset_right = 440
	_mensaje.offset_top = 18
	_mensaje.offset_bottom = 70
	_mensaje.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_mensaje.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	_mensaje.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	_mensaje.modulate.a = 0.0

	# Medidores refinados: cada recurso tiene nombre, porcentaje y una barra delgada.
	var panel_recursos := PanelContainer.new()
	panel_recursos.set_anchors_preset(Control.PRESET_TOP_LEFT)
	panel_recursos.offset_left = 18
	panel_recursos.offset_top = 16
	panel_recursos.offset_right = 222
	panel_recursos.offset_bottom = 106
	panel_recursos.add_theme_stylebox_override("panel", _estilo_tarjeta(Color(0.82, 0.67, 0.34)))
	panel_recursos.mouse_filter = Control.MOUSE_FILTER_IGNORE
	var filas_recursos := VBoxContainer.new()
	filas_recursos.add_theme_constant_override("separation", 6)
	panel_recursos.add_child(filas_recursos)
	var bateria := _crear_fila_recurso("LINTERNA", Color(0.92, 0.68, 0.24), filas_recursos)
	_barra_bateria = bateria["barra"] as ProgressBar
	_valor_bateria = bateria["valor"] as Label
	_relleno_bateria = bateria["relleno"] as StyleBoxFlat
	var energia := _crear_fila_recurso("ESTAMINA", Color(0.28, 0.78, 0.69), filas_recursos)
	_barra_energia = energia["barra"] as ProgressBar
	_valor_energia = energia["valor"] as Label
	_relleno_energia = energia["relleno"] as StyleBoxFlat
	raiz.add_child(panel_recursos)

	# Objetivo compacto con progreso secundario.
	var tarjeta_objetivo := PanelContainer.new()
	tarjeta_objetivo.set_anchors_preset(Control.PRESET_BOTTOM_LEFT)
	tarjeta_objetivo.offset_left = 18
	tarjeta_objetivo.offset_right = 418
	tarjeta_objetivo.offset_top = -122
	tarjeta_objetivo.offset_bottom = -18
	tarjeta_objetivo.add_theme_stylebox_override("panel", _estilo_tarjeta(Color(0.85, 0.67, 0.27)))
	tarjeta_objetivo.mouse_filter = Control.MOUSE_FILTER_IGNORE
	var contenido_objetivo := VBoxContainer.new()
	contenido_objetivo.add_theme_constant_override("separation", 3)
	tarjeta_objetivo.add_child(contenido_objetivo)
	_objetivo_titulo = _label("OBJETIVO ACTUAL", contenido_objetivo, 11)
	_objetivo_titulo.add_theme_color_override("font_color", Color(1.0, 0.78, 0.34))
	_objetivo = _label("", contenido_objetivo, 14)
	_objetivo.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	_objetivo.custom_minimum_size = Vector2(360, 34)
	_progreso = _label("", contenido_objetivo, 11)
	_progreso.add_theme_color_override("font_color", Color(0.7, 0.81, 0.79))
	raiz.add_child(tarjeta_objetivo)

	# Subtítulo de radio: voz y texto sin panel que tape la escena.
	_radio_contenedor = Control.new()
	_radio_contenedor.set_anchors_preset(Control.PRESET_CENTER_BOTTOM)
	_radio_contenedor.offset_left = -460
	_radio_contenedor.offset_right = 460
	_radio_contenedor.offset_top = -210
	_radio_contenedor.offset_bottom = -126
	_radio_contenedor.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_radio_titulo = _label("ROBERTO · RADIO", _radio_contenedor, 12)
	_radio_titulo.position = Vector2(0, 0)
	_radio_titulo.size = Vector2(920, 18)
	_radio_titulo.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_radio_titulo.add_theme_color_override("font_color", Color(1.0, 0.72, 0.34))
	_radio = _label("", _radio_contenedor, 17)
	_radio.position = Vector2(0, 18)
	_radio.size = Vector2(920, 60)
	_radio.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_radio.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	_radio.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	_radio.add_theme_color_override("font_color", Color(1.0, 0.94, 0.78))
	_radio_contenedor.modulate.a = 0.0
	_radio_contenedor.hide()
	raiz.add_child(_radio_contenedor)

	# Reloj de la noche (arriba a la derecha)
	_reloj = _label("00:00", raiz, 26)
	_reloj.set_anchors_preset(Control.PRESET_TOP_RIGHT)
	_reloj.offset_left = -220
	_reloj.offset_right = -24
	_reloj.offset_top = 18
	_reloj.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
	_reloj.add_theme_color_override("font_color", Color(1.0, 0.35, 0.3))
	var fecha := _label("VIE 13 OCT 2026", raiz, 13)
	fecha.set_anchors_preset(Control.PRESET_TOP_RIGHT)
	fecha.offset_left = -220
	fecha.offset_right = -24
	fecha.offset_top = 50
	fecha.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
	fecha.modulate.a = 0.75

	# Los controles se muestran al entrar y se desvanecen para despejar la vista.
	_ayuda = _label("WASD MOVER · SHIFT CORRER · C VISTA · V ESPEJO · E USAR · F LINTERNA · R SEÑUELO", raiz, 12)
	_ayuda.set_anchors_preset(Control.PRESET_BOTTOM_RIGHT)
	_ayuda.offset_left = -610
	_ayuda.offset_right = -18
	_ayuda.offset_top = -38
	_ayuda.offset_bottom = -16
	_ayuda.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
	_ayuda.modulate.a = 0.58
