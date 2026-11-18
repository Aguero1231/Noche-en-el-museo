extends "res://scripts/environment/room_base.gd"

## PISO 3: Pabellon de Paleontologia y Boveda de Contencion.
## La lamina del microscopio revela el orden de los tres sellos: craneo, costillas y cola.

const EstatuaEnemiga = preload("res://scripts/enemies/estatua_enemiga.gd")

const X0 := -9.0
const X1 := 9.0
const Z0 := 3.5
const Z1 := 30.5
const ALTURA := 5.6
const REGION_FOSIL := Rect2(-7.4, 6.4, 14.8, 14.2)
const SECUENCIA_SEGURO := [0, 1, 2]

var _progreso_seguro := 0
var _reja_boveda: MeshInstance3D
var _ojos_fosil: Array[StandardMaterial3D] = []


func build() -> void:
	var piedra := u.stone(Color(0.35, 0.39, 0.46), 0.34)
	var oscuro := u.stone(Color(0.13, 0.16, 0.21), 0.36)
	var laton := u.gold()
	var hueso := u.mat(Color(0.72, 0.66, 0.51), 0.82)
	var hueso_sombra := u.mat(Color(0.36, 0.32, 0.25), 0.9)

	u.box(self, Vector3(0, -0.25, 17.0), Vector3(19.0, 0.5, 28.0), u.marble(Color(0.30, 0.34, 0.40), 0.16), true, Vector3.ZERO, "PisoPaleontologia")
	u.box(self, Vector3(0, ALTURA + 0.2, 17.0), Vector3(19.0, 0.4, 28.0), oscuro, true, Vector3.ZERO, "TechoPaleontologia")
	wall_z(-9.25, Z0, Z1, 0.5, ALTURA, piedra)
	# Vano ancho y a ras de suelo para recibir el rellano de la escalera sin un borde que bloquee el paso.
	wall_z(9.25, Z0, Z1, 0.5, ALTURA, piedra, [{"a": 8.0, "b": 11.0, "h": 3.0}])
	wall_x(Z0, X0, X1, 0.5, ALTURA, piedra)
	# La salida al sótano atraviesa el muro norte; la escalera exterior baja por un tiro protegido.
	wall_x(Z1, X0, X1, 0.5, ALTURA, piedra, [{"a": -4.1, "b": -1.9, "h": 3.0}])
	zocalo_z(X0, 1.0, Z0, Z1, [], 1.0)
	zocalo_z(X1, -1.0, Z0, Z1, [{"a": 8.0, "b": 11.0}], 1.0)
	zocalo_x(Z0, 1.0, X0, X1, [], 1.0)
	zocalo_x(Z1, -1.0, X0, X1, [{"a": -4.1, "b": -1.9}], 1.0)
	_banda_exhibicion(laton, oscuro)
	_detalles_pabellon(piedra, laton)
	_luces(laton)
	_exhibiciones(hueso, hueso_sombra, laton)
	_microscopio_y_diario(laton)
	_seguro_boveda(piedra, laton)
	_crear_fosil(hueso, hueso_sombra)
	_fragmento(hueso, laton)
	_escalera_sotano(piedra, laton)


func _escalera_sotano(piedra: Material, metal: Material) -> void:
	# Escalera exterior de tres tramos: evita cortar los pisos ya construidos del museo.
	var marco := u.stone(Color(0.22, 0.25, 0.31), 0.32)
	u.box(self, Vector3(-3.0, 0.02, 30.95), Vector3(2.2, 0.04, 1.2), piedra, true, Vector3.ZERO, "UmbralSotano")
	u.text3d(self, "CRIPTA  ·  PISO 4", Vector3(0, 2.25, 30.28), 0.0, 27, Color(0.68, 0.78, 0.9), 0.003)
	# Las tres rampas descienden nueve metros cada una, en una caja abierta con barandales.
	_tramo_sotano(-3.0, 31.5, 41.5, 0.0, -9.0, piedra, metal)
	u.box(self, Vector3(-1.5, -9.0, 41.5), Vector3(3.0, 0.22, 2.1), marco, true, Vector3.ZERO, "DescansoSotano1")
	_tramo_sotano(0.0, 41.5, 31.5, -9.0, -18.0, piedra, metal)
	u.box(self, Vector3(1.5, -18.0, 31.5), Vector3(3.0, 0.22, 2.1), marco, true, Vector3.ZERO, "DescansoSotano2")
	_tramo_sotano(3.0, 31.5, 41.5, -18.0, -27.0, piedra, metal)
	# Descanso y pasillo corto a la puerta norte de la cripta (piso global -9 m).
	u.box(self, Vector3(3.0, -27.0, 43.0), Vector3(2.2, 0.22, 3.2), marco, true, Vector3.ZERO, "DescansoEntradaCripta")
	for pos in [Vector3(-5.0, -4.5, 36.5), Vector3(2.0, -13.5, 36.5), Vector3(5.0, -22.5, 36.5)]:
		var farol_pos: Vector3 = pos
		var farol := u.node3d(self, "FarolSotano", farol_pos)
		u.box(farol, Vector3.ZERO, Vector3(0.24, 0.55, 0.24), metal)
		var llama := u.mat(Color(0.8, 0.37, 0.12), 0.35, 0.0, Color(1.0, 0.22, 0.04), 1.2)
		u.sphere(farol, Vector3(0, -0.37, 0), 0.12, llama)
		var luz := u.omni(farol, Vector3(0, -0.55, 0), Color(1.0, 0.42, 0.16), 0.95, 7.0)
		luz_fija(luz)


func _tramo_sotano(x: float, z0: float, z1: float, y0: float, y1: float, piedra: Material, metal: Material) -> void:
	var cantidad := 36
	var dz := z1 - z0
	var dy := y1 - y0
	var angulo := atan2(-dy, dz)
	var largo := Vector2(dz, dy).length()
	u.box(self, Vector3(x, (y0 + y1) * 0.5, (z0 + z1) * 0.5), Vector3(2.15, 0.18, largo), piedra, true, Vector3(rad_to_deg(angulo), 0, 0), "BaseRampaSotano")
	for i in cantidad:
		var t := (float(i) + 0.5) / float(cantidad)
		var z := lerpf(z0, z1, t)
		var y := lerpf(y0, y1, float(i) / float(cantidad))
		u.box(self, Vector3(x, y - absf(dy) / cantidad * 0.5, z), Vector3(2.2, absf(dy) / cantidad, absf(dz) / cantidad + 0.025), piedra)
		var nariz_z := z + signf(dz) * (absf(dz) / cantidad * 0.46)
		u.box(self, Vector3(x, y - 0.025, nariz_z), Vector3(2.2, 0.035, 0.035), metal)
	# Pasamanos continuos y montantes, siempre por ambos lados del tramo.
	var baranda := u.metal(Color(0.24, 0.25, 0.29))
	for lado in [-1.0, 1.0]:
		var bx := x + float(lado) * 1.03
		for i in 9:
			var t := float(i) / 8.0
			u.box(self, Vector3(bx, lerpf(y0, y1, t) + 0.5, lerpf(z0, z1, t)), Vector3(0.07, 0.85, 0.07), baranda)
		u.box(self, Vector3(bx, (y0 + y1) * 0.5 + 0.95, (z0 + z1) * 0.5), Vector3(0.09, 0.09, largo), baranda, true, Vector3(rad_to_deg(angulo), 0, 0))


func _banda_exhibicion(laton: Material, oscuro: Material) -> void:
	var friso := u.mat(Color(0.08, 0.12, 0.17), 0.8)
	for lado in [[X0 + 0.03, 90.0], [X1 - 0.03, -90.0]]:
		var panel := u.node3d(self, "FrisoFosiles", Vector3(float(lado[0]), 4.65, 17.0), float(lado[1]))
		u.box(panel, Vector3.ZERO, Vector3(27.0, 0.42, 0.04), friso)
		u.box(panel, Vector3(0, 0.23, 0.02), Vector3(27.0, 0.045, 0.05), laton)
		u.box(panel, Vector3(0, -0.23, 0.02), Vector3(27.0, 0.045, 0.05), laton)
	for z in [8.0, 14.0, 20.0, 26.0]:
		for x in [-5.8, 5.8]:
			var vitrina := u.node3d(self, "VitrinaFosil", Vector3(x, 0.0, z))
			u.box(vitrina, Vector3(0, 0.12, 0), Vector3(3.5, 0.22, 2.2), oscuro)
			u.box(vitrina, Vector3(0, 0.27, 0), Vector3(3.35, 0.06, 2.05), laton)
			# Estructura superior abierta: ligera para conservar visibilidad y rendimiento.
			for sx in [-1.0, 1.0]:
				for sz in [-1.0, 1.0]:
					u.box(vitrina, Vector3(sx * 1.6, 1.12, sz * 0.98), Vector3(0.055, 1.65, 0.055), laton)
			for sx in [-1.0, 1.0]:
				u.box(vitrina, Vector3(sx * 1.6, 1.90, 0), Vector3(0.055, 0.055, 2.0), laton)
			if z == 8.0:
				_fosil_costillas(vitrina, Vector3.ZERO, u.mat(Color(0.65, 0.59, 0.46), 0.9), oscuro)
			elif z == 14.0:
				# Amonite decorativa de perfil.
				var ammonite := TorusMesh.new()
				ammonite.inner_radius = 0.10
				ammonite.outer_radius = 0.26
				var m := MeshInstance3D.new()
				m.mesh = ammonite
				m.material_override = u.mat(Color(0.68, 0.55, 0.35), 0.86)
				m.position = Vector3(0, 0.83, 0)
				m.rotation_degrees = Vector3(90, 0, 0)
				vitrina.add_child(m)
			else:
				_fosil_costillas(vitrina, Vector3(0, 0, 0), u.mat(Color(0.78, 0.71, 0.56), 0.88), oscuro)


func _fosil_costillas(padre: Node3D, centro: Vector3, mat_hueso: Material, mat_sombra: Material) -> void:
	u.sphere(padre, centro + Vector3(0, 0.78, 0), 0.13, mat_hueso, Vector3(1.0, 0.75, 1.0))
	for i in 5:
		var z := -0.55 + i * 0.27
		u.sphere(padre, centro + Vector3(0, 0.82, z), 0.075, mat_sombra)
		for lado in [-1.0, 1.0]:
			var costilla := u.cyl(padre, centro + Vector3(lado * 0.28, 0.72, z), 0.025, 0.025, 0.55, mat_hueso)
			costilla.rotation_degrees.z = lado * -18.0
	for lado in [-1.0, 1.0]:
		u.cyl(padre, centro + Vector3(lado * 0.48, 0.45, -0.42), 0.04, 0.025, 0.4, mat_hueso, Vector3(0, 0, lado * 24.0))


func _luces(laton: Material) -> void:
	# Rieles de museo con focos alternados: relleno frío y acentos cálidos en las piezas.
	var vidrio_azul := u.mat(Color(0.22, 0.42, 0.68), 0.6, 0.0, Color(0.14, 0.34, 0.72), 0.55)
	var vidrio_calido := u.mat(Color(0.64, 0.43, 0.20), 0.5, 0.0, Color(0.9, 0.42, 0.12), 0.45)
	for lado in [-1.0, 1.0]:
		var x: float = float(lado) * 3.2
		u.box(self, Vector3(x, ALTURA - 0.12, 17.0), Vector3(0.12, 0.12, 22.0), laton)
		for indice in range(3):
			var z: float = 9.0 + float(indice) * 8.0
			var lampara := u.node3d(self, "ProyectorMuseo", Vector3(x, ALTURA - 0.36, z))
			var cristal: Material = vidrio_azul if indice % 2 == 0 else vidrio_calido
			u.box(lampara, Vector3(0, 0.08, 0), Vector3(0.58, 0.18, 0.48), laton)
			u.box(lampara, Vector3(0, -0.035, 0), Vector3(0.38, 0.04, 0.32), cristal)
			var tono: Color = Color(0.60, 0.74, 1.0) if indice % 2 == 0 else Color(1.0, 0.68, 0.38)
			luz_fija(u.spot(lampara, Vector3(0, -0.08, 0), Vector3(-90, 0, 0), tono, 1.45, 9.0, 54.0))


func _detalles_pabellon(piedra: Material, laton: Material) -> void:
	# Pilastras y capiteles dan escala arquitectónica y ordenan las exhibiciones laterales.
	for lado in [-1.0, 1.0]:
		var x: float = float(lado) * 8.82
		for z in [8.0, 15.0, 22.0, 29.0]:
			u.box(self, Vector3(x, 2.1, z), Vector3(0.24, 4.2, 0.34), piedra)
			u.box(self, Vector3(x, 0.16, z), Vector3(0.38, 0.22, 0.48), laton)
			u.box(self, Vector3(x, 4.18, z), Vector3(0.42, 0.18, 0.52), laton)


func _exhibiciones(hueso: Material, hueso_sombra: Material, laton: Material) -> void:
	var placa := u.node3d(self, "PlacaPabellon", Vector3(-8.92, 1.75, 5.6), 90.0)
	u.box(placa, Vector3.ZERO, Vector3(0.05, 1.1, 1.9), u.wood())
	u.text3d(placa, "PALEONTOLOGIA", Vector3(0.04, 0, 0), 0.0, 32, Color(0.86, 0.75, 0.50), 0.003)
	var vitrina_trex := u.node3d(self, "CostillarDelTiranosaurio", Vector3(0, 0, 11.0))
	u.box(vitrina_trex, Vector3(0, 0.15, 0), Vector3(5.4, 0.25, 4.4), u.stone(Color(0.24, 0.27, 0.32), 0.35))
	u.box(vitrina_trex, Vector3(0, 0.31, 0), Vector3(5.1, 0.07, 4.1), laton)
	_fosil_costillas(vitrina_trex, Vector3(0, 0.0, 0), hueso, hueso_sombra)
	for x in [-2.0, 2.0]:
		u.box(vitrina_trex, Vector3(x, 1.1, 0), Vector3(0.055, 1.7, 0.055), laton)
	for z in [-1.7, 1.7]:
		u.box(vitrina_trex, Vector3(0, 1.95, z), Vector3(4.0, 0.055, 0.055), laton)
	var letrero := u.node3d(self, "RotuloCostillar", Vector3(0, 0, 13.35))
	u.box(letrero, Vector3(0, 1.1, 0), Vector3(2.5, 0.52, 0.06), u.wood())
	u.text3d(letrero, "TYRANNOSAURUS REX", Vector3(0, 1.12, 0.04), 0.0, 24, Color(0.85, 0.71, 0.42), 0.002)
	var craneo := u.node3d(self, "CraneoFosil", Vector3(-4.8, 0, 19.0))
	u.box(craneo, Vector3(0, 0.12, 0), Vector3(2.8, 0.22, 1.3), u.stone(Color(0.3, 0.32, 0.37), 0.35))
	u.sphere(craneo, Vector3(0, 0.85, 0.1), 0.38, hueso, Vector3(1.0, 0.72, 1.25))
	u.box(craneo, Vector3(0, 0.72, 0.5), Vector3(0.56, 0.20, 0.55), hueso_sombra)
	u.text3d(self, "REPLICA  ·  NO AUTENTICO", Vector3(-4.8, 1.55, 19.9), 0.0, 20, Color(0.72, 0.68, 0.57), 0.003)
	var cadera := u.node3d(self, "ReplicaCadera", Vector3(4.8, 0, 19.0))
	u.box(cadera, Vector3(0, 0.12, 0), Vector3(2.8, 0.22, 1.3), u.stone(Color(0.3, 0.32, 0.37), 0.35))
	u.sphere(cadera, Vector3(0, 0.82, 0), 0.39, hueso, Vector3(1.3, 0.72, 0.65))
	u.text3d(self, "REPLICA  ·  NO AUTENTICA", Vector3(4.8, 1.55, 19.9), 0.0, 20, Color(0.72, 0.68, 0.57), 0.003)


func _microscopio_y_diario(laton: Material) -> void:
	var mesa := u.node3d(self, "MesaAnalisis", Vector3(-5.2, 0.0, 16.8))
	u.box(mesa, Vector3(0, 0.86, 0), Vector3(2.1, 0.12, 1.25), u.wood_light(), true)
	for x in [-0.82, 0.82]:
		for z in [-0.43, 0.43]:
			u.box(mesa, Vector3(x, 0.42, z), Vector3(0.10, 0.84, 0.10), u.wood())
	# Microscopio de inspeccion construido con piezas simples.
	var micro := u.node3d(mesa, "Microscopio", Vector3(0.15, 0.95, 0.0))
	u.cyl(micro, Vector3(0, 0.05, 0), 0.16, 0.16, 0.035, laton)
	u.cyl(micro, Vector3(0.0, 0.30, 0.0), 0.055, 0.045, 0.42, u.metal(Color(0.18, 0.22, 0.27)), Vector3(0, 0, -22.0))
	u.cyl(micro, Vector3(-0.09, 0.49, 0.0), 0.075, 0.065, 0.11, laton, Vector3(0, 0, -22.0))
	u.sphere(micro, Vector3(0.15, 0.19, 0), 0.06, u.metal(Color(0.18, 0.22, 0.27)))
	u.box(micro, Vector3(-0.12, 0.08, 0), Vector3(0.34, 0.035, 0.24), u.metal(Color(0.2, 0.23, 0.28)))
	reg(micro, "microscopio", "Observar la lámina en el microscopio", {"nodo": micro}, 3.0, Vector3(0, 0.2, 0), micro)
	var d := hoja_papel(mesa, Vector3(-0.45, 0.94, -0.20), -8.0, Vector2(0.34, 0.23))
	var texto := "[b]NOTAS DE LABORATORIO — DRA. ELENA TORRES[/b]\n\n"
	texto += "La tarjeta del piso 3 solo permite entrar al pabellon. La puerta de contencion responde a tres placas oseas.\n\n"
	texto += "Bajo el microscopio, las marcas del autentico sello aparecen en este orden: [b]craneo → costillas → cola[/b]. Las replicas del costado no conservan el mismo polvo azul.\n\n"
	texto += "El gran costillar es una reconstruccion; la pieza autentica esta bajo llave, en la boveda.\n\n"
	texto += "Si la criatura despierta, no dejes que desaparezca de tu vista mientras revisas las muestras."
	nota(d, "Leer notas del laboratorio", "Notas de la Dra. Torres", texto, "papel", "— Elena Torres", d)


func interactuar(it: Dictionary) -> void:
	match String(it.get("tipo", "")):
		"microscopio":
			_observar_microscopio()
		"placa_osea":
			_activar_placa(int(it.get("pieza", -1)))
		_:
			super.interactuar(it)


func _observar_microscopio() -> void:
	estado.mensaje.emit("Ajustas el ocular y dejas de vigilar la sala por un instante...")
	await get_tree().create_timer(1.4).timeout
	estado.mensaje.emit("La muestra autentica revela tres marcas: cráneo, costillas y cola.")


func _seguro_boveda(piedra: Material, laton: Material) -> void:
	# La pared interna forma una boveda independiente y una entrada sellada.
	wall_x(21.8, -4.2, 4.2, 0.35, 4.2, piedra, [{"a": -1.15, "b": 1.15, "h": 2.75}])
	var entrada := u.node3d(self, "EntradaSellada", Vector3(0, 0, 21.8))
	_reja_boveda = u.box(entrada, Vector3(0, 1.375, 0), Vector3(2.28, 2.75, 0.22), u.metal(Color(0.18, 0.2, 0.23)), true, Vector3.ZERO, "RejaBoveda")
	for x in [-0.92, -0.46, 0.0, 0.46, 0.92]:
		u.box(entrada, Vector3(x, 1.38, -0.13), Vector3(0.045, 2.70, 0.035), laton)
	u.box(entrada, Vector3(0, 2.48, -0.15), Vector3(1.7, 0.08, 0.05), laton)
	u.text3d(self, "BOVEDA DE CONTENCION", Vector3(0, 3.35, 21.35), 0.0, 27, Color(0.88, 0.72, 0.43), 0.003)
	var iconos := ["CRANEO", "COSTILLAS", "COLA"]
	for i in 3:
		var x := -1.55 + i * 1.55
		var placa := u.node3d(self, "PlacaOsea" + str(i), Vector3(x, 1.15, 19.55))
		u.box(placa, Vector3(0, 0, 0), Vector3(0.82, 0.48, 0.11), u.metal(Color(0.19, 0.21, 0.25)))
		u.box(placa, Vector3(0, 0.03, -0.065), Vector3(0.28, 0.10, 0.035), laton)
		u.text3d(placa, iconos[i], Vector3(0, -0.39, -0.07), 0.0, 17, Color(0.82, 0.73, 0.54), 0.002)
		reg(placa, "placa_osea", "Presionar placa: " + iconos[i], {"pieza": i}, 3.0, Vector3.ZERO, placa)
	for i in 3:
		u.omni(self, Vector3(-1.5 + i * 1.5, 2.4, 20.4), Color(0.2, 0.45, 0.9), 0.34, 2.6)


func _activar_placa(pieza: int) -> void:
	if _progreso_seguro >= SECUENCIA_SEGURO.size():
		return
	if pieza != SECUENCIA_SEGURO[_progreso_seguro]:
		_progreso_seguro = 0
		Sfx.tocar("beep_no")
		estado.mensaje.emit("El seguro rechaza la secuencia. Revisa las notas y la muestra del microscopio.")
		return
	_progreso_seguro += 1
	Sfx.tocar("beep_ok")
	if _progreso_seguro < SECUENCIA_SEGURO.size():
		estado.mensaje.emit("Placa aceptada (%d/3)." % _progreso_seguro)
		return
	estado.poner_flag("boveda_piso3_abierta")
	estado.mensaje.emit("Las tres placas encajan. La reja de la bóveda se eleva.")
	if is_instance_valid(_reja_boveda):
		var tween := create_tween()
		tween.tween_property(_reja_boveda, "position:y", 4.2, 0.8).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_OUT)
		tween.tween_callback(_reja_boveda.queue_free)


func _fragmento(hueso: Material, laton: Material) -> void:
	var pedestal := u.node3d(self, "PedestalFragmento3", Vector3(0, 0, 26.0))
	u.box(pedestal, Vector3(0, 0.45, 0), Vector3(1.0, 0.9, 1.0), u.stone(Color(0.27, 0.29, 0.34), 0.32), true)
	u.box(pedestal, Vector3(0, 0.93, 0), Vector3(1.2, 0.08, 1.2), laton)
	var pieza := u.node3d(pedestal, "Fragmento3", Vector3(0, 1.02, 0), 18.0)
	u.box(pieza, Vector3(0, 0.03, 0), Vector3(0.22, 0.055, 0.14), hueso)
	var glifo := u.mat(Color(0.05, 0.23, 0.22), 0.35, 0.0, Color(0.12, 0.85, 0.72), 2.4)
	for i in 3:
		u.box(pieza, Vector3(-0.055 + i * 0.055, 0.061, 0), Vector3(0.012, 0.004, 0.09), glifo)
	luz_fija(u.omni(pieza, Vector3(0, 0.25, 0), Color(0.2, 0.8, 0.7), 0.65, 3.2))
	pickup(pieza, "Tomar el tercer fragmento", "fragmento", "Fragmento del amuleto (3/4). El registro de la doctora termina aquí.", 1, Callable(self, "_tomo_fragmento3"), Vector3(0, 0.1, 0))
	var diario := hoja_papel(pedestal, Vector3(0.4, 1.0, 0.2), -14.0, Vector2(0.24, 0.18))
	var cierre := "[b]ULTIMA NOTA — ELENA TORRES[/b]\n\n"
	cierre += "Si encontraste el tercer fragmento, el cuarto sigue bajo el museo. Las momias no son guardianes del amuleto: protegen la cripta que lo alimentaba.\n\n"
	cierre += "No lleves la reliquia a la luz del amanecer sin cerrar antes el sello. La sala principal es el unico lugar donde las cuatro piezas pueden reunirse."
	nota(diario, "Leer la última nota de Elena", "Última nota de la Dra. Torres", cierre, "papel", "— Elena", diario)


func _tomo_fragmento3() -> void:
	estado.poner_flag("frag3")
	estado.poner_flag("piso3_fragmento_obtenido")
	Sfx.tocar("golpe")
	estado.mensaje.emit("El tercer fragmento está contigo. La nota señala el acceso al sótano.")


func _crear_fosil(hueso: Material, sombra: Material) -> void:
	var enemigo := EstatuaEnemiga.new()
	enemigo.name = "FosilRaptor"
	enemigo.tipo = "FOSIL"
	enemigo.velocidad = 1.45
	enemigo.distancia_aviso = 7.0
	enemigo.region = REGION_FOSIL
	enemigo.position = Vector3(0.0, 0.0, 14.0)
	enemigo.add_to_group("wake_paleontologia")
	enemigo.set_meta("enemy_type", "FOSIL")
	add_child(enemigo)
	var visual := Node3D.new()
	visual.name = "Visual"
	enemigo.add_child(visual)
	u.sphere(visual, Vector3(0, 1.04, -0.02), 0.35, sombra, Vector3(0.9, 0.82, 1.65))
	# Vértebras expuestas y costillas del depredador.
	for i in 7:
		var z := -0.48 + i * 0.16
		u.sphere(visual, Vector3(0, 1.36, z), 0.085, hueso, Vector3(0.85, 0.75, 0.8))
	for i in 5:
		var z := -0.28 + i * 0.15
		for lado in [-1.0, 1.0]:
			var costilla := u.cyl(visual, Vector3(lado * 0.25, 1.12, z), 0.032, 0.025, 0.43, hueso, Vector3(0, 0, lado * -32.0))
			costilla.rotation_degrees.x = 90.0
			u.sphere(visual, Vector3(lado * 0.34, 0.91, z), 0.045, hueso)
	# Piernas digitígradas, pies y garras.
	for lado in [-1.0, 1.0]:
		u.cyl(visual, Vector3(lado * 0.2, 0.67, -0.22), 0.12, 0.085, 0.44, hueso, Vector3(0, 0, lado * -11.0))
		u.cyl(visual, Vector3(lado * 0.22, 0.34, -0.03), 0.075, 0.06, 0.38, hueso, Vector3(0, 0, lado * 18.0))
		u.box(visual, Vector3(lado * 0.22, 0.14, 0.18), Vector3(0.16, 0.09, 0.34), hueso)
		for garra in 3:
			u.cyl(visual, Vector3(lado * 0.22 - 0.045 + garra * 0.045, 0.1, 0.36), 0.0, 0.035, 0.15, sombra, Vector3(-80, 0, 0), 6)
	# Brazos cortos y cola segmentada hacia atrás.
	for lado in [-1.0, 1.0]:
		u.cyl(visual, Vector3(lado * 0.31, 1.05, 0.28), 0.055, 0.045, 0.28, hueso, Vector3(0, 0, lado * 20.0))
		u.sphere(visual, Vector3(lado * 0.34, 0.92, 0.39), 0.06, hueso)
		for garra in 2:
			u.cyl(visual, Vector3(lado * 0.34 + (garra - 0.5) * 0.045, 0.88, 0.48), 0.0, 0.022, 0.11, sombra, Vector3(70, 0, 0), 6)
	for i in 5:
		var z := -0.48 - i * 0.22
		var radio := 0.12 - i * 0.015
		u.cyl(visual, Vector3(0, 1.05 - i * 0.045, z), radio * 0.65, radio, 0.26, hueso, Vector3(-90, 0, 0))
	# Cabeza pivotable, dientes y ojos que se encienden al avanzar.
	var cabeza := Node3D.new()
	cabeza.name = "Cabeza"
	cabeza.position = Vector3(0, 1.25, 0.48)
	visual.add_child(cabeza)
	u.sphere(cabeza, Vector3(0, 0.04, 0.16), 0.20, hueso, Vector3(0.95, 0.76, 1.25))
	u.box(cabeza, Vector3(0, -0.075, 0.39), Vector3(0.24, 0.10, 0.38), hueso)
	var ojo := u.mat(Color(0.45, 0.015, 0.004), 0.2, 0.0, Color(1.0, 0.018, 0.003), 0.0)
	for lado in [-1.0, 1.0]:
		u.sphere(cabeza, Vector3(lado * 0.12, 0.09, 0.25), 0.045, ojo)
		for diente in 3:
			u.cyl(cabeza, Vector3(lado * (0.055 + diente * 0.035), -0.13, 0.48), 0.0, 0.018, 0.09, hueso, Vector3(180, 0, 0), 6)
	_ojos_fosil.append(ojo)
	visual.set_meta("ojos", _ojos_fosil)


