extends Node

## Registro de objetos con los que se puede interactuar (cartas, puertas, items...).
## Cada escenario registra sus objetos; museum.gd pregunta cual tiene el jugador cerca
## y llama a interactuar() cuando presiona E / clic.
##
## Un interactivo es un Dictionary con: nodo, duenio, tipo, texto, alcance, offset,
## resaltar (nodo cuyo contorno se pinta de verde) y los datos extra que quiera el duenio.

var lista: Array[Dictionary] = []
var _resaltado: Node
var _mat_contorno: StandardMaterial3D


func _init() -> void:
	_mat_contorno = StandardMaterial3D.new()
	_mat_contorno.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	_mat_contorno.albedo_color = Color(0.35, 1.0, 0.45)
	_mat_contorno.cull_mode = BaseMaterial3D.CULL_FRONT
	_mat_contorno.grow = true
	_mat_contorno.grow_amount = 0.004


func registrar(nodo: Node3D, duenio: Object, tipo: String, texto: String, alcance: float = 3.0, offset: Vector3 = Vector3.ZERO, datos: Dictionary = {}, resaltar: Node = null) -> Dictionary:
	var it: Dictionary = {
		"nodo": nodo, "duenio": duenio, "tipo": tipo, "texto": texto,
		"alcance": alcance, "offset": offset, "resaltar": resaltar, "activo": true,
	}
	for k in datos.keys():
		it[k] = datos[k]
	lista.append(it)
	return it


func quitar(it: Dictionary) -> void:
	if _resaltado == (it["resaltar"] as Node):
		_resaltado = null
	lista.erase(it)


## Prioridad al elegir entre objetos cercanos (menor = mas prioritario): lo que se puede
## recoger gana a las notas, y estas a las puertas; los interruptores van al final para que
## nunca le "roben" el boton a un objeto que quieres agarrar.
const PESOS := {
	"recoger": 0.7, "nota": 0.9, "examinar": 1.0, "puerta": 1.0, "puerta_oficina": 1.0,
	"terminal": 1.0, "terminal_pc": 1.0, "camara": 1.1, "reloj": 1.2, "radio_base": 1.2,
	"altar": 0.9, "interruptor": 1.8, "interruptor_area": 1.8,
}


## Candidatos cercanos al jugador, del mas probable al menos (maximo 4), sin paredes de por medio.
func buscar_varios(pos_jugador: Vector3, origen_mira: Vector3, direccion_mira: Vector3, excluir: RID, mundo: World3D, maximo: int = 4) -> Array[Dictionary]:
	var punt: Array[Dictionary] = []
	var f := direccion_mira.normalized()
	for it in lista:
		if not bool(it["activo"]):
			continue
		var n := it["nodo"] as Node3D
		if n == null or not is_instance_valid(n):
			continue
		var p := n.to_global(it["offset"] as Vector3)
		var hacia := p - origen_mira
		var d := pos_jugador.distance_to(p)
		var alcance := minf(float(it["alcance"]) + 0.35, 3.6)
		if d > alcance or absf(p.y - pos_jugador.y - 1.0) > 2.4:
			continue
		var cos_ang := f.dot(hacia.normalized()) if hacia.length_squared() > 0.0001 else 1.0
		# El centro de la vista manda; un cono amplio conserva un poco de tolerancia.
		if cos_ang < 0.72:
			continue
		var peso := float(PESOS.get(String(it["tipo"]), 1.0))
		# Favorece objetos centrados en la vista y cercanos, respetando prioridades por tipo.
		punt.append({"it": it, "score": maxf(d, 0.3) * (1.0 + 3.0 * (1.0 - cos_ang)) * peso, "pos": p})
	punt.sort_custom(func(a: Dictionary, b: Dictionary) -> bool: return float(a["score"]) < float(b["score"]))
	var res: Array[Dictionary] = []
	for c in punt:
		var mp: Vector3 = c["pos"]
		var q := PhysicsRayQueryParameters3D.create(origen_mira, mp)
		q.collision_mask = 1
		q.exclude = [excluir]
		var hit := mundo.direct_space_state.intersect_ray(q)
		if not hit.is_empty():
			var dist_hit := origen_mira.distance_to(hit["position"] as Vector3)
			# Muchos interactivos estan dentro de su propio collider (vitrinas, puertas, estatuas).
			# Tolera la superficie cercana del objeto, pero conserva el bloqueo de paredes alejadas.
			if dist_hit < origen_mira.distance_to(mp) - 0.75:
				continue
		res.append(c["it"] as Dictionary)
		if res.size() >= maximo:
			break
	return res


## El mejor candidato (o {} si no hay ninguno).
func buscar(pos_jugador: Vector3, origen_mira: Vector3, direccion_mira: Vector3, excluir: RID, mundo: World3D) -> Dictionary:
	var r := buscar_varios(pos_jugador, origen_mira, direccion_mira, excluir, mundo, 1)
	return r[0] if not r.is_empty() else {}


## Contorno verde en el objeto al que apunta el jugador.
func resaltar(it: Dictionary) -> void:
	var nuevo: Node = null
	if not it.is_empty():
		nuevo = it["resaltar"] as Node
	if nuevo != _resaltado:
		_aplicar(_resaltado, false)
		_aplicar(nuevo, true)
		_resaltado = nuevo


func interactuar(it: Dictionary) -> void:
	if it.is_empty():
		return
	var d := it["duenio"] as Object
	if d and is_instance_valid(d):
		d.call("interactuar", it)


func _aplicar(raiz: Node, activo: bool) -> void:
	if raiz == null or not is_instance_valid(raiz):
		return
	var mallas: Array[Node] = raiz.find_children("*", "MeshInstance3D", true, false)
	if raiz is MeshInstance3D:
		mallas.append(raiz)
	for n in mallas:
		var mi := n as MeshInstance3D
		mi.material_overlay = _mat_contorno if activo else null
