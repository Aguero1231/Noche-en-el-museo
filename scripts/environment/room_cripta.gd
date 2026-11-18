extends "res://scripts/environment/room_base.gd"

## PISO 4: cripta subterranea. Tres momias despiertan cuando Alex entra al recinto.

const EstatuaEnemiga = preload("res://scripts/enemies/estatua_enemiga.gd")

const REGION_MOMIAS := Rect2(-9.0, 17.0, 18.0, 26.0)
const ANCHO := 22.0
const FONDO := 28.0
const ALTURA := 4.8


func build() -> void:
	var piedra := u.stone(Color(0.27, 0.25, 0.23), 0.34)
	var losa := u.stone(Color(0.37, 0.34, 0.29), 0.25)
	var bronce := u.metal(Color(0.34, 0.24, 0.12))
	var vendaje := u.mat(Color(0.55, 0.47, 0.34), 0.92)
	var sombra_vendaje := u.mat(Color(0.25, 0.22, 0.19), 0.95)

	# La raiz queda en y=-9, debajo de la planta baja, y alineada con la escalera exterior.
	u.box(self, Vector3(0, -0.25, 17.0), Vector3(ANCHO, 0.5, FONDO), u.marble(Color(0.24, 0.23, 0.25), 0.18), true, Vector3.ZERO, "SueloCripta")
	u.box(self, Vector3(0, ALTURA + 0.2, 17.0), Vector3(ANCHO, 0.4, FONDO), piedra, true, Vector3.ZERO, "TechoCripta")
	# Entrada por el muro norte, centrada con el ultimo descanso de la escalera.
	wall_z(-11.0, 3.0, 31.0, 0.5, ALTURA, piedra)
	wall_z(11.0, 3.0, 31.0, 0.5, ALTURA, piedra)
	wall_x(3.0, -11.0, 11.0, 0.5, ALTURA, piedra)
	wall_x(31.0, -11.0, 11.0, 0.5, ALTURA, piedra, [{"a": 1.65, "b": 4.35, "h": 2.9}])
	zocalo_z(-10.75, 1.0, 3.0, 31.0, [], 0.8)
	zocalo_z(10.75, -1.0, 3.0, 31.0, [], 0.8)
	zocalo_x(3.25, 1.0, -11.0, 11.0, [], 0.8)
	zocalo_x(30.75, -1.0, -11.0, 11.0, [{"a": 1.65, "b": 4.35}], 0.8)
	_banda_sarcografos(piedra, losa, bronce)
	_luces(bronce)
	_sarcografos(losa, bronce)
	_altares_y_pistas(bronce)
	_crear_momia("MomiaCriptaA", Vector3(-6.0, 0, 11.0), vendaje, sombra_vendaje, 1.0)
	_crear_momia("MomiaCriptaB", Vector3(6.0, 0, 18.0), vendaje, sombra_vendaje, 1.15)
	_crear_momia("MomiaCriptaC", Vector3(-1.0, 0, 25.0), vendaje, sombra_vendaje, 1.05)
	_fragmento4(vendaje, bronce)


func _banda_sarcografos(piedra: Material, losa: Material, bronce: Material) -> void:
	for z in [7.0, 14.0, 21.0, 28.0]:
		for x in [-8.4, 8.4]:
			u.box(self, Vector3(x, 0.04, z), Vector3(3.3, 0.08, 4.0), piedra, true, Vector3.ZERO, "BaseNicho")
			u.box(self, Vector3(x, 0.16, z), Vector3(3.0, 0.12, 3.7), losa)
	for x in [-10.3, 10.3]:
		for z in [8.0, 15.0, 22.0, 29.0]:
			u.box(self, Vector3(x, 1.0, z), Vector3(0.38, 2.0, 0.38), piedra, true, Vector3.ZERO, "PilarCripta")
			u.box(self, Vector3(x, 2.08, z), Vector3(0.58, 0.16, 0.58), bronce)
	# Friso y marcas antiguas para que la sala tenga lectura visual desde la entrada.
	for lado in [-1.0, 1.0]:
		var x: float = float(lado) * 10.72
		u.box(self, Vector3(x, 3.75, 17.0), Vector3(0.08, 0.12, 27.0), bronce)
		for z in [9.0, 16.0, 23.0, 29.0]:
			u.box(self, Vector3(x - lado * 0.08, 2.4, z), Vector3(0.035, 0.8, 0.55), bronce)


func _luces(bronce: Material) -> void:
	var llama := u.mat(Color(0.67, 0.31, 0.12), 0.5, 0.0, Color(0.9, 0.18, 0.04), 0.8)
	for z in [7.0, 15.0, 23.0, 29.0]:
		var antorcha := u.node3d(self, "AntorchaCripta", Vector3(0, 3.65, z))
		u.box(antorcha, Vector3(0, 0.0, 0), Vector3(0.48, 0.09, 0.48), bronce)
		u.cyl(antorcha, Vector3(0, -0.18, 0), 0.055, 0.07, 0.3, bronce)
		u.sphere(antorcha, Vector3(0, -0.43, 0), 0.11, llama)
		var luz := u.omni(antorcha, Vector3(0, -0.56, 0), Color(1.0, 0.4, 0.16), 0.95, 7.0)
		luz_fija(luz)
	# Apliques laterales de baja intensidad revelan los sarcófagos sin borrar el tono de cripta.
	for indice in range(3):
		var lado: float = -1.0 if indice % 2 == 0 else 1.0
		var z: float = 10.0 + float(indice) * 8.0
		var aplique := u.node3d(self, "ApliqueCripta", Vector3(lado * 10.35, 2.65, z))
		u.box(aplique, Vector3(-lado * 0.18, 0, 0), Vector3(0.34, 0.10, 0.18), bronce)
		u.sphere(aplique, Vector3(-lado * 0.36, -0.02, 0), 0.10, llama, Vector3(0.8, 1.4, 0.8))
		var luz_lateral := u.omni(aplique, Vector3(-lado * 0.38, -0.04, 0), Color(1.0, 0.52, 0.24), 0.38, 4.8)
		luz_fija(luz_lateral)


func _sarcografos(losa: Material, bronce: Material) -> void:
	for datos in [Vector3(-8.4, 8.0, 0), Vector3(8.4, 14.0, 180), Vector3(-8.4, 22.0, 0), Vector3(8.4, 28.0, 180)]:
		var sarco := u.node3d(self, "Sarcófago", Vector3(datos.x, 0, datos.y), datos.z)
		u.box(sarco, Vector3(0, 0.46, 0), Vector3(2.1, 0.85, 3.2), losa, true)
		u.box(sarco, Vector3(0, 0.94, 0), Vector3(2.18, 0.12, 3.28), bronce, true)
		u.box(sarco, Vector3(0, 1.07, -0.7), Vector3(1.15, 0.20, 0.72), losa)
		u.sphere(sarco, Vector3(0, 1.20, -1.05), 0.26, losa, Vector3(0.8, 0.55, 1.15))
		for i in 3:
			u.box(sarco, Vector3(0, 1.19, -0.2 + i * 0.38), Vector3(0.9, 0.025, 0.055), bronce)


func _altares_y_pistas(bronce: Material) -> void:
	var altar := u.node3d(self, "AltarCripta", Vector3(0, 0, 7.0))
	u.box(altar, Vector3(0, 0.45, 0), Vector3(2.1, 0.9, 1.8), u.stone(Color(0.27, 0.25, 0.22), 0.28), true)
	u.box(altar, Vector3(0, 0.94, 0), Vector3(2.3, 0.1, 2.0), bronce)
	var tabla := u.node3d(self, "InscripcionFinal", Vector3(0, 1.5, 4.8))
	u.box(tabla, Vector3(0, 0.85, 0), Vector3(2.6, 1.8, 0.14), u.stone(Color(0.31, 0.28, 0.24), 0.4), true)
	u.text3d(tabla, "EL SELLO\nDEBE CERRARSE", Vector3(0, 0.8, 0.09), 0.0, 24, Color(0.78, 0.65, 0.42), 0.003)
	var hoja := hoja_papel(altar, Vector3(1.0, 1.0, 0.55), -12.0, Vector2(0.35, 0.25))
	var cuerpo := "[b]REGISTRO DE LA CRIPTA[/b]\n\n"
	cuerpo += "Los cuatro fragmentos no son un tesoro: son las piezas de un sello. La estatua de Anubis guarda la entrada al recinto y reaccionara cuando el amuleto vuelva a estar completo.\n\n"
	cuerpo += "Las momias protegen el último fragmento. La escalera norte lleva de regreso a Paleontología."
	nota(hoja, "Leer registro de la cripta", "Registro de la cripta", cuerpo, "papel", "— Archivo del museo", hoja)


func _crear_momia(nombre: String, pos: Vector3, vendaje: Material, sombra: Material, rapidez: float) -> void:
	var enemigo := EstatuaEnemiga.new()
	enemigo.name = nombre
	enemigo.tipo = "MOMIA"
	enemigo.velocidad = rapidez
	enemigo.distancia_aviso = 7.5
	enemigo.region = REGION_MOMIAS
	enemigo.position = pos
	enemigo.add_to_group("wake_cripta")
	enemigo.set_meta("enemy_type", "MOMIA")
	add_child(enemigo)
	var visual := Node3D.new()
	visual.name = "Visual"
	enemigo.add_child(visual)
	# Envoltura de tela con silueta encorvada, piezas de venda y brazos extendidos.
	u.cyl(visual, Vector3(0, 0.91, 0), 0.25, 0.36, 0.95, sombra, Vector3.ZERO, 10)
	u.sphere(visual, Vector3(0, 1.43, 0.02), 0.23, vendaje, Vector3(0.9, 1.1, 0.86))
	u.cyl(visual, Vector3(0, 0.28, -0.05), 0.19, 0.24, 0.48, sombra, Vector3.ZERO, 9)
	for y_value in [0.52, 0.72, 0.92, 1.12, 1.31]:
		var y: float = float(y_value)
		var faja := u.cyl(visual, Vector3(0, y, 0), 0.29 - (y - 0.52) * 0.08, 0.30 - (y - 0.52) * 0.08, 0.075, vendaje, Vector3.ZERO, 10)
		faja.rotation_degrees.y = 8.0 if int(y * 100.0) % 2 == 0 else -8.0
	for lado in [-1.0, 1.0]:
		u.cyl(visual, Vector3(lado * 0.38, 1.0, 0.08), 0.12, 0.10, 0.66, sombra, Vector3(0, 0, lado * 48.0), 9)
		u.cyl(visual, Vector3(lado * 0.56, 0.73, 0.12), 0.085, 0.07, 0.53, vendaje, Vector3(0, 0, lado * -22.0), 9)
		for i in 3:
			u.box(visual, Vector3(lado * (0.55 + i * 0.014), 0.46, 0.22 + i * 0.045), Vector3(0.035, 0.48, 0.035), vendaje, false, Vector3(0, 0, lado * 5.0))
	# Ojos hundidos bajo las vendas: se iluminan cuando la momia empieza a avanzar.
	var ojos := u.mat(Color(0.33, 0.012, 0.004), 0.18, 0.0, Color(1.0, 0.015, 0.002), 0.0)
	for lado in [-1.0, 1.0]:
		u.sphere(visual, Vector3(lado * 0.09, 1.48, 0.19), 0.038, ojos)
	visual.set_meta("ojos", [ojos])


func _fragmento4(vendaje: Material, bronce: Material) -> void:
	var pedestal := u.node3d(self, "PedestalFragmento4", Vector3(0, 0, 7.0))
	u.box(pedestal, Vector3(0, 1.05, 0), Vector3(0.65, 1.9, 0.65), u.stone(Color(0.29, 0.27, 0.25), 0.28), true)
	u.box(pedestal, Vector3(0, 2.04, 0), Vector3(1.0, 0.1, 1.0), bronce)
	var pieza := u.node3d(pedestal, "Fragmento4", Vector3(0, 2.15, 0), -14.0)
	u.box(pieza, Vector3.ZERO, Vector3(0.25, 0.06, 0.18), vendaje)
	var glifo := u.mat(Color(0.12, 0.08, 0.03), 0.32, 0.0, Color(1.0, 0.49, 0.1), 2.0)
	u.box(pieza, Vector3(0, 0.034, 0), Vector3(0.04, 0.008, 0.13), glifo)
	luz_fija(u.omni(pieza, Vector3(0, 0.3, 0), Color(1.0, 0.42, 0.12), 0.82, 4.2))
	pickup(pieza, "Tomar el cuarto fragmento", "fragmento", "Fragmento del amuleto (4/4). Ya puedes reunir las cuatro piezas en el pedestal de la Sala Egipcia.", 1, Callable(self, "_tomo_fragmento4"), Vector3(0, 0.1, 0))


func _tomo_fragmento4() -> void:
	estado.poner_flag("frag4")
	estado.poner_flag("piso4_fragmento_obtenido")
	Sfx.tocar("golpe")
	estado.mensaje.emit("El amuleto está completo. Regresa a la Sala Egipcia y colócalo en el pedestal.")
