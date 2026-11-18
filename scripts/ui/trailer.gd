extends Node3D

## Secuencia cinematográfica in-engine, construida con las salas reales del juego.
## Se puede saltar con Esc, Enter, Espacio o el botón de la esquina.

@onready var museo: Node3D = $Museum
@onready var camara: Camera3D = $TrailerCamera
@onready var fundido: ColorRect = $CinematicUI/Fade
@onready var titulo: Label = $CinematicUI/Title
@onready var subtitulo: Label = $CinematicUI/Subtitle
@onready var musica: AudioStreamPlayer = $TrailerMusic

var _mirar_a := Vector3.ZERO
var _terminando := false
var _inicio_ms := 0
var _puertas_trailer: Array[Node3D] = []


func _ready() -> void:
	Input.mouse_mode = Input.MOUSE_MODE_VISIBLE
	# Fija la cámara antes de esperar frames para que no se vea el encuadre por defecto del museo.
	camara.global_position = Vector3(12.2, 2.2, 23.0)
	_mirar_a = Vector3(10.8, 2.1, 25.0)
	camara.current = true
	$CinematicUI/ExitButton.pressed.connect(_volver_menu)
	for etiqueta in [titulo, subtitulo]:
		etiqueta.add_theme_color_override("font_shadow_color", Color(0.0, 0.0, 0.0, 0.98))
		etiqueta.add_theme_constant_override("shadow_offset_x", 2)
		etiqueta.add_theme_constant_override("shadow_offset_y", 3)
		etiqueta.add_theme_constant_override("shadow_outline_size", 4)
	# Deja que el museo termine de construir sus salas y luego congela la simulación.
	await get_tree().process_frame
	await get_tree().process_frame
	museo.process_mode = Node.PROCESS_MODE_DISABLED
	var cctv := museo.get_node_or_null("CCTV") as Node3D
	if cctv:
		# Las carcasas de las cámaras de vigilancia son las esferas que se cruzan en algunos encuadres.
		cctv.visible = false
	var camara_juego := museo.get_node_or_null("Camera3D") as Camera3D
	if camara_juego:
		camara_juego.current = false
	var jugador := museo.get_node_or_null("Guardia") as Node3D
	if jugador:
		jugador.visible = false
	var interactivos := museo.get_node_or_null("Interactivos") as Node3D
	if interactivos:
		interactivos.visible = false
	for nombre in ["HUD", "VisorDeNotas", "Candado", "GameOver"]:
		var capa := museo.get_node_or_null(nombre)
		if capa is CanvasLayer:
			capa.visible = false
		elif capa is CanvasItem:
			capa.visible = false
	# Mantiene el plano de apertura en la oficina durante el fundido de entrada.
	camara.global_position = Vector3(12.2, 2.2, 23.0)
	_mirar_a = Vector3(10.8, 2.1, 25.0)
	camara.near = 0.12
	camara.cull_mask = 1
	camara.current = true
	fundido.modulate.a = 1.0
	titulo.modulate.a = 0.0
	subtitulo.modulate.a = 0.0
	await get_tree().create_timer(0.8).timeout
	var entrada := create_tween()
	entrada.tween_property(fundido, "modulate:a", 0.0, 1.4)
	await entrada.finished
	if _terminando:
		return
	_inicio_ms = Time.get_ticks_msec()
	musica.play()
	_reproducir_secuencia()


func _process(_delta: float) -> void:
	if camara.current and camara.global_position.distance_to(_mirar_a) > 0.05:
		camara.look_at(_mirar_a, Vector3.UP)


func _unhandled_input(event: InputEvent) -> void:
	if event.is_action_pressed("ui_cancel") or event.is_action_pressed("ui_accept"):
		_volver_menu()
	elif event is InputEventKey and event.pressed and event.keycode == KEY_SPACE:
		_volver_menu()


func _reproducir_secuencia() -> void:
	if _terminando:
		return
	await _plano(Vector3(12.2, 2.2, 23.0), Vector3(10.8, 2.1, 25.0), "TURNO DE NOCHE", "Las cámaras vigilan el museo. ¿Qué ocurre cuando nadie mira?", 6.0)

	# Piso principal: planos amplios y lentos desde los puntos de cámara despejados.
	await _plano(Vector3(0.0, 2.35, 10.5), Vector3(0.0, 2.4, -14.2), "UNA NOCHE TRANQUILA", "El museo cierra. El turno de Alex apenas comienza.", 9.0)
	await _plano(Vector3(-3.0, 5.4, 13.2), Vector3(0.0, 2.0, -5.0), "UNA REGLA SENCILLA", "No apartes la mirada de las reliquias.", 9.0)
	await _plano(Vector3(5.5, 6.1, 8.0), Vector3(0.0, 1.8, -7.0), "PERO EL MUSEO ES ENORME", "Y la oscuridad siempre encuentra un punto ciego.", 9.0)
	await _plano(Vector3(-8.5, 5.8, -10.0), Vector3(2.0, 1.2, 2.0), "BUSCA LO QUE SE PERDIÓ", "Cuatro fragmentos mantienen unido un sello antiguo.", 9.0)
	await _plano(Vector3(3.8, 4.5, -9.0), Vector3(0.0, 2.1, -14.2), "ALGO DESPERTÓ", "La estatua de Anubis guarda la salida.", 9.0)
	await _cartela("ESCUCHA LA RADIO", "Una voz amiga puede ser lo único que te guíe.", 7.0)
	await _plano(Vector3(7.2, 4.1, 12.0), Vector3(-2.0, 1.2, 5.0), "USA LO QUE TENGAS", "Linterna, espejo y walkie-talkie: cada segundo cuenta.", 9.0)

	# Segundo piso solamente: galería y armería terminadas, sin mostrar niveles en obra.
	await _plano(Vector3(8.4, 13.6, 29.4), Vector3(0.0, 10.0, 12.0), "SUBE A LA GALERÍA", "El segundo piso conserva sus propios secretos.", 9.0)
	await _plano(Vector3(0.0, 12.0, -2.5), Vector3(0.0, 10.8, -11.0), "ACERO EN LA OSCURIDAD", "No todas las armaduras siguen siendo exhibiciones.", 9.0)
	await _plano(Vector3(-8.0, 14.2, 17.0), Vector3(2.5, 10.4, 25.0), "CADA PASILLO ES UNA DECISIÓN", "Avanza con cuidado. Algo puede estar esperándote.", 9.0)
	await _plano(Vector3(-6.0, 12.4, 16.0), Vector3(-2.5, 10.6, 22.0), "NO HAY UN CAMINO SEGURO", "La luz te protege… solo por un momento.", 9.0)

	# Los pisos 3 y 4 se anuncian con pantalla oscura; no se muestran sus espacios aún incompletos.
	# Dos planos distintos en el vestíbulo sustituyen cartelas repetidas y preparan la salida.
	await _plano(Vector3(-4.2, 2.2, 20.5), Vector3(0.0, 2.0, 29.7), "EL ÚLTIMO PASILLO", "La salida está más cerca de lo que parece.", 7.0)
	await _plano(Vector3(4.3, 2.0, 22.2), Vector3(0.0, 2.0, 30.0), "NO HAY VUELTA ATRÁS", "Algo espera al otro lado.", 7.0)
	await _cartela("CUATRO NIVELES. CUATRO FRAGMENTOS.", "Reúne el sello antes de que el museo te encuentre.", 7.0)
	await _toma_puerta_salida(true, 7.5)
	await _toma_puerta_salida(false, 7.5)

	# Mantén el montaje acompasado al instrumental, incluso si alguna transición termina antes.
	var transcurrido := float(Time.get_ticks_msec() - _inicio_ms) / 1000.0
	var restante := 139.2 - transcurrido
	if restante > 0.0:
		await get_tree().create_timer(restante).timeout
	if _terminando:
		return
	var salida := create_tween().set_parallel(true)
	salida.tween_property(fundido, "modulate:a", 1.0, 0.7)
	salida.tween_property(musica, "volume_db", -36.0, 0.7)
	await salida.finished
	get_tree().change_scene_to_file("res://scenes/main_menu.tscn")


func _cartela(linea: String, detalle: String, duracion: float) -> void:
	if _terminando:
		return
	titulo.text = linea
	subtitulo.text = detalle
	_mirar_a = camara.global_position + Vector3.FORWARD
	await _mostrar_texto(duracion)


func _plano(posicion: Vector3, objetivo: Vector3, linea: String, detalle: String, duracion: float) -> void:
	if _terminando:
		return
	if linea == "NO APARTES LA MIRADA":
		Sfx.tocar("static", -18.0)
	elif linea == "ALGO DESPERTÓ":
		Sfx.tocar("clank", -16.0)
	elif linea == "BAJO EL MUSEO":
		Sfx.tocar("latido", -18.0)
	titulo.text = linea
	subtitulo.text = detalle
	_mirar_a = objetivo
	# Cortes intencionales entre salas: evita atravesar muros/techos al cambiar de piso.
	camara.global_position = posicion
	var indice: int = int(get_meta("numero_plano", 0))
	set_meta("numero_plano", indice + 1)
	var deriva := Vector3(0.0, 0.0, 0.0)
	if indice % 3 == 0:
		deriva = Vector3(0.42, 0.12, 0.0)
	elif indice % 3 == 1:
		deriva = Vector3(-0.32, 0.0, 0.22)
	else:
		deriva = Vector3(0.0, 0.18, -0.34)
	var movimiento := maxf(2.0, duracion - 0.45)
	var tween := create_tween().set_parallel(true)
	tween.set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_IN_OUT)
	tween.tween_property(camara, "global_position", posicion + deriva, movimiento)
	tween.tween_property(self, "_mirar_a", objetivo, movimiento)
	tween.tween_property(titulo, "modulate:a", 1.0, 0.45)
	tween.tween_property(subtitulo, "modulate:a", 1.0, 0.45)
	await tween.finished
	if _terminando:
		return
	await get_tree().create_timer(0.1).timeout
	await _ocultar_texto()


func _mostrar_texto(duracion: float) -> void:
	# Incluso las cartelas tienen una deriva mínima de cámara para que el montaje no se congele.
	var destino_camara := camara.global_position + Vector3(0.10, 0.035, 0.0)
	var deriva_camara := create_tween()
	deriva_camara.set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)
	deriva_camara.tween_property(camara, "global_position", destino_camara, duracion)
	var t := create_tween().set_parallel(true)
	t.tween_property(titulo, "modulate:a", 1.0, 0.7)
	t.tween_property(subtitulo, "modulate:a", 1.0, 0.7)
	await t.finished
	await get_tree().create_timer(maxf(0.0, duracion - 1.05)).timeout
	await _ocultar_texto()


func _ocultar_texto() -> void:
	var t := create_tween().set_parallel(true)
	t.tween_property(titulo, "modulate:a", 0.0, 0.35)
	t.tween_property(subtitulo, "modulate:a", 0.0, 0.35)
	await t.finished


func _toma_puerta_salida(abrir: bool, duracion: float) -> void:
	if _terminando:
		return
	if _puertas_trailer.is_empty():
		_crear_puerta_trailer()
	titulo.text = "LA SALIDA ESTÁ AHÍ" if abrir else "¿TE ATREVERÁS?"
	subtitulo.text = "¿Qué hay al otro lado?" if abrir else "Entra al museo y descúbrelo."
	_mirar_a = Vector3(0.0, 2.0, 30.1)
	var tween := create_tween().set_parallel(true)
	tween.set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_IN_OUT)
	tween.tween_property(titulo, "modulate:a", 1.0, 0.45)
	tween.tween_property(subtitulo, "modulate:a", 1.0, 0.45)
	if abrir:
		# Aproximación longitudinal dentro del vestíbulo, sin subir/bajar atravesando pisos.
		tween.tween_property(camara, "global_position", Vector3(0.0, 2.1, 24.8), duracion - 0.45)
		for i in _puertas_trailer.size():
			var lado := -1.0 if i == 0 else 1.0
			tween.tween_property(_puertas_trailer[i], "rotation:y", deg_to_rad(78.0 * -lado), 1.25)
	else:
		tween.tween_property(camara, "global_position", Vector3(0.0, 2.1, 24.2), duracion - 0.45)
		for hoja in _puertas_trailer:
			tween.tween_property(hoja, "rotation:y", 0.0, 0.8)
	await tween.finished
	if _terminando:
		return
	await get_tree().create_timer(0.1).timeout
	await _ocultar_texto()


func _crear_puerta_trailer() -> void:
	var lobby := museo.get_node_or_null("Mundo/Vestibulo")
	var original := lobby.get_node_or_null("PuertasPrincipales") if lobby else null
	if original:
		original.visible = false
	var objetivo_puerta := lobby.get_node_or_null("PuertasPrincipales_Objetivo") if lobby else null
	if objetivo_puerta:
		objetivo_puerta.visible = false
	# El zócalo de madera y su filete dorado cruzan el hueco por delante del fondo.
	# Se oculta solo su tramo central, conservando los laterales del vestíbulo.
	if lobby:
		for nodo in lobby.find_children("*", "MeshInstance3D", true, false):
			var malla_lobby := nodo as MeshInstance3D
			var p := malla_lobby.position
			if p.y < 0.35 and p.z > 30.1 and p.z < 30.25 and absf(p.x) < 3.0:
				malla_lobby.visible = false
	var fondo := MeshInstance3D.new()
	fondo.name = "FondoOscuroSalidaTrailer"
	var fondo_malla := BoxMesh.new()
	fondo_malla.size = Vector3(5.28, 4.12, 0.025)
	fondo.mesh = fondo_malla
	# Este plano queda delante del muro real, para que al abrir las hojas no se vea una pared.
	fondo.position = Vector3(0.0, 2.05, 30.05)
	var fondo_mat := StandardMaterial3D.new()
	fondo_mat.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	fondo_mat.albedo_color = Color(0.055, 0.075, 0.11)
	fondo_mat.emission_enabled = true
	fondo_mat.emission = Color(0.14, 0.2, 0.29)
	fondo_mat.emission_energy_multiplier = 0.7
	fondo.material_override = fondo_mat
	museo.add_child(fondo)
	# Marco dorado que remata los bordes del fondo y hace legible la salida.
	var marco_mat := StandardMaterial3D.new()
	marco_mat.albedo_color = Color(0.48, 0.29, 0.08)
	marco_mat.metallic = 0.62
	marco_mat.roughness = 0.38
	for x in [-2.78, 2.78]:
		_crear_pieza_puerta(Vector3(x, 2.08, 29.90), Vector3(0.2, 4.42, 0.2), marco_mat)
	_crear_pieza_puerta(Vector3(0.0, 4.28, 29.90), Vector3(5.76, 0.2, 0.2), marco_mat)
	# Moldura interior cubre el filo azulado visible entre el fondo y las jambas exteriores.
	var moldura_mat := StandardMaterial3D.new()
	moldura_mat.albedo_color = Color(0.25, 0.12, 0.045)
	moldura_mat.metallic = 0.35
	moldura_mat.roughness = 0.55
	for x in [-2.53, 2.53]:
		_crear_pieza_puerta(Vector3(x, 2.04, 29.86), Vector3(0.16, 4.05, 0.12), moldura_mat)
	_crear_pieza_puerta(Vector3(0.0, 4.02, 29.86), Vector3(5.18, 0.16, 0.12), moldura_mat)
	var letrero := Label3D.new()
	letrero.name = "LetreroSalidaTrailer"
	letrero.text = "SALIDA"
	letrero.font_size = 64
	letrero.pixel_size = 0.008
	letrero.position = Vector3(0.0, 4.65, 29.85)
	letrero.rotation_degrees.y = 180.0
	letrero.modulate = Color(1.0, 0.76, 0.3)
	letrero.outline_size = 8
	letrero.outline_modulate = Color(0.035, 0.02, 0.005)
	museo.add_child(letrero)
	for lado in [-1.0, 1.0]:
		var pivote := Node3D.new()
		pivote.name = "PuertaTrailer"
		pivote.position = Vector3(lado * 2.3, 0.0, 29.92)
		museo.add_child(pivote)
		var panel := MeshInstance3D.new()
		var malla := BoxMesh.new()
		malla.size = Vector3(2.48, 3.98, 0.14)
		panel.mesh = malla
		panel.position = Vector3(-lado * 1.14, 1.95, 0.0)
		var material := StandardMaterial3D.new()
		material.albedo_color = Color(0.30, 0.20, 0.12)
		material.metallic = 0.35
		material.roughness = 0.58
		panel.material_override = material
		pivote.add_child(panel)
		var panel_azul := MeshInstance3D.new()
		var azul_malla := BoxMesh.new()
		azul_malla.size = Vector3(1.64, 1.42, 0.025)
		panel_azul.mesh = azul_malla
		panel_azul.position = Vector3(-lado * 1.14, 2.6, -0.085)
		var azul := StandardMaterial3D.new()
		azul.albedo_color = Color(0.035, 0.07, 0.14)
		azul.emission_enabled = true
		azul.emission = Color(0.035, 0.07, 0.14)
		azul.emission_energy_multiplier = 0.45
		panel_azul.material_override = azul
		pivote.add_child(panel_azul)
		for y in [0.9, 1.5, 3.3]:
			var filete := MeshInstance3D.new()
			var filete_malla := BoxMesh.new()
			filete_malla.size = Vector3(2.1, 0.07, 0.035)
			filete.mesh = filete_malla
			filete.position = Vector3(-lado * 1.14, y, -0.09)
			filete.material_override = marco_mat
			pivote.add_child(filete)
		var traba := MeshInstance3D.new()
		var traba_malla := BoxMesh.new()
		traba_malla.size = Vector3(2.35, 0.12, 0.045)
		traba.mesh = traba_malla
		traba.position = Vector3(-lado * 1.14, 2.0, -0.12)
		traba.material_override = moldura_mat
		pivote.add_child(traba)
		_puertas_trailer.append(pivote)


func _crear_pieza_puerta(posicion: Vector3, tamano: Vector3, material: Material) -> void:
	var pieza := MeshInstance3D.new()
	var malla := BoxMesh.new()
	malla.size = tamano
	pieza.mesh = malla
	pieza.position = posicion
	pieza.material_override = material
	museo.add_child(pieza)


func _volver_menu() -> void:
	if _terminando:
		return
	_terminando = true
	musica.stop()
	var salida := create_tween()
	salida.tween_property(fundido, "modulate:a", 1.0, 0.6)
	await salida.finished
	get_tree().change_scene_to_file("res://scenes/main_menu.tscn")
