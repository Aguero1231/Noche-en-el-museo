extends "res://scripts/environment/room_base.gd"

## ARMERIA (PISO 2): "Pasillos de Acero". Laberinto de pasillos estrechos (2.5 m) con armaduras
## de la Orden del Acero. El FRAGMENTO 3 esta al fondo, en la camara del norte.
## Hay dos rutas (este y oeste); cada una tiene una armadura y un reflector con su panel: giralo hasta que
## la luz toque a la armadura para inmovilizarla para siempre y poder pasar.
## El nodo se coloca a y = 9; el mapa se lee desde MAPA (# = muro, . = pasillo).

const EstatuaEnemiga = preload("res://scripts/enemies/estatua_enemiga.gd")
const Modelos = preload("res://scripts/environment/estatua_modelos.gd")
const Reflector = preload("res://scripts/game/reflector.gd")

const CELDA := 2.5
const X0 := -8.75
const Z0 := -14.0
const H := 5.4
const TOP := 5.8
const MAPA := [
	"#######",
	"#.....#",
	"#.###.#",
	"#.#...#",
	"#.#.###",
	"#.....#",
	"###.###",
]

var _acero: StandardMaterial3D
var _oro: StandardMaterial3D


## Centro de una celda (columna, fila) en coordenadas del mundo (x, z).
func _c(col: int, fila: int) -> Vector3:
	return Vector3(X0 + (col + 0.5) * CELDA, 0.0, Z0 + (fila + 0.5) * CELDA)


func build() -> void:
	var piedra := u.stone(Color(0.52, 0.54, 0.62), 0.28)
	var osc := u.stone(Color(0.24, 0.25, 0.3), 0.3)
	_acero = u.mat(Color(0.58, 0.60, 0.66), 0.3, 0.85)
	_oro = u.gold()
	var ancho := 7.0 * CELDA

	u.box(self, Vector3(0, -0.25, Z0 + ancho / 2.0), Vector3(ancho + 1.0, 0.5, ancho + 1.0), u.marble(Color(0.42, 0.42, 0.5), 0.12), true, Vector3.ZERO, "Piso")
	u.box(self, Vector3(0, H + 0.2, Z0 + ancho / 2.0), Vector3(ancho + 1.0, 0.4, ancho + 1.0), osc, true, Vector3.ZERO, "Techo")

	# Muros: se juntan las celdas "#" consecutivas de cada fila en una sola caja
	for fila in MAPA.size():
		var fila_txt: String = MAPA[fila]
		var col := 0
		while col < fila_txt.length():
			if fila_txt[col] == "#":
				var ini := col
				while col < fila_txt.length() and fila_txt[col] == "#":
					col += 1
				var largo := (col - ini) * CELDA
				var cx := X0 + ini * CELDA + largo / 2.0
				u.box(self, Vector3(cx, TOP / 2.0, Z0 + (fila + 0.5) * CELDA), Vector3(largo, TOP, CELDA), piedra, true)
			else:
				col += 1

	_decorar_pasillos()
	_luces()
	_camara_del_fragmento()
	_rincon_de_pilas()
	_ruta_este()
	_ruta_oeste()


# ---------------------------------------------------------------- decoracion y luces

func _celda_libre(col: int, fila: int) -> bool:
	if fila < 0 or fila >= MAPA.size():
		return false
	var f: String = MAPA[fila]
	return col >= 0 and col < f.length() and f[col] == "."


## Escudos y espadas cruzadas en los muros que dan a los pasillos; vigas de madera en el techo.
func _decorar_pasillos() -> void:
	var rojo := u.mat(Color(0.42, 0.05, 0.07), 0.9)
	var azul := u.mat(Color(0.08, 0.14, 0.45), 0.9)
	var madera := u.wood()
	var n := 0
	for fila in MAPA.size():
		for col in 7:
			if not _celda_libre(col, fila):
				continue
			var c := _c(col, fila)
			u.box(self, Vector3(c.x, H - 0.2, c.z), Vector3(CELDA, 0.4, 0.4), madera)
			# Una decoracion por cada pared vecina, alternando escudo / espadas
			for lado in [[1, 0, -90.0], [-1, 0, 90.0], [0, 1, 180.0], [0, -1, 0.0]]:
				var dc: int = lado[0]
				var df: int = lado[1]
				if _celda_libre(col + dc, fila + df):
					continue
				n += 1
				if n % 3 != 0:
					continue
				var pos := Vector3(c.x + dc * (CELDA / 2.0 - 0.04), 2.2, c.z + df * (CELDA / 2.0 - 0.04))
				var d := u.node3d(self, "Decoracion", pos, float(lado[2]))   # mira hacia el pasillo
				if n % 2 == 0:
					u.cyl(d, Vector3.ZERO, 0.32, 0.32, 0.05, rojo if n % 4 == 0 else azul, Vector3(90, 0, 0))
					u.sphere(d, Vector3(0, 0, 0.04), 0.07, _oro)
					u.box(d, Vector3(0, 0, 0.03), Vector3(0.05, 0.56, 0.015), _oro)
				else:
					for s in [-1.0, 1.0]:
						u.box(d, Vector3(0, 0, 0.02), Vector3(0.06, 1.1, 0.025), _acero, false, Vector3(0, 0, s * 38))
						u.box(d, Vector3(s * 0.28, -0.22, 0.03), Vector3(0.22, 0.03, 0.03), _oro, false, Vector3(0, 0, s * 38))


func _luces() -> void:
	# Antorchas pegadas a un muro de cada celda clave (junto a las armaduras tambien); algunas parpadean
	var celdas := [[3, 6], [3, 5], [3, 3], [4, 3], [5, 2], [3, 1], [1, 1], [1, 3], [1, 4], [1, 5], [5, 5]]
	var dirs := [Vector2i(1, 0), Vector2i(-1, 0), Vector2i(0, 1), Vector2i(0, -1)]
	for k in celdas.size():
		var col: int = celdas[k][0]
		var fila: int = celdas[k][1]
		var c := _c(col, fila)
		var hacia_muro := Vector2i.ZERO
		for d in dirs:
			if not _celda_libre(col + d.x, fila + d.y):
				hacia_muro = d
				break
		var t := u.node3d(self, "Antorcha", Vector3(c.x + hacia_muro.x * (CELDA / 2.0 - 0.1), 2.5, c.z + hacia_muro.y * (CELDA / 2.0 - 0.1)))
		var quitar := Vector3(-hacia_muro.x, 0, -hacia_muro.y)      # hacia el centro del pasillo
		u.box(t, Vector3(0, -0.1, 0) + quitar * 0.05, Vector3(0.1, 0.5, 0.1), u.wood())
		u.box(t, Vector3(0, -0.34, 0) + quitar * 0.02, Vector3(0.2, 0.05, 0.2), u.metal())
		u.sphere(t, Vector3(0, 0.22, 0) + quitar * 0.12, 0.08, u.mat(Color(1.0, 0.85, 0.5), 0.5, 0.0, Color(1.0, 0.6, 0.15), 3.5), Vector3(1, 1.8, 1))
		var l := u.omni(t, Vector3(0, 0.4, 0) + quitar * 0.3, Color(1.0, 0.6, 0.28), 1.35, 7.0)
		parpadear(l, 9.0 + k, k % 3 == 0)


func _camara_del_fragmento() -> void:
	# Camara norte (fila 1, columnas 1..5): FRAGMENTO 3 sobre un pedestal con jeroglificos
	var c := _c(3, 1)
	var p := u.node3d(self, "PedestalFragmento3", Vector3(c.x, 0, c.z))
	u.box(p, Vector3(0, 0.45, 0), Vector3(0.7, 0.9, 0.7), u.stone(Color(0.3, 0.3, 0.36), 0.3), true)
	u.box(p, Vector3(0, 0.93, 0), Vector3(0.82, 0.07, 0.82), _oro)
	var f := u.node3d(p, "Fragmento3", Vector3(0, 1.02, 0), -10.0)
	var pieza := u.box(f, Vector3(0, 0.03, 0), Vector3(0.2, 0.05, 0.13), u.mat(Color(0.5, 0.48, 0.45), 0.8), false, Vector3(0, 0, 8))
	var glifo := u.mat(Color(0.05, 0.25, 0.22), 0.3, 0.0, Color(0.2, 1.0, 0.85), 3.0)
	for i in 3:
		u.box(pieza, Vector3(-0.05 + i * 0.05, 0.027, 0), Vector3(0.012, 0.004, 0.08), glifo)
	luz_fija(u.omni(f, Vector3(0, 0.25, 0), Color(0.3, 1.0, 0.85), 0.9, 3.5))
	pickup(f, "Tomar fragmento del amuleto", "fragmento", "Fragmento del amuleto (3/4). Los jeroglíficos arden en tus manos.", 1, Callable(self, "_tomo_fragmento3"), Vector3(0, 0.1, 0))
	u.text3d(self, "CÁMARA DEL TESORO", Vector3(c.x, 3.3, Z0 + CELDA + 0.05), 0.0, 44, Color(0.9, 0.75, 0.3), 0.005)


func _tomo_fragmento3() -> void:
	estado.poner_flag("frag3")
	Sfx.tocar("golpe")
	estado.mensaje.emit("Las armaduras de la Armería crujen y se ponen en marcha...")
	estado.despertar.emit("wake_frag3")


func _rincon_de_pilas() -> void:
	# Callejon sin salida al este de la fila 5: pilas y un diario
	var c := _c(5, 5)
	var mesa := u.node3d(self, "MesaRincon", Vector3(c.x + 0.5, 0, c.z))
	u.box(mesa, Vector3(0, 0.45, 0), Vector3(0.7, 0.9, 1.6), u.wood_light(), true)
	var pilas := u.box(mesa, Vector3(0.0, 0.94, -0.35), Vector3(0.12, 0.05, 0.07), u.mat(Color(0.1, 0.35, 0.2), 0.4, 0.2, Color(0.3, 1.0, 0.5), 0.3))
	pickup(pilas, "Tomar pilas AA", "baterias", "Pilas AA de la Armería: la linterna recupera carga.", 1)
	var d6 := hoja_papel(mesa, Vector3(0.0, 0.915, 0.35), 8.0, Vector2(0.21, 0.3))
	var tx := "[b]DIARIO DE LA DRA. ELENA TORRES - 6[/b]\n\n"
	tx += "La Armería es un laberinto a propósito: los caballeros la diseñaron con pasillos de dos metros y medio para que un solo guardián pudiera detener a un ejército.\n\n"
	tx += "Hay [b]dos rutas[/b] hasta la cámara del tesoro, la del este y la del oeste. Cada una tiene su armadura y su reflector. [b]Con asegurar una ruta basta.[/b]\n\n"
	tx += "Los paneles de los reflectores están pegados a la pared de cada ruta. Gira el foco sin dejar de vigilar: yo perdí un día entero por darle la espalda a una.\n\n"
	tx += "[i]Al fondo está el fragmento tres. Cuando lo tomes, las armaduras que sigan libres se pondrán en marcha.[/i]"
	nota(d6, "Leer diario", "Diario de la Dra. Torres (6)", tx, "papel", "", d6)
	# Estante con armas de adorno
	for k in 3:
		u.box(mesa, Vector3(0.28, 1.3 + k * 0.0, -0.5 + k * 0.5), Vector3(0.05, 0.9, 0.05), u.wood(), false, Vector3(0, 0, 8))


# ---------------------------------------------------------------- las dos rutas

func _armadura(nombre: String, c: Vector3, rot_y: float, color: Color) -> void:
	var e := EstatuaEnemiga.new()
	e.name = nombre
	e.position = c
	e.rotation_degrees.y = rot_y
	e.tipo = "ARMADURA"
	e.velocidad = 2.2
	e.ruidosa = true
	e.region = Rect2(X0, Z0, 7.0 * CELDA, 7.0 * CELDA)
	e.add_to_group("wake_armeria")
	e.add_to_group("wake_frag3")
	e.set_meta("enemy_type", "ARMADURA")
	add_child(e)
	Modelos.armadura(e, u, color)
	examinar(e, "Examinar armadura", "Una armadura de la Orden del Acero, de pie en mitad del pasillo. Alex: «Qué mala espina... un reflector podría fijarla.»", e, Vector3(0, 1.6, 0))


func _panel(rotulo: String, pos: Vector3, rot_y: float, r: Node3D) -> void:
	var p := u.node3d(self, "Panel" + rotulo.replace(" ", ""), pos, rot_y)
	var metal := u.metal(Color(0.2, 0.2, 0.24))
	u.box(p, Vector3(0, 0.5, 0), Vector3(0.5, 1.0, 0.4), metal, true)
	u.box(p, Vector3(0, 1.05, 0.05), Vector3(0.52, 0.1, 0.46), metal, false, Vector3(-20, 0, 0))
	u.cyl(p, Vector3(0.12, 1.15, 0.12), 0.015, 0.015, 0.25, u.dark(), Vector3(25, 0, 10))
	u.sphere(p, Vector3(0.14, 1.28, 0.2), 0.04, u.mat(Color(0.7, 0.05, 0.05), 0.4))
	u.box(p, Vector3(-0.12, 1.1, 0.16), Vector3(0.14, 0.05, 0.04), u.mat(Color(0.3, 0.05, 0.0), 0.5, 0.0, Color(1.0, 0.4, 0.1), 1.6))
	u.text3d(p, rotulo.to_upper(), Vector3(0, 0.62, 0.21), 0.0, 24, Color(0.9, 0.8, 0.4), 0.003)
	reg(p, "reflector", "Girar " + rotulo.to_lower(), {"reflector": r}, 3.2, Vector3(0, 1.1, 0), p)


func _reflector(rotulo: String, pos: Vector3, rumbo_ini: int, inclinacion: float) -> Reflector:
	var r := Reflector.new()
	r.name = rotulo.replace(" ", "")
	r.position = pos
	r.rumbo = rumbo_ini
	r.inclinacion = inclinacion
	r.alcance = 7.0
	add_child(r)
	r.fijo_estatua.connect(_reflector_fijo)
	return r


func _reflector_fijo(_e: Node3D) -> void:
	Sfx.tocar("beep_ok")
	estado.mensaje.emit("¡El reflector fija a la armadura! Queda inmóvil para siempre.")


## Ruta este: celdas (3,3) -> (4,3) -> (5,3) -> (5,2) -> (5,1). Armadura en (4,3).
func _ruta_este() -> void:
	var a := _c(4, 3)
	_armadura("ArmaduraEste", a, -90.0, Color(0.1, 0.18, 0.5))
	var rc := _c(3, 3)
	# El foco cuelga sobre la celda (3,3) y apunta al este; empieza apuntando al oeste
	var r := _reflector("Reflector Este", Vector3(rc.x + 0.2, 4.4, rc.z), 3, -atan(3.4 / (a.x - rc.x - 0.2)) * 180.0 / PI)
	_panel("Reflector Este", Vector3(rc.x - 0.95, 0, rc.z + 0.6), 90.0, r)


## Ruta oeste: celdas (3,5) -> (2,5) -> (1,5) -> (1,4) -> (1,3) -> (1,2) -> (1,1). Armadura en (1,3).
func _ruta_oeste() -> void:
	var a := _c(1, 3)
	var rc := _c(1, 4)
	_armadura("ArmaduraOeste", a, 0.0, Color(0.5, 0.06, 0.08))
	# El foco cuelga sobre la celda (1,4) y apunta al norte; empieza apuntando al sur
	var r := _reflector("Reflector Oeste", Vector3(rc.x, 4.4, rc.z - 0.2), 2, -atan(3.4 / (rc.z - a.z - 0.2)) * 180.0 / PI)
	_panel("Reflector Oeste", Vector3(rc.x - 0.95, 0, rc.z + 0.3), 90.0, r)
