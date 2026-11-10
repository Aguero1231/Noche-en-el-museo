extends Node3D

## Base de los cuartos del primer piso (vestibulo, control, oficina de la doctora...).
## Da paredes con huecos, puertas animadas (libres, con candado o con tarjeta),
## notas legibles, objetos recogibles y luces que parpadean.
## Los cuartos hijos solo sobrescriben build() y, si hace falta, interactuar() / _procesar().

const BuildUtils = preload("res://scripts/environment/build_utils.gd")
const GameState = preload("res://scripts/game/game_state.gd")
const Interactables = preload("res://scripts/game/interactables.gd")
const CCTV = preload("res://scripts/environment/cctv_system.gd")

var u := BuildUtils.new()
var estado: GameState
var registry: Interactables
var cctv: CCTV

var puertas: Array[Dictionary] = []
var luces_encendidas := true
var _flicker: Array[Dictionary] = []
var _emisivos: Array[Dictionary] = []
var _t := 0.0


func build() -> void:
	pass


func _procesar(_delta: float) -> void:
	pass


func _process(delta: float) -> void:
	_t += delta
	for f in _flicker:
		var l := f["luz"] as Light3D
		var base: float = f["base"]
		var vel: float = f["vel"]
		var fase: float = f["fase"]
		var k := 1.0 + 0.10 * sin(_t * vel + fase) + 0.05 * sin(_t * vel * 2.7 + fase * 1.7)
		if f.get("falla", false) and fmod(_t + fase, 9.0) > 8.6:
			k *= 0.15   # parpadeo de falla electrica
		l.light_energy = base * k
	_procesar(delta)


## Prende / apaga TODAS las luces del cuarto (omni y spot) y sus lamparas emisivas.
## Lo usan los interruptores de la escena (objeto_interactivo.tscn con id_luces).
## Las luces marcadas con luz_fija() (emergencia, reliquia...) no se apagan.
func set_luces(encendidas: bool) -> void:
	luces_encendidas = encendidas
	for n in find_children("*", "Light3D", true, false):
		var luz := n as Light3D
		if not bool(luz.get_meta("fija", false)):
			luz.visible = encendidas
	for e in _emisivos:
		var m := e["mat"] as StandardMaterial3D
		m.emission_energy_multiplier = float(e["e"]) if encendidas else 0.0


## Registra un material emisivo (pantalla de lampara, fluorescente) para que se apague con las luces.
func emisivo(m: StandardMaterial3D) -> StandardMaterial3D:
	_emisivos.append({"mat": m, "e": m.emission_energy_multiplier})
	return m


## Una luz "fija" no se apaga con el interruptor (luz de emergencia, la reliquia, la luna).
func luz_fija(l: Light3D) -> Light3D:
	l.set_meta("fija", true)
	return l


func parpadear(luz: Light3D, vel: float = 7.0, falla: bool = false) -> void:
	_flicker.append({"luz": luz, "base": luz.light_energy, "vel": vel, "fase": randf() * 6.28, "falla": falla})


# ---------------------------------------------------------------- paredes

## Tramos libres de [a0, a1] una vez quitados los huecos (cada hueco: {a, b, h}).
func _tramos(a0: float, a1: float, huecos: Array) -> Array[Vector2]:
	var orden := huecos.duplicate()
	orden.sort_custom(func(p: Dictionary, q: Dictionary) -> bool: return float(p["a"]) < float(q["a"]))
	var res: Array[Vector2] = []
	var cursor := a0
	for h in orden:
		var d: Dictionary = h
		if float(d["a"]) > cursor + 0.001:
			res.append(Vector2(cursor, float(d["a"])))
		cursor = float(d["b"])
	if a1 > cursor + 0.001:
		res.append(Vector2(cursor, a1))
	return res


## Pared que corre a lo largo de X (plano z fijo). huecos: [{a, b, h}] en x.
func wall_x(z: float, x0: float, x1: float, t: float, y_top: float, m: Material, huecos: Array = []) -> void:
	for s in _tramos(x0, x1, huecos):
		u.box(self, Vector3((s.x + s.y) / 2.0, y_top / 2.0, z), Vector3(s.y - s.x, y_top, t), m, true)
	for h in huecos:
		var d: Dictionary = h
		var hh: float = d["h"]
		if hh < y_top - 0.001:
			u.box(self, Vector3((float(d["a"]) + float(d["b"])) / 2.0, (hh + y_top) / 2.0, z), Vector3(float(d["b"]) - float(d["a"]), y_top - hh, t), m, true)


## Pared que corre a lo largo de Z (plano x fijo). huecos: [{a, b, h}] en z.
func wall_z(x: float, z0: float, z1: float, t: float, y_top: float, m: Material, huecos: Array = []) -> void:
	for s in _tramos(z0, z1, huecos):
		u.box(self, Vector3(x, y_top / 2.0, (s.x + s.y) / 2.0), Vector3(t, y_top, s.y - s.x), m, true)
	for h in huecos:
		var d: Dictionary = h
		var hh: float = d["h"]
		if hh < y_top - 0.001:
			u.box(self, Vector3(x, (hh + y_top) / 2.0, (float(d["a"]) + float(d["b"])) / 2.0), Vector3(t, y_top - hh, float(d["b"]) - float(d["a"])), m, true)


## Zocalo de madera + liston dorado + base de piedra, a lo largo de X (cara interior en z).
## dir = +1 si el cuarto esta hacia +z de la pared, -1 si esta hacia -z.
func zocalo_x(z: float, dir: float, x0: float, x1: float, huecos: Array = [], h: float = 1.1) -> void:
	for s in _tramos(x0, x1, huecos):
		var cx := (s.x + s.y) / 2.0
		var largo := s.y - s.x
		u.box(self, Vector3(cx, h / 2.0, z + dir * 0.05), Vector3(largo, h, 0.1), u.wood())
		u.box(self, Vector3(cx, h + 0.03, z + dir * 0.065), Vector3(largo, 0.06, 0.13), u.gold())
		u.box(self, Vector3(cx, 0.09, z + dir * 0.075), Vector3(largo, 0.18, 0.15), u.stone(Color(0.4, 0.38, 0.42)))


func zocalo_z(x: float, dir: float, z0: float, z1: float, huecos: Array = [], h: float = 1.1) -> void:
	for s in _tramos(z0, z1, huecos):
		var cz := (s.x + s.y) / 2.0
		var largo := s.y - s.x
		u.box(self, Vector3(x + dir * 0.05, h / 2.0, cz), Vector3(0.1, h, largo), u.wood())
		u.box(self, Vector3(x + dir * 0.065, h + 0.03, cz), Vector3(0.13, 0.06, largo), u.gold())
		u.box(self, Vector3(x + dir * 0.075, 0.09, cz), Vector3(0.15, 0.18, largo), u.stone(Color(0.4, 0.38, 0.42)))


## Banda de jeroglificos (hiero_band.png) pegada a una pared. rot_y: 0 mira a +z, 180 a -z, 90 a +x, -90 a -x.
func banda(pos: Vector3, rot_y: float, largo: float, alto: float = 0.5) -> void:
	var tex := u.tex("hiero_band.png")
	if tex == null:
		return
	var n := maxi(1, int(round(largo / (alto * 8.0))))
	var ancho := largo / n
	var m := StandardMaterial3D.new()
	m.albedo_texture = tex
	m.roughness = 0.7
	m.emission_enabled = true
	m.emission_texture = tex
	m.emission_energy_multiplier = 0.8
	var dir := Vector3(cos(deg_to_rad(rot_y)), 0, -sin(deg_to_rad(rot_y)))
	for i in n:
		var off := (i + 0.5) * ancho - largo / 2.0
		u.quad(self, pos + dir * off, Vector2(ancho, alto), m, rot_y)


# ---------------------------------------------------------------- interactivos

func reg(nodo: Node3D, tipo: String, texto: String, datos: Dictionary = {}, alcance: float = 3.0, offset: Vector3 = Vector3.ZERO, resaltar: Node = null) -> Dictionary:
	return registry.registrar(nodo, self, tipo, texto, alcance, offset, datos, resaltar)


## Carta / diario / pantalla que se lee al interactuar.
func nota(nodo: Node3D, prompt: String, titulo: String, cuerpo: String, estilo: String = "papel", firma: String = "", resaltar: Node = null, al_leer: Callable = Callable(), alcance: float = 3.0, offset: Vector3 = Vector3.ZERO) -> Dictionary:
	var datos: Dictionary = {
		"nota": {"titulo": titulo, "texto": cuerpo, "estilo": estilo, "firma": firma},
		"al_leer": al_leer,
	}
	return reg(nodo, "nota", prompt, datos, alcance, offset, resaltar)


## Objeto que se guarda al recogerlo (item = nombre en el inventario).
func pickup(nodo: Node3D, prompt: String, item: String, mensaje: String, cantidad: int = 1, al_recoger: Callable = Callable(), offset: Vector3 = Vector3.ZERO) -> Dictionary:
	var datos: Dictionary = {"item": item, "mensaje": mensaje, "cantidad": cantidad, "al_recoger": al_recoger}
	return reg(nodo, "recoger", prompt, datos, 3.0, offset, nodo)


func examinar(nodo: Node3D, prompt: String, mensaje: String, resaltar: Node = null, offset: Vector3 = Vector3.ZERO) -> Dictionary:
	return reg(nodo, "examinar", prompt, {"mensaje": mensaje}, 3.0, offset, resaltar)


func interactuar(it: Dictionary) -> void:
	match String(it["tipo"]):
		"nota":
			Sfx.tocar("papel")
			estado.nota.emit(it["nota"] as Dictionary)
			var cb := it.get("al_leer", Callable()) as Callable
			if cb.is_valid():
				cb.call()
		"examinar":
			estado.mensaje.emit(String(it["mensaje"]))
		"recoger":
			_recoger(it)
		"puerta":
			_usar_puerta(it["puerta"] as Dictionary)
		"reflector":
			var rumbo := String((it["reflector"] as Node3D).call("rotar"))
			Sfx.tocar("puerta")
			estado.mensaje.emit("Reflector orientado al " + rumbo + ".")


func _recoger(it: Dictionary) -> void:
	var raiz := it["resaltar"] as Node
	registry.quitar(it)
	if raiz and is_instance_valid(raiz):
		raiz.queue_free()
	var item := String(it["item"])
	if item == "baterias":
		estado.recargar_bateria.emit(50.0)
		Sfx.tocar("pickup")
		estado.mensaje.emit(String(it["mensaje"]))
	else:
		estado.recoger(item, int(it["cantidad"]), String(it["mensaje"]))
	var cb := it.get("al_recoger", Callable()) as Callable
	if cb.is_valid():
		cb.call()


# ---------------------------------------------------------------- puertas

## Puerta de una hoja. pos = bisagra (a nivel del piso), rot_y = hacia donde apunta la hoja cerrada
## (0 = hacia +x, -90 = hacia +z), abre_deg = cuanto gira al abrirse.
## bloqueo: "" (libre), "candado" (codigo), "tarjeta" (item_req), "sellada" (nunca abre).
func crear_puerta(nombre: String, pos: Vector3, rot_y: float, ancho: float, alto: float, abre_deg: float, mat_hoja: Material, bloqueo: String = "", datos: Dictionary = {}) -> Dictionary:
	var bis := u.node3d(self, nombre, pos, rot_y)
	var hoja_w := ancho - 0.04
	u.box(bis, Vector3(ancho / 2.0, alto / 2.0, 0), Vector3(hoja_w, alto - 0.04, 0.07), mat_hoja, true, Vector3.ZERO, "Hoja")
	u.box(bis, Vector3(ancho - 0.16, 1.0, 0.07), Vector3(0.12, 0.03, 0.12), u.metal(Color(0.6, 0.5, 0.2)))
	u.box(bis, Vector3(ancho / 2.0, alto - 0.5, 0.04), Vector3(hoja_w - 0.3, 0.5, 0.01), u.mat(Color(0.2, 0.15, 0.1), 0.6, 0.3))
	var centro := pos + Basis(Vector3.UP, deg_to_rad(rot_y)) * Vector3(ancho / 2.0, 1.1, 0)
	var objetivo := u.node3d(self, nombre + "_Objetivo", centro)
	var d: Dictionary = {
		"hinge": bis, "abierta": false, "bloqueo": bloqueo, "bloqueada": bloqueo != "",
		"abre": abre_deg, "rot0": rot_y, "tween": null, "led": null, "it": {}, "nombre": nombre,
	}
	for k in datos.keys():
		d[k] = datos[k]
	puertas.append(d)
	d["it"] = reg(objetivo, "puerta", _texto_puerta(d), {"puerta": d}, 3.6)
	return d


## Lector de tarjetas junto a la puerta (LED rojo -> verde al abrir).
func lector_tarjeta(d: Dictionary, pos: Vector3, rot_y: float) -> void:
	var raiz := u.node3d(self, "Lector_" + String(d["nombre"]), pos, rot_y)
	u.box(raiz, Vector3(0, 0, 0), Vector3(0.14, 0.22, 0.04), u.mat(Color(0.12, 0.12, 0.13), 0.4, 0.5))
	var led := u.mat(Color(0.3, 0, 0), 0.5, 0.0, Color(1.0, 0.1, 0.1), 3.0)
	u.box(raiz, Vector3(0, 0.06, 0.022), Vector3(0.05, 0.025, 0.01), led)
	u.box(raiz, Vector3(0, -0.03, 0.022), Vector3(0.09, 0.03, 0.005), u.mat(Color(0.02, 0.02, 0.02), 0.3))
	d["led"] = led


func _texto_puerta(d: Dictionary) -> String:
	if bool(d["bloqueada"]):
		match String(d["bloqueo"]):
			"candado":
				return "Puerta con candado"
			"tarjeta":
				return "Lector de tarjetas"
			"sellada":
				return "Examinar puerta"
	return "Cerrar puerta" if bool(d["abierta"]) else "Abrir puerta"


func _usar_puerta(d: Dictionary) -> void:
	if bool(d["bloqueada"]):
		match String(d["bloqueo"]):
			"candado":
				estado.pedir_codigo.emit({
					"titulo": String(d.get("titulo", "CANDADO")),
					"correcto": String(d["codigo"]),
					"pista": String(d.get("pista", "")),
					"al_resolver": Callable(self, "_desbloquear").bind(d),
				})
			"tarjeta":
				if estado.tiene(String(d["item_req"])):
					_desbloquear(d)
				else:
					Sfx.tocar("beep_no")
					estado.mensaje.emit(String(d["msg_falta"]))
			"sellada":
				Sfx.tocar("beep_no")
				estado.mensaje.emit(String(d["msg_falta"]))
		return
	_alternar(d)


func _desbloquear(d: Dictionary) -> void:
	d["bloqueada"] = false
	if d["led"] != null:
		var led := d["led"] as StandardMaterial3D
		led.albedo_color = Color(0, 0.3, 0)
		led.emission = Color(0.1, 1.0, 0.2)
	Sfx.tocar("beep_ok")
	var cb := d.get("al_abrir", Callable()) as Callable
	if cb.is_valid():
		cb.call()
	_alternar(d)


func _alternar(d: Dictionary) -> void:
	d["abierta"] = not bool(d["abierta"])
	var hinge := d["hinge"] as Node3D
	var tw := d["tween"] as Tween
	if tw and tw.is_valid():
		tw.kill()
	var destino := float(d["rot0"]) + (float(d["abre"]) if bool(d["abierta"]) else 0.0)
	tw = create_tween()
	tw.tween_property(hinge, "rotation_degrees:y", destino, 0.55).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)
	d["tween"] = tw
	Sfx.tocar("puerta")
	(d["it"] as Dictionary)["texto"] = _texto_puerta(d)


# ---------------------------------------------------------------- muebles comunes

## Librero con libros de colores. Mira hacia +z local (gira con rot_y).
func librero(pos: Vector3, rot_y: float, ancho: float = 2.0, alto: float = 2.2) -> Node3D:
	var r := u.node3d(self, "Librero", pos, rot_y)
	var madera := u.wood()
	u.box(r, Vector3(0, alto / 2.0, 0), Vector3(ancho, alto, 0.4), madera, true)
	var colores: Array[Color] = [Color(0.45, 0.08, 0.08), Color(0.12, 0.2, 0.32), Color(0.35, 0.28, 0.1), Color(0.18, 0.3, 0.2), Color(0.3, 0.18, 0.1), Color(0.55, 0.5, 0.4)]
	var filas := int(alto / 0.42)
	for f in filas:
		var y := 0.25 + f * 0.4
		u.box(r, Vector3(0, y - 0.18, 0.02), Vector3(ancho - 0.06, 0.03, 0.42), madera)
		var x := -ancho / 2.0 + 0.1
		var k := 0
		while x < ancho / 2.0 - 0.12:
			var w := 0.05 + float((k * 7 + f * 3) % 4) * 0.015
			var h := 0.26 + float((k * 5 + f) % 3) * 0.04
			u.box(r, Vector3(x + w / 2.0, y - 0.16 + h / 2.0, 0.07), Vector3(w, h, 0.26), u.mat(colores[(k + f) % colores.size()], 0.9))
			x += w + 0.008
			k += 1
	return r


## Escritorio: tapa + 2 laterales. Mira hacia +z local. Devuelve el nodo; la superficie esta en y = alto.
func escritorio(pos: Vector3, rot_y: float, ancho: float = 1.8, fondo: float = 0.9, alto: float = 0.76, madera: Material = null) -> Node3D:
	var m: Material = madera if madera != null else u.wood_light()
	var r := u.node3d(self, "Escritorio", pos, rot_y)
	u.box(r, Vector3(0, alto - 0.03, 0), Vector3(ancho, 0.06, fondo), m, true)
	u.box(r, Vector3(-ancho / 2.0 + 0.05, (alto - 0.06) / 2.0, 0), Vector3(0.08, alto - 0.06, fondo - 0.1), u.wood(), true)
	u.box(r, Vector3(ancho / 2.0 - 0.05, (alto - 0.06) / 2.0, 0), Vector3(0.08, alto - 0.06, fondo - 0.1), u.wood(), true)
	u.box(r, Vector3(0, (alto - 0.06) / 2.0 + 0.05, -fondo / 2.0 + 0.04), Vector3(ancho - 0.1, alto - 0.2, 0.04), u.wood())
	return r


func silla(pos: Vector3, rot_y: float, tela: Color = Color(0.30, 0.09, 0.07)) -> Node3D:
	var s := u.node3d(self, "Silla", pos, rot_y)
	var m_tela := u.mat(tela, 0.85)
	var m_neg := u.mat(Color(0.08, 0.08, 0.08), 0.5, 0.5)
	u.cyl(s, Vector3(0, 0.27, 0), 0.03, 0.03, 0.4, m_neg)
	for i in 3:
		var pata := u.box(s, Vector3(0, 0.06, 0), Vector3(0.36, 0.03, 0.05), m_neg)
		pata.rotation_degrees.y = i * 60.0
	u.box(s, Vector3(0, 0.5, 0), Vector3(0.5, 0.08, 0.5), m_tela)
	u.box(s, Vector3(0, 0.85, 0.25), Vector3(0.48, 0.55, 0.07), m_tela, false, Vector3(8, 0, 0))
	return s


## Lampara de escritorio (pantalla emisiva + luz pequeña).
func lampara_escritorio(padre: Node3D, pos: Vector3, energia: float = 0.7) -> OmniLight3D:
	u.cyl(padre, pos + Vector3(0, 0.01, 0), 0.07, 0.08, 0.02, u.metal(Color(0.1, 0.1, 0.1)))
	u.cyl(padre, pos + Vector3(0, 0.2, 0), 0.01, 0.01, 0.38, u.metal(Color(0.1, 0.1, 0.1)))
	u.cyl(padre, pos + Vector3(0.04, 0.4, 0), 0.02, 0.1, 0.1, emisivo(u.mat(Color(0.2, 0.3, 0.2), 0.5, 0.0, Color(1.0, 0.8, 0.45), 1.8)))
	return u.omni(padre, pos + Vector3(0.05, 0.38, 0), Color(1.0, 0.75, 0.42), energia, 3.2)


## Hoja de papel sobre una superficie (para cartas y diarios). Material propio -> se puede resaltar.
func hoja_papel(padre: Node3D, pos: Vector3, rot_y: float = 0.0, tam: Vector2 = Vector2(0.21, 0.3), color: Color = Color(0.86, 0.8, 0.62)) -> MeshInstance3D:
	var p := u.box(padre, pos, Vector3(tam.x, 0.006, tam.y), u.mat(color, 0.95))
	p.rotation_degrees.y = rot_y
	return p
