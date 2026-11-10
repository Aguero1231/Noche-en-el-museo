extends Node

## Estado compartido de la partida: inventario, banderas, reloj del juego y mensajes.
## Lo crea museum.gd y se lo pasan a todos los escenarios. Tambien es el "bus" por
## donde los escenarios le piden cosas a la interfaz (notas, candado, radio, sonidos).

signal mensaje(texto: String)
signal radio(texto: String)
signal nota(datos: Dictionary)           # {titulo, texto, estilo, firma}
signal pedir_codigo(datos: Dictionary)   # {titulo, correcto, longitud, pista, al_resolver}
signal inventario_cambio(item: String)
signal sonido(nombre: String)
signal recargar_bateria(porcentaje: float)
signal despertar(grupo: String)          # despierta a las estatuas de un grupo ("wake_galeria"...)

const MINUTOS_JUEGO_POR_SEGUNDO := 0.25   # 1 min del juego = 4 s reales (00:00 -> 06:00 en 24 min)
const FRAGMENTOS_TOTALES := 4

var items: Dictionary = {}
var flags: Dictionary = {}
var minutos := 0.0


func tiene(item: String) -> bool:
	return int(items.get(item, 0)) > 0


func cantidad(item: String) -> int:
	return int(items.get(item, 0))


func dar(item: String, n: int = 1) -> void:
	items[item] = cantidad(item) + n
	inventario_cambio.emit(item)


func quitar(item: String, n: int = 1) -> void:
	items[item] = maxi(0, cantidad(item) - n)
	inventario_cambio.emit(item)


func flag(nombre: String) -> bool:
	return bool(flags.get(nombre, false))


func poner_flag(nombre: String, valor: bool = true) -> void:
	flags[nombre] = valor


## Recoger un objeto del mundo: lo mete al inventario y avisa.
func recoger(item: String, n: int, texto: String) -> void:
	dar(item, n)
	sonido.emit("pickup")
	if texto != "":
		mensaje.emit(texto)


## Dice una vez (y solo una) una frase por radio.
func radio_una_vez(id: String, texto: String) -> void:
	if flag("radio_" + id):
		return
	poner_flag("radio_" + id)
	radio.emit(texto)


func avanzar_reloj(delta: float) -> void:
	minutos = minf(minutos + delta * MINUTOS_JUEGO_POR_SEGUNDO, 360.0)


func hora_texto() -> String:
	var m := int(minutos)
	return "%02d:%02d" % [m / 60, m % 60]


func hora_con_segundos() -> String:
	var total := int(minutos * 60.0)
	return "%02d:%02d:%02d" % [total / 3600, (total / 60) % 60, total % 60]


func faltan_texto() -> String:
	var resto := int(360.0 - minutos)
	return "%02d:%02d" % [resto / 60, resto % 60]


func fragmentos_total() -> int:
	return cantidad("fragmento") + cantidad("fragmento_colocado")


## Texto del objetivo actual (HUD), segun lo que lleva el jugador y el nivel en que va.
func objetivo_actual() -> String:
	var l := "[x]" if tiene("linterna") else "[ ]"
	var e := "[x]" if tiene("espejo") else "[ ]"
	var w := "[x]" if tiene("walkie") else "[ ]"
	var fila := "%s Linterna  %s Espejo  %s Walkie   |   Fragmentos: %d/%d" % [l, e, w, fragmentos_total(), FRAGMENTOS_TOTALES]
	var obj := ""
	if not (tiene("linterna") and tiene("espejo") and tiene("walkie")):
		obj = "Equípate en la oficina: linterna, espejo y walkie-talkie."
	elif not flag("oficina_elena_abierta"):
		obj = "Sal al vestíbulo. Abre la oficina de la Dra. Torres (candado)."
	elif not tiene("tarjeta_dorada") and not flag("restauracion_abierta"):
		obj = "Busca la tarjeta de acceso en la oficina de la Dra. Torres."
	elif not flag("restauracion_abierta"):
		obj = "Abre la Sala de Restauración con la tarjeta dorada."
	elif not flag("escalera_abierta"):
		# Nivel 1: primer fragmento y tarjeta azul
		if fragmentos_total() < 1:
			obj = "Encuentra el primer fragmento del amuleto."
		elif cantidad("fragmento") > 0:
			obj = "Coloca el fragmento en el Pedestal de Sellado (Sala Egipcia)."
		elif not tiene("tarjeta_azul"):
			obj = "Toma la tarjeta de acceso Nivel 1 del pedestal."
		else:
			obj = "Abre la escalera de servicio (junto a la entrada) con la tarjeta azul."
	elif not flag("piso2_visitado"):
		obj = "Sube por la escalera de servicio al Nivel 2 (Galería Medieval)."
	elif cantidad("fragmento_colocado") < 3:
		# Nivel 2: fragmentos 2 y 3
		if not (flag("frag2") and flag("frag3")):
			var falta := ""
			if not flag("frag2"):
				falta += "fragmento 2 (tumba del caballero)"
			if not flag("frag3"):
				falta += (" y " if falta != "" else "") + "fragmento 3 (Armería)"
			obj = "Nivel 2: consigue el " + falta + "."
			if not flag("frag3") and not flag("armeria_abierta"):
				obj += " La reja de la Armería pide un año de 4 dígitos."
		else:
			obj = "Baja al Pedestal de Sellado (Sala Egipcia) y coloca los fragmentos."
	elif not tiene("tarjeta_roja") and not flag("piso3_abierto"):
		obj = "Toma la tarjeta de acceso Nivel 2 del pedestal."
	else:
		obj = "Sube y abre la escalera al Piso 3 con la tarjeta roja. (Nivel 3: próximamente)"
	return "OBJETIVO: %s\n%s" % [obj, fila]
