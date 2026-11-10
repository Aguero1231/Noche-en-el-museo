extends "res://scripts/environment/room_base.gd"

## SALA DE RESTAURACION: aqui dejaron el paquete confidencial con la "Lagrima de Osiris".
## La reliquia late con luz turquesa y a su lado esta el PRIMER FRAGMENTO del amuleto.
## Se abre con la tarjeta dorada (lector en el vestibulo).

const EstatuaEnemiga = preload("res://scripts/enemies/estatua_enemiga.gd")
const Modelos = preload("res://scripts/environment/estatua_modelos.gd")

const X0 := -16.5
const X1 := -9.5
const Z0 := 23.5
const Z1 := 31.0
const H := 3.6

var _reliquia: Node3D
var _luz_reliquia: OmniLight3D
var _cristal_reliquia: StandardMaterial3D
var _fragmento_nodo: Node3D


func build() -> void:
	var piedra := u.stone(Color(0.72, 0.8, 0.95), 0.3)
	var top := H + 0.4

	u.box(self, Vector3(-13.0, -0.25, 27.5), Vector3(7.5, 0.5, 8.5), u.marble(Color(0.7, 0.76, 0.85), 0.2), true, Vector3.ZERO, "Piso")
	u.box(self, Vector3(-13.0, H + 0.2, 27.5), Vector3(7.5, 0.4, 8.5), u.stone(Color(0.22, 0.24, 0.3), 0.3), true, Vector3.ZERO, "Techo")
	wall_z(-16.75, 23.5, 31.5, 0.5, top, piedra)
	wall_x(31.25, -17.0, -9.0, 0.5, top, piedra)
	wall_z(-9.25, 30.75, 31.5, 0.5, top, piedra)       # completa la pared este (el resto es del vestibulo)

	zocalo_x(31.0, -1.0, X0, X1)
	zocalo_z(X0, 1.0, Z0, 31.0)
	banda(Vector3(X0 + 0.012, 3.05, 27.2), 90.0, 7.5, 0.28)
	banda(Vector3(-13.0, 3.05, 31.0 - 0.012), 180.0, 7.0, 0.28)

	# Luz fria tipo fluorescente, con fallas
	var l := u.omni(self, Vector3(-13.0, 3.3, 27.0), Color(0.78, 0.9, 1.0), 1.1, 8.5)
	parpadear(l, 8.0, true)
	var fluorescente := emisivo(u.mat(Color(0.8, 0.9, 1.0), 0.4, 0.0, Color(0.7, 0.85, 1.0), 1.4))
	for z in [24.5, 28.0]:
		u.box(self, Vector3(-13.0, H - 0.04, z), Vector3(2.2, 0.06, 0.18), fluorescente)

	_mesa_de_la_reliquia()
	_mesa_lateral()
	_extras()


func _mesa_de_la_reliquia() -> void:
	var acero := u.metal(Color(0.5, 0.52, 0.55))
	var m := u.node3d(self, "MesaReliquia", Vector3(-13.0, 0, 27.4))
	u.box(m, Vector3(0, 0.45, 0), Vector3(2.4, 0.9, 1.2), acero, true)
	u.box(m, Vector3(0, 0.92, 0), Vector3(2.5, 0.05, 1.3), u.mat(Color(0.7, 0.72, 0.75), 0.25, 0.7))

	# Base y cupula de cristal sobre la Lagrima de Osiris
	u.cyl(m, Vector3(-0.2, 0.97, 0), 0.3, 0.32, 0.06, u.gold())
	u.cyl(m, Vector3(-0.2, 1.35, 0), 0.27, 0.27, 0.7, u.glass(Color(0.6, 0.9, 0.95, 0.10)), Vector3.ZERO, 20)
	u.sphere(m, Vector3(-0.2, 1.7, 0), 0.27, u.glass(Color(0.6, 0.9, 0.95, 0.10)))
	# La reliquia: gota turquesa que flota, gira y late
	_reliquia = u.node3d(m, "Reliquia", Vector3(-0.2, 1.35, 0))
	_cristal_reliquia = u.mat(Color(0.05, 0.3, 0.28), 0.1, 0.2, Color(0.2, 1.0, 0.85), 2.5)
	u.sphere(_reliquia, Vector3(0, 0, 0), 0.1, _cristal_reliquia, Vector3(1, 1.2, 1))
	u.cyl(_reliquia, Vector3(0, 0.17, 0), 0.0, 0.085, 0.16, _cristal_reliquia, Vector3.ZERO, 12)
	_luz_reliquia = luz_fija(u.omni(m, Vector3(-0.2, 1.4, 0), Color(0.25, 1.0, 0.85), 1.7, 5.5)) as OmniLight3D
	var obj_r := u.node3d(m, "Reliquia_Objetivo", Vector3(-0.2, 1.2, 0.0))
	examinar(obj_r, "Examinar reliquia", "La Lágrima de Osiris late como un corazón. Cada pulso hace vibrar las luces. Alex: «No la mires mucho tiempo...»", null)

	# Fragmento del amuleto sobre un cojin (pieza de piedra con jeroglificos luminosos)
	_fragmento_nodo = u.node3d(m, "Fragmento", Vector3(0.7, 0.98, 0.0), 20.0)
	u.box(_fragmento_nodo, Vector3(0, -0.01, 0), Vector3(0.3, 0.03, 0.22), u.mat(Color(0.35, 0.05, 0.06), 1.0))
	var piedra := u.mat(Color(0.5, 0.48, 0.45), 0.8)
	var pieza := u.box(_fragmento_nodo, Vector3(0, 0.035, 0), Vector3(0.2, 0.05, 0.13), piedra, false, Vector3(0, 0, 8))
	var glifo := u.mat(Color(0.05, 0.25, 0.22), 0.3, 0.0, Color(0.2, 1.0, 0.85), 3.0)
	for i in 3:
		u.box(pieza, Vector3(-0.05 + i * 0.05, 0.027, 0), Vector3(0.012, 0.004, 0.08), glifo)
	u.box(pieza, Vector3(0, 0.027, -0.03), Vector3(0.16, 0.004, 0.01), glifo)
	luz_fija(u.omni(_fragmento_nodo, Vector3(0, 0.2, 0), Color(0.3, 1.0, 0.85), 0.6, 2.5))
	pickup(_fragmento_nodo, "Tomar fragmento del amuleto", "fragmento", "Fragmento del amuleto (1/4). Los jeroglíficos brillan en tus manos.", 1, Callable(self, "_tomo_fragmento"), Vector3(0, 0.1, 0))
	# el resaltado de un pickup apunta al nodo completo (incluye el cojin); ya viene en pickup()


func _tomo_fragmento() -> void:
	estado.poner_flag("frag1")
	Sfx.tocar("golpe")
	estado.mensaje.emit("Algo se mueve bajo la sábana...")
	estado.despertar.emit("wake_cubierta")
	estado.radio_una_vez("fragmento", "ROBERTO (radio): «...¿Qué fue ese ruido? Alex, no me estás tomando el pelo, ¿verdad? Alex... [estática]»")
	Sfx.tocar("static")


func _mesa_lateral() -> void:
	# Mesa de trabajo junto a la pared oeste: herramientas, remito y diario
	var m := u.node3d(self, "MesaTrabajo", Vector3(-15.7, 0, 25.6))
	u.box(m, Vector3(0, 0.43, 0), Vector3(1.0, 0.86, 2.2), u.wood_light(), true)
	for z in [-0.7, 0.0, 0.7]:
		u.box(m, Vector3(0.1, 0.9, z), Vector3(0.1, 0.05, 0.08), u.metal())
	u.cyl(m, Vector3(0.2, 0.88, 0.9), 0.05, 0.05, 0.04, u.mat(Color(0.7, 0.1, 0.1), 0.5))
	u.omni(m, Vector3(0.3, 1.5, 0), Color(1.0, 0.9, 0.7), 0.5, 3.0)

	# Remito del paquete
	var remito := hoja_papel(m, Vector3(0.1, 0.9, -0.4), 5.0, Vector2(0.21, 0.29), Color(0.82, 0.82, 0.78))
	var r := "[b]REMITO DE ENVÍO - CONFIDENCIAL[/b]\n\n"
	r += "[b]Remitente:[/b] Dra. Elena Torres (Valle de los Reyes, expedición 2026)\n"
	r += "[b]Destino:[/b] Sala de Restauración, Museo Metropolitano\n"
	r += "[b]Contenido:[/b] 1 reliquia ceremonial («Lágrima de Osiris») + 1 fragmento de amuleto (1/4)\n\n"
	r += "[b]INSTRUCCIONES:[/b]\n"
	r += "· Manipular solo con guantes.\n"
	r += "· NO exponer a luz artificial nocturna.\n"
	r += "· NO abrir fuera de la sala de restauración.\n\n"
	r += "[i]Firma: E. Torres — Recibido: 23:40.[/i]"
	nota(remito, "Leer remito", "Remito del paquete", r, "papel", "", remito)

	# Diario #2
	var d2 := hoja_papel(m, Vector3(0.05, 0.9, 0.4), -12.0, Vector2(0.22, 0.3))
	var t := "[b]DIARIO DE LA DRA. ELENA TORRES - 2[/b]\n[i]Restauración, 23:50[/i]\n\n"
	t += "La Lágrima late. Lo juro: late. Y cada pulso apaga una luz del pasillo.\n\n"
	t += "El primer fragmento venía envuelto en lino. Lo dejé sobre el cojín; no me atrevo a guardarlo lejos de ella. Faltan diez minutos para la medianoche y los cálculos dicen que entonces despertará.\n\n"
	t += "He decidido ir a la bóveda a preparar el sellado. Si regreso, lo explicaré todo. Si no... [b]las estatuas solo se mueven cuando nadie las mira.[/b] Un espejo las detiene. Una luz fuerte, también.\n\n"
	t += "Roberto, perdóname por no avisarte."
	nota(d2, "Leer diario", "Diario de la Dra. Torres (2)", t, "papel", "", d2)


func _extras() -> void:
	var acero := u.metal(Color(0.45, 0.47, 0.5))
	# Caja del paquete, abierta
	var caja := u.node3d(self, "CajaPaquete", Vector3(-14.9, 0, 28.7), 15.0)
	u.box(caja, Vector3(0, 0.3, 0), Vector3(1.0, 0.6, 0.8), u.wood_light(), true)
	u.box(caja, Vector3(0, 0.6, 0), Vector3(0.9, 0.04, 0.7), u.mat(Color(0.85, 0.82, 0.7), 1.0))
	u.box(caja, Vector3(0.1, 0.9, -0.5), Vector3(1.0, 0.04, 0.8), u.wood_light(), false, Vector3(-65, 0, 0))
	u.text3d(caja, "CONFIDENCIAL", Vector3(0, 0.3, 0.41), 0.0, 50, Color(0.8, 0.08, 0.08), 0.004)

	# Estatua cubierta con una lona
	# Despierta cuando el jugador toma el fragmento (museum.gd la activa) y lo persigue por el cuarto
	var est := EstatuaEnemiga.new()
	est.name = "EstatuaCubierta"
	est.position = Vector3(-15.6, 0, 30.0)
	est.tipo = "CUBIERTA"
	est.velocidad = 1.1
	est.region = Rect2(-16.3, 23.7, 6.7, 7.1)
	est.set_meta("enemy_type", "ESTATUA CUBIERTA")
	est.add_to_group("wake_cubierta")
	add_child(est)
	Modelos.estatua_cubierta(est, u)
	examinar(est, "Examinar estatua cubierta", "Una estatua cubierta con una sábana. Alex: «Mejor no la destapo...»", est, Vector3(0, 1.6, 0))

	# Vitrina rota con pilas AA
	var v := u.node3d(self, "VitrinaRota", Vector3(-10.4, 0, 30.1))
	u.box(v, Vector3(0, 0.45, 0), Vector3(1.0, 0.9, 0.9), u.stone(Color(0.35, 0.33, 0.38), 0.4), true)
	u.box(v, Vector3(0, 0.92, 0), Vector3(1.05, 0.05, 0.95), u.gold())
	u.box(v, Vector3(-0.45, 1.25, 0.43), Vector3(0.04, 0.6, 0.04), acero)
	u.box(v, Vector3(0.45, 1.25, -0.43), Vector3(0.04, 0.6, 0.04), acero)
	u.box(v, Vector3(0.1, 1.0, 0.45), Vector3(0.5, 0.35, 0.01), u.glass(Color(0.7, 0.85, 1.0, 0.18)), false, Vector3(-30, 15, 0))
	for sx in [-0.2, 0.15, 0.3]:
		u.box(v, Vector3(sx, 0.96, 0.2), Vector3(0.06, 0.003, 0.05), u.glass(Color(0.8, 0.9, 1.0, 0.35)), false, Vector3(0, sx * 200.0, 0))
	var pilas := u.box(v, Vector3(-0.15, 0.97, -0.05), Vector3(0.12, 0.05, 0.07), u.mat(Color(0.1, 0.35, 0.2), 0.4, 0.2, Color(0.3, 1.0, 0.5), 0.3))
	pickup(pilas, "Tomar pilas AA", "baterias", "Pilas AA de la vitrina rota: la linterna recupera carga.", 1)

	# Estantes con cajas a lo largo de la pared sur
	for x in [-14.8, -12.8, -10.8]:
		var e := u.node3d(self, "Estante", Vector3(x, 0, 30.7))
		u.box(e, Vector3(0, 1.0, 0), Vector3(1.6, 2.0, 0.4), acero, true)
		for y in [0.6, 1.2, 1.8]:
			u.box(e, Vector3(0, y, 0.02), Vector3(1.5, 0.03, 0.42), u.metal(Color(0.35, 0.36, 0.4)))
		u.box(e, Vector3(-0.3, 0.8, 0.05), Vector3(0.4, 0.3, 0.3), u.mat(Color(0.5, 0.4, 0.28), 0.9))
		u.box(e, Vector3(0.3, 1.4, 0.05), Vector3(0.5, 0.3, 0.3), u.mat(Color(0.45, 0.36, 0.25), 0.9))


func _procesar(_delta: float) -> void:
	if _reliquia == null or not is_instance_valid(_reliquia):
		return
	_reliquia.rotation.y = _t * 0.8
	_reliquia.position.y = 1.35 + sin(_t * 1.6) * 0.04
	# Latido: dos pulsos rapidos y una pausa
	var fase := fmod(_t, 1.6)
	var pulso := exp(-pow((fase - 0.15) * 9.0, 2.0)) + 0.7 * exp(-pow((fase - 0.5) * 9.0, 2.0))
	_luz_reliquia.light_energy = 1.0 + pulso * 1.6
	_cristal_reliquia.emission_energy_multiplier = 1.8 + pulso * 2.2
