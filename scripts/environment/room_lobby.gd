extends "res://scripts/environment/room_base.gd"

## VESTIBULO PRINCIPAL (planta baja). Esta pegado a la pared sur de la Sala Egipcia
## (se une por un arco) y desde aqui salen todas las puertas del primer piso:
##   este  -> oficina de seguridad (puerta) y sala de control (entrada abierta)
##   oeste -> oficina de la Dra. Torres (candado) y Sala de Restauracion (tarjeta dorada)
##   sur   -> escalera de servicio (tarjeta azul) y las puertas principales (selladas)

const X0 := -9.0
const X1 := 9.0
const Z0 := 16.25
const Z1 := 30.25
const EstatuaEnemiga = preload("res://scripts/enemies/estatua_enemiga.gd")
const Modelos = preload("res://scripts/environment/estatua_modelos.gd")

const H := 6.0
const T := 0.5
const TOP := 6.4           # altura total de las paredes (incluye el techo)

const ARCH_HALF := 2.6     # medio ancho del arco hacia la Sala Egipcia
const ARCH_H := 4.6

# Huecos de las paredes (coordenadas del mundo)
const OFICINA_Z := 22.0           # centro de la puerta de la oficina de seguridad (pared este)
const OFICINA_W := 1.46
const CONTROL_A := 28.0           # entrada a la sala de control (pared este)
const CONTROL_B := 29.6
const ELENA_A := 19.8             # oficina de la Dra. Torres (pared oeste)
const ELENA_B := 21.2
const REST_A := 26.7              # sala de restauracion (pared oeste)
const REST_B := 28.3
const ESC_A := -7.875             # escalera de servicio, alineada con el primer tramo
const ESC_B := -6.075             # hueco de 1.8 m centrado en el carril de subida

var _cuenta: Label3D
var _luz_emergencia: OmniLight3D
var _t_emerg := 0.0


func build() -> void:
	var piedra := u.stone(Color(0.9, 0.84, 0.76), 0.25)
	var piedra_osc := u.stone(Color(0.32, 0.30, 0.34), 0.25)

	# ---- suelo (marmol del museo, mismo patron que la sala) y techo
	u.box(self, Vector3(0, -0.25, 23.5), Vector3(19.0, 0.5, 15.0), u.marble(), true, Vector3.ZERO, "Piso")
	u.box(self, Vector3(9.5, -0.25, OFICINA_Z), Vector3(0.4, 0.5, 1.6), u.marble(), true, Vector3.ZERO, "UmbralOficina")
	u.box(self, Vector3(0, H + 0.2, 23.5), Vector3(19.0, 0.4, 15.0), piedra_osc, true, Vector3.ZERO, "Techo")
	for z in [19.0, 23.0, 27.0]:
		u.box(self, Vector3(0, H - 0.25, z), Vector3(19.0, 0.45, 0.5), u.wood())

	# ---- paredes con sus huecos (la pared norte es la de la Sala Egipcia, con el arco)
	wall_x(30.5, -9.5, 9.5, T, TOP, piedra, [{"a": ESC_A, "b": ESC_B, "h": 2.5}])
	wall_z(-9.25, Z0, 30.75, T, TOP, piedra, [
		{"a": ELENA_A, "b": ELENA_B, "h": 2.4},
		{"a": REST_A, "b": REST_B, "h": 2.8},
	])
	wall_z(9.25, Z0, 30.75, T, TOP, piedra, [
		{"a": OFICINA_Z - OFICINA_W / 2.0, "b": OFICINA_Z + OFICINA_W / 2.0, "h": 2.3},
		{"a": CONTROL_A, "b": CONTROL_B, "h": 2.8},
	])

	# ---- decoracion de paredes: zocalo de madera, liston dorado y banda de jeroglificos
	zocalo_x(Z0, 1.0, X0, X1, [{"a": -ARCH_HALF, "b": ARCH_HALF}])
	zocalo_x(30.25, -1.0, X0, X1, [{"a": ESC_A - 0.1, "b": ESC_B + 0.1}])
	zocalo_z(-9.0, 1.0, Z0, 30.25, [{"a": ELENA_A - 0.1, "b": ELENA_B + 0.1}, {"a": REST_A - 0.1, "b": REST_B + 0.1}])
	zocalo_z(9.0, -1.0, Z0, 30.25, [
		{"a": OFICINA_Z - 0.83, "b": OFICINA_Z + 0.83},
		{"a": CONTROL_A - 0.1, "b": CONTROL_B + 0.1},
	])
	banda(Vector3(0, 4.95, Z0 + 0.012), 0.0, 18.0, 0.56)
	banda(Vector3(0, 4.95, 30.25 - 0.012), 180.0, 18.0, 0.56)
	banda(Vector3(-9.0 + 0.012, 4.95, 23.25), 90.0, 14.0, 0.56)
	banda(Vector3(9.0 - 0.012, 4.95, 23.25), -90.0, 14.0, 0.56)
	_estandartes()

	_marcos_y_letreros()
	_lamparas()
	_puertas_internas()
	_puertas_principales()
	_recepcion()
	_mobiliario()


# ---------------------------------------------------------------- estructura

func _estandartes() -> void:
	var rojo := u.mat(Color(0.55, 0.05, 0.07), 1.0)
	var oro := u.gold()
	for p in [[-9.0, 17.6, 1.0], [-9.0, 24.2, 1.0], [9.0, 17.6, -1.0], [9.0, 25.4, -1.0]]:
		var lado: float = p[2]
		var b := u.node3d(self, "Estandarte", Vector3(float(p[0]) + 0.06 * lado, 0.0, float(p[1])))
		u.box(b, Vector3(0, 3.5, 0), Vector3(0.05, 2.4, 1.1), rojo)
		u.box(b, Vector3(0.03 * lado, 4.72, 0), Vector3(0.1, 0.1, 1.3), oro)
		u.box(b, Vector3(0.03 * lado, 2.3, 0), Vector3(0.08, 0.1, 1.1), oro)
		u.box(b, Vector3(0.03 * lado, 3.5, 0), Vector3(0.03, 0.45, 0.45), oro, false, Vector3(45, 0, 0))


func _marco(pos: Vector3, ancho: float, alto: float, rot_y: float) -> void:
	# Marco oscuro con dintel dorado alrededor de un hueco (se ve desde el vestibulo).
	var r := u.node3d(self, "Marco", pos, rot_y)
	var osc := u.mat(Color(0.09, 0.07, 0.06), 0.7)
	u.box(r, Vector3(-ancho / 2.0 - 0.04, alto / 2.0, 0), Vector3(0.08, alto, 0.2), osc)
	u.box(r, Vector3(ancho / 2.0 + 0.04, alto / 2.0, 0), Vector3(0.08, alto, 0.2), osc)
	u.box(r, Vector3(0, alto + 0.04, 0), Vector3(ancho + 0.16, 0.08, 0.2), u.gold())


func _letrero(texto: String, pos: Vector3, rot_y: float, ancho: float) -> void:
	var r := u.node3d(self, "Letrero", pos, rot_y)
	u.box(r, Vector3.ZERO, Vector3(ancho, 0.34, 0.05), u.gold())
	u.text3d(r, texto, Vector3(0, 0, 0.03), 0.0, 40, Color(0.10, 0.06, 0.02), 0.0042)


func _marcos_y_letreros() -> void:
	# Arco a la Sala Egipcia (el hueco ya lo abre museum_builder)
	_letrero("SALA EGIPCIA", Vector3(0, ARCH_H + 0.55, Z0 + 0.06), 0.0, 3.4)
	# Oficina de seguridad (pared este)
	_marco(Vector3(9.0, 0, OFICINA_Z), OFICINA_W, 2.3, -90.0)
	_letrero("SEGURIDAD", Vector3(8.94, 2.75, OFICINA_Z), -90.0, 1.7)
	# Sala de control (pared este)
	_marco(Vector3(9.0, 0, (CONTROL_A + CONTROL_B) / 2.0), CONTROL_B - CONTROL_A, 2.8, -90.0)
	_letrero("SALA DE CONTROL", Vector3(8.94, 3.25, (CONTROL_A + CONTROL_B) / 2.0), -90.0, 2.4)
	# Oficina de la doctora y restauracion (pared oeste)
	_marco(Vector3(-9.0, 0, (ELENA_A + ELENA_B) / 2.0), ELENA_B - ELENA_A, 2.4, 90.0)
	_letrero("DRA. E. TORRES", Vector3(-8.94, 2.85, (ELENA_A + ELENA_B) / 2.0), 90.0, 1.9)
	_marco(Vector3(-9.0, 0, (REST_A + REST_B) / 2.0), REST_B - REST_A, 2.8, 90.0)
	_letrero("RESTAURACIÓN - ACCESO RESTRINGIDO", Vector3(-8.94, 3.25, (REST_A + REST_B) / 2.0), 90.0, 3.6)
	# Escalera de servicio (pared sur)
	_marco(Vector3((ESC_A + ESC_B) / 2.0, 0, 30.25), ESC_B - ESC_A, 2.5, 180.0)
	_letrero("ESCALERA DE SERVICIO - NIVEL 2", Vector3((ESC_A + ESC_B) / 2.0, 2.95, 30.19), 180.0, 3.6)
	# Marco dorado del arco (lado vestibulo)
	for s in [-1.0, 1.0]:
		u.box(self, Vector3(s * (ARCH_HALF + 0.1), ARCH_H / 2.0, Z0 + 0.12), Vector3(0.2, ARCH_H, 0.24), u.gold())
	u.box(self, Vector3(0, ARCH_H + 0.1, Z0 + 0.12), Vector3(ARCH_HALF * 2.0 + 0.4, 0.2, 0.24), u.gold())


func _lamparas() -> void:
	var emis := emisivo(u.mat(Color(0.2, 0.12, 0.06), 0.6, 0.0, Color(1.0, 0.58, 0.25), 1.1))
	for p in [[-5.5, 19.5], [5.5, 19.5], [-5.5, 26.5], [5.5, 26.5], [0.0, 23.0]]:
		var x: float = p[0]
		var z: float = p[1]
		u.cyl(self, Vector3(x, H - 0.55, z), 0.01, 0.01, 1.1, u.dark())
		u.cyl(self, Vector3(x, H - 1.2, z), 0.18, 0.5, 0.35, emis, Vector3.ZERO, 12)
		var l := u.omni(self, Vector3(x, H - 1.4, z), Color(1.0, 0.7, 0.4), 1.9, 11.0)
		if x != 0.0:
			parpadear(l, 5.0 + abs(x), x < 0.0 and z > 25.0)
	# Luz de emergencia roja sobre las puertas principales (pulsa)
	_luz_emergencia = luz_fija(u.omni(self, Vector3(0, 4.3, 29.3), Color(1.0, 0.1, 0.08), 1.4, 7.5)) as OmniLight3D
	u.omni(self, Vector3(0, 3.4, 23.5), Color(1.0, 0.75, 0.5), 0.6, 12.0)
	# Un toque frio (luz de luna que entra por el arco desde la sala)
	luz_fija(u.omni(self, Vector3(0, 3.8, 17.2), Color(0.35, 0.5, 1.0), 0.8, 7.0))


func _procesar(delta: float) -> void:
	_t_emerg += delta
	if _luz_emergencia:
		_luz_emergencia.light_energy = 0.9 + 0.8 * (0.5 + 0.5 * sin(_t_emerg * 3.0))


## museum.gd llama a esto cada segundo con el tiempo que falta para las 06:00.
func set_cuenta_regresiva(faltan: String) -> void:
	if _cuenta:
		_cuenta.text = "SALIDAS BLOQUEADAS\nPROTOCOLO SEG-13\nSE LIBERAN EN  %s" % faltan


# ---------------------------------------------------------------- puertas

func _puertas_internas() -> void:
	var hoja := u.mat(Color(0.22, 0.14, 0.09), 0.6, 0.2)
	var metal := u.mat(Color(0.20, 0.21, 0.23), 0.5, 0.6)

	# Oficina de la Dra. Torres: candado de 4 digitos (la fecha de hoy: 13 de octubre -> 1310)
	var d1 := crear_puerta("PuertaElena", Vector3(-9.25, 0, ELENA_A), -90.0, ELENA_B - ELENA_A, 2.4, -90.0, hoja, "candado", {
		"codigo": "1310",
		"titulo": "CANDADO - OFICINA DRA. TORRES",
		"pista": "Combinación de cuatro dígitos. Roberto dijo: «la fecha de hoy, día y mes».",
		"al_abrir": Callable(self, "_abrio_elena"),
	})
	u.box(self, Vector3(-9.2, 1.0, ELENA_A + 0.15), Vector3(0.14, 0.16, 0.1), u.metal(Color(0.7, 0.55, 0.2)))
	d1["it"]["texto"] = "Puerta con candado"

	# Sala de Restauracion: lector de tarjetas (tarjeta dorada)
	var d2 := crear_puerta("PuertaRestauracion", Vector3(-9.25, 0, REST_A), -90.0, REST_B - REST_A, 2.8, -90.0, metal, "tarjeta", {
		"item_req": "tarjeta_dorada",
		"msg_falta": "Lector de acceso: se necesita la tarjeta dorada (Restauración).",
		"al_abrir": Callable(self, "_abrio_restauracion"),
	})
	lector_tarjeta(d2, Vector3(-9.0 + 0.04, 1.25, REST_A - 0.25), 90.0)

	# Escalera de servicio: lector de tarjetas (tarjeta azul, Nivel 1)
	var d3 := crear_puerta("PuertaEscalera", Vector3(ESC_A, 0, 30.5), 0.0, ESC_B - ESC_A, 2.5, 90.0, metal, "tarjeta", {
		"item_req": "tarjeta_azul",
		"msg_falta": "Lector de acceso: se necesita la tarjeta de acceso Nivel 1.",
		"al_abrir": Callable(self, "_abrio_escalera"),
	})
	lector_tarjeta(d3, Vector3(ESC_B + 0.35, 1.25, 30.25 - 0.04), 180.0)


func _abrio_elena() -> void:
	estado.poner_flag("oficina_elena_abierta")
	estado.mensaje.emit("Alex: «Bien... el candado cedió. Qué fácil.»")
	estado.radio_una_vez("elena", "ROBERTO (radio): «¿Abriste ya la oficina de la doctora? No le digas que te di el código, ¿eh?»")


func _abrio_restauracion() -> void:
	estado.poner_flag("restauracion_abierta")
	estado.mensaje.emit("Acceso concedido. Sala de Restauración.")


func _abrio_escalera() -> void:
	estado.poner_flag("escalera_abierta")
	estado.mensaje.emit("Acceso concedido. Escalera de servicio.")


func _puertas_principales() -> void:
	# Puertas dobles de la entrada, selladas por el protocolo de emergencia
	var metal := u.mat(Color(0.16, 0.17, 0.19), 0.45, 0.7)
	var raiz := u.node3d(self, "PuertasPrincipales", Vector3(0, 0, 30.1))
	u.box(raiz, Vector3(0, 2.1, 0.08), Vector3(5.2, 4.2, 0.2), u.dark())
	for s in [-1.0, 1.0]:
		u.box(raiz, Vector3(s * 1.2, 1.95, 0), Vector3(2.3, 3.9, 0.12), metal)
		u.box(raiz, Vector3(s * 1.2, 2.6, -0.07), Vector3(1.6, 1.4, 0.02), u.mat(Color(0.04, 0.06, 0.12), 0.1, 0.0, Color(0.05, 0.1, 0.25), 0.6))
		for y in [0.9, 1.5, 3.3]:
			u.box(raiz, Vector3(s * 1.2, y, -0.075), Vector3(2.1, 0.07, 0.03), u.gold())
	u.box(raiz, Vector3(0, 1.1, -0.12), Vector3(0.1, 0.5, 0.1), u.gold())
	# Barra de bloqueo roja
	u.box(raiz, Vector3(0, 2.0, -0.12), Vector3(4.6, 0.12, 0.06), u.mat(Color(0.5, 0.02, 0.02), 0.4, 0.2, Color(1.0, 0.05, 0.05), 1.2))
	_cuenta = u.text3d(raiz, "SALIDAS BLOQUEADAS\nPROTOCOLO SEG-13\nSE LIBERAN EN  06:00", Vector3(0, 4.55, -0.12), 180.0, 44, Color(1.0, 0.18, 0.12), 0.0045)
	var obj := u.node3d(self, "PuertasPrincipales_Objetivo", Vector3(0, 1.4, 29.7))
	examinar(obj, "Examinar puertas principales", "Las puertas están selladas (Protocolo SEG-13). El bloqueo se libera a las 06:00. Alex: «Genial... estoy atrapado.»")


# ---------------------------------------------------------------- recepcion y mobiliario

func _recepcion() -> void:
	var r := u.node3d(self, "Recepcion", Vector3(-5.0, 0, 25.0))
	var piedra_osc := u.stone(Color(0.35, 0.33, 0.38), 0.3)
	u.box(r, Vector3(0, 0.5, 0), Vector3(4.0, 1.0, 0.9), u.wood(), true)
	u.box(r, Vector3(0, 0.55, 0.47), Vector3(3.8, 0.8, 0.04), piedra_osc)
	u.box(r, Vector3(0, 1.03, 0.04), Vector3(4.2, 0.07, 1.1), u.mat(Color(0.5, 0.42, 0.36), 0.35, 0.1))
	u.box(r, Vector3(0, 1.075, 0.04), Vector3(4.24, 0.03, 1.14), u.gold())
	u.text3d(r, "RECEPCIÓN", Vector3(0, 1.25, 0.58), 0.0, 36, Color(0.9, 0.7, 0.3), 0.004)
	u.box(r, Vector3(0, 1.15, 0.57), Vector3(1.5, 0.28, 0.03), u.dark())

	# Computadora CRT de la recepcion (mira hacia el visitante: +z local)
	var crema := u.mat(Color(0.62, 0.55, 0.42), 0.7)
	u.box(r, Vector3(-1.4, 1.2, -0.1), Vector3(0.42, 0.34, 0.4), crema)
	u.box(r, Vector3(-1.4, 1.2, 0.11), Vector3(0.32, 0.24, 0.02), u.mat(Color(0.02, 0.05, 0.03), 0.1, 0.0, Color(0.1, 0.35, 0.2), 0.8))
	u.box(r, Vector3(-1.4, 1.12, 0.3), Vector3(0.4, 0.03, 0.14), crema)
	# Telefono y campanilla
	u.box(r, Vector3(1.55, 1.1, -0.15), Vector3(0.2, 0.08, 0.22), u.mat(Color(0.1, 0.09, 0.08), 0.4))
	u.cyl(r, Vector3(1.0, 1.11, 0.15), 0.05, 0.06, 0.05, u.gold())

	# Libro de registro de visitas (nota)
	var libro := hoja_papel(r, Vector3(-0.3, 1.095, 0.1), 10.0, Vector2(0.3, 0.22), Color(0.3, 0.2, 0.12))
	var texto := "[b]LIBRO DE REGISTRO - VESTÍBULO PRINCIPAL[/b]\n\n"
	texto += "Jue 12/10  17:40 · Grupo escolar (32 alumnos) · Sala Egipcia\n"
	texto += "Jue 12/10  19:30 · Empresa de seguridad · Cambio del generador de emergencia\n"
	texto += "Vie 13/10  22:50 · [b]Dra. E. Torres[/b] · Entra con caja de transporte sellada, «CONFIDENCIAL». Destino: Restauración\n"
	texto += "Vie 13/10  23:40 · Mensajería «Nilo Express» · Entrega firmada por la Dra. Torres\n"
	texto += "Vie 13/10  23:55 · Roberto C. · Fin de turno. Sale\n\n"
	texto += "Salida de la Dra. Torres: ________ [i](sin registro)[/i]\n\n"
	texto += "[i]Nota al margen, letra de Roberto: «Alex, después de las 00:00 no dejes entrar a nadie.»[/i]"
	nota(libro, "Leer libro de registro", "Libro de visitas", texto, "papel", "", libro)

	# Pilas AA sobre el mostrador (recargan la linterna)
	for x in [0.55, 1.3]:
		var pilas := u.box(r, Vector3(x, 1.12, -0.1), Vector3(0.12, 0.05, 0.07), u.mat(Color(0.1, 0.35, 0.2), 0.4, 0.2, Color(0.3, 1.0, 0.5), 0.3))
		pickup(pilas, "Tomar pilas AA", "baterias", "Pilas AA: la linterna recupera carga.", 1)
	# Sillas detras del mostrador
	silla(Vector3(-5.0, 0, 23.9), 180.0, Color(0.15, 0.17, 0.25))

	# Directorio del museo (pared sur, a la derecha de las puertas)
	var dir := u.node3d(self, "Directorio", Vector3(5.2, 0, 30.12))
	u.box(dir, Vector3(0, 1.6, 0), Vector3(1.6, 1.1, 0.06), u.dark())
	var papel := u.box(dir, Vector3(0, 1.6, -0.035), Vector3(1.4, 0.9, 0.01), u.mat(Color(0.82, 0.76, 0.58), 0.9))
	papel.rotation_degrees.y = 180.0
	u.text3d(dir, "DIRECTORIO", Vector3(0, 1.95, -0.05), 180.0, 38, Color(0.15, 0.08, 0.04), 0.0035)
	var cuerpo := "[b]MUSEO DE HISTORIA Y ANTIGÜEDADES METROPOLITANAS[/b]\n\n"
	cuerpo += "[b]PLANTA BAJA[/b]   Vestíbulo · Sala Egipcia · Seguridad · Sala de Control · Oficinas · Restauración\n\n"
	cuerpo += "[b]PISO 2[/b]   Galería Medieval · Armería\n\n"
	cuerpo += "[b]PISO 3[/b]   Pabellón de Paleontología y Antigüedades · Bóveda de Contención\n\n"
	cuerpo += "Escalera de servicio junto a la entrada: acceso con tarjeta.\nHorario: martes a domingo, 9:00 a 18:00."
	var dobj := u.node3d(self, "Directorio_Objetivo", Vector3(5.2, 1.5, 29.7))
	nota(dobj, "Leer directorio", "Directorio del museo", cuerpo, "papel")


func _mobiliario() -> void:
	var cuero := u.mat(Color(0.09, 0.05, 0.04), 0.6)
	# Bancas contra la pared este
	for z in [18.4, 25.4]:
		var b := u.node3d(self, "Banca", Vector3(8.3, 0, z))
		u.box(b, Vector3(0, 0.25, 0), Vector3(0.6, 0.5, 2.0), u.wood(), true)
		u.box(b, Vector3(0, 0.52, 0), Vector3(0.55, 0.1, 2.0), cuero)
	# Bustos de piedra a cada lado del arco (esculpidos en scripts/environment/estatua_modelos.gd)
	# Se deslizan hacia el jugador cuando nadie los mira.
	for k in 2:
		var lado := -1.0 if k == 0 else 1.0
		var p := EstatuaEnemiga.new()
		p.name = "Busto%d" % k
		p.position = Vector3(lado * 4.0, 0, 17.4)
		p.tipo = "BUSTO"
		p.velocidad = 0.8
		p.region = Rect2(-8.6, 16.8, 17.2, 13.0)
		p.set_meta("enemy_type", "BUSTO")
		p.add_to_group("wake_vestibulo")
		add_child(p)
		Modelos.busto(p, u, k)
		examinar(p, "Examinar busto", "Busto de piedra. Alex: «Vamos Alex, solo es piedra... la piedra no camina.»", p, Vector3(0, 1.7, 0))
	# Plantas
	for x in [[-8.3, 29.7], [8.3, 17.3]]:
		var m := u.node3d(self, "Planta", Vector3(float(x[0]), 0, float(x[1])))
		u.cyl(m, Vector3(0, 0.3, 0), 0.32, 0.25, 0.6, u.mat(Color(0.35, 0.18, 0.1), 0.8), Vector3.ZERO, 12, true)
		for i in 5:
			var hoja := u.mat(Color(0.1, 0.3 + 0.03 * i, 0.12), 0.8)
			u.sphere(m, Vector3(0.18 * cos(i * 1.26), 0.9 + 0.12 * i, 0.18 * sin(i * 1.26)), 0.22, hoja, Vector3(1, 1.5, 1))
