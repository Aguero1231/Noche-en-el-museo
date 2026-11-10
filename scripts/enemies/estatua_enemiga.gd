extends CharacterBody3D

## ESTATUA / BUSTO / ARMADURA / MOMIA: "Lo que no miras, se mueve."
##
## Solo se mueve hacia el jugador cuando NADIE la observa. Se queda congelada si:
##   - "vista":    esta delante del guardia, dentro del encuadre de la camara y sin pared de por medio
##                 (las que estan detras de el se mueven aunque las veas en pantalla)
##   - "linterna": la alumbra el haz de la linterna encendida
##   - "espejo":   aparece en la vista posterior del espejo de inspección cuando se levanta con V
##   - "reflector": un reflector de exhibicion la ilumina y la FIJA para siempre (fijar())
## Si llega a menos de "distancia_captura" del jugador, lo atrapa (fin del juego).
## Se desplaza por el cuarto con A* sobre una cuadricula que se calcula de la geometria real,
## asi rodea muebles, columnas y paredes (tambien en los pasillos estrechos del Nivel 2).
##
## Solo persigue mientras el jugador este dentro de su "region" y en su mismo piso. Empieza
## dormida: museum.gd la despierta ("activa = true") cuando se activa la zona de ese cuarto.

signal atrapo_al_jugador(enemigo: Node3D)
signal se_acerca(enemigo: Node3D)
signal congelada(enemigo: Node3D, motivo: String)
signal sonido_paso(enemigo: Node3D)
signal fijada_para_siempre(enemigo: Node3D)

const CELDA := 0.8

@export var tipo := "BUSTO"
@export var velocidad := 0.8
@export var activa := false
## Zona (x, z, ancho, largo) donde se mueve y persigue.
@export var region := Rect2(-8.0, 17.0, 16.0, 13.0)
@export var distancia_captura := 1.05
@export var distancia_aviso := 4.5
## Las armaduras hacen ruido al caminar (se oyen a distancia).
@export var ruidosa := false
@export var bloquea := true

## Multiplicador de velocidad (sube cuando el jugador toma un fragmento del amuleto).
var multiplicador := 1.0
var fijada := false
var protegida_por_luz := false
var observada := false
var motivo := ""
var en_movimiento := false
var rid_bloqueo := RID()

static var _navs: Dictionary = {}

var _jugador: CharacterBody3D
var _t_aviso := 0.0
var _t := 0.0
var _t_paso := 0.0
var _t_ruta := 0.0
var _t_observacion := 0.0
var _motivo_observacion := ""
var _t_camino_directo := 0.0
var _camino_directo_despejado := false
var _ruta: Array[Vector3] = []
var _senuelo_pos := Vector3.ZERO
var _senuelo_t := 0.0
var _visual: Node3D
var _cabeza: Node3D
var _ojos: Array = []
var _nav: Dictionary = {}
var _nav_en_progreso := false


func _ready() -> void:
	add_to_group("enemigos")
	collision_layer = 2     # no estorba al jugador ni a la camara
	collision_mask = 1      # pero respeta paredes y muebles
	motion_mode = CharacterBody3D.MOTION_MODE_FLOATING
	if get_node_or_null("CollisionShape3D") == null:
		var cs := CollisionShape3D.new()
		var cap := CapsuleShape3D.new()
		cap.radius = 0.45
		cap.height = 1.9
		cs.shape = cap
		cs.position = Vector3(0, 0.95, 0)
		add_child(cs)
	if bloquea:
		# Cuerpo solido para el jugador (no se puede atravesar una estatua).
		var b := StaticBody3D.new()
		b.name = "Bloqueo"
		var bs := CollisionShape3D.new()
		var caja := BoxShape3D.new()
		caja.size = Vector3(0.75, 1.9, 0.75)
		bs.shape = caja
		bs.position = Vector3(0, 0.95, 0)
		b.add_child(bs)
		add_child(b)
		rid_bloqueo = b.get_rid()
		add_collision_exception_with(b)     # que no choque con su propio cuerpo solido
	call_deferred("_buscar_visual")


func _buscar_visual() -> void:
	_visual = get_node_or_null("Visual") as Node3D
	if _visual:
		_cabeza = _visual.find_child("Cabeza", true, false) as Node3D
		_ojos = _visual.get_meta("ojos", []) as Array


## Un reflector la ilumina: queda inmovilizada para siempre.
func fijar() -> void:
	if fijada:
		return
	fijada = true
	activa = false
	en_movimiento = false
	observada = true
	motivo = "reflector"
	velocity = Vector3.ZERO
	fijada_para_siempre.emit(self)


## El walkie suena en "pos": la estatua va hacia alli unos segundos en vez de ir por el jugador.
func atraer(pos: Vector3, segundos: float) -> void:
	_senuelo_pos = pos
	_senuelo_t = segundos
	_ruta.clear()


func _physics_process(delta: float) -> void:
	_t += delta
	_animar(delta)
	if not activa or fijada:
		return
	if _jugador == null:
		_jugador = get_tree().get_first_node_in_group("jugador") as CharacterBody3D
		if _jugador == null:
			return
	_t_aviso = maxf(0.0, _t_aviso - delta)
	_senuelo_t = maxf(0.0, _senuelo_t - delta)

	var pj := _jugador.global_position
	if not region.has_point(Vector2(pj.x, pj.z)) or absf(pj.y - global_position.y) > 3.5:
		en_movimiento = false
		observada = false
		return

	# CONDICION: nadie la mira -> se mueve; alguien la mira -> se congela
	_t_observacion -= delta
	if _t_observacion <= 0.0:
		_t_observacion = 0.08
		_motivo_observacion = "luz_sala" if protegida_por_luz else _quien_me_observa()
	var nuevo_motivo := _motivo_observacion
	if nuevo_motivo != "" and nuevo_motivo != motivo:
		congelada.emit(self, nuevo_motivo)
	motivo = nuevo_motivo
	observada = motivo != ""
	if observada:
		en_movimiento = false
		velocity = Vector3.ZERO
		return

	var hacia := pj - global_position
	hacia.y = 0.0
	var d := hacia.length()
	if d < distancia_captura:
		activa = false
		atrapo_al_jugador.emit(self)
		return
	if d < distancia_aviso and _t_aviso <= 0.0:
		_t_aviso = 25.0
		se_acerca.emit(self)

	var destino := pj
	if _senuelo_t > 0.0:
		destino = _senuelo_pos
	var wp := _siguiente_punto(destino, delta)
	var dir := wp - global_position
	dir.y = 0.0
	if dir.length() < 0.05:
		en_movimiento = false
		return
	dir = dir.normalized()
	velocity = dir * velocidad * multiplicador
	move_and_slide()
	en_movimiento = true
	rotation.y = lerp_angle(rotation.y, atan2(dir.x, dir.z), 5.0 * delta)
	_t_paso -= delta
	if _t_paso <= 0.0:
		_t_paso = 0.45 if ruidosa else 0.85
		sonido_paso.emit(self)


# ---------------------------------------------------------------- animacion

func _animar(delta: float) -> void:
	if _visual == null:
		return
	var k := 1.0 - exp(-8.0 * delta)
	if en_movimiento:
		# Paso pesado: balanceo y cabeceo
		_visual.rotation.z = lerpf(_visual.rotation.z, sin(_t * 5.0) * 0.05, k)
		_visual.rotation.x = lerpf(_visual.rotation.x, sin(_t * 2.5) * 0.025, k)
		_visual.position.y = lerpf(_visual.position.y, absf(sin(_t * 2.5)) * 0.03, k)
	else:
		_visual.rotation.z = lerpf(_visual.rotation.z, 0.0, k)
		_visual.rotation.x = lerpf(_visual.rotation.x, 0.0, k)
		_visual.position.y = lerpf(_visual.position.y, 0.0, k)
	# Ojos que brillan cuando se mueve
	for o in _ojos:
		var m := o as StandardMaterial3D
		m.emission_energy_multiplier = lerpf(m.emission_energy_multiplier, 3.5 if en_movimiento else 0.0, k)
	# La cabeza gira hacia el jugador cuando nadie la mira
	if _cabeza and _jugador and activa and not observada and not fijada:
		var d := _jugador.global_position + Vector3(0, 1.6, 0) - _cabeza.global_position
		var yaw := wrapf(atan2(d.x, d.z) - global_rotation.y, -PI, PI)
		_cabeza.rotation.y = lerp_angle(_cabeza.rotation.y, clampf(yaw, -1.1, 1.1), 3.5 * delta)


# ---------------------------------------------------------------- observacion

## Devuelve "vista", "linterna", "espejo" o "" (nadie la observa).
func _quien_me_observa() -> String:
	var centro := global_position + Vector3(0, 1.0, 0)
	var cam := get_viewport().get_camera_3d()
	# "Vista": esta en pantalla Y delante del guardia. Las que estan DETRAS de el se siguen moviendo
	# aunque las veas en la camara (hay que girarse para mirarlas o usar el espejo).
	var delante := (centro - _jugador.global_position).dot(-_jugador.global_transform.basis.z) > 0.0
	if delante and cam and cam.is_position_in_frustum(centro) and _linea_libre(cam.global_position, centro):
		return "vista"
	var luz := _jugador.get_node_or_null("Linterna") as SpotLight3D
	if luz and luz.is_visible_in_tree():
		var dir_luz := -luz.global_transform.basis.z
		var hacia := centro - luz.global_position
		if hacia.length() < luz.spot_range and dir_luz.angle_to(hacia) < deg_to_rad(luz.spot_angle) and _linea_libre(luz.global_position, centro):
			return "linterna"
	if bool(_jugador.get("espejo_levantado")):
		var cam_e := _jugador.get("camara_espejo") as Camera3D
		if cam_e and cam_e.is_position_in_frustum(centro) and _linea_libre(cam_e.global_position, centro):
			return "espejo"
	return ""


## True si no hay una pared u objeto solido entre "desde" y "hasta".
func _linea_libre(desde: Vector3, hasta: Vector3) -> bool:
	var q := PhysicsRayQueryParameters3D.create(desde, hasta)
	q.collision_mask = 1
	q.exclude = [_jugador.get_rid(), rid_bloqueo]
	var hit := get_world_3d().direct_space_state.intersect_ray(q)
	if hit.is_empty():
		return true
	return desde.distance_to(hit["position"] as Vector3) > desde.distance_to(hasta) - 0.9


# ---------------------------------------------------------------- navegacion (A* sobre la geometria)

func _siguiente_punto(destino: Vector3, delta: float) -> Vector3:
	# Camino directo si no hay nada de por medio
	var desde := global_position + Vector3(0, 0.6, 0)
	var hasta := Vector3(destino.x, global_position.y + 0.6, destino.z)
	_t_camino_directo -= delta
	if _t_camino_directo <= 0.0:
		_t_camino_directo = 0.1
		_camino_directo_despejado = desde.distance_to(hasta) < 8.0 and _camino_despejado(desde, hasta)
	if _camino_directo_despejado:
		_ruta.clear()
		return destino
	if _nav.is_empty():
		if not _nav_en_progreso:
			_nav_en_progreso = true
			_cargar_nav()
		# No bloqueamos el fotograma horneando cientos de celdas de navegación.
		# El movimiento con colisión sigue funcionando mientras termina el mapa.
		return destino
	_t_ruta -= delta
	if _t_ruta <= 0.0 or _ruta.is_empty():
		_t_ruta = 0.5
		_ruta = _calcular_ruta(destino)
	while not _ruta.is_empty() and Vector2(global_position.x - _ruta[0].x, global_position.z - _ruta[0].z).length() < 0.45:
		_ruta.pop_front()
	if _ruta.is_empty():
		return destino
	return _ruta[0]


func _camino_despejado(desde: Vector3, hasta: Vector3) -> bool:
	# Tres rayos (centro y a los lados) para que el cuerpo no roce una esquina
	var lado := (hasta - desde).cross(Vector3.UP).normalized() * 0.4
	for off in [Vector3.ZERO, lado, -lado]:
		var q := PhysicsRayQueryParameters3D.create(desde + off, hasta + off)
		q.collision_mask = 1
		q.exclude = [rid_bloqueo, _jugador.get_rid()]     # el propio jugador no cuenta como obstaculo
		if not get_world_3d().direct_space_state.intersect_ray(q).is_empty():
			return false
	return true


func _celda(p: Vector3, origen: Vector2, w: int, h: int) -> Vector2i:
	return Vector2i(clampi(int((p.x - origen.x) / CELDA), 0, w - 1), clampi(int((p.z - origen.y) / CELDA), 0, h - 1))


func _calcular_ruta(destino: Vector3) -> Array[Vector3]:
	var res: Array[Vector3] = []
	var astar := _nav["astar"] as AStarGrid2D
	var origen: Vector2 = _nav["origen"]
	var w: int = _nav["w"]
	var h: int = _nav["h"]
	var a := _libre_cerca(astar, _celda(global_position, origen, w, h), w, h)
	var b := _libre_cerca(astar, _celda(destino, origen, w, h), w, h)
	var ids: Array[Vector2i] = astar.get_id_path(a, b)
	for c in ids:
		res.append(Vector3(origen.x + (c.x + 0.5) * CELDA, global_position.y, origen.y + (c.y + 0.5) * CELDA))
	return res


func _libre_cerca(astar: AStarGrid2D, c: Vector2i, w: int, h: int) -> Vector2i:
	if not astar.is_point_solid(c):
		return c
	for radio in range(1, 4):
		for dx in range(-radio, radio + 1):
			for dy in range(-radio, radio + 1):
				var n := Vector2i(clampi(c.x + dx, 0, w - 1), clampi(c.y + dy, 0, h - 1))
				if not astar.is_point_solid(n):
					return n
	return c


func _cargar_nav() -> void:
	_nav = await _obtener_nav()
	_nav_en_progreso = false


func _obtener_nav() -> Dictionary:
	var y := global_position.y
	var clave := "%s|%.1f" % [str(region), y]
	if _navs.has(clave):
		return _navs[clave]
	var w := int(ceil(region.size.x / CELDA))
	var h := int(ceil(region.size.y / CELDA))
	var astar := AStarGrid2D.new()
	astar.region = Rect2i(0, 0, w, h)
	astar.cell_size = Vector2(CELDA, CELDA)
	astar.diagonal_mode = AStarGrid2D.DIAGONAL_MODE_ONLY_IF_NO_OBSTACLES
	astar.update()
	var esfera := SphereShape3D.new()
	esfera.radius = 0.38
	var q := PhysicsShapeQueryParameters3D.new()
	q.shape = esfera
	q.collision_mask = 1
	var propios: Array[RID] = []
	for n in get_tree().get_nodes_in_group("enemigos"):
		var r = n.get("rid_bloqueo")
		if r is RID:
			propios.append(r)
	q.exclude = propios
	var espacio := get_world_3d().direct_space_state
	for i in w:
		for j in h:
			q.transform = Transform3D(Basis.IDENTITY, Vector3(region.position.x + (i + 0.5) * CELDA, y + 0.95, region.position.y + (j + 0.5) * CELDA))
			if not espacio.intersect_shape(q, 1).is_empty():
				astar.set_point_solid(Vector2i(i, j), true)
		# Reparte las consultas de colision entre varios fotogramas para evitar
		# congelones cuando una criatura necesita rodear un obstaculo por primera vez.
		if i % 3 == 2:
			await get_tree().process_frame
	var nav := {"astar": astar, "origen": region.position, "w": w, "h": h}
	_navs[clave] = nav
	return nav
