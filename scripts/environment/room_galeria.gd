extends "res://scripts/environment/room_base.gd"

## GALERIA MEDIEVAL (PISO 2). Nivel 2 "Pasillos de Acero".
## El nodo se coloca a y = 9 (piso 2); aqui las alturas son locales (suelo = 0).
##
## - Nave central con columnas, vitrales, candelabros, estandartes y vitrinas con armas.
## - La TUMBA DEL CABALLERO guarda el FRAGMENTO 2 (al tomarlo despierta una armadura mas).
## - 3 armaduras ruidosas y rapidas. Cada una tiene un REFLECTOR con su panel: gira el foco hasta
##   que la luz toque a la armadura y quedara inmovilizada para siempre.
## - La reja de la ARMERIA (norte) pide un codigo de 4 digitos: el año grabado en el escudo del fundador.
## - La puerta del PISO 3 (este) se abre con la tarjeta roja (todavia no esta construido).

const EstatuaEnemiga = preload("res://scripts/enemies/estatua_enemiga.gd")
const Modelos = preload("res://scripts/environment/estatua_modelos.gd")
const Reflector = preload("res://scripts/game/reflector.gd")

const X0 := -9.0
const X1 := 9.0
const Z0 := 4.0
const Z1 := 30.25
const H := 5.4
const TOP := 5.8
const REGION := Rect2(-8.6, 4.4, 17.2, 25.6)

var _acero: StandardMaterial3D
var _oro: StandardMaterial3D


func build() -> void:
	var piedra := u.stone(Color(0.62, 0.64, 0.74), 0.22)
	var osc := u.stone(Color(0.26, 0.27, 0.33), 0.25)
	_acero = u.mat(Color(0.58, 0.60, 0.66), 0.3, 0.85)
	_oro = u.gold()

	u.box(self, Vector3(0, -0.25, 17.1), Vector3(19.0, 0.5, 27.5), u.marble(Color(0.5, 0.5, 0.58), 0.1), true, Vector3.ZERO, "Piso")
	u.box(self, Vector3(0, H + 0.2, 17.1), Vector3(19.0, 0.4, 27.5), osc, true, Vector3.ZERO, "Techo")
	for z in [8.0, 13.0, 18.0, 23.0, 28.0]:
		u.box(self, Vector3(0, H - 0.2, z), Vector3(18.6, 0.4, 0.45), u.wood())
	wall_z(-9.25, 3.5, 30.75, 0.5, TOP, piedra)
	wall_z(9.25, 3.5, 30.75, 0.5, TOP, piedra, [{"a": 6.2, "b": 7.6, "h": 2.8}])
	wall_x(30.5, -9.5, 9.5, 0.5, TOP, piedra, [{"a": -5.9, "b": -4.15, "h": 2.9}])
	wall_x(3.75, -9.5, 9.5, 0.5, TOP, piedra, [{"a": -1.2, "b": 1.2, "h": 3.1}])
	zocalo_z(X0, 1.0, Z0, Z1, [], 1.0)
	zocalo_z(X1, -1.0, Z0, Z1, [{"a": 6.1, "b": 7.7}], 1.0)
	zocalo_x(Z1, -1.0, X0, X1, [{"a": -5.95, "b": -4.1}], 1.0)
	zocalo_x(Z0, 1.0, X0, X1, [{"a": -1.3, "b": 1.3}], 1.0)
	_friso()

	# Alfombra de la nave (carpet.png) y columnas
	var plano := PlaneMesh.new()
	plano.size = Vector2(2.4, 24.5)
	var alf := MeshInstance3D.new()
	alf.mesh = plano
	alf.material_override = u.carpet(24.5 / 4.8)
	alf.position = Vector3(0, 0.012, 17.4)
	add_child(alf)
	for x in [-4.2, 4.2]:
		for z in [8.0, 13.0, 18.0, 23.0, 28.0]:
			_columna(Vector3(x, 0, z), piedra, osc)

	for z in [8.0, 14.0, 20.0, 26.0]:
		_ventana(X0 + 0.0, 90.0, z)
		_ventana(X1 - 0.0, -90.0, z)
	for z in [11.0, 17.0, 23.0]:
		_estandarte(Vector3(X0 + 0.06, 0, z), 90.0, Color(0.5, 0.06, 0.08) if int(z) % 2 == 1 else Color(0.08, 0.14, 0.45))
		_estandarte(Vector3(X1 - 0.06, 0, z), -90.0, Color(0.08, 0.14, 0.45) if int(z) % 2 == 1 else Color(0.5, 0.06, 0.08))

	_luces()
	_vitrinas()
	_trono()
	_tumba()
	_armaduras_y_reflectores()
	_puerta_armeria()
	_puerta_piso3()
	_avisos()


# ---------------------------------------------------------------- estructura y decoracion

func _friso() -> void:
	var rojo := u.mat(Color(0.42, 0.05, 0.07), 0.9)
	for lado in [[X0 + 0.02, 1.0, 90.0], [X1 - 0.02, -1.0, -90.0]]:
		var r := u.node3d(self, "Friso", Vector3(float(lado[0]), 4.75, 17.1), float(lado[2]))
		u.box(r, Vector3(0, 0, 0.0), Vector3(Z1 - Z0, 0.45, 0.04), rojo)
		u.box(r, Vector3(0, 0.25, 0.01), Vector3(Z1 - Z0, 0.05, 0.05), _oro)
		u.box(r, Vector3(0, -0.25, 0.01), Vector3(Z1 - Z0, 0.05, 0.05), _oro)
		for k in 26:
			u.box(r, Vector3(-12.5 + k * 1.0, 0, 0.03), Vector3(0.18, 0.18, 0.02), _oro, false, Vector3(0, 0, 45))


func _columna(pos: Vector3, piedra: Material, osc: Material) -> void:
	var c := u.node3d(self, "Columna", pos)
	u.box(c, Vector3(0, 0.18, 0), Vector3(0.95, 0.36, 0.95), osc)
	u.cyl(c, Vector3(0, 2.6, 0), 0.36, 0.40, 4.5, piedra, Vector3.ZERO, 8, true)
	u.box(c, Vector3(0, 4.95, 0), Vector3(0.9, 0.3, 0.9), osc)
	u.box(c, Vector3(0, 5.2, 0), Vector3(1.05, 0.22, 1.05), piedra)
	for k in 4:
		var ang := k * 90.0
		var cb := u.box(c, Vector3(0, 4.6, 0), Vector3(0.12, 0.3, 0.12), osc)
		cb.position = Vector3(sin(deg_to_rad(ang)) * 0.45, 4.6, cos(deg_to_rad(ang)) * 0.45)


## Vitral gotico (rot_y: 90 en la pared oeste, -90 en la este).
func _ventana(x: float, rot_y: float, z: float) -> void:
	var v := u.node3d(self, "Ventana", Vector3(x, 0, z), rot_y)
	var osc := u.mat(Color(0.12, 0.12, 0.15), 0.8)
	u.box(v, Vector3(0, 2.8, 0.0), Vector3(1.5, 3.1, 0.06), osc)
	var colores := [Color(0.12, 0.2, 0.8), Color(0.85, 0.15, 0.12), Color(0.9, 0.65, 0.12)]
	for k in 3:
		var cr := u.mat(Color(0.05, 0.05, 0.08), 0.3, 0.0, colores[k], 0.9)
		u.box(v, Vector3((k - 1) * 0.46, 2.8, 0.04), Vector3(0.40, 2.9, 0.02), cr)
		u.box(v, Vector3((k - 1) * 0.46, 4.3, 0.04), Vector3(0.40, 0.4, 0.02), cr, false, Vector3(0, 0, 0))
	for k in 2:
		u.box(v, Vector3(-0.23 + k * 0.46, 2.8, 0.05), Vector3(0.04, 3.0, 0.03), osc)
	u.box(v, Vector3(0, 3.3, 0.05), Vector3(1.4, 0.04, 0.03), osc)
	u.box(v, Vector3(0, 2.3, 0.05), Vector3(1.4, 0.04, 0.03), osc)
	var punta := u.mat(Color(0.06, 0.06, 0.1), 0.3, 0.0, Color(0.9, 0.7, 0.2), 0.9)
	u.box(v, Vector3(0, 4.62, 0.04), Vector3(0.78, 0.78, 0.02), punta, false, Vector3(0, 0, 45))
	u.box(v, Vector3(0, 4.62, 0.03), Vector3(0.92, 0.92, 0.02), osc, false, Vector3(0, 0, 45))


func _estandarte(pos: Vector3, rot_y: float, color: Color) -> void:
	var b := u.node3d(self, "Estandarte", pos, rot_y)
	var tela := u.mat(color, 1.0)
	u.box(b, Vector3(0, 3.0, 0.02), Vector3(0.9, 1.7, 0.03), tela)
	u.box(b, Vector3(0, 3.0, 0.045), Vector3(0.12, 1.2, 0.015), _oro)
	u.box(b, Vector3(0, 3.2, 0.045), Vector3(0.5, 0.12, 0.015), _oro)
	u.box(b, Vector3(0, 3.95, 0.02), Vector3(1.0, 0.06, 0.06), _oro)
	for k in 3:
		u.box(b, Vector3(-0.3 + k * 0.3, 2.07, 0.02), Vector3(0.14, 0.2, 0.03), tela, false, Vector3(0, 0, 45))


func _luces() -> void:
	# Candelabros de hierro con velas sobre la nave
	for z in [10.5, 17.0, 23.5]:
		var c := u.node3d(self, "Candelabro", Vector3(0, 0, z))
		var hierro := u.mat(Color(0.08, 0.08, 0.09), 0.5, 0.6)
		for k in 3:
			var cad := u.cyl(c, Vector3(sin(k * 2.094) * 0.5, 4.95, cos(k * 2.094) * 0.5), 0.012, 0.012, 1.0, hierro)
			cad.rotation_degrees = Vector3(0, 0, 0)
		var aro := TorusMesh.new()
		aro.inner_radius = 0.62
		aro.outer_radius = 0.7
		var mi := MeshInstance3D.new()
		mi.mesh = aro
		mi.material_override = hierro
		mi.position = Vector3(0, 4.4, 0)
		c.add_child(mi)
		var llama := u.mat(Color(1.0, 0.8, 0.4), 0.5, 0.0, Color(1.0, 0.7, 0.25), 3.0)
		for k in 8:
			var a := k * TAU / 8.0
			u.cyl(c, Vector3(sin(a) * 0.66, 4.5, cos(a) * 0.66), 0.025, 0.025, 0.14, u.mat(Color(0.9, 0.88, 0.8), 0.8))
			u.sphere(c, Vector3(sin(a) * 0.66, 4.62, cos(a) * 0.66), 0.03, llama, Vector3(1, 1.7, 1))
		var l := u.omni(c, Vector3(0, 4.2, 0), Color(1.0, 0.7, 0.4), 1.3, 9.5)
		parpadear(l, 6.0, true)
	# Antorchas junto a la entrada y a la reja
	for p in [[-8.7, 28.5, 90.0], [8.7, 28.5, -90.0], [-8.7, 6.0, 90.0], [8.7, 6.0, -90.0]]:
		var t := u.node3d(self, "Antorcha", Vector3(float(p[0]), 2.4, float(p[1])), float(p[2]))
		u.box(t, Vector3(0, 0, 0.1), Vector3(0.1, 0.5, 0.1), u.wood(), false, Vector3(-18, 0, 0))
		u.sphere(t, Vector3(0, 0.34, 0.2), 0.07, u.mat(Color(1.0, 0.85, 0.5), 0.5, 0.0, Color(1.0, 0.6, 0.15), 3.5), Vector3(1, 1.8, 1))
		var l2 := u.omni(t, Vector3(0, 0.45, 0.3), Color(1.0, 0.62, 0.3), 0.9, 6.0)
		parpadear(l2, 11.0, false)
	# Luz de luna fria que entra por los vitrales
	u.omni(self, Vector3(-7.0, 3.6, 12.0), Color(0.35, 0.45, 1.0), 0.7, 10.0)
	u.omni(self, Vector3(7.0, 3.6, 24.0), Color(0.5, 0.35, 0.9), 0.6, 10.0)
	u.omni(self, Vector3(7.2, 3.4, 15.0), Color(0.4, 0.45, 1.0), 0.7, 9.0)
	u.omni(self, Vector3(-7.2, 3.4, 23.5), Color(0.5, 0.4, 0.95), 0.7, 9.0)


func _vitrinas() -> void:
	var datos := [
		[Vector3(-7.9, 0, 11.0), 90.0, "espada", "Espada de la Orden del Acero", "[b]ESPADA LARGA DE LA ORDEN DEL ACERO[/b]\nHierro forjado · siglo XIV\n\nSimbolo de la hermandad de caballeros que custodio el amuleto. La hoja lleva grabada una frase en latin: «Vigilat qui non videtur»: vigila aquel a quien no se ve."],
		[Vector3(7.9, 0, 11.0), -90.0, "casco", "Yelmo de torneo", "[b]YELMO DE TORNEO[/b]\nAcero repujado · siglo XV\n\nUsado en justas. Los caballeros decian que ninguna armadura se queda quieta si nadie la mira.\n\n[i]Alex: «Siento que me mira... no, es solo la luz.»[/i]"],
		[Vector3(-7.9, 0, 17.0), 90.0, "corona", "Corona del rey Edric", "[b]CORONA DEL REY EDRIC[/b]\nOro y granates · siglo XII\n\nEl rey Edric encargo ocultar el amuleto en cuatro lugares. Su sepulcro esta en esta galeria."],
		[Vector3(7.9, 0, 17.0), -90.0, "caliz", "Caliz de plata", "[b]CALIZ DE PLATA[/b]\nPlata con esmaltes · siglo XIII\n\nPieza de la capilla del castillo. Se usaba en la misa previa a cada batalla."],
		[Vector3(-7.9, 0, 23.0), 90.0, "ballesta", "Ballesta de repeticion", "[b]BALLESTA DE REPETICION[/b]\nMadera y acero · siglo XV\n\nLa Armeria del museo (al norte) guarda mas piezas como esta, en pasillos estrechos pensados para defender la camara del tesoro."],
		[Vector3(7.9, 0, 23.0), -90.0, "escudo", "Escudo heraldico", "[b]ESCUDO HERALDICO[/b]\nMadera y cuero pintado · siglo XIV\n\nCruz de oro sobre campo azul: el emblema de la Orden del Acero."],
	]
	for d in datos:
		_vitrina(d[0], float(d[1]), String(d[2]), String(d[3]), String(d[4]))


## Vitrina medieval (mira hacia +z local).
func _vitrina(pos: Vector3, rot_y: float, pieza: String, titulo: String, texto: String) -> void:
	var v := u.node3d(self, "Vitrina_" + pieza, pos, rot_y)
	u.box(v, Vector3(0, 0.45, 0), Vector3(0.9, 0.9, 1.7), u.wood(), true)
	u.box(v, Vector3(0, 0.91, 0), Vector3(0.96, 0.04, 1.76), _oro)
	u.box(v, Vector3(0, 1.1, 0), Vector3(0.84, 0.36, 1.6), u.mat(Color(0.25, 0.04, 0.06), 1.0))   # terciopelo
	var vidrio := u.glass(Color(0.7, 0.85, 1.0, 0.10))
	u.box(v, Vector3(0, 1.65, 0), Vector3(0.9, 1.0, 1.7), vidrio)
	u.box(v, Vector3(0, 2.16, 0), Vector3(0.96, 0.04, 1.76), _oro)
	var p := Node3D.new()
	p.position = Vector3(0, 1.3, 0)
	v.add_child(p)
	match pieza:
		"espada":
			u.box(p, Vector3(0, 0, 0), Vector3(0.07, 0.025, 1.0), _acero)
			u.box(p, Vector3(0, 0.0, 0.38), Vector3(0.3, 0.03, 0.04), _oro)
			u.box(p, Vector3(0, 0.0, 0.5), Vector3(0.04, 0.04, 0.16), u.wood())
			u.sphere(p, Vector3(0, 0, 0.6), 0.035, _oro)
		"casco":
			u.sphere(p, Vector3(0, 0.12, 0), 0.19, _acero, Vector3(0.95, 1.1, 1.1))
			u.box(p, Vector3(0.17, 0.1, 0), Vector3(0.04, 0.025, 0.26), u.dark())
			u.cyl(p, Vector3(0, 0.34, -0.02), 0.01, 0.05, 0.16, u.mat(Color(0.5, 0.06, 0.08), 0.9))
		"corona":
			u.cyl(p, Vector3(0, 0.1, 0), 0.19, 0.19, 0.12, _oro)
			for k in 7:
				var a := k * TAU / 7.0
				u.cyl(p, Vector3(sin(a) * 0.19, 0.24, cos(a) * 0.19), 0.0, 0.035, 0.14, _oro)
				u.sphere(p, Vector3(sin(a) * 0.19, 0.12, cos(a) * 0.19), 0.022, u.mat(Color(0.5, 0.0, 0.08), 0.2, 0.0, Color(0.9, 0.1, 0.2), 0.8))
		"caliz":
			u.cyl(p, Vector3(0, 0.02, 0), 0.07, 0.1, 0.03, _acero)
			u.cyl(p, Vector3(0, 0.12, 0), 0.02, 0.02, 0.2, _acero)
			u.cyl(p, Vector3(0, 0.3, 0), 0.1, 0.045, 0.17, _acero)
		"ballesta":
			u.box(p, Vector3(0, 0.05, 0), Vector3(0.06, 0.07, 0.8), u.wood())
			u.box(p, Vector3(0, 0.07, -0.34), Vector3(0.7, 0.03, 0.04), u.wood(), false, Vector3(0, 0, 0))
			u.box(p, Vector3(0, 0.09, -0.34), Vector3(0.66, 0.006, 0.006), u.dark())
		"escudo":
			u.cyl(p, Vector3(0, 0.3, 0), 0.34, 0.34, 0.04, u.mat(Color(0.08, 0.14, 0.5), 0.9), Vector3(0, 0, 90))
			u.box(p, Vector3(0.025, 0.3, 0), Vector3(0.01, 0.6, 0.07), _oro)
			u.box(p, Vector3(0.025, 0.3, 0), Vector3(0.01, 0.07, 0.5), _oro)
	nota(v, "Leer placa", titulo, texto, "papel", "", null, Callable(), 3.6, Vector3(0, 1.4, 0))


func _trono() -> void:
	# Estrado del rey frente a la reja de la Armeria
	var t := u.node3d(self, "Trono", Vector3(0, 0, 7.4))
	u.box(t, Vector3(0, 0.15, 0), Vector3(3.6, 0.3, 2.4), u.stone(Color(0.4, 0.4, 0.46), 0.3), true)
	u.box(t, Vector3(0, 0.36, 0), Vector3(2.8, 0.12, 1.8), u.mat(Color(0.42, 0.05, 0.07), 1.0))
	var madera := u.wood()
	u.box(t, Vector3(0, 0.75, -0.35), Vector3(0.9, 0.5, 0.8), madera, true)
	u.box(t, Vector3(0, 1.0, -0.35), Vector3(0.7, 0.1, 0.6), u.mat(Color(0.42, 0.05, 0.07), 1.0))
	u.box(t, Vector3(0, 1.5, -0.7), Vector3(0.9, 1.4, 0.12), madera)
	u.box(t, Vector3(0, 2.28, -0.7), Vector3(1.1, 0.2, 0.16), _oro)
	for s in [-1.0, 1.0]:
		u.box(t, Vector3(s * 0.5, 1.1, -0.35), Vector3(0.1, 0.4, 0.7), madera)
		u.cyl(t, Vector3(s * 0.55, 1.4, -0.7), 0.03, 0.03, 0.9, madera)
		u.sphere(t, Vector3(s * 0.55, 1.88, -0.7), 0.06, _oro)


func _tumba() -> void:
	# Sepulcro de Sir Edric con efigie; el FRAGMENTO 2 reposa sobre su pecho
	var t := u.node3d(self, "TumbaCaballero", Vector3(-6.4, 0, 19.2))
	var piedra := u.stone(Color(0.5, 0.5, 0.56), 0.35)
	u.box(t, Vector3(0, 0.4, 0), Vector3(1.0, 0.8, 2.2), piedra, true)
	u.box(t, Vector3(0, 0.86, 0), Vector3(1.12, 0.12, 2.34), u.stone(Color(0.38, 0.38, 0.44), 0.35))
	var efigie := u.stone(Color(0.62, 0.62, 0.68), 0.5)
	u.box(t, Vector3(0, 1.0, 0.05), Vector3(0.42, 0.16, 1.2), efigie)
	u.sphere(t, Vector3(0, 1.1, -0.7), 0.13, efigie, Vector3(0.95, 1.0, 1.1))
	u.box(t, Vector3(0, 1.0, 0.85), Vector3(0.3, 0.12, 0.3), efigie)
	for s in [-1.0, 1.0]:
		u.box(t, Vector3(s * 0.22, 1.02, -0.05), Vector3(0.1, 0.1, 0.55), efigie)
	u.box(t, Vector3(0, 1.1, 0.1), Vector3(0.05, 0.05, 1.0), _acero)
	u.box(t, Vector3(0, 1.1, -0.2), Vector3(0.34, 0.04, 0.05), _acero)
	u.box(t, Vector3(0.505, 0.45, 0), Vector3(0.02, 0.5, 0.9), _oro)
	u.text3d(t, "SIR EDRIC", Vector3(0.52, 0.45, 0.0), 90.0, 40, Color(0.12, 0.08, 0.02), 0.004)

	# Fragmento 2
	var f := u.node3d(t, "Fragmento2", Vector3(0, 1.2, -0.25), 15.0)
	var pieza := u.box(f, Vector3(0, 0.0, 0), Vector3(0.2, 0.05, 0.13), u.mat(Color(0.5, 0.48, 0.45), 0.8), false, Vector3(0, 0, 8))
	var glifo := u.mat(Color(0.05, 0.25, 0.22), 0.3, 0.0, Color(0.2, 1.0, 0.85), 3.0)
	for i in 3:
		u.box(pieza, Vector3(-0.05 + i * 0.05, 0.027, 0), Vector3(0.012, 0.004, 0.08), glifo)
	luz_fija(u.omni(f, Vector3(0, 0.2, 0), Color(0.3, 1.0, 0.85), 0.7, 3.0))
	pickup(f, "Tomar fragmento del amuleto", "fragmento", "Fragmento del amuleto (2/4). El sepulcro cruje...", 1, Callable(self, "_tomo_fragmento2"), Vector3(0, 0.1, 0))

	# Diario 5 sobre la tapa de la tumba
	var d5 := hoja_papel(t, Vector3(0.28, 0.935, 0.95), 20.0, Vector2(0.21, 0.3))
	var tx := "[b]DIARIO DE LA DRA. ELENA TORRES - 5[/b]\n\n"
	tx += "Sir Edric fue el ultimo custodio del amuleto. Su orden, la [b]Orden del Acero[/b], dejo vigilantes de metal en esta galeria: armaduras que ahora se mueven cuando nadie las mira, y mucho mas rapido que las estatuas de piedra.\n\n"
	tx += "Los [b]reflectores de exhibicion[/b] del techo son la defensa original: un foco orientable. Giren cada uno con su panel hasta que la luz toque a la armadura y quedara [b]inmovilizada para siempre[/b]. Solo un rumbo funciona.\n\n"
	tx += "El segundo fragmento esta sobre el pecho de Edric. El tercero, al fondo de la Armeria: la reja se abre con el [b]año de fundacion de la Orden[/b], grabado en el escudo del fundador.\n\n"
	tx += "[i]Cuando tomen el fragmento, el sepulcro despertara a otra armadura. Aseguren primero la salida.[/i]"
	nota(d5, "Leer diario", "Diario de la Dra. Torres (5)", tx, "papel", "", d5)


func _tomo_fragmento2() -> void:
	estado.poner_flag("frag2")
	Sfx.tocar("golpe")
	estado.mensaje.emit("Algo se mueve entre las sombras de la galería...")
	estado.despertar.emit("wake_frag2")


func _armadura(nombre: String, pos: Vector3, rot_y: float, grupo: String, color: Color) -> Node3D:
	var e := EstatuaEnemiga.new()
	e.name = nombre
	e.position = pos
	e.rotation_degrees.y = rot_y
	e.tipo = "ARMADURA"
	e.velocidad = 2.1
	e.ruidosa = true
	e.region = REGION
	e.add_to_group(grupo)
	e.set_meta("enemy_type", "ARMADURA")
	add_child(e)
	Modelos.armadura(e, u, color)
	examinar(e, "Examinar armadura", "Una armadura de placas de la Orden del Acero, hueca y fría. Hace ruido al moverse. Alex: «Qué mala espina... esto estaba de pie hace un rato.»", e, Vector3(0, 1.6, 0))
	return e


func _armaduras_y_reflectores() -> void:
	# Armadura 1 (este) y 2 (oeste) despiertan al entrar; la 3 (cerca de la salida) al tomar el fragmento
	_armadura("ArmaduraGaleria1", Vector3(6.6, 0, 22.0), -90.0, "wake_galeria", Color(0.1, 0.18, 0.5))
	_armadura("ArmaduraGaleria2", Vector3(-6.6, 0, 10.5), 90.0, "wake_galeria", Color(0.5, 0.06, 0.08))
	_armadura("ArmaduraGaleria3", Vector3(-6.6, 0, 26.0), 90.0, "wake_frag2", Color(0.12, 0.35, 0.2))
	# Reflectores: rumbo correcto  E / O / O. Cada uno empieza mal orientado.
	_reflector("Reflector 1", Vector3(3.0, 5.0, 22.0), 3, Vector3(2.2, 0, 22.0), 1.57)
	_reflector("Reflector 2", Vector3(-3.0, 5.0, 10.5), 1, Vector3(-2.2, 0, 10.5), -1.57)
	_reflector("Reflector 3", Vector3(-3.0, 5.0, 26.0), 0, Vector3(-2.2, 0, 26.0), -1.57)


## Reflector colgado del techo + su panel de control (palanca). inclinacion -48: apunta a media altura a ~3.5 m.
func _reflector(rotulo: String, pos_techo: Vector3, rumbo_ini: int, pos_panel: Vector3, rot_panel: float) -> void:
	var r := Reflector.new()
	r.name = rotulo.replace(" ", "")
	r.position = pos_techo
	r.rumbo = rumbo_ini
	r.inclinacion = -48.0
	add_child(r)
	r.fijo_estatua.connect(_reflector_fijo)
	# Panel: atril con palanca
	var p := u.node3d(self, "Panel" + r.name, pos_panel, rad_to_deg(rot_panel))
	var metal := u.metal(Color(0.2, 0.2, 0.24))
	u.box(p, Vector3(0, 0.5, 0), Vector3(0.5, 1.0, 0.4), metal, true)
	u.box(p, Vector3(0, 1.05, 0.05), Vector3(0.52, 0.1, 0.46), metal, false, Vector3(-20, 0, 0))
	u.cyl(p, Vector3(0.12, 1.15, 0.12), 0.015, 0.015, 0.25, u.dark(), Vector3(25, 0, 10))
	u.sphere(p, Vector3(0.14, 1.28, 0.2), 0.04, u.mat(Color(0.7, 0.05, 0.05), 0.4))
	u.box(p, Vector3(-0.12, 1.1, 0.16), Vector3(0.14, 0.05, 0.04), u.mat(Color(0.3, 0.05, 0.0), 0.5, 0.0, Color(1.0, 0.4, 0.1), 1.6))
	u.text3d(p, rotulo.to_upper(), Vector3(0, 0.62, 0.21), 0.0, 24, Color(0.9, 0.8, 0.4), 0.003)
	reg(p, "reflector", "Girar " + rotulo.to_lower(), {"reflector": r}, 3.2, Vector3(0, 1.1, 0), p)


func _reflector_fijo(_e: Node3D) -> void:
	Sfx.tocar("beep_ok")
	estado.mensaje.emit("¡La luz del reflector fija a la armadura! Queda inmóvil para siempre.")
	estado.radio_una_vez("reflector", "ROBERTO (radio): «¡Eso es! Mira cómo se quedó... el foco la tiene atrapada. Una menos, Alex.»")


# ---------------------------------------------------------------- puertas y avisos

func _puerta_armeria() -> void:
	var hierro := u.mat(Color(0.10, 0.10, 0.12), 0.5, 0.7)
	var d := crear_puerta("ReJaArmeria", Vector3(-1.2, 0, 3.75), 0.0, 2.4, 3.1, 90.0, hierro, "candado", {
		"codigo": "1348",
		"titulo": "REJA DE LA ARMERÍA",
		"pista": "Cuatro dígitos: el año de fundación de la Orden del Acero, grabado en el escudo del fundador.",
		"al_abrir": Callable(self, "_abrio_armeria"),
	})
	d["it"]["texto"] = "Reja con candado"
	# Barrotes extra sobre la hoja (decoracion)
	var hoja := (d["hinge"] as Node3D)
	for k in 7:
		u.box(hoja, Vector3(0.2 + k * 0.33, 1.55, 0.05), Vector3(0.04, 3.0, 0.04), u.metal(Color(0.25, 0.25, 0.28)))
	# Escudo del fundador (con el año)
	var e := u.node3d(self, "EscudoFundador", Vector3(-3.6, 2.3, 4.05), 0.0)
	u.cyl(e, Vector3.ZERO, 0.42, 0.42, 0.05, u.mat(Color(0.35, 0.05, 0.07), 0.8), Vector3(90, 0, 0))
	u.cyl(e, Vector3(0, 0, 0.03), 0.4, 0.4, 0.02, _oro, Vector3(90, 0, 0))
	u.cyl(e, Vector3(0, 0, 0.04), 0.36, 0.36, 0.02, u.mat(Color(0.12, 0.2, 0.55), 0.8), Vector3(90, 0, 0))
	u.sphere(e, Vector3(0, 0, 0.07), 0.07, _oro)
	u.box(e, Vector3(0, 0, 0.06), Vector3(0.06, 0.66, 0.015), _oro)
	u.box(e, Vector3(0, 0, 0.06), Vector3(0.66, 0.06, 0.015), _oro)
	u.text3d(e, "1348", Vector3(0, -0.5, 0.02), 0.0, 36, Color(0.9, 0.75, 0.3), 0.004)
	var tx := "[b]ESCUDO DEL FUNDADOR[/b]\nOrden del Acero\n\nEn el borde, cincelado: «Fundada en el año de gracia [b]1348[/b]».\n\n[i]Alex: «Cuatro dígitos... ¡el candado de la reja!»[/i]"
	nota(e, "Leer escudo del fundador", "Escudo del fundador", tx, "papel", "", e, Callable(), 3.6, Vector3(0, 0, 0.5))


func _abrio_armeria() -> void:
	estado.poner_flag("armeria_abierta")
	estado.mensaje.emit("La reja se abre con un chirrido metálico... La Armería está al fondo.")


func _puerta_piso3() -> void:
	var hoja := u.mat(Color(0.2, 0.2, 0.24), 0.5, 0.6)
	var d := crear_puerta("PuertaPiso3", Vector3(9.25, 0, 6.2), -90.0, 1.4, 2.8, 90.0, hoja, "tarjeta", {
		"item_req": "tarjeta_roja",
		"msg_falta": "Lector de acceso: se necesita la tarjeta de acceso Nivel 2 (roja).",
		"al_abrir": Callable(self, "_abrio_piso3"),
	})
	lector_tarjeta(d, Vector3(8.96, 1.25, 5.85), -90.0)
	u.text3d(self, "ESCALERA AL PISO 3", Vector3(8.95, 3.15, 6.9), -90.0, 36, Color(0.95, 0.75, 0.3), 0.004)
	# Descanso oscuro detras de la puerta (el piso 3 todavia no existe)
	var osc := u.stone(Color(0.2, 0.2, 0.25), 0.3)
	u.box(self, Vector3(11.0, -0.25, 6.9), Vector3(3.0, 0.5, 3.0), osc, true)
	u.box(self, Vector3(11.0, 3.2, 6.9), Vector3(3.0, 0.4, 3.0), osc, true)
	wall_x(5.35, 9.5, 12.5, 0.3, 3.4, osc)
	wall_x(8.45, 9.5, 12.5, 0.3, 3.4, osc)
	wall_z(12.65, 5.2, 8.6, 0.3, 3.4, osc)
	u.text3d(self, "PISO 3\nPAVELLÓN DE PALEONTOLOGÍA\nPRÓXIMAMENTE", Vector3(12.45, 1.8, 6.9), -90.0, 30, Color(0.95, 0.75, 0.3), 0.004)


func _abrio_piso3() -> void:
	estado.poner_flag("piso3_abierto")
	estado.mensaje.emit("Acceso concedido. Piso 3: Pabellón de Paleontología (próximamente).")


func _avisos() -> void:
	# Aviso de Roberto junto a la escalera: el walkie sirve de señuelo
	var tablero := u.node3d(self, "AvisoRoberto", Vector3(-8.95, 1.7, 27.2), 90.0)
	u.box(tablero, Vector3.ZERO, Vector3(0.7, 0.5, 0.04), u.wood())
	var papel := hoja_papel(tablero, Vector3(0, 0, 0.03), 0.0, Vector2(0.4, 0.3))
	papel.rotation_degrees.x = 90
	var tx := "[b]AVISO PARA EL TURNO DE NOCHE[/b]\n\n"
	tx += "Las armaduras de este piso son [b]ruidosas[/b]: se oyen venir por el pasillo aunque no las veas.\n\n"
	tx += "Si te persiguen, usa el [b]walkie-talkie[/b]: presiona [b]R[/b] para dejarlo sonando en el suelo. Las armaduras irán hacia el pitido unos segundos y te dará tiempo de cruzar la puerta.\n\n"
	tx += "No lo uses seguido: la batería del walkie tarda en recuperarse.\n\n[i]— Roberto[/i]"
	nota(tablero, "Leer aviso de Roberto", "Aviso para el turno de noche", tx, "papel", "", tablero)
