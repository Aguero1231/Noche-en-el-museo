extends "res://scripts/environment/room_base.gd"

## SALA DE CONTROL: pared de monitores con las camaras del museo en vivo,
## consola, bitacora del turno de la tarde y pilas de repuesto.
## Entrada abierta desde el vestibulo (pared este, z entre 28.0 y 29.6).

const X0 := 9.5
const X1 := 15.5
const Z0 := 26.4
const Z1 := 31.4
const H := 3.4

var _terminal_nodo: Node3D
var _mon_cam7: Dictionary = {}
var _mon_cam8: Dictionary = {}


func build() -> void:
	var piedra := u.stone(Color(0.62, 0.68, 0.82), 0.3)
	var top := H + 0.4

	u.box(self, Vector3(12.75, -0.25, 28.9), Vector3(6.5, 0.5, 6.0), u.marble(Color(0.55, 0.6, 0.72), 0.2), true, Vector3.ZERO, "Piso")
	u.box(self, Vector3(12.75, H + 0.2, 28.9), Vector3(6.5, 0.4, 6.0), u.stone(Color(0.25, 0.26, 0.3), 0.3), true, Vector3.ZERO, "Techo")
	wall_x(26.15, X0, 16.0, 0.5, top, piedra)
	wall_x(31.65, X0, 16.0, 0.5, top, piedra)
	wall_z(15.75, 25.9, 31.9, 0.5, top, piedra)
	wall_z(9.25, 30.75, 31.9, 0.5, top, piedra)      # completa la pared oeste (el resto es del vestibulo)

	zocalo_x(Z0, 1.0, X0, X1)
	zocalo_x(Z1, -1.0, X0, X1)
	banda(Vector3(12.5, 3.05, Z0 + 0.012), 0.0, 6.0, 0.28)
	banda(Vector3(12.5, 3.05, Z1 - 0.012), 180.0, 6.0, 0.28)

	_pared_de_monitores()
	_consola()

	# Luz blanca fria del techo (con parpadeo electrico): es la que apaga el interruptor
	var fluo := emisivo(u.mat(Color(0.8, 0.9, 1.0), 0.4, 0.0, Color(0.75, 0.88, 1.0), 1.4))
	for z in [27.6, 30.2]:
		u.box(self, Vector3(12.5, H - 0.04, z), Vector3(2.0, 0.06, 0.18), fluo)
	var l := u.omni(self, Vector3(12.5, 3.1, 28.9), Color(0.85, 0.93, 1.0), 1.6, 8.0)
	parpadear(l, 9.0, true)
	# Resplandor de los monitores: sigue prendido aunque se apaguen las luces
	luz_fija(u.omni(self, Vector3(14.6, 2.0, 28.9), Color(0.4, 0.8, 1.0), 0.9, 4.0))


func _pared_de_monitores() -> void:
	# 4 x 2 monitores en la pared este (miran hacia -x). Las camaras 7 y 8 no tienen senal.
	var feeds_fila_alta := [0, 1, 2, 3]
	var feeds_fila_baja := [4, 5, -1, -1]
	var zs := [27.05, 28.25, 29.45, 30.65]
	for i in 4:
		cctv.crear_monitor(self, Vector3(15.5, 2.5, zs[i]), -90.0, 1.0, feeds_fila_alta[i])
		var mb := cctv.crear_monitor(self, Vector3(15.5, 1.45, zs[i]), -90.0, 1.0, feeds_fila_baja[i])
		if i == 2:
			_mon_cam7 = mb
		elif i == 3:
			_mon_cam8 = mb
	# Rotulos de cada camara
	var nombres := ["CAM 01", "CAM 02", "CAM 03", "CAM 04", "CAM 05", "CAM 06", "CAM 07", "CAM 08"]
	for i in 4:
		u.text3d(self, nombres[i], Vector3(15.46, 3.0, zs[i]), -90.0, 26, Color(0.7, 0.95, 0.8), 0.0025)
		u.text3d(self, nombres[4 + i], Vector3(15.46, 1.95, zs[i]), -90.0, 26, Color(0.7, 0.95, 0.8), 0.0025)
	# Marco metalico de la pared de monitores
	u.box(self, Vector3(15.42, 3.0 - 0.7, 28.85), Vector3(0.06, 0.06, 5.0), u.metal(Color(0.2, 0.2, 0.22)))


func _consola() -> void:
	# Consola larga frente a los monitores
	var c := u.node3d(self, "Consola", Vector3(14.0, 0, 28.9))
	u.box(c, Vector3(0, 0.375, 0), Vector3(0.9, 0.75, 4.6), u.metal(Color(0.22, 0.23, 0.26)), true)
	u.box(c, Vector3(0, 0.78, 0), Vector3(1.0, 0.06, 4.7), u.mat(Color(0.08, 0.08, 0.09), 0.4, 0.3))
	var crema := u.mat(Color(0.62, 0.55, 0.42), 0.7)
	# Teclados, joystick y radio
	for z in [-1.4, 0.2, 1.5]:
		u.box(c, Vector3(-0.1, 0.83, z), Vector3(0.3, 0.03, 0.46), crema)
	u.cyl(c, Vector3(0.05, 0.88, 0.9), 0.025, 0.04, 0.12, u.dark())
	u.sphere(c, Vector3(0.05, 0.96, 0.9), 0.04, u.mat(Color(0.6, 0.05, 0.05), 0.4))
	u.box(c, Vector3(0.1, 0.86, -0.4), Vector3(0.22, 0.1, 0.16), u.mat(Color(0.15, 0.2, 0.15), 0.5, 0.2))
	# Tazas del turno anterior
	for z in [-1.9, 1.95]:
		u.cyl(c, Vector3(0.15, 0.86, z), 0.04, 0.038, 0.09, u.mat(Color(0.8, 0.78, 0.7), 0.4))
	# Silla de la consola
	silla(Vector3(12.9, 0, 28.9), 90.0, Color(0.1, 0.12, 0.2))

	# Terminal de vigilancia (pantalla de texto que se lee)
	var term := u.box(c, Vector3(0.1, 1.05, -1.0), Vector3(0.4, 0.3, 0.34), crema)
	u.box(c, Vector3(-0.1, 1.05, -1.0), Vector3(0.02, 0.22, 0.28), u.mat(Color(0.02, 0.06, 0.03), 0.1, 0.0, Color(0.15, 0.6, 0.3), 1.0))
	_terminal_nodo = term
	reg(term, "terminal", "Revisar sistema de cámaras", {}, 3.4, Vector3(0, 0, 0), term)

	# Bitacora del turno de la tarde (nota de Roberto)
	var bit := hoja_papel(c, Vector3(0.2, 0.815, 1.0), 20.0, Vector2(0.24, 0.32))
	var t := "[b]BITÁCORA - TURNO DE LA TARDE[/b]\n\n"
	t += "17:00  Cambio de turno. Todo tranquilo.\n"
	t += "19:30  Los técnicos instalaron el generador nuevo. Dijeron que habrá «microapagones».\n"
	t += "22:50  Llegó la Dra. Torres con una caja sellada. Muy nerviosa, no quiso hablar.\n"
	t += "23:10  CAM 07 y CAM 08 (pisos superiores) perdieron señal. Reporté al técnico.\n"
	t += "23:40  Veo en CAM 05 un resplandor turquesa en Restauración. Debe ser el equipo de la doctora.\n"
	t += "23:55  Me voy a casa. Alex entra en cinco minutos. [i]No hay nada que temer, ¿verdad?[/i]\n\n"
	t += "[i]— Roberto[/i]"
	nota(bit, "Leer bitácora", "Bitácora del turno", t, "papel", "", bit)

	# Pilas AA de repuesto
	var pilas := u.box(c, Vector3(0.28, 0.82, -1.7), Vector3(0.12, 0.05, 0.07), u.mat(Color(0.1, 0.35, 0.2), 0.4, 0.2, Color(0.3, 1.0, 0.5), 0.3))
	pickup(pilas, "Tomar pilas AA", "baterias", "Pilas AA: la linterna recupera carga.", 1)


## Cuando el jugador llega al piso 2 vuelven las camaras 7 y 8 (Galeria Medieval y Armeria).
func activar_camaras_piso2() -> void:
	if not _mon_cam7.is_empty() and cctv.feeds.size() > 7:
		cctv.asignar_feed(_mon_cam7, 6)
		cctv.asignar_feed(_mon_cam8, 7)


func interactuar(it: Dictionary) -> void:
	if String(it["tipo"]) == "terminal":
		Sfx.tocar("tecla")
		var h := estado.hora_con_segundos()
		var txt := "SISTEMA DE VIGILANCIA v2.3 - MUSEO METROPOLITANO\n"
		txt += "FECHA: VIE 13/10/2026   HORA: %s\n" % h
		txt += "----------------------------------------\n"
		txt += "CAM 01 VESTÍBULO .............. ONLINE\n"
		txt += "CAM 02 SALA EGIPCIA (SUR) ..... ONLINE\n"
		txt += "CAM 03 SALA EGIPCIA (ANUBIS) .. ONLINE\n"
		txt += "CAM 04 SALA EGIPCIA (OESTE) ... ONLINE\n"
		txt += "CAM 05 RESTAURACIÓN ........... ONLINE\n"
		txt += "CAM 06 ENTRADA PRINCIPAL ...... ONLINE\n"
		var piso2 := "ONLINE" if estado.flag("piso2_visitado") else "SIN SEÑAL"
		txt += "CAM 07 GALERÍA MEDIEVAL ....... %s\n" % piso2
		txt += "CAM 08 ARMERÍA ................. %s\n" % piso2
		txt += "----------------------------------------\n"
		txt += "ALERTA 00:00  Falla de energía principal.\n"
		txt += "ALERTA 00:00  PROTOCOLO SEG-13 ACTIVADO.\n"
		txt += "              Salidas de emergencia bloqueadas hasta las 06:00.\n"
		txt += "ALERTA %s  Movimiento detectado: CAM 03.\n" % estado.hora_texto()
		estado.nota.emit({"titulo": "VIGILANCIA > ESTADO", "texto": txt, "estilo": "terminal", "firma": ""})
		return
	super.interactuar(it)
