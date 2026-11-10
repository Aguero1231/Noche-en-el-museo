extends RefCounted

## MODELOS DE ESTATUAS (esculturas por codigo y armadura desde GLB):
##   busto()          busto con rostro esculpido (nariz, cejas, cuencas, pomulos, boca, menton, pelo),
##                    hombros con pliegues de toga y pedestal
##   estatua_cubierta() figura tapada con una sabana (pliegues, brazo extendido, el rostro se insinua)
##   armadura()       caballero de placas detallado desde assets/enemies/armadura_orden_acero.glb
## Todos devuelven un nodo "Visual". Si tienen cabeza, esta se llama "Cabeza" (las estatuas giran la cabeza
## hacia el jugador) y los ojos que brillan al moverse se guardan en el metadato "ojos".

const BuildUtils = preload("res://scripts/environment/build_utils.gd")
const ARMADURA_GLB: PackedScene = preload("res://assets/enemies/armadura_orden_acero.glb")


# ---------------------------------------------------------------- matematicas de escultura

static func _g(v: float, c: float, s: float) -> float:
	var t := (v - c) / s
	return exp(-t * t)


static func _ss(a: float, b: float, x: float) -> float:
	return smoothstep(a, b, x)


## Cabeza esculpida: elipsoide desplazado. +z = frente, +y = arriba. Mide ~0.23 de ancho.
static func malla_cabeza(pelo: bool, calvo_frente: bool = false) -> ArrayMesh:
	var filas := 40
	var cols := 56
	var rx := 0.105
	var ry := 0.168
	var rz := 0.128
	var st := SurfaceTool.new()
	st.begin(Mesh.PRIMITIVE_TRIANGLES)
	for i in range(filas + 1):
		var phi := PI * float(i) / filas
		for j in range(cols + 1):
			var th := TAU * float(j) / cols + PI      # la costura queda en la espalda
			var d := Vector3(sin(phi) * sin(th), cos(phi), sin(phi) * cos(th))
			var x := d.x
			var y := d.y
			var z := d.z
			var fz := clampf(z, 0.0, 1.0)
			var ax := absf(x)
			var r := 1.0
			# nariz: puente y punta
			r += 0.10 * _g(x, 0.0, 0.09) * _g(y, 0.12, 0.20) * fz
			r += 0.40 * _g(x, 0.0, 0.11) * _g(y, -0.13, 0.13) * fz * fz
			r += 0.10 * _g(ax, 0.17, 0.07) * _g(y, -0.16, 0.08) * fz
			# ceja marcada y cuencas hundidas
			r += 0.13 * _g(y, 0.25, 0.07) * _ss(0.0, 0.5, fz) * (1.0 - _ss(0.7, 0.98, ax))
			r -= 0.22 * _g(ax, 0.40, 0.11) * _g(y, 0.13, 0.085) * fz
			# pomulos, boca, labios y menton
			r += 0.08 * _g(ax, 0.60, 0.15) * _g(y, -0.14, 0.14) * fz
			r -= 0.06 * _g(x, 0.0, 0.30) * _g(y, -0.43, 0.030) * fz
			r += 0.035 * _g(x, 0.0, 0.22) * _g(y, -0.37, 0.05) * fz
			r += 0.14 * _g(x, 0.0, 0.20) * _g(y, -0.72, 0.14) * fz
			# sienes y cuello
			r -= 0.05 * _g(ax, 0.95, 0.12) * _g(y, 0.05, 0.3)
			var ancho := 1.0 - 0.30 * (1.0 - _ss(-0.9, -0.1, y))   # la mandibula se angosta
			# pelo: casquete que baja mas por atras y los lados; rizos o mechones
			if pelo:
				var linea := lerpf(-0.30, 0.46, _ss(-0.7, 0.25, z))
				if calvo_frente:
					linea = lerpf(-0.30, 0.15, _ss(-0.7, 0.25, z))
				var w := _ss(linea - 0.05, linea + 0.10, y)
				r += w * (0.075 + 0.030 * sin(th * 15.0 + y * 6.0) * sin(phi * 22.0))
			var p := Vector3(x * rx * ancho, y * ry, z * rz) * r
			st.set_uv(Vector2(float(j) / cols, float(i) / filas))
			st.add_vertex(p)
	for i in range(filas):
		for j in range(cols):
			var a := i * (cols + 1) + j
			var b := a + 1
			var c := a + (cols + 1)
			var e := c + 1
			st.add_index(a)
			st.add_index(b)
			st.add_index(c)
			st.add_index(b)
			st.add_index(e)
			st.add_index(c)
	st.generate_normals()
	return st.commit()


## Hombros y pecho de un busto con pliegues de toga. Centrado en el origen, abierto por abajo.
static func malla_hombros() -> ArrayMesh:
	var filas := 22
	var cols := 48
	var st := SurfaceTool.new()
	st.begin(Mesh.PRIMITIVE_TRIANGLES)
	for i in range(filas + 1):
		var phi := (PI * 0.62) * float(i) / filas
		for j in range(cols + 1):
			var th := TAU * float(j) / cols + PI
			var d := Vector3(sin(phi) * sin(th), cos(phi), sin(phi) * cos(th))
			var r := 1.0 + 0.022 * sin(th * 7.0 + d.y * 5.0) + 0.012 * sin(th * 13.0 - d.y * 4.0)
			# banda diagonal (toga cruzada sobre el pecho)
			r += 0.05 * _g(d.x * 0.8 + d.y * 0.6 - 0.2, 0.0, 0.18) * _ss(0.0, 0.5, d.z)
			var p := Vector3(d.x * 0.30, d.y * 0.19, d.z * 0.17) * r
			st.set_uv(Vector2(float(j) / cols, float(i) / filas))
			st.add_vertex(p)
	for i in range(filas):
		for j in range(cols):
			var a := i * (cols + 1) + j
			var b := a + 1
			var c := a + (cols + 1)
			var e := c + 1
			st.add_index(a)
			st.add_index(b)
			st.add_index(c)
			st.add_index(b)
			st.add_index(e)
			st.add_index(c)
	st.generate_normals()
	return st.commit()


## Figura tapada con una sabana: perfil de revolucion + pliegues + nariz que se insinua.
static func malla_sabana() -> ArrayMesh:
	var perfil := [
		[0.00, 0.64], [0.12, 0.62], [0.45, 0.47], [0.90, 0.39], [1.25, 0.47], [1.48, 0.52],
		[1.66, 0.34], [1.80, 0.21], [1.95, 0.27], [2.15, 0.26], [2.30, 0.17], [2.38, 0.00],
	]
	var filas := 56
	var cols := 56
	var st := SurfaceTool.new()
	st.begin(Mesh.PRIMITIVE_TRIANGLES)
	for i in range(filas + 1):
		var y := 2.38 * float(i) / filas
		var rad := 0.0
		for k in range(perfil.size() - 1):
			var a: Array = perfil[k]
			var b: Array = perfil[k + 1]
			if y >= float(a[0]) and y <= float(b[0]):
				rad = lerpf(float(a[1]), float(b[1]), (y - float(a[0])) / maxf(0.0001, float(b[0]) - float(a[0])))
				break
		for j in range(cols + 1):
			var th := TAU * float(j) / cols + PI
			var r := rad * (1.0 + 0.075 * sin(5.0 * th + 1.5 * y) + 0.04 * sin(9.0 * th - 2.3 * y))
			if y < 0.4:
				r *= 1.0 + 0.10 * (1.0 - y / 0.4) * sin(7.0 * th + 0.5)
			# rostro insinuado bajo la tela (frente = +z -> th = 0)
			var fr := _g(wrapf(th, -PI, PI), 0.0, 0.32)
			r += 0.05 * fr * _g(y, 2.05, 0.12)       # nariz
			r += 0.03 * fr * _g(y, 2.17, 0.06)       # frente
			r -= 0.025 * fr * _g(y, 2.10, 0.04)      # hundimiento de los ojos
			st.set_uv(Vector2(float(j) / cols, float(i) / filas))
			st.add_vertex(Vector3(r * sin(th), y, r * cos(th)))
	for i in range(filas):
		for j in range(cols):
			var a := i * (cols + 1) + j
			var b := a + 1
			var c := a + (cols + 1)
			var e := c + 1
			st.add_index(a)
			st.add_index(c)
			st.add_index(b)
			st.add_index(b)
			st.add_index(c)
			st.add_index(e)
	st.generate_normals()
	return st.commit()


static func _malla(padre: Node3D, mesh: Mesh, m: Material, pos: Vector3, escala: Vector3 = Vector3.ONE, rot_deg: Vector3 = Vector3.ZERO) -> MeshInstance3D:
	var mi := MeshInstance3D.new()
	mi.mesh = mesh
	mi.material_override = m
	mi.position = pos
	mi.scale = escala
	mi.rotation_degrees = rot_deg
	padre.add_child(mi)
	return mi


# ---------------------------------------------------------------- busto

## variante 0: senador romano (rizos cortos y corona de laurel). 1: dama con peinado alto y diadema.
static func busto(padre: Node3D, u: BuildUtils, variante: int = 0) -> Node3D:
	var raiz := Node3D.new()
	raiz.name = "Visual"
	padre.add_child(raiz)
	var piedra := u.mat(Color(0.70, 0.68, 0.65), 0.82)
	var piedra_osc := u.mat(Color(0.34, 0.32, 0.33), 0.9)
	var oro := u.gold()

	# Pedestal con basa y cornisa
	u.box(raiz, Vector3(0, 0.07, 0), Vector3(0.80, 0.14, 0.80), piedra_osc)
	u.box(raiz, Vector3(0, 0.19, 0), Vector3(0.66, 0.10, 0.66), piedra)
	u.box(raiz, Vector3(0, 0.62, 0), Vector3(0.52, 0.76, 0.52), piedra)
	u.box(raiz, Vector3(0, 0.62, 0.265), Vector3(0.30, 0.44, 0.02), piedra_osc)     # placa
	u.box(raiz, Vector3(0, 1.03, 0), Vector3(0.68, 0.08, 0.68), piedra_osc)
	u.box(raiz, Vector3(0, 1.09, 0), Vector3(0.60, 0.05, 0.60), piedra)

	var b := Node3D.new()
	b.name = "Busto"
	b.position = Vector3(0, 1.115, 0)
	b.scale = Vector3.ONE * 1.75
	raiz.add_child(b)
	_malla(b, malla_hombros(), piedra, Vector3(0, 0.15, 0))
	u.cyl(b, Vector3(0, 0.29, 0), 0.046, 0.058, 0.12, piedra)

	var cabeza := Node3D.new()
	cabeza.name = "Cabeza"
	cabeza.position = Vector3(0, 0.46, 0.005)
	b.add_child(cabeza)
	_malla(cabeza, malla_cabeza(true, variante == 1), piedra, Vector3.ZERO)
	# orejas
	for s in [-1.0, 1.0]:
		u.sphere(cabeza, Vector3(s * 0.114, -0.005, -0.012), 0.022, piedra, Vector3(0.45, 1.25, 0.8))
	# ojos (vacios: brillan cuando la estatua se mueve)
	var ojo := u.mat(Color(0.02, 0.02, 0.03), 0.3, 0.0, Color(1.0, 0.15, 0.1), 0.0)
	for s in [-1.0, 1.0]:
		u.sphere(cabeza, Vector3(s * 0.043, 0.020, 0.100), 0.016, ojo, Vector3(1.2, 0.8, 0.9))
	raiz.set_meta("ojos", [ojo])

	if variante == 0:
		# corona de laurel: aro de hojitas
		for k in range(14):
			var ang := TAU * float(k) / 14.0
			var hoja := u.box(cabeza, Vector3(sin(ang) * 0.122, 0.085 - 0.012 * cos(ang), cos(ang) * 0.128), Vector3(0.02, 0.012, 0.045), piedra_osc)
			hoja.rotation = Vector3(0.0, ang, 0.35)
	else:
		# mono alto + diadema
		u.sphere(cabeza, Vector3(0, 0.15, -0.075), 0.062, piedra, Vector3(1.0, 0.9, 1.0))
		u.sphere(cabeza, Vector3(0, 0.11, -0.12), 0.05, piedra)
		var tiara := u.cyl(cabeza, Vector3(0, 0.095, 0.01), 0.128, 0.128, 0.012, oro, Vector3(-8, 0, 0))
		tiara.scale = Vector3(1.0, 1.0, 1.05)
	# Fisuras oscuras y una muesca en la piedra para que no parezca recién moldeada.
	var fisura := u.mat(Color(0.25, 0.23, 0.21), 1.0)
	u.box(cabeza, Vector3(0.085, -0.015, 0.079), Vector3(0.009, 0.052, 0.006), fisura, false, Vector3(0, 0, -18))
	u.box(cabeza, Vector3(0.079, -0.055, 0.083), Vector3(0.008, 0.032, 0.006), fisura, false, Vector3(0, 0, 24))
	u.box(b, Vector3(-0.235, 0.11, 0.12), Vector3(0.065, 0.025, 0.018), piedra_osc, false, Vector3(0, 0, 18))
	return raiz


# ---------------------------------------------------------------- estatua cubierta

static func estatua_cubierta(padre: Node3D, u: BuildUtils) -> Node3D:
	var raiz := Node3D.new()
	raiz.name = "Visual"
	padre.add_child(raiz)
	var tela := u.mat(Color(0.78, 0.75, 0.68), 1.0)
	var cuerda := u.mat(Color(0.25, 0.17, 0.10), 0.95)
	# base de madera (tarima)
	u.box(raiz, Vector3(0, 0.06, 0), Vector3(1.15, 0.12, 1.15), u.wood())
	var f := Node3D.new()
	f.name = "Cuerpo"
	f.position = Vector3(0, 0.12, 0)
	f.scale = Vector3(0.92, 1.0, 0.92)
	raiz.add_child(f)
	_malla(f, malla_sabana(), tela, Vector3.ZERO)
	# Silueta encorvada bajo la lona: hombros altos, brazos largos y manos deformes.
	var hombros := CapsuleMesh.new()
	hombros.radius = 0.14
	hombros.height = 0.48
	_malla(f, hombros, tela, Vector3(0, 1.52, 0.02), Vector3(1.8, 0.72, 1.25), Vector3(-8, 0, 0))
	var brazo := CapsuleMesh.new()
	brazo.radius = 0.12
	brazo.height = 0.92
	_malla(f, brazo, tela, Vector3(0.38, 1.36, 0.32), Vector3.ONE, Vector3(-66, 12, 0))
	var brazo_izq := CapsuleMesh.new()
	brazo_izq.radius = 0.105
	brazo_izq.height = 0.78
	_malla(f, brazo_izq, tela, Vector3(-0.31, 1.35, 0.04), Vector3.ONE, Vector3(-22, -18, 8))
	var mano := SphereMesh.new()
	mano.radius = 0.12
	mano.height = 0.24
	_malla(f, mano, tela, Vector3(0.44, 1.12, 0.72), Vector3(0.9, 0.75, 1.35))
	_malla(f, mano, cuerda, Vector3(-0.40, 1.10, 0.22), Vector3(0.85, 0.7, 1.1))
	# Dedos largos asomando por las vendas.
	for k in 3:
		var dedo := CapsuleMesh.new()
		dedo.radius = 0.025
		dedo.height = 0.16
		_malla(f, dedo, cuerda, Vector3(0.44 + (k - 1) * 0.045, 1.04, 0.80), Vector3.ONE, Vector3(-22, 0, (k - 1) * 12))
	# cuerda al cuello
	var cu := TorusMesh.new()
	cu.inner_radius = 0.23
	cu.outer_radius = 0.285
	_malla(f, cu, cuerda, Vector3(0, 1.83, 0), Vector3(1, 1, 1))
	# brillo rojo bajo la tela: solo se nota cuando se mueve
	var ojo := u.mat(Color(0.2, 0.0, 0.0), 0.5, 0.0, Color(1.0, 0.1, 0.05), 0.0)
	for s in [-1.0, 1.0]:
		u.sphere(f, Vector3(s * 0.085, 2.10, 0.255), 0.022, cuerda, Vector3(1.4, 1.0, 0.6))
		u.sphere(f, Vector3(s * 0.085, 2.10, 0.272), 0.012, ojo)
	# Tiras sueltas de lino para romper la forma lisa de la sábana.
	for s in [-1.0, 1.0]:
		var tira := u.box(f, Vector3(s * 0.30, 0.45, 0.12), Vector3(0.055, 0.52, 0.025), cuerda, false, Vector3(0, 0, s * 9))
		tira.rotation_degrees.x = -8.0
	raiz.set_meta("ojos", [ojo])
	var cab := Node3D.new()
	cab.name = "Cabeza"
	raiz.add_child(cab)
	return raiz


# ---------------------------------------------------------------- armadura de caballero

## color_tabardo: color de la tela del escudo de armas.
static func armadura(padre: Node3D, _u: BuildUtils, color_tabardo: Color = Color(0.5, 0.06, 0.08)) -> Node3D:
	var visual := ARMADURA_GLB.instantiate() as Node3D
	if visual == null:
		push_error("No se pudo instanciar assets/enemies/armadura_orden_acero.glb")
		return Node3D.new()
	visual.name = "Visual"
	padre.add_child(visual)
	var ojos: Array[StandardMaterial3D] = []
	_aplicar_variantes_armadura(visual, color_tabardo, ojos)
	visual.set_meta("ojos", ojos)
	return visual


static func _aplicar_variantes_armadura(nodo: Node, color_tabardo: Color, ojos: Array[StandardMaterial3D]) -> void:
	if nodo is MeshInstance3D and nodo.mesh:
		var malla := nodo as MeshInstance3D
		for superficie in malla.mesh.get_surface_count():
			var original := malla.mesh.surface_get_material(superficie)
			if original == null:
				continue
			var nombre := original.resource_name.to_lower()
			if not ("tabardo" in nombre or "ojos" in nombre):
				continue
			var variante := original.duplicate() as StandardMaterial3D
			if variante == null:
				continue
			if "tabardo" in nombre:
				variante.albedo_color = color_tabardo
			else:
				variante.emission_enabled = true
				variante.emission = Color(1.0, 0.025, 0.008)
				variante.emission_energy_multiplier = 0.0
				ojos.append(variante)
			malla.set_surface_override_material(superficie, variante)
	for hijo in nodo.get_children():
		_aplicar_variantes_armadura(hijo, color_tabardo, ojos)
