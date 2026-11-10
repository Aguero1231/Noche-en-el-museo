extends "res://scripts/environment/room_base.gd"

## OFICINA DE SEGURIDAD: punto de inicio del juego.
##
## Se construye toda por codigo y usa las mismas texturas del museo (assets/environment/):
## piedra, marmol, alfombra y banda de jeroglificos. Esta pegada a la pared ESTE del
## vestibulo principal (el cuarto esta girado 90 grados) y su puerta da al vestibulo.
##
## Tiene la historia del inicio: carta de Roberto, calendario, corcho, computadora,
## radio, monitores de las camaras de seguridad, y los objetos del jugador
## (linterna, espejo y walkie-talkie).

const TEX := "res://assets/environment/"

# Medidas de la oficina (metros)
const ANCHO := 5.0
const FONDO := 4.5
const ALTO := 2.8
const GROSOR := 0.2
const PUERTA_X := 1.2
const PUERTA_ANCHO := 1.3
const PUERTA_ALTO := 2.2
const ESC_Y := 0.78 # altura de la superficie del escritorio

## Donde se coloca esta oficina en el mundo: el fondo (pared de la puerta) pegado por fuera a la
## pared este del vestibulo (x = 9.5), con la puerta mirando al oeste, en z = 22.
const ROT_Y := 90.0
const ORIGEN := Vector3(9.5 + FONDO / 2.0 + GROSOR, 0.0, 22.0 + PUERTA_X)

## Donde aparece el jugador (en coordenadas del cuarto) y hacia donde mira (yaw del mundo).
const SPAWN_LOCAL := Vector3(-0.95, 0.0, -0.5)
const SPAWN_YAW := 1.5707963   # 90 grados: mira hacia la puerta (oeste)

const C_LUZ_CALIDA := Color(1.0, 0.72, 0.42)

@export var puerta_inicia_abierta: bool = true
@export var puerta_automatica: bool = true
@export_range(0.0, 3.0) var brillo_luces: float = 1.0

var _nodo_bisagra: Node3D
var _boton_int: MeshInstance3D
var _luces_oficina: Array[Light3D] = []
var _luz_pasillo: SpotLight3D
var _mat_lampara: StandardMaterial3D
var _puerta_abierta := false
var _luz_encendida := true
var _tween_puerta: Tween
var _bloqueo_auto := 0.0
var _monitor_consola: Dictionary = {}

# Materiales
var mat_pared: StandardMaterial3D
var mat_techo: StandardMaterial3D
var mat_zocalo: StandardMaterial3D
var mat_dorado: StandardMaterial3D
var mat_piso: StandardMaterial3D
var mat_madera: StandardMaterial3D
var mat_metal: StandardMaterial3D


func build() -> void:
	_preparar_materiales()
	_crear_cuarto()
	_crear_molduras()
	_crear_banda_jeroglifos()
	_crear_puerta()
	_crear_luces_oficina()
	_crear_interruptor()
	_crear_cartel()
	_crear_archiveros()
	_crear_pared_derecha()
	_crear_pared_frente()
	_crear_alfombra_y_silla()
	_crear_escritorio()
	_crear_pilar_lupa_y_espejo()
	_crear_rejilla_verde()
	_crear_consola_camaras()
	_registrar_pared_derecha()
	_crear_luz_de_la_sala()
	_crear_polvo()

	if puerta_inicia_abierta:
		_puerta_abierta = true
		_nodo_bisagra.rotation_degrees.y = -75.0


# ---------------------------------------------------------------- materiales

func _tex(archivo: String) -> Texture2D:
	var ruta := TEX + archivo
	if ResourceLoader.exists(ruta):
		return load(ruta) as Texture2D
	return null


## Piedra del museo (wall_stone.png + normal map), con un tinte para que se vea mas calida.
func _mat_piedra(tinte: Color, escala: float) -> StandardMaterial3D:
	var m := StandardMaterial3D.new()
	m.albedo_texture = _tex("wall_stone.png")
	m.albedo_color = tinte
	var n := _tex("wall_stone_n.png")
	if n:
		m.normal_enabled = true
		m.normal_texture = n
		m.normal_scale = 1.0
	m.roughness = 0.85
	m.uv1_triplanar = true
	m.uv1_world_triplanar = true
	m.uv1_scale = Vector3(escala, escala, escala)
	return m


## Marmol del museo (floor_marble.png + normal map).
func _mat_marmol(tinte: Color, escala: float) -> StandardMaterial3D:
	var m := StandardMaterial3D.new()
	m.albedo_texture = _tex("floor_marble.png")
	m.albedo_color = tinte
	var n := _tex("floor_marble_n.png")
	if n:
		m.normal_enabled = true
		m.normal_texture = n
		m.normal_scale = 0.45
	m.roughness = 0.32
	m.metallic_specular = 0.6
	m.uv1_triplanar = true
	m.uv1_world_triplanar = true
	m.uv1_scale = Vector3(escala, escala, escala)
	return m


func _preparar_materiales() -> void:
	mat_pared = _mat_piedra(Color(0.95, 0.84, 0.72), 0.4)
	mat_techo = _mat_piedra(Color(0.45, 0.40, 0.38), 0.4)
	mat_piso = _mat_marmol(Color(1.0, 0.95, 0.9), 0.25)
	mat_zocalo = _mat(Color(0.20, 0.12, 0.07), 0.55)
	mat_dorado = _mat(Color(0.7, 0.52, 0.2), 0.4, Color(0.6, 0.4, 0.1), 0.5, 0.3)
	mat_madera = _mat(Color(0.38, 0.23, 0.13), 0.5)
	mat_metal = _mat(Color(0.28, 0.27, 0.26), 0.35, Color.BLACK, 0.8)


func _mat(color: Color, rugosidad: float = 1.0, emision: Color = Color.BLACK, metalico: float = 0.0, energia_emision: float = 1.5) -> StandardMaterial3D:
	var m := StandardMaterial3D.new()
	m.albedo_color = color
	m.roughness = rugosidad
	m.metallic = metalico
	m.texture_filter = BaseMaterial3D.TEXTURE_FILTER_LINEAR_WITH_MIPMAPS
	if emision != Color.BLACK:
		m.emission_enabled = true
		m.emission = emision
		m.emission_energy_multiplier = energia_emision
	return m


func _mat_vidrio(color: Color) -> StandardMaterial3D:
	var m := StandardMaterial3D.new()
	m.albedo_color = color
	m.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	m.roughness = 0.05
	m.metallic = 0.4
	return m

## Baldosas procedurales por shader (sin texturas externas).


# ---------------------------------------------------------------- mallas base

func _caja(nombre_nodo: String, tam: Vector3, pos: Vector3, mat: Material, padre: Node3D = null, colision: bool = true) -> MeshInstance3D:
	if padre == null: padre = self
	var mi := MeshInstance3D.new()
	mi.name = nombre_nodo
	var bm := BoxMesh.new()
	bm.size = tam
	mi.mesh = bm
	mi.material_override = mat
	mi.position = pos
	padre.add_child(mi)
	if colision:
		var cuerpo := StaticBody3D.new()
		cuerpo.name = "Fisica"
		var cs := CollisionShape3D.new()
		var bs := BoxShape3D.new()
		bs.size = tam
		cs.shape = bs
		cuerpo.add_child(cs)
		mi.add_child(cuerpo)
	return mi


func _cilindro(nombre_nodo: String, r_sup: float, r_inf: float, alto: float, pos: Vector3, mat: Material, padre: Node3D = null, rot_deg: Vector3 = Vector3.ZERO, segmentos: int = 32) -> MeshInstance3D:
	if padre == null: padre = self
	var mi := MeshInstance3D.new()
	mi.name = nombre_nodo
	var cm := CylinderMesh.new()
	cm.top_radius = r_sup
	cm.bottom_radius = r_inf
	cm.height = alto
	cm.radial_segments = segmentos
	mi.mesh = cm
	mi.material_override = mat
	mi.position = pos
	mi.rotation_degrees = rot_deg
	padre.add_child(mi)
	return mi


func _toro(nombre_nodo: String, r_int: float, r_ext: float, pos: Vector3, mat: Material, padre: Node3D = null, rot_deg: Vector3 = Vector3.ZERO) -> MeshInstance3D:
	if padre == null: padre = self
	var mi := MeshInstance3D.new()
	mi.name = nombre_nodo
	var tm := TorusMesh.new()
	tm.inner_radius = r_int
	tm.outer_radius = r_ext
	tm.rings = 32
	tm.ring_segments = 16
	mi.mesh = tm
	mi.material_override = mat
	mi.position = pos
	mi.rotation_degrees = rot_deg
	padre.add_child(mi)
	return mi


func _nodo(nombre: String, pos: Vector3, rot_y: float = 0.0, padre: Node3D = null) -> Node3D:
	if padre == null: padre = self
	var n := Node3D.new()
	n.name = nombre
	n.position = pos
	n.rotation_degrees.y = rot_y
	padre.add_child(n)
	return n

# ---------------------------------------------------------------- estructura

func _crear_cuarto() -> void:
	var hx := ANCHO / 2.0
	var hz := FONDO / 2.0
	var cuarto := _nodo("Cuarto", Vector3.ZERO)

	_caja("Piso", Vector3(ANCHO + GROSOR, GROSOR, FONDO + GROSOR), Vector3(0, -GROSOR / 2.0, 0), mat_piso, cuarto)
	_caja("Techo", Vector3(ANCHO + GROSOR, GROSOR, FONDO + GROSOR), Vector3(0, ALTO + GROSOR / 2.0, 0), mat_techo, cuarto)
	_caja("ParedIzquierda", Vector3(GROSOR, ALTO, FONDO + GROSOR), Vector3(-hx - GROSOR / 2.0, ALTO / 2.0, 0), mat_pared, cuarto)
	_caja("ParedDerecha", Vector3(GROSOR, ALTO, FONDO + GROSOR), Vector3(hx + GROSOR / 2.0, ALTO / 2.0, 0), mat_pared, cuarto)
	_caja("ParedFrente", Vector3(ANCHO, ALTO, GROSOR), Vector3(0, ALTO / 2.0, hz + GROSOR / 2.0), mat_pared, cuarto)

	# Pared del fondo (la de la puerta): dos tramos y un dintel
	var zf := -hz - GROSOR / 2.0
	var x_izq := PUERTA_X - PUERTA_ANCHO / 2.0
	var ancho_izq := x_izq - (-hx)
	_caja("ParedFondoIzq", Vector3(ancho_izq, ALTO, GROSOR), Vector3(-hx + ancho_izq / 2.0, ALTO / 2.0, zf), mat_pared, cuarto)
	var x_der := PUERTA_X + PUERTA_ANCHO / 2.0
	var ancho_der := hx - x_der
	_caja("ParedFondoDer", Vector3(ancho_der, ALTO, GROSOR), Vector3(hx - ancho_der / 2.0, ALTO / 2.0, zf), mat_pared, cuarto)
	_caja("DintelPuerta", Vector3(PUERTA_ANCHO, ALTO - PUERTA_ALTO, GROSOR), Vector3(PUERTA_X, PUERTA_ALTO + (ALTO - PUERTA_ALTO) / 2.0, zf), mat_pared, cuarto)

	# Zocalo de madera oscura (igual que el de la sala del museo)
	var zh := 0.9
	var zg := 0.03
	_caja("ZocaloIzq", Vector3(zg, zh, FONDO), Vector3(-hx + zg / 2.0, zh / 2.0, 0), mat_zocalo, cuarto, false)
	_caja("ZocaloDer", Vector3(zg, zh, FONDO), Vector3(hx - zg / 2.0, zh / 2.0, 0), mat_zocalo, cuarto, false)
	_caja("ZocaloFrente", Vector3(ANCHO, zh, zg), Vector3(0, zh / 2.0, hz - zg / 2.0), mat_zocalo, cuarto, false)
	_caja("ZocaloFondoIzq", Vector3(ancho_izq, zh, zg), Vector3(-hx + ancho_izq / 2.0, zh / 2.0, -hz + zg / 2.0), mat_zocalo, cuarto, false)
	_caja("ZocaloFondoDer", Vector3(ancho_der, zh, zg), Vector3(hx - ancho_der / 2.0, zh / 2.0, -hz + zg / 2.0), mat_zocalo, cuarto, false)

	# Vigas de madera en el techo (como las del museo)
	for z in [-1.45, 1.75]:
		_caja("Viga", Vector3(ANCHO, 0.16, 0.22), Vector3(0, ALTO - 0.08, z), mat_zocalo, cuarto, false)


## Moldura superior, liston dorado sobre el zocalo y guardapolvo del piso.
func _crear_molduras() -> void:
	var hx := ANCHO / 2.0
	var hz := FONDO / 2.0
	var m_mold := _mat(Color(0.12, 0.08, 0.06), 0.8)
	var raiz := _nodo("Molduras", Vector3.ZERO)
	for y in [ALTO - 0.05, 0.05]:
		_caja("MoldIzq", Vector3(0.05, 0.1, FONDO), Vector3(-hx + 0.025, y, 0), m_mold, raiz, false)
		_caja("MoldDer", Vector3(0.05, 0.1, FONDO), Vector3(hx - 0.025, y, 0), m_mold, raiz, false)
		_caja("MoldFrente", Vector3(ANCHO, 0.1, 0.05), Vector3(0, y, hz - 0.025), m_mold, raiz, false)
		_caja("MoldFondo", Vector3(ANCHO, 0.1, 0.05), Vector3(0, y, -hz + 0.025), m_mold, raiz, false)
	# Liston dorado que remata el zocalo
	_caja("ListonIzq", Vector3(0.05, 0.05, FONDO), Vector3(-hx + 0.025, 0.9, 0), mat_dorado, raiz, false)
	_caja("ListonDer", Vector3(0.05, 0.05, FONDO), Vector3(hx - 0.025, 0.9, 0), mat_dorado, raiz, false)
	_caja("ListonFrente", Vector3(ANCHO, 0.05, 0.05), Vector3(0, 0.9, hz - 0.025), mat_dorado, raiz, false)


## Banda de jeroglificos del museo (hiero_band.png) cerca del techo.
func _crear_banda_jeroglifos() -> void:
	var tex := _tex("hiero_band.png")
	if tex == null:
		return
	var hx := ANCHO / 2.0
	var hz := FONDO / 2.0
	var y := 2.52
	var alto := 0.28
	var raiz := _nodo("BandaJeroglificos", Vector3.ZERO)
	# [posicion, rotacion Y, largo]
	var tramos := [
		[Vector3(-hx + 0.012, y, 0.0), 90.0, FONDO],
		[Vector3(hx - 0.012, y, 0.0), -90.0, FONDO],
		[Vector3(0.0, y, hz - 0.012), 180.0, ANCHO],
		[Vector3(-1.0, y, -hz + 0.012), 0.0, 3.0],
	]
	for t in tramos:
		var largo: float = t[2]
		var m := StandardMaterial3D.new()
		m.albedo_texture = tex
		m.roughness = 0.7
		m.emission_enabled = true
		m.emission_texture = tex
		m.emission_energy_multiplier = 0.7
		m.uv1_scale = Vector3(largo / (alto * 8.0), 1.0, 1.0)
		var q := QuadMesh.new()
		q.size = Vector2(largo, alto)
		var mi := MeshInstance3D.new()
		mi.name = "Banda"
		mi.mesh = q
		mi.material_override = m
		mi.position = t[0]
		mi.rotation_degrees.y = t[1]
		raiz.add_child(mi)


func _crear_puerta() -> void:
	var m_marco := _mat(Color(0.09, 0.07, 0.06), 0.7)
	var zf := -FONDO / 2.0 - GROSOR / 2.0
	var x_izq := PUERTA_X - PUERTA_ANCHO / 2.0
	var x_der := PUERTA_X + PUERTA_ANCHO / 2.0

	_caja("MarcoIzq", Vector3(0.08, PUERTA_ALTO, GROSOR + 0.04), Vector3(x_izq - 0.02, PUERTA_ALTO / 2.0, zf), m_marco, null, true)
	_caja("MarcoDer", Vector3(0.08, PUERTA_ALTO, GROSOR + 0.04), Vector3(x_der + 0.02, PUERTA_ALTO / 2.0, zf), m_marco, null, true)
	_caja("MarcoSup", Vector3(PUERTA_ANCHO + 0.16, 0.08, GROSOR + 0.04), Vector3(PUERTA_X, PUERTA_ALTO + 0.02, zf), m_marco, null, false)

	_nodo_bisagra = _nodo("BisagraPuerta", Vector3(x_izq, 0, zf))

	var ancho_hoja := PUERTA_ANCHO - 0.05
	var m_puerta := _mat(Color(0.17, 0.15, 0.14), 0.55, Color.BLACK, 0.55)
	var m_oxido := _mat(Color(0.32, 0.19, 0.10), 0.9)
	_caja("Hoja", Vector3(ancho_hoja, PUERTA_ALTO - 0.05, 0.08), Vector3(ancho_hoja / 2.0, PUERTA_ALTO / 2.0, 0), m_puerta, _nodo_bisagra, true)
	_caja("Placa1", Vector3(ancho_hoja - 0.2, 0.5, 0.01), Vector3(ancho_hoja / 2.0, 1.55, 0.043), m_oxido, _nodo_bisagra, false)
	_caja("Placa2", Vector3(ancho_hoja - 0.2, 0.7, 0.01), Vector3(ancho_hoja / 2.0, 0.6, 0.043), _mat(Color(0.20, 0.17, 0.15), 0.6, Color.BLACK, 0.5), _nodo_bisagra, false)
	_caja("Cerradura", Vector3(0.12, 0.2, 0.03), Vector3(ancho_hoja - 0.12, 1.05, 0.055), mat_metal, _nodo_bisagra, false)
	_caja("Manija", Vector3(0.15, 0.04, 0.12), Vector3(ancho_hoja - 0.2, 1.0, 0.09), mat_metal, _nodo_bisagra, false)

	# Punto de interacción fijo en el centro del vano (radio grande = fácil de usar)
	var objetivo := _nodo("PuertaObjetivo", Vector3(PUERTA_X, 1.1, zf))
	reg(objetivo, "puerta_oficina", "Abrir / cerrar puerta", {}, 3.6)


func _crear_interruptor() -> void:
	var x_int := PUERTA_X + PUERTA_ANCHO / 2.0 + 0.35
	var z_int := -FONDO / 2.0 + 0.011
	var pos := Vector3(x_int, 1.3, z_int)
	_caja("InterruptorBase", Vector3(0.12, 0.17, 0.022), pos, _mat(Color(0.75, 0.70, 0.60), 0.5), null, false)
	_boton_int = _caja("InterruptorBoton", Vector3(0.04, 0.06, 0.012), pos + Vector3(0, 0.02, 0.014), _mat(Color(0.9, 0.9, 0.85)), null, false)
	var objetivo := _nodo("InterruptorObjetivo", pos)
	reg(objetivo, "interruptor", "Luz", {}, 3.2)


# ---------------------------------------------------------------- luces

func _crear_luces_oficina() -> void:
	var pos_luz := Vector3(0.1, ALTO - 0.08, 0.45)

	_mat_lampara = _mat(Color(0.12, 0.10, 0.08), 0.8, Color(1.0, 0.75, 0.4), 0.0, 1.6)
	_cilindro("PantallaLampara", 0.12, 0.42, 0.16, pos_luz, _mat_lampara, null, Vector3.ZERO, 8)
	_cilindro("Cable", 0.01, 0.01, 0.2, pos_luz + Vector3(0, 0.15, 0), _mat(Color.BLACK), null)

	var foco := SpotLight3D.new()
	foco.name = "FocoPrincipal"
	foco.position = pos_luz + Vector3(0, -0.08, 0)
	foco.rotation_degrees.x = -90
	foco.spot_angle = 55.0
	foco.spot_angle_attenuation = 1.3
	foco.spot_range = 6.0
	foco.light_color = C_LUZ_CALIDA
	foco.light_energy = 10.0 * brillo_luces
	foco.shadow_enabled = true
	add_child(foco)
	_luces_oficina.append(foco)

	# Relleno calido (rango corto para que no se filtre a la sala del museo)
	var relleno := OmniLight3D.new()
	relleno.name = "RellenoCalido"
	relleno.position = Vector3(0, ALTO - 0.5, 0.9)
	relleno.omni_range = 4.0
	relleno.light_color = Color(1.0, 0.65, 0.35)
	relleno.light_energy = 1.4 * brillo_luces
	add_child(relleno)
	_luces_oficina.append(relleno)

	# Toque calido sobre el cartel para que se lea bien
	var cartel_luz := OmniLight3D.new()
	cartel_luz.name = "LuzCartel"
	cartel_luz.position = Vector3(-1.6, 2.2, -0.75)
	cartel_luz.omni_range = 2.5
	cartel_luz.light_color = Color(1.0, 0.7, 0.4)
	cartel_luz.light_energy = 0.8 * brillo_luces
	add_child(cartel_luz)
	_luces_oficina.append(cartel_luz)


## Luz fria y parpadeante que entra por la puerta desde la Sala Egipcia (museo).
func _crear_luz_de_la_sala() -> void:
	_luz_pasillo = SpotLight3D.new()
	_luz_pasillo.name = "LuzSala"
	_luz_pasillo.position = Vector3(PUERTA_X, 2.6, -FONDO / 2.0 - GROSOR - 4.5)
	_luz_pasillo.rotation_degrees.x = -22.0
	_luz_pasillo.spot_angle = 24.0
	_luz_pasillo.spot_range = 13.0
	_luz_pasillo.light_color = Color(0.3, 0.55, 1.0)
	_luz_pasillo.light_energy = 3.0
	_luz_pasillo.shadow_enabled = true
	# rotation.y = 180 hace que el foco mire hacia +z (hacia la oficina)
	_luz_pasillo.rotation_degrees.y = 180.0
	add_child(_luz_pasillo)


# ---------------------------------------------------------------- decoracion

func _crear_cartel() -> void:
	var poster := _nodo("CartelSeguridad", Vector3(-ANCHO / 2.0 + 0.06, 1.75, -0.75), 90)
	var tinta := Color(0.08, 0.05, 0.04)
	_caja("Papel", Vector3(1.9, 1.2, 0.02), Vector3.ZERO, _mat(Color(0.80, 0.68, 0.50), 0.9), poster, false)
	# Cintas en las esquinas
	var m_cinta := _mat(Color(0.7, 0.65, 0.5, 1.0), 0.6)
	for sx in [-1.0, 1.0]:
		_caja("Cinta", Vector3(0.12, 0.04, 0.025), Vector3(sx * 0.9, 0.58, 0.005), m_cinta, poster, false).rotation_degrees.z = sx * 25.0

	# Logo: edificio de museo
	_caja("LogoFondo", Vector3(0.42, 0.34, 0.01), Vector3(-0.66, 0.36, 0.014), _mat(Color(0.08, 0.06, 0.05)), poster, false)
	var techo := MeshInstance3D.new()
	var prisma := PrismMesh.new()
	prisma.size = Vector3(0.32, 0.09, 0.01)
	techo.mesh = prisma
	techo.material_override = _mat(Color(0.9, 0.85, 0.75))
	techo.position = Vector3(-0.66, 0.44, 0.022)
	poster.add_child(techo)
	for i in 4:
		_caja("LogoCol%d" % i, Vector3(0.03, 0.12, 0.01), Vector3(-0.77 + i * 0.07, 0.34, 0.022), _mat(Color(0.9, 0.85, 0.75)), poster, false)
	_caja("LogoBase", Vector3(0.34, 0.03, 0.01), Vector3(-0.66, 0.265, 0.022), _mat(Color(0.9, 0.85, 0.75)), poster, false)
	_label_poster(poster, "MUSEO HISTÓRICO", Vector3(-0.66, 0.2, 0.02), 26, tinta, 0.0)

	_label_poster(poster, "SEGURIDAD", Vector3(0.28, 0.42, 0.02), 110, tinta, 6.0)
	_label_poster(poster, "MUSEO HISTÓRICO - REPORTE", Vector3(0.28, 0.27, 0.02), 44, tinta, 2.0)
	_label_poster(poster, "TURNO DE NOCHE", Vector3(0.28, 0.17, 0.02), 44, tinta, 2.0)
	_caja("Linea", Vector3(1.7, 0.006, 0.01), Vector3(0, 0.02, 0.014), _mat(tinta), poster, false)
	_label_poster(poster, "Title: \"Alex Poom Flores\" (Guardia)", Vector3(0, -0.06, 0.02), 42, tinta, 1.0)
	_label_poster(poster, "OBJETIVO INICIAL: Asegurar la Sala\nEgipcia. Recoger linterna, espejo y walkie.", Vector3(0, -0.26, 0.02), 42, tinta, 1.5)
	_label_poster(poster, "CUIDADO: La reliquia está\ninusualmente inquieta.", Vector3(-0.1, -0.46, 0.02), 42, tinta, 1.5)


func _label_poster(padre: Node3D, texto: String, pos: Vector3, tam: int, color: Color, contorno: float) -> void:
	var f := SystemFont.new()
	f.font_names = PackedStringArray(["Arial", "Helvetica", "Roboto", "sans-serif"])
	f.font_weight = 700
	var t := Label3D.new()
	t.text = texto
	t.font = f
	t.font_size = tam
	t.pixel_size = 0.0018
	t.modulate = color
	t.outline_modulate = color
	t.outline_size = int(contorno)
	t.double_sided = false
	t.position = pos
	padre.add_child(t)


func _archivero(nombre: String, pos: Vector3, alto: float, cajones: int) -> Node3D:
	var raiz := _nodo(nombre, pos)
	var m_cuerpo := _mat(Color(0.30, 0.25, 0.20), 0.55, Color.BLACK, 0.35)
	var m_frente := _mat(Color(0.36, 0.30, 0.24), 0.5, Color.BLACK, 0.4)
	var m_papel := _mat(Color(0.80, 0.72, 0.55), 0.9)
	_caja("Cuerpo", Vector3(0.6, alto, 0.65), Vector3(0, alto / 2.0, 0), m_cuerpo, raiz)
	var h := alto / cajones
	for k in cajones:
		var y := h * (k + 0.5)
		_caja("Frente%d" % k, Vector3(0.03, h - 0.04, 0.56), Vector3(0.315, y, 0), m_frente, raiz, false)
		_caja("Asa%d" % k, Vector3(0.04, 0.03, 0.2), Vector3(0.34, y - 0.04, 0), mat_metal, raiz, false)
		_caja("Etiqueta%d" % k, Vector3(0.012, 0.06, 0.12), Vector3(0.335, y + 0.06, 0), m_papel, raiz, false)
	return raiz


func _crear_archiveros() -> void:
	var x := -ANCHO / 2.0 + 0.35
	var a := _archivero("ArchiveroA", Vector3(x, 0, 0.9), 1.1, 3)
	_caja("Libro1", Vector3(0.32, 0.07, 0.22), Vector3(0, 1.135, 0.05), _mat(Color(0.35, 0.22, 0.12), 0.8), a, false)
	_caja("Libro2", Vector3(0.30, 0.06, 0.20), Vector3(0.02, 1.2, 0.05), _mat(Color(0.25, 0.20, 0.13), 0.8), a, false)
	var b := _archivero("ArchiveroB", Vector3(x, 0, 0.15), 0.75, 2)
	var m_carpeta := _mat(Color(0.20, 0.12, 0.09), 0.7)
	for i in 3:
		_caja("Carpeta%d" % i, Vector3(0.2, 0.3, 0.07), Vector3(0, 0.9, -0.15 + i * 0.1), m_carpeta, b, false)
		_caja("CarpetaEt%d" % i, Vector3(0.21, 0.08, 0.05), Vector3(0, 0.93, -0.15 + i * 0.1), _mat(Color(0.8, 0.72, 0.55)), b, false)

## Pared derecha: repisa con cajas y radio, reloj, tablero de llaves y bote de basura.


## Pared derecha: repisa con cajas y radio, reloj, tablero de llaves y bote de basura.
func _crear_pared_derecha() -> void:
	# Nodo pegado a la pared derecha mirando hacia adentro: x local = z mundo, z local = hacia el cuarto
	var p := _nodo("ParedDerechaDeco", Vector3(ANCHO / 2.0, 0, 0), -90)
	var m_tabla := _mat(Color(0.30, 0.19, 0.11), 0.6)
	var m_caja := _mat(Color(0.55, 0.45, 0.30), 0.85)
	var m_caja2 := _mat(Color(0.42, 0.34, 0.24), 0.85)

	# Repisas
	_caja("Repisa1", Vector3(1.3, 0.03, 0.3), Vector3(0.3, 1.25, 0.15), m_tabla, p, false)
	_caja("Repisa2", Vector3(1.3, 0.03, 0.3), Vector3(0.3, 1.75, 0.15), m_tabla, p, false)
	for sx in [-0.3, 0.9]:
		_caja("Soporte", Vector3(0.03, 0.5, 0.25), Vector3(sx, 1.5, 0.13), m_tabla, p, false)
	# Cajas de archivo
	_caja("CajaA1", Vector3(0.3, 0.22, 0.24), Vector3(-0.15, 1.375, 0.15), m_caja, p, false)
	_caja("CajaA2", Vector3(0.28, 0.2, 0.24), Vector3(0.18, 1.365, 0.15), m_caja2, p, false)
	_caja("CajaB1", Vector3(0.34, 0.22, 0.24), Vector3(0.05, 1.875, 0.15), m_caja2, p, false)
	_caja("EtiquetaA1", Vector3(0.12, 0.06, 0.005), Vector3(-0.15, 1.38, 0.275), _mat(Color(0.85, 0.78, 0.6)), p, false)
	# Radio antigua
	var m_radio := _mat(Color(0.25, 0.14, 0.08), 0.5)
	_caja("Radio", Vector3(0.32, 0.2, 0.15), Vector3(0.65, 1.865, 0.15), m_radio, p, false)
	_cilindro("RadioDial", 0.04, 0.04, 0.01, Vector3(0.75, 1.87, 0.235), _mat(Color(0.8, 0.7, 0.4), 0.3, Color.BLACK, 0.6), p, Vector3(90, 0, 0))
	_caja("RadioRejilla", Vector3(0.14, 0.12, 0.005), Vector3(0.57, 1.865, 0.228), _mat(Color(0.1, 0.07, 0.05)), p, false)

	# Reloj de pared
	var m_reloj := _mat(Color(0.85, 0.8, 0.7), 0.5)
	var m_neg := _mat(Color(0.05, 0.05, 0.05), 0.5)
	var reloj := _nodo("Reloj", Vector3(1.6, 2.1, 0.03), 0, p)
	_cilindro("Cara", 0.2, 0.2, 0.04, Vector3.ZERO, m_reloj, reloj, Vector3(90, 0, 0))
	_toro("Borde", 0.19, 0.22, Vector3(0, 0, 0.0), m_neg, reloj, Vector3(90, 0, 0))
	_caja("Horas", Vector3(0.012, 0.11, 0.008), Vector3(0.02, 0.04, 0.022), m_neg, reloj, false).rotation_degrees.z = -30
	_caja("Minutos", Vector3(0.008, 0.16, 0.008), Vector3(-0.02, 0.05, 0.026), m_neg, reloj, false).rotation_degrees.z = 40

	# Tablero de llaves
	var tablero := _nodo("TableroLlaves", Vector3(-1.1, 1.55, 0.02), 0, p)
	_caja("Fondo", Vector3(0.5, 0.4, 0.03), Vector3.ZERO, _mat(Color(0.22, 0.14, 0.09), 0.7), tablero, false)
	var m_llave := _mat(Color(0.7, 0.6, 0.25), 0.3, Color.BLACK, 0.8)
	for i in 4:
		_caja("Gancho%d" % i, Vector3(0.01, 0.01, 0.03), Vector3(-0.15 + i * 0.1, 0.1, 0.03), mat_metal, tablero, false)
		_caja("Llave%d" % i, Vector3(0.03, 0.1, 0.008), Vector3(-0.15 + i * 0.1, 0.03, 0.03), m_llave, tablero, false)

	# Bote de basura
	_cilindro("Basura", 0.14, 0.11, 0.32, Vector3(2.15, 0.16, 1.9), _mat(Color(0.14, 0.14, 0.14), 0.5, Color.BLACK, 0.6), null)


func _crear_alfombra_y_silla() -> void:
	# Alfombra del museo (carpet.png) bajo el escritorio; solo visual, no estorba al caminar.
	# La textura es 1:2, por eso el plano mide 1.9 x 3.8.
	var m_alf := StandardMaterial3D.new()
	var tex_alf := _tex("carpet.png")
	m_alf.albedo_texture = tex_alf
	if tex_alf == null:
		m_alf.albedo_color = Color(0.4, 0.06, 0.07)
	m_alf.roughness = 1.0
	var plano := PlaneMesh.new()
	plano.size = Vector2(1.9, 3.8)
	var alfombra := MeshInstance3D.new()
	alfombra.name = "Alfombra"
	alfombra.mesh = plano
	alfombra.material_override = m_alf
	alfombra.position = Vector3(0.2, 0.012, 0.35)
	alfombra.rotation_degrees.y = 90.0
	add_child(alfombra)

	# Silla de oficina detrás del escritorio
	var s := _nodo("Silla", Vector3(0.1, 0, -0.62), 15)
	var m_tela := _mat(Color(0.30, 0.09, 0.07), 0.85)
	var m_neg := _mat(Color(0.08, 0.08, 0.08), 0.5, Color.BLACK, 0.5)
	_cilindro("Piston", 0.03, 0.03, 0.4, Vector3(0, 0.27, 0), m_neg, s)
	for i in 3:
		var pata := _caja("Pata%d" % i, Vector3(0.36, 0.03, 0.05), Vector3(0, 0.06, 0), m_neg, s, false)
		pata.rotation_degrees.y = i * 60.0
	_caja("Asiento", Vector3(0.5, 0.08, 0.5), Vector3(0, 0.5, 0), m_tela, s, false)
	_caja("Respaldo", Vector3(0.48, 0.55, 0.07), Vector3(0, 0.85, -0.25), m_tela, s, false).rotation_degrees.x = -8


func _crear_escritorio() -> void:
	var escritorio := _nodo("Escritorio", Vector3(0.2, 0, 0.5))
	var sup := ESC_Y
	_caja("Tapa", Vector3(2.2, 0.06, 1.0), Vector3(0, sup - 0.03, 0), mat_madera, escritorio)
	_caja("BordeFrente", Vector3(2.2, 0.03, 0.03), Vector3(0, sup - 0.075, 0.485), _mat(Color(0.14, 0.08, 0.05), 0.5), escritorio, false)
	_caja("BaseIzq", Vector3(0.05, sup - 0.06, 0.9), Vector3(-1.0, (sup - 0.06) / 2, 0), mat_metal, escritorio)
	_caja("BaseDer", Vector3(0.05, sup - 0.06, 0.9), Vector3(1.0, (sup - 0.06) / 2, 0), mat_metal, escritorio)
	# Bandeja de cajones a la derecha (por debajo)
	var m_caj := _mat(Color(0.30, 0.20, 0.12), 0.6)
	_caja("Cajonera", Vector3(0.5, 0.6, 0.85), Vector3(0.7, 0.3, 0), m_caj, escritorio, false)
	for k in 2:
		_caja("CajonFrente%d" % k, Vector3(0.02, 0.24, 0.7), Vector3(0.7 - 0.26, 0.15 + k * 0.3, 0), _mat(Color(0.36, 0.24, 0.14), 0.5), escritorio, false)

	# ---------------- Zona derecha: computadora CRT con teclado
	var m_crema := _mat(Color(0.62, 0.55, 0.42), 0.7)
	var pc := _nodo("ComputadoraCRT", Vector3(0.72, sup, -0.12), 20, escritorio)
	_caja("Caja", Vector3(0.5, 0.12, 0.42), Vector3(0, 0.06, 0), m_crema, pc, false)
	_caja("Monitor", Vector3(0.46, 0.42, 0.44), Vector3(0, 0.33, 0), m_crema, pc, false)
	_caja("MonitorAtras", Vector3(0.3, 0.32, 0.34), Vector3(0.3, 0.33, 0), m_crema, pc, false)
	_caja("Pantalla", Vector3(0.02, 0.32, 0.36), Vector3(-0.235, 0.34, 0), _mat(Color(0.02, 0.025, 0.02), 0.08, Color(0.02, 0.05, 0.03), 0.3, 0.6), pc, false)
	_caja("Teclado", Vector3(0.2, 0.03, 0.48), Vector3(-0.48, 0.015, 0.05), m_crema, pc, false)
	var m_teclas := _mat(Color(0.35, 0.31, 0.24), 0.8)
	for i in 4:
		_caja("Teclas%d" % i, Vector3(0.028, 0.012, 0.44), Vector3(-0.54 + i * 0.04, 0.035, 0.05), m_teclas, pc, false)
	reg(pc, "terminal_pc", "Revisar computadora", {}, 3.0, Vector3(0, 0.3, 0), pc)

	# ---------------- Zona izquierda: mapa, libreta, teléfono
	var mapa := _nodo("Mapa", Vector3(-0.4, sup + 0.003, 0.0), -10, escritorio)
	var m_tinta := _mat(Color(0.35, 0.22, 0.1), 0.9)
	_caja("Papel", Vector3(0.5, 0.005, 0.62), Vector3.ZERO, _mat(Color(0.72, 0.58, 0.34), 0.9), mapa, false)
	_toro("Emblema", 0.04, 0.08, Vector3(0, 0.012, 0.03), m_tinta, mapa)
	_caja("Marca1", Vector3(0.3, 0.004, 0.01), Vector3(0, 0.004, -0.2), m_tinta, mapa, false)
	_caja("Marca2", Vector3(0.2, 0.004, 0.01), Vector3(0.05, 0.004, -0.25), m_tinta, mapa, false)
	var plano := "[b]PLANO DEL MUSEO - PLANTA BAJA[/b]\n\n"
	plano += "[b]Sala Egipcia[/b] (al norte, marcada en rojo): la sala grande. Pedestal de Sellado frente al gran Anubis.\n"
	plano += "[b]Vestíbulo Principal[/b]: al salir de esta oficina. Recepción, entrada (sellada) y escalera de servicio.\n"
	plano += "[b]Seguridad[/b]: esta oficina, al este del vestíbulo. [b]Sala de Control[/b]: al lado, hacia el sur.\n"
	plano += "[b]Oficina de la Dra. Torres[/b] y [b]Restauración[/b]: al oeste del vestíbulo.\n\n"
	plano += "[i]Piso 2: Galería Medieval y Armería. Piso 3: Paleontología y Bóveda.[/i]"
	nota(mapa, "Mirar plano del museo", "Plano del museo", plano, "papel", "", mapa)

	var libreta := _nodo("Libreta", Vector3(-0.88, sup + 0.01, 0.3), 12, escritorio)
	_caja("Hojas", Vector3(0.2, 0.02, 0.28), Vector3.ZERO, _mat(Color(0.75, 0.7, 0.55), 0.9), libreta, false)
	_caja("Tapa", Vector3(0.21, 0.008, 0.29), Vector3(0, -0.012, 0), _mat(Color(0.15, 0.1, 0.07), 0.7), libreta, false)
	_cilindro("Lapiz", 0.006, 0.006, 0.15, Vector3(0.05, 0.016, 0.02), _mat(Color(0.75, 0.55, 0.1), 0.5), libreta, Vector3(90, 0, 20))
	var ronda := "[b]HOJA DE RONDAS - TURNO DE NOCHE[/b]\n[i]Viernes 13 de octubre de 2026 · 00:00 a 06:00[/i]\n\n"
	ronda += "00:00  Vestíbulo Principal (puertas y recepción)\n"
	ronda += "01:00  Sala Egipcia (reflectores, vitrinas, pedestales)\n"
	ronda += "02:00  Sala de Control (revisar cámaras)\n"
	ronda += "03:00  Restauración [i](NO ENTRAR: zona de la Dra. Torres)[/i]\n"
	ronda += "04:00  Vestíbulo y escalera de servicio\n"
	ronda += "05:00  Cierre de bitácora\n\n"
	ronda += "[i]Alex escribió con lápiz: «Primera noche. Que no pase nada raro.»[/i]"
	nota(libreta, "Leer hoja de rondas", "Hoja de rondas", ronda, "papel", "", libreta)

	# Carta de Roberto (la que cuenta el inicio de la historia)
	var carta := _nodo("CartaRoberto", Vector3(-0.8, sup + 0.012, -0.38), -18, escritorio)
	_caja("Papel", Vector3(0.21, 0.004, 0.3), Vector3.ZERO, _mat(Color(0.88, 0.82, 0.64), 0.95), carta, false)
	_caja("Sobre", Vector3(0.12, 0.003, 0.08), Vector3(0.05, 0.004, 0.12), _mat(Color(0.7, 0.62, 0.45), 0.9), carta, false)
	var cr := "[b]ALEX:[/b]\n\n"
	cr += "Bienvenido al turno de noche. Soy Roberto; llevo 20 años en este museo y te dejo estas notas antes de irme a casa.\n\n"
	cr += "[b]1)[/b] Haz tu ronda cada hora (la hoja está en tu libreta).\n"
	cr += "[b]2)[/b] Las luces fallan desde que instalaron el generador nuevo. No te asustes.\n"
	cr += "[b]3)[/b] Hoy llegó un paquete confidencial para la Dra. Torres. Lo dejó en Restauración. Nadie debe tocarlo.\n"
	cr += "[b]4)[/b] Si necesitas algo de su oficina, el candado usa la fecha de hoy, día y mes (cuatro dígitos). No le digas que te lo dije.\n"
	cr += "[b]5)[/b] Linterna y walkie están sobre el escritorio. Radio: canal 3.\n\n"
	cr += "Seguro no pasa nada. Los de la tarde dicen que las estatuas «se ven raras» pero ya sabes cómo son.\n\n"
	cr += "[i]P.D. Si ves algo moverse, probablemente sea el viento. En un museo cerrado. Ja.[/i]"
	nota(carta, "Leer carta de Roberto", "Carta de Roberto", cr, "papel", "— Roberto", carta, Callable(self, "_leyo_carta"))

	# Walkie-talkie (para hablar con Roberto)
	var walkie := _nodo("Walkie", Vector3(0.3, sup + 0.04, -0.38), -25, escritorio)
	var m_wk := _mat(Color(0.12, 0.12, 0.13), 0.5, Color.BLACK, 0.3)
	_caja("Cuerpo", Vector3(0.07, 0.17, 0.035), Vector3(0, 0.0, 0), m_wk, walkie, false).rotation_degrees.x = 90
	_cilindro("Antena", 0.007, 0.007, 0.12, Vector3(0.025, 0.0, -0.13), m_wk, walkie, Vector3(90, 0, 0))
	_caja("Perilla", Vector3(0.02, 0.02, 0.01), Vector3(-0.02, 0.02, -0.05), _mat(Color(0.8, 0.1, 0.1), 0.4), walkie, false)
	pickup(walkie, "Recoger walkie-talkie", "walkie", "Walkie-talkie en el cinturón. Canal 3.", 1, Callable(self, "_tomo_walkie"))

	var tel := _nodo("Telefono", Vector3(-0.9, sup, -0.2), 8, escritorio)
	var m_tel := _mat(Color(0.12, 0.10, 0.09), 0.4)
	_caja("Base", Vector3(0.17, 0.05, 0.21), Vector3(0, 0.025, 0), m_tel, tel, false)
	_caja("Auricular", Vector3(0.05, 0.03, 0.2), Vector3(0, 0.065, 0), m_tel, tel, false)

	# ---------------- Zona central: ankh sobre una base, ordenado
	var m_piedra := _mat(Color(0.62, 0.57, 0.48), 0.8)
	_caja("BaseAnkh", Vector3(0.28, 0.008, 0.42), Vector3(0.05, sup + 0.004, 0.08), _mat(Color(0.10, 0.07, 0.05), 0.7), escritorio, false)
	var ankh := _nodo("Ankh", Vector3(0.05, sup + 0.024, 0.13), -15, escritorio)
	_caja("Barra", Vector3(0.06, 0.03, 0.3), Vector3.ZERO, m_piedra, ankh, false)
	_caja("Brazos", Vector3(0.24, 0.03, 0.06), Vector3(0, 0, -0.05), m_piedra, ankh, false)
	_toro("Lazo", 0.04, 0.09, Vector3(0, 0, -0.2), m_piedra, ankh)
	examinar(ankh, "Examinar ankh", "Un ankh de piedra, réplica de la tienda del museo. Está tibio... como si algo respirara dentro.", ankh)

	# ---------------- Frente derecho: linterna y taza
	var linterna := _nodo("Linterna", Vector3(0.5, sup + 0.035, 0.33), 45, escritorio)
	var m_negro := _mat(Color(0.10, 0.10, 0.10), 0.3, Color.BLACK, 0.4)
	_cilindro("Cuerpo", 0.03, 0.03, 0.2, Vector3.ZERO, m_negro, linterna, Vector3(90, 0, 0))
	_cilindro("Cabeza", 0.05, 0.035, 0.07, Vector3(0, 0, -0.13), m_negro, linterna, Vector3(90, 0, 0))
	_cilindro("Lente", 0.045, 0.045, 0.01, Vector3(0, 0, -0.168), _mat(Color.WHITE, 0.1, Color(0.8, 0.9, 1.0), 0.0, 0.8), linterna, Vector3(90, 0, 0))
	pickup(linterna, "Recoger linterna", "linterna", "Linterna encendida  -  Clic derecho o F para apagar / prender", 1, Callable(), Vector3(0, 0, -0.05))

	var taza := _nodo("Taza", Vector3(0.95, sup, 0.32), 0, escritorio)
	_cilindro("Cuerpo", 0.04, 0.038, 0.09, Vector3(0, 0.045, 0), _mat(Color(0.75, 0.72, 0.65), 0.4), taza)
	_cilindro("Cafe", 0.034, 0.034, 0.005, Vector3(0, 0.088, 0), _mat(Color(0.08, 0.04, 0.02), 0.2), taza)
	_toro("Asa", 0.012, 0.028, Vector3(0.05, 0.045, 0), _mat(Color(0.75, 0.72, 0.65), 0.4), taza, Vector3(0, 0, 90))

	# ---------------- Frente izquierdo: lupa de escritorio (sobre el mapa, como en la referencia)
	var lupa := _nodo("LupaEscritorio", Vector3(-0.4, sup + 0.03, 0.3), 200, escritorio)
	_toro("Aro", 0.075, 0.10, Vector3.ZERO, _mat(Color(0.30, 0.16, 0.08), 0.5, Color.BLACK, 0.3), lupa)
	_caja("Mango", Vector3(0.03, 0.025, 0.2), Vector3(0, 0, 0.2), _mat(Color(0.25, 0.12, 0.06), 0.6), lupa, false)
	_cilindro("CristalLupa", 0.075, 0.075, 0.008, Vector3.ZERO, _mat_vidrio(Color(0.8, 0.9, 1.0, 0.3)), lupa)

	# ---------------- Fondo: pila de documentos y carpeta
	var docs := _nodo("Documentos", Vector3(-0.05, sup, -0.37), -5, escritorio)
	for i in 5:
		_caja("Hoja%d" % i, Vector3(0.2, 0.004, 0.26), Vector3(0.002 * i, 0.002 + i * 0.004, 0.003 * i), _mat(Color(0.82, 0.76, 0.62), 0.9), docs, false)
	_caja("Carpeta", Vector3(0.22, 0.012, 0.28), Vector3(0, 0.026, 0), _mat(Color(0.28, 0.16, 0.10), 0.7), docs, false)


func _crear_pilar_lupa_y_espejo() -> void:
	var hz := -FONDO / 2.0 + 0.55
	_caja("Pilar", Vector3(0.5, ALTO, 0.5), Vector3(PUERTA_X - 1.2, ALTO / 2.0, hz), mat_pared)
	_caja("PilarZocalo", Vector3(0.53, 0.9, 0.53), Vector3(PUERTA_X - 1.2, 0.45, hz), mat_zocalo, null, false)

	var m_negro := _mat(Color(0.08, 0.07, 0.06), 0.5, Color.BLACK, 0.3)
	var lupa := _nodo("LupaGrande", Vector3(-0.2, 0, -1.3), 25)
	lupa.rotation_degrees = Vector3(-14, 25, 6)
	_cilindro("Mango", 0.018, 0.022, 1.3, Vector3(0, 0.65, 0), m_negro, lupa)
	_toro("Aro", 0.17, 0.21, Vector3(0, 1.5, 0), _mat(Color(0.28, 0.27, 0.26), 0.35, Color.BLACK, 0.8), lupa, Vector3(90, 0, 0))
	_cilindro("Vidrio", 0.17, 0.17, 0.01, Vector3(0, 1.5, 0), _mat_vidrio(Color(0.7, 0.8, 0.85, 0.25)), lupa, Vector3(90, 0, 0))
	examinar(lupa, "Mirar lupa", "Una lupa enorme. Todo se ve borroso a través del cristal.", lupa, Vector3(0, 1.2, 0))

	var espejo := _nodo("Espejo", Vector3(0.22, 0, -1.5))
	espejo.rotation_degrees = Vector3(-10, -15, 0)
	_caja("Marco", Vector3(0.46, 0.86, 0.03), Vector3(0, 0.45, 0), _mat(Color(0.10, 0.08, 0.07), 0.5, Color.BLACK, 0.3), espejo, false)
	_caja("Cristal", Vector3(0.38, 0.78, 0.035), Vector3(0, 0.45, 0.002), _mat(Color(0.85, 0.9, 0.95), 0.03, Color.BLACK, 1.0), espejo, false)
	pickup(espejo, "Recoger espejo de inspección", "espejo", "Espejo de inspección. Alex: «Con esto puedo vigilar mis espaldas.»", 1, Callable(), Vector3(0, 0.45, 0))


func _crear_rejilla_verde() -> void:
	var raiz := _nodo("RejillaVerde", Vector3(1.0, 0.0, -1.5))
	_caja("Placa", Vector3(0.6, 0.012, 0.4), Vector3(0, 0.006, 0), _mat(Color(0.05, 0.06, 0.05), 0.5, Color.BLACK, 0.5), raiz, false)
	var m_verde := _mat(Color(0.1, 0.4, 0.15), 0.4, Color(0.2, 1.0, 0.35), 0.0, 3.0)
	for i in 6:
		_caja("Barra%d" % i, Vector3(0.03, 0.005, 0.28), Vector3(-0.22 + i * 0.088, 0.014, 0), m_verde, raiz, false)
	var l := OmniLight3D.new()
	l.position = Vector3(0, 0.15, 0)
	l.omni_range = 1.5
	l.light_color = Color(0.2, 1.0, 0.35)
	l.light_energy = 0.4
	raiz.add_child(l)

## Motas de polvo dentro del cono de luz.


## Motas de polvo dentro del cono de luz.
func _crear_polvo() -> void:
	var p := GPUParticles3D.new()
	p.name = "Polvo"
	p.position = Vector3(0.2, 1.4, 0.5)
	p.amount = 80
	p.lifetime = 10.0
	p.preprocess = 10.0
	p.visibility_aabb = AABB(Vector3(-3, -3, -3), Vector3(6, 6, 6))
	var pm := ParticleProcessMaterial.new()
	pm.emission_shape = ParticleProcessMaterial.EMISSION_SHAPE_BOX
	pm.emission_box_extents = Vector3(1.2, 1.2, 1.2)
	pm.gravity = Vector3.ZERO
	pm.direction = Vector3(0.3, 0.1, 0.0)
	pm.spread = 180.0
	pm.initial_velocity_min = 0.01
	pm.initial_velocity_max = 0.05
	p.process_material = pm
	var qm := QuadMesh.new()
	qm.size = Vector2(0.012, 0.012)
	var dm := StandardMaterial3D.new()
	dm.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	dm.billboard_mode = BaseMaterial3D.BILLBOARD_ENABLED
	dm.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	dm.albedo_color = Color(1.0, 0.85, 0.6, 0.6)
	qm.material = dm
	p.draw_pass_1 = qm
	add_child(p)


# ---------------------------------------------------------------- acciones

func _accion_puerta(manual: bool = true) -> void:
	_puerta_abierta = not _puerta_abierta
	if manual:
		# Si la cierras a mano, no se vuelve a abrir sola por un buen rato
		_bloqueo_auto = 0.0 if _puerta_abierta else 30.0
	var destino := -75.0 if _puerta_abierta else 0.0
	if _tween_puerta and _tween_puerta.is_valid():
		_tween_puerta.kill()
	_tween_puerta = create_tween()
	_tween_puerta.tween_property(_nodo_bisagra, "rotation_degrees:y", destino, 0.6).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)


func _accion_luz() -> void:
	_luz_encendida = not _luz_encendida
	for l in _luces_oficina:
		l.visible = _luz_encendida
	_mat_lampara.emission_energy_multiplier = 1.6 if _luz_encendida else 0.0
	_boton_int.position.y += (0.04 if _luz_encendida else -0.04)


# ---------------------------------------------------------------- historia: pared frontal, consola y radio

func _crear_pared_frente() -> void:
	var z := FONDO / 2.0 - 0.02
	# Calendario de pared: el 13 de octubre esta marcado en rojo
	var cal := _nodo("Calendario", Vector3(-1.1, 1.55, z), 180)
	_caja("Hoja", Vector3(0.42, 0.56, 0.015), Vector3.ZERO, _mat(Color(0.9, 0.88, 0.8), 0.9), cal, false)
	_caja("Cabecera", Vector3(0.42, 0.12, 0.016), Vector3(0, 0.22, 0.002), _mat(Color(0.5, 0.1, 0.1), 0.8), cal, false)
	_label_poster(cal, "OCT 2026", Vector3(0, 0.22, 0.012), 34, Color(0.95, 0.9, 0.8), 0.0)
	_label_poster(cal, "13", Vector3(0, -0.02, 0.012), 130, Color(0.7, 0.08, 0.08), 2.0)
	_label_poster(cal, "VIERNES", Vector3(0, -0.21, 0.012), 38, Color(0.15, 0.1, 0.08), 0.0)
	var tc := "[b]OCTUBRE 2026[/b]\n\n"
	tc += "El [b]viernes 13[/b] está marcado con un círculo rojo.\n\n"
	tc += "Debajo, con letra de Alex: «Primer turno de noche. ¡Por fin un trabajo!»\n\n"
	tc += "[i]Fecha de hoy: 13 de octubre → día 13, mes 10.[/i]"
	nota(cal, "Mirar calendario", "Calendario", tc, "papel", "", cal)

	# Corcho con avisos (protocolo de emergencia)
	var cork := _nodo("Corcho", Vector3(0.7, 1.65, z), 180)
	_caja("Marco", Vector3(1.1, 0.75, 0.03), Vector3.ZERO, mat_zocalo, cork, false)
	_caja("Fondo", Vector3(1.0, 0.65, 0.02), Vector3(0, 0, 0.006), _mat(Color(0.55, 0.38, 0.2), 1.0), cork, false)
	var papeles: Array[Color] = [Color(0.88, 0.84, 0.7), Color(0.9, 0.9, 0.8), Color(0.85, 0.7, 0.45), Color(0.8, 0.88, 0.9)]
	for k in 4:
		var px := -0.32 + (k % 2) * 0.55
		var py := 0.12 - (k / 2) * 0.28
		_caja("Aviso%d" % k, Vector3(0.28, 0.22, 0.004), Vector3(px, py, 0.02), _mat(papeles[k], 0.95), cork, false).rotation_degrees.z = (k - 1.5) * 4.0
		_caja("Chinche%d" % k, Vector3(0.02, 0.02, 0.012), Vector3(px, py + 0.08, 0.026), _mat(Color(0.8, 0.1, 0.1), 0.5), cork, false)
	var ta := "[b]AVISO INTERNO - PROTOCOLO SEG-13[/b]\n\n"
	ta += "En caso de [b]falla de energía principal[/b], el edificio activa el bloqueo de emergencia:\n"
	ta += "· Las salidas se sellan automáticamente.\n"
	ta += "· El bloqueo se libera solo a las [b]06:00[/b].\n"
	ta += "· Los elevadores quedan fuera de servicio; usar la escalera de servicio (con tarjeta).\n\n"
	ta += "[b]AVISO DE LA CURADORA:[/b] Prohibido tocar el paquete de Restauración. Atte. Dra. E. Torres.\n\n"
	ta += "[i]Recordatorio: pilas de repuesto en recepción y en la sala de control.[/i]"
	nota(cork, "Leer avisos del corcho", "Avisos", ta, "papel", "", cork)


func _crear_consola_camaras() -> void:
	if cctv == null:
		return
	# Consola contra la pared del fondo (izquierda del pilar) con los monitores de las camaras
	var c := _nodo("ConsolaCamaras", Vector3(-1.45, 0, -1.98))
	_caja("Mueble", Vector3(1.9, 0.75, 0.5), Vector3(0, 0.375, 0), mat_metal, c, true)
	_caja("Tapa", Vector3(2.0, 0.05, 0.56), Vector3(0, 0.775, 0), _mat(Color(0.1, 0.1, 0.11), 0.4, Color.BLACK, 0.3), c, false)
	_caja("Estante", Vector3(1.9, 0.04, 0.3), Vector3(0, 1.5, -0.1), mat_metal, c, false)
	_caja("Teclado", Vector3(0.45, 0.025, 0.16), Vector3(0.1, 0.815, 0.12), _mat(Color(0.62, 0.55, 0.42), 0.7), c, false)
	for x in [-0.65, 0.0, 0.65]:
		_caja("Soporte", Vector3(0.14, 0.07, 0.14), Vector3(x, 0.835, -0.02), _mat(Color(0.2, 0.19, 0.17), 0.6), c, false)
	var feeds_bajos := [0, 1, 2]
	var xs := [-0.65, 0.0, 0.65]
	for i in 3:
		var mon := cctv.crear_monitor(c, Vector3(xs[i], 1.1, 0.0), 0.0, 0.5, feeds_bajos[i])
		if i == 1:
			_monitor_consola = mon
	cctv.crear_monitor(c, Vector3(-0.4, 1.78, -0.12), 0.0, 0.5, 3)
	cctv.crear_monitor(c, Vector3(0.4, 1.78, -0.12), 0.0, 0.5, 4)
	if not _monitor_consola.is_empty():
		var raiz := _monitor_consola["raiz"] as Node3D
		reg(raiz, "camara", "Cambiar de cámara", {}, 3.2, Vector3(0, -0.3, 0.3), raiz)
	# Letrero de la consola
	_label_poster(c, "CÁMARAS", Vector3(0.0, 0.62, 0.26), 40, Color(0.7, 0.95, 0.8), 0.0)


func _registrar_pared_derecha() -> void:
	var deco := get_node_or_null("ParedDerechaDeco")
	if deco == null:
		return
	var reloj := deco.get_node_or_null("Reloj") as Node3D
	if reloj:
		reg(reloj, "reloj", "Ver reloj", {}, 3.4, Vector3.ZERO, reloj)
	var tablero := deco.get_node_or_null("TableroLlaves") as Node3D
	if tablero:
		var t := "[b]TABLERO DE LLAVES[/b]\n\n"
		t += "Cuatro ganchos. Etiquetas escritas a mano:\n\n"
		t += "1. [b]Vestíbulo[/b] ......... colgada\n"
		t += "2. [b]Sala de Control[/b] ... colgada\n"
		t += "3. [b]Restauración[/b] ...... [color=#a33]FALTA[/color]  (la tiene la Dra. Torres)\n"
		t += "4. [b]Bóveda[/b] ............ [color=#a33]FALTA[/color]\n\n"
		t += "[i]Se necesita una tarjeta de acceso para esas puertas.[/i]"
		nota(tablero, "Revisar tablero de llaves", "Tablero de llaves", t, "papel", "", tablero)
	var radio_base := deco.get_node_or_null("Radio") as Node3D
	if radio_base:
		reg(radio_base, "radio_base", "Escuchar radio", {}, 3.4, Vector3.ZERO, radio_base)


# ---------------------------------------------------------------- historia: eventos

func _leyo_carta() -> void:
	estado.radio_una_vez("carta", "ROBERTO (radio): «¿Leíste mi carta? Lo del candado va en serio: la fecha de hoy. Y nada de curiosear en Restauración, ¿eh?»")


func _tomo_walkie() -> void:
	Sfx.tocar("static")
	estado.radio_una_vez("walkie", "ROBERTO (walkie): «Alex, ¿me copias? Perfecto, canal 3. Si ves algo raro avísame... aunque seguro es el viento, jaja.»")


func _pantalla_pc() -> void:
	Sfx.tocar("tecla")
	var t := "MUSEO METROPOLITANO - ESTACIÓN DE SEGURIDAD\n"
	t += "USUARIO: GUARDIA_NOCTURNO      %s\n" % estado.hora_con_segundos()
	t += "------------------------------------------------\n"
	t += "> ESTADO DEL EDIFICIO\n"
	t += "  ENERGÍA PRINCIPAL ........... FALLA (00:00)\n"
	t += "  GENERADOR DE EMERGENCIA ..... ACTIVO (INESTABLE)\n"
	t += "  SALIDAS DE EMERGENCIA ....... BLOQUEADAS (SEG-13)\n"
	t += "  LIBERACIÓN AUTOMÁTICA ....... 06:00\n"
	t += "> MENSAJES\n"
	t += "  [R. CASTILLO] Alex, bienvenido. Mira mi carta\n"
	t += "  en el escritorio. Radio en canal 3.\n"
	t += "  [SISTEMA] Intrusión: NINGUNA.\n"
	t += "  [SISTEMA] Movimiento anómalo: SALA EGIPCIA.\n"
	estado.nota.emit({"titulo": "SEGURIDAD > TERMINAL", "texto": t, "estilo": "terminal", "firma": ""})


# ---------------------------------------------------------------- API para museum.gd

func punto_de_aparicion() -> Vector3:
	return to_global(SPAWN_LOCAL)


func interactuar(it: Dictionary) -> void:
	match String(it["tipo"]):
		"puerta_oficina":
			_accion_puerta()
		"interruptor":
			_accion_luz()
		"terminal_pc":
			_pantalla_pc()
		"reloj":
			estado.mensaje.emit("Reloj de pared: %s. Faltan %s para las 06:00." % [estado.hora_texto(), estado.faltan_texto()])
		"radio_base":
			Sfx.tocar("static")
			estado.radio_una_vez("inicio", "RADIO (base): «Alex, soy Roberto... ¿me escuchas? Recoge tu walkie y tu linterna del escritorio. Y lee mi carta.»")
			estado.mensaje.emit("La radio de la oficina solo da estática y la voz de Roberto a ratos.")
		"camara":
			var nombre := cctv.siguiente_feed(_monitor_consola)
			Sfx.tocar("tecla")
			estado.mensaje.emit("Monitor: " + nombre)
		_:
			super.interactuar(it)


## Llamar cada frame de fisica: puerta automatica y parpadeo de la luz fria de la sala.
func actualizar(delta: float, pos_jugador: Vector3) -> void:
	if _luz_pasillo:
		_luz_pasillo.light_energy = 3.0 + sin(_t * 9.0) * 0.2 + sin(_t * 23.0) * 0.12

	_bloqueo_auto = maxf(0.0, _bloqueo_auto - delta)
	if puerta_automatica and not _puerta_abierta and _bloqueo_auto <= 0.0:
		var rel := to_local(pos_jugador)
		var dx := rel.x - PUERTA_X
		var dz := rel.z - (-FONDO / 2.0)
		if Vector2(dx, dz).length() < 1.9:
			_accion_puerta(false)
