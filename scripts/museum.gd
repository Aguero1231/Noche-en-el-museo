extends Node3D

const OfficeBuilder = preload("res://scripts/environment/office_builder.gd")
const MuseumBuilder = preload("res://scripts/environment/museum_builder.gd")
const RoomLobby = preload("res://scripts/environment/room_lobby.gd")
const RoomControl = preload("res://scripts/environment/room_control.gd")
const RoomCurator = preload("res://scripts/environment/room_curator.gd")
const RoomRestoration = preload("res://scripts/environment/room_restoration.gd")
const RoomStairs = preload("res://scripts/environment/room_stairs.gd")
const RoomGaleria = preload("res://scripts/environment/room_galeria.gd")
const RoomArmeria = preload("res://scripts/environment/room_armeria.gd")
const CCTV = preload("res://scripts/environment/cctv_system.gd")
const GameState = preload("res://scripts/game/game_state.gd")
const Interactables = preload("res://scripts/game/interactables.gd")
const GameHud = preload("res://scripts/ui/game_hud.gd")
const NoteViewer = preload("res://scripts/ui/note_viewer.gd")
const CodeLock = preload("res://scripts/ui/code_lock.gd")
const OptionsPanel = preload("res://scripts/ui/options_panel.gd")
const RoomBase = preload("res://scripts/environment/room_base.gd")
const Guardia = preload("res://scripts/player/guardia.gd")
const ZonaActivacion = preload("res://scripts/game/zona_activacion.gd")
const ObjetoInteractivo = preload("res://scripts/game/objeto_interactivo.gd")
const EstatuaEnemiga = preload("res://scripts/enemies/estatua_enemiga.gd")
const GameOver = preload("res://scripts/ui/game_over.gd")

# --- Ajustes de camara (tercera persona). Las velocidades estan en el Inspector del nodo Guardia. ---
const CAM_DISTANCE := 3.8          # distancia maxima de la camara detras del guardia
const CAM_PIVOT_HEIGHT := 1.62     # altura de los ojos en primera persona
const PITCH_MIN := -35.0           # grados: mirar abajo
const PITCH_MAX := 40.0            # grados: mirar arriba
const DURACION_LUZ_SEGURA := 10.0

# Camaras de seguridad (coordenadas del mundo). Los monitores de la oficina y de la sala
# de control las muestran en vivo. El orden es el de CAM 01, CAM 02...
const CAMARAS := [
	{"nombre": "CAM 01 VESTIBULO", "pos": Vector3(8.4, 5.3, 17.0), "mira": Vector3(-2.0, 0.8, 26.0), "fov": 75.0},
	{"nombre": "CAM 02 SALA EGIPCIA S", "pos": Vector3(-3.5, 7.0, 15.4), "mira": Vector3(1.0, 0.5, 0.0), "fov": 70.0},
	{"nombre": "CAM 03 SALA EGIPCIA N", "pos": Vector3(4.5, 7.0, -15.4), "mira": Vector3(-1.0, 1.0, 10.0), "fov": 65.0},
	{"nombre": "CAM 04 SALA EGIPCIA O", "pos": Vector3(-15.4, 6.5, -12.0), "mira": Vector3(6.0, 1.0, 8.0), "fov": 70.0},
	{"nombre": "CAM 05 RESTAURACION", "pos": Vector3(-10.0, 3.3, 24.1), "mira": Vector3(-14.0, 1.0, 28.5), "fov": 75.0},
	{"nombre": "CAM 06 ENTRADA", "pos": Vector3(-8.4, 5.3, 17.0), "mira": Vector3(0.0, 1.5, 29.5), "fov": 75.0},
	{"nombre": "CAM 07 GALERIA", "pos": Vector3(8.4, 13.6, 29.4), "mira": Vector3(0.0, 10.0, 12.0), "fov": 72.0},
	{"nombre": "CAM 08 ARMERIA", "pos": Vector3(5.9, 13.3, -11.1), "mira": Vector3(-3.0, 10.2, -10.25), "fov": 75.0},
]

var player: Guardia
var camera: Camera3D
var primera_persona := false
var brazo_izquierdo_vista: Node3D
var brazo_derecho_vista: Node3D
var espejo_modelo_vista: Node3D
var walkie_vista: Node3D
var linterna_vista: MeshInstance3D
var material_niebla_espejo: ShaderMaterial
var body_model: Node3D
var flashlight: SpotLight3D
var linterna_pos_tercera := Vector3(0.22, 1.3, -0.3)
var flashlight_model: MeshInstance3D
var walkie_model: MeshInstance3D
var pierna_izquierda: Node3D
var pierna_derecha: Node3D
var brazo_izquierdo: Node3D
var brazo_derecho: Node3D
var codo_izquierdo: Node3D
var codo_derecho: Node3D
var torso_model: Node3D
var cabeza_model: Node3D
var mano_derecha: Node3D
var estado: GameState
var registry: Interactables
var cctv: CCTV
var hall: MuseumBuilder
var office: OfficeBuilder
var lobby: RoomLobby
var control: RoomControl
var curator: RoomCurator
var restoration: RoomRestoration
var stairs: RoomStairs
var galeria: RoomGaleria
var armeria: RoomArmeria
var hud: GameHud
var note_viewer: NoteViewer
var code_lock: CodeLock
var pause_layer: CanvasLayer
var pause_backdrop: ColorRect
var pause_panel: Panel
var pause_continue_button: Button
var pause_view_button: Button
var options_panel: Panel
var controls_panel: Panel
var mouse_captured := true

var look_pitch := deg_to_rad(-12.0)   # positivo = mirando hacia arriba
var cam_dist_now := CAM_DISTANCE
var stamina := 100.0
var battery := 100.0
var flashlight_on := false
var target: Dictionary = {}
var _acc_hud := 0.0
var _acc_cuenta := 0.0

# Dificultad: espejo, tension y fin del juego
var game_over_ui: GameOver
var game_over_activo := false
var espejo_vp: SubViewport
var espejo_cam: Camera3D
var _sway_mouse := Vector2.ZERO
var _peligro_actual := 0.0
var _espejo_solicitado := false
var _t_latido := 0.0
var _t_static := 0.0
var _t_senuelo := 0.0
var _anim_t := 0.0
var _fase_pasos := 0.0
var _intensidad_movimiento := 0.0
var _t_pisada := 0.0
var _turnos_luz: Dictionary = {}
var _acc_interaccion := 0.0
var _acc_brazos_occlusion := 0.0
var _brazo_izq_tapado := false
var _brazo_der_tapado := false

func _ready() -> void:
	# Todo vive en la escena museum.tscn (ver el Scene Tree): aqui solo se conecta y se arma el mundo.
	estado = $Estado as GameState
	registry = $RegistroInteractivos as Interactables
	hud = $HUD as GameHud
	note_viewer = $VisorDeNotas as NoteViewer
	code_lock = $Candado as CodeLock
	game_over_ui = $GameOver as GameOver

	_build_world()
	_build_player()
	_build_espejo()
	_brazos_primera_persona()
	_sync_linterna_vista()
	_update_camera(1.0)
	_connect_estado()
	_connect_escena()
	_build_ui()
	Settings.changed.connect(_on_settings_changed)
	_apply_settings()
	Sfx.zumbido(true)
	Input.mouse_mode = Input.MOUSE_MODE_CAPTURED
	# Primer mensaje: Roberto por la radio de la oficina
	get_tree().create_timer(3.5).timeout.connect(func():
		estado.radio_una_vez("inicio", "RADIO (base): «Alex... ¿me escuchas? Soy Roberto. Recoge tu walkie y tu linterna del escritorio. Y lee mi carta, ¿sí?»"))

func _exit_tree() -> void:
	Sfx.zumbido(false)

## Pasa el estado, el registro de interactivos y las camaras a un cuarto y lo construye.
func _preparar_sala(sala: Node3D) -> Node3D:
	sala.set("estado", estado)
	sala.set("registry", registry)
	sala.set("cctv", cctv)
	sala.call("build")
	return sala

func _build_world() -> void:
	# Camaras de seguridad (primero, para que los monitores ya tengan imagen)
	cctv = $CCTV as CCTV
	cctv.estado = estado
	cctv.crear_camaras(CAMARAS)

	# Sala Egipcia (suelo, paredes, luces, vitrinas, estatuas...): scripts/environment/museum_builder.gd
	hall = $Mundo/SalaEgipcia as MuseumBuilder
	hall.registry = registry
	hall.estado = estado
	hall.build()

	# Primer piso: vestibulo y los cuartos que salen de el (nodos de Mundo en museum.tscn)
	lobby = _preparar_sala($Mundo/Vestibulo) as RoomLobby
	control = _preparar_sala($Mundo/SalaDeControl) as RoomControl
	curator = _preparar_sala($Mundo/OficinaDraTorres) as RoomCurator
	restoration = _preparar_sala($Mundo/SalaDeRestauracion) as RoomRestoration
	stairs = _preparar_sala($Mundo/EscaleraDeServicio) as RoomStairs
	galeria = _preparar_sala($Mundo/GaleriaMedieval) as RoomGaleria
	armeria = _preparar_sala($Mundo/Armeria) as RoomArmeria

	# Oficina de seguridad (inicio del juego): pegada a la pared este del vestibulo, girada 90 grados
	office = _preparar_sala($Mundo/OficinaSeguridad) as OfficeBuilder

func _build_player() -> void:
	# El guardia es un nodo de la escena (scenes/player/guardia.tscn, instanciado en museum.tscn);
	# su origen esta en los pies. Aqui solo se coloca en la oficina y se le arma el modelo.
	player = $Guardia as Guardia
	player.global_position = office.punto_de_aparicion() + Vector3(0, 0.05, 0)
	player.rotation.y = OfficeBuilder.SPAWN_YAW
	body_model = player.get_node("Modelo") as Node3D
	_build_guard_model()
	flashlight = player.get_node("Linterna") as SpotLight3D
	linterna_pos_tercera = flashlight.position

	camera = Camera3D.new()
	camera.fov = Settings.fov
	camera.cull_mask = 1 | 2
	add_child(camera)
	camera.current = true

func _brazos_primera_persona() -> void:
	# Brazos de primer plano modelados con cápsulas y cajas, apoyados en los bordes bajos.
	var manga := _flat_vista(Color(0.045, 0.085, 0.19))
	var puño := _flat_vista(Color(0.13, 0.20, 0.32))
	var piel := _flat_vista(Color(0.74, 0.53, 0.40))
	var parche := _flat_vista(Color(0.72, 0.57, 0.25))
	brazo_izquierdo_vista = _crear_brazo_vista(-1.0, manga, puño, piel, parche)
	brazo_derecho_vista = _crear_brazo_vista(1.0, manga, puño, piel, parche)
	brazo_izquierdo_vista.visible = false
	brazo_derecho_vista.visible = false
	_crear_espejo_vista(piel, parche)
	_crear_walkie_vista()

func _flat_vista(color: Color) -> StandardMaterial3D:
	var material := StandardMaterial3D.new()
	material.albedo_color = color
	material.roughness = 0.82
	material.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	return material

func _crear_brazo_vista(lado: float, manga: Material, puño: Material, piel: Material, parche: Material) -> Node3D:
	var raiz := Node3D.new()
	raiz.name = "BrazoVistaIzquierdo" if lado < 0.0 else "BrazoVistaDerecho"
	raiz.position = Vector3(lado * 0.48, -0.56, -0.62)
	camera.add_child(raiz)
	var direccion := Vector2(-lado * 0.19, 0.32)
	var largo := direccion.length()
	var manga_malla := CapsuleMesh.new()
	manga_malla.radius = 0.095
	manga_malla.height = largo + 0.12
	manga_malla.radial_segments = 8
	manga_malla.rings = 3
	var manga_inst := MeshInstance3D.new()
	manga_inst.mesh = manga_malla
	manga_inst.material_override = manga
	manga_inst.position = Vector3(direccion.x * 0.5, direccion.y * 0.5, 0.0)
	manga_inst.rotation.z = atan2(-direccion.x, direccion.y)
	raiz.add_child(manga_inst)
	var puno_malla := BoxMesh.new()
	puno_malla.size = Vector3(0.20, 0.065, 0.19)
	var puno_inst := MeshInstance3D.new()
	puno_inst.mesh = puno_malla
	puno_inst.material_override = puño
	puno_inst.position = Vector3(direccion.x, direccion.y - 0.02, 0.0)
	puno_inst.rotation.z = manga_inst.rotation.z
	raiz.add_child(puno_inst)
	var mano := MeshInstance3D.new()
	var mano_malla := SphereMesh.new()
	mano_malla.radius = 0.085
	mano_malla.height = 0.14
	mano_malla.radial_segments = 8
	mano_malla.rings = 4
	mano.mesh = mano_malla
	mano.material_override = piel
	mano.position = Vector3(direccion.x, direccion.y + 0.055, -0.015)
	raiz.add_child(mano)
	var placa := MeshInstance3D.new()
	var placa_malla := BoxMesh.new()
	placa_malla.size = Vector3(0.085, 0.075, 0.018)
	placa.mesh = placa_malla
	placa.material_override = parche
	placa.position = Vector3(lado * 0.045, direccion.y * 0.57, 0.085)
	placa.rotation.z = manga_inst.rotation.z
	raiz.add_child(placa)
	# Dedos cuadrados estilizados para conservar la lectura de la mano en baja resolución.
	for dedo in range(3):
		var dedo_inst := MeshInstance3D.new()
		var dedo_malla := BoxMesh.new()
		dedo_malla.size = Vector3(0.035, 0.075, 0.045)
		dedo_inst.mesh = dedo_malla
		dedo_inst.material_override = piel
		dedo_inst.position = Vector3(direccion.x + (float(dedo) - 1.0) * 0.04, direccion.y + 0.11, -0.01)
		raiz.add_child(dedo_inst)
	if lado > 0.0:
		linterna_vista = MeshInstance3D.new()
		linterna_vista.name = "LinternaModelo"
		var linterna_malla := CylinderMesh.new()
		linterna_malla.top_radius = 0.026
		linterna_malla.bottom_radius = 0.034
		linterna_malla.height = 0.20
		linterna_vista.mesh = linterna_malla
		linterna_vista.material_override = _flat_vista(Color(0.075, 0.08, 0.09))
		linterna_vista.position = Vector3(direccion.x - 0.015, direccion.y + 0.10, -0.055)
		linterna_vista.rotation.x = deg_to_rad(90.0)
		linterna_vista.visible = flashlight_model.visible
		raiz.add_child(linterna_vista)
	_aislar_modelo_vista(raiz)
	return raiz

func _crear_espejo_vista(piel: Material, oro: Material) -> void:
	# La empuñadura y el marco forman un pequeño espejo sostenido desde la mano izquierda.
	espejo_modelo_vista = Node3D.new()
	espejo_modelo_vista.name = "EspejoEnManoIzquierda"
	espejo_modelo_vista.position = Vector3(0.23, 0.61, -0.015)
	espejo_modelo_vista.rotation.z = deg_to_rad(-9.0)
	brazo_izquierdo_vista.add_child(espejo_modelo_vista)
	var soporte := MeshInstance3D.new()
	var mango := CapsuleMesh.new()
	mango.radius = 0.025
	mango.height = 0.24
	mango.radial_segments = 8
	mango.rings = 3
	soporte.mesh = mango
	soporte.material_override = oro
	soporte.position = Vector3(0.0, -0.27, 0.0)
	espejo_modelo_vista.add_child(soporte)
	var marco := MeshInstance3D.new()
	var marco_malla := BoxMesh.new()
	marco_malla.size = Vector3(0.30, 0.39, 0.045)
	marco.mesh = marco_malla
	marco.material_override = oro
	espejo_modelo_vista.add_child(marco)
	var cristal := MeshInstance3D.new()
	var cristal_malla := QuadMesh.new()
	cristal_malla.size = Vector2(0.235, 0.315)
	cristal.mesh = cristal_malla
	var cristal_mat := StandardMaterial3D.new()
	cristal_mat.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	cristal_mat.albedo_texture = espejo_vp.get_texture()
	cristal_mat.cull_mode = BaseMaterial3D.CULL_DISABLED
	cristal.material_override = cristal_mat
	cristal.position.z = 0.026
	espejo_modelo_vista.add_child(cristal)
	var remate := MeshInstance3D.new()
	var remate_malla := BoxMesh.new()
	remate_malla.size = Vector3(0.065, 0.065, 0.012)
	remate.mesh = remate_malla
	remate.material_override = oro
	remate.position = Vector3(0.0, 0.17, 0.033)
	remate.rotation.z = deg_to_rad(45.0)
	espejo_modelo_vista.add_child(remate)
	var niebla := MeshInstance3D.new()
	var niebla_malla := QuadMesh.new()
	niebla_malla.size = Vector2(0.225, 0.305)
	niebla.mesh = niebla_malla
	var niebla_shader := Shader.new()
	niebla_shader.code = "shader_type spatial;\nrender_mode unshaded, blend_mix, depth_draw_never, cull_disabled;\nuniform float nivel = 0.0;\nvoid fragment(){ vec2 p=UV*vec2(7.0,5.0); float n=sin(p.x+sin(p.y*1.7))*sin(p.y+p.x*0.7); float nube=smoothstep(-0.2,0.65,n); ALBEDO=vec3(0.76,0.86,0.9); ALPHA=nivel*nube*0.34; }"
	material_niebla_espejo = ShaderMaterial.new()
	material_niebla_espejo.shader = niebla_shader
	niebla.material_override = material_niebla_espejo
	niebla.position.z = 0.029
	espejo_modelo_vista.add_child(niebla)
	espejo_modelo_vista.visible = false
	_aislar_modelo_vista(espejo_modelo_vista)

func _crear_walkie_vista() -> void:
	# La radio queda sobre el cinturón y solo entra en el encuadre al mirar hacia abajo.
	walkie_vista = Node3D.new()
	walkie_vista.name = "WalkieCinturonVista"
	player.add_child(walkie_vista)
	walkie_vista.position = Vector3(0.19, 0.96, -0.13)
	var pecho := MeshInstance3D.new()
	var pecho_malla := BoxMesh.new()
	pecho_malla.size = Vector3(0.48, 0.34, 0.14)
	pecho.mesh = pecho_malla
	pecho.material_override = _flat_vista(Color(0.045, 0.085, 0.19))
	pecho.position = Vector3(-0.02, 0.0, 0.06)
	walkie_vista.add_child(pecho)
	var cuerpo := MeshInstance3D.new()
	var caja := BoxMesh.new()
	caja.size = Vector3(0.075, 0.15, 0.045)
	cuerpo.mesh = caja
	cuerpo.material_override = _flat_vista(Color(0.075, 0.08, 0.085))
	walkie_vista.add_child(cuerpo)
	var pantalla := MeshInstance3D.new()
	var panel := BoxMesh.new()
	panel.size = Vector3(0.046, 0.04, 0.008)
	pantalla.mesh = panel
	pantalla.material_override = _flat_vista(Color(0.18, 0.62, 0.42))
	pantalla.position = Vector3(0.0, 0.035, 0.027)
	walkie_vista.add_child(pantalla)
	var antena := MeshInstance3D.new()
	var barra := CylinderMesh.new()
	barra.top_radius = 0.005
	barra.bottom_radius = 0.008
	barra.height = 0.095
	antena.mesh = barra
	antena.material_override = _flat_vista(Color(0.08, 0.08, 0.09))
	antena.position = Vector3(-0.024, 0.115, -0.005)
	walkie_vista.add_child(antena)
	var correa := MeshInstance3D.new()
	var correa_malla := BoxMesh.new()
	correa_malla.size = Vector3(0.48, 0.12, 0.055)
	correa.mesh = correa_malla
	correa.material_override = _flat_vista(Color(0.10, 0.075, 0.055))
	correa.position = Vector3(-0.02, -0.05, -0.025)
	walkie_vista.add_child(correa)
	_aislar_modelo_vista(walkie_vista)
	walkie_vista.visible = false


func _aislar_modelo_vista(raiz_modelo: Node3D) -> void:
	for n in raiz_modelo.find_children("*", "GeometryInstance3D", true, false):
		var malla := n as GeometryInstance3D
		malla.layers = 2
		malla.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF

func _sync_linterna_vista() -> void:
	if is_instance_valid(linterna_vista) and is_instance_valid(flashlight_model):
		linterna_vista.visible = flashlight_model.visible

func _build_guard_model() -> void:
	# Alex: uniforme de guardia (camisa azul marino, pantalon negro, botas, gorra, portagafete,
	# parche "Seguridad Museo", tiras reflectantes y cinturon con walkie y linterna).
	var uniform := _flat(Color(0.08, 0.13, 0.28), 0.8)
	var pants := _flat(Color(0.05, 0.05, 0.06), 0.85)
	var boots := _flat(Color(0.03, 0.03, 0.03), 0.5)
	var skin := _flat(Color(0.78, 0.60, 0.48), 0.7)
	var leather := _flat(Color(0.10, 0.06, 0.04), 0.6)
	var hair := _flat(Color(0.25, 0.15, 0.08), 0.9)
	var reflect := _flat(Color(0.75, 0.78, 0.8), 0.4)
	reflect.emission_enabled = true
	reflect.emission = Color(0.5, 0.52, 0.55)
	reflect.emission_energy_multiplier = 0.4

	pierna_izquierda = _crear_pierna(-0.11, pants, boots)
	pierna_derecha = _crear_pierna(0.11, pants, boots)

	torso_model = Node3D.new()
	torso_model.position = Vector3(0, 1.17, 0)
	body_model.add_child(torso_model)
	_guard_box_en(torso_model, Vector3(0.46, 0.62, 0.28), Vector3.ZERO, uniform)
	_guard_box(Vector3(0.5, 0.07, 0.32), Vector3(0, 0.88, 0), leather)
	brazo_izquierdo = _crear_brazo(-0.29, uniform, skin, false)
	brazo_derecho = _crear_brazo(0.29, uniform, skin, true)
	# Tiras reflectantes (pecho y brazos), parche del hombro y portagafete
	_guard_box_en(torso_model, Vector3(0.47, 0.04, 0.29), Vector3(0, -0.12, 0), reflect)
	_guard_box_en(brazo_izquierdo, Vector3(0.14, 0.035, 0.15), Vector3(0, -0.12, -0.075), reflect)
	_guard_box_en(brazo_derecho, Vector3(0.14, 0.035, 0.15), Vector3(0, -0.12, -0.075), reflect)
	_guard_box(Vector3(0.05, 0.07, 0.03), Vector3(0.3, 1.36, -0.08), _flat(Color(0.9, 0.75, 0.2), 0.6))
	_guard_box(Vector3(0.1, 0.13, 0.015), Vector3(-0.1, 1.2, -0.15), _flat(Color(0.9, 0.9, 0.85), 0.5))
	_guard_box(Vector3(0.015, 0.2, 0.015), Vector3(-0.1, 1.33, -0.14), leather)
	# Funda del walkie en el cinturon
	_guard_box(Vector3(0.06, 0.15, 0.04), Vector3(-0.2, 0.84, -0.17), _flat(Color(0.04, 0.04, 0.04), 0.5))

	cabeza_model = Node3D.new()
	cabeza_model.position = Vector3(0, 1.55, 0)
	body_model.add_child(cabeza_model)
	var head := MeshInstance3D.new()
	var sphere := SphereMesh.new()
	sphere.radius = 0.14
	sphere.height = 0.28
	head.mesh = sphere
	head.material_override = skin
	head.position = Vector3(0, 0.09, 0)
	cabeza_model.add_child(head)
	_guard_box_en(cabeza_model, Vector3(0.26, 0.1, 0.1), Vector3(0, 0.18, 0.07), hair)
	var cara := _flat(Color(0.78, 0.60, 0.48), 0.75)
	var ojos := _flat(Color(0.035, 0.025, 0.02), 0.45)
	for lado in [-1.0, 1.0]:
		_guard_box_en(cabeza_model, Vector3(0.026, 0.018, 0.012), Vector3(lado * 0.052, 0.115, -0.128), ojos)
	_guard_box_en(cabeza_model, Vector3(0.035, 0.045, 0.035), Vector3(0, 0.075, -0.135), cara)
	_guard_box_en(cabeza_model, Vector3(0.065, 0.012, 0.012), Vector3(0, 0.04, -0.13), ojos)

	# Gorra con visera (la visera marca hacia donde mira)
	var cap := MeshInstance3D.new()
	var cap_mesh := CylinderMesh.new()
	cap_mesh.top_radius = 0.16
	cap_mesh.bottom_radius = 0.16
	cap_mesh.height = 0.09
	cap.mesh = cap_mesh
	cap.material_override = uniform
	cap.position = Vector3(0, 0.21, 0)
	cabeza_model.add_child(cap)
	_guard_box_en(cabeza_model, Vector3(0.22, 0.02, 0.14), Vector3(0, 0.17, -0.16), leather)

	# Linterna y walkie en la mano / cinturon (aparecen al recogerlos)
	flashlight_model = MeshInstance3D.new()
	var fl_mesh := CylinderMesh.new()
	fl_mesh.top_radius = 0.035
	fl_mesh.bottom_radius = 0.03
	fl_mesh.height = 0.22
	flashlight_model.mesh = fl_mesh
	flashlight_model.name = "LinternaModelo"
	flashlight_model.material_override = _flat(Color(0.08, 0.08, 0.08), 0.4)
	flashlight_model.position = Vector3(0, -0.08, -0.05)
	flashlight_model.rotation_degrees = Vector3(-90, 0, 0)
	flashlight_model.visible = false
	mano_derecha.add_child(flashlight_model)
	walkie_model = MeshInstance3D.new()
	var wk := BoxMesh.new()
	wk.size = Vector3(0.05, 0.13, 0.03)
	walkie_model.mesh = wk
	walkie_model.material_override = _flat(Color(0.12, 0.12, 0.13), 0.5)
	walkie_model.position = Vector3(-0.2, 0.93, -0.19)
	walkie_model.visible = false
	body_model.add_child(walkie_model)
	_guard_box_en(walkie_model, Vector3(0.034, 0.045, 0.008), Vector3(0, 0.025, -0.02), _flat(Color(0.25, 0.55, 0.35), 0.4))
	_guard_box_en(walkie_model, Vector3(0.012, 0.04, 0.012), Vector3(0.012, 0.1, 0), leather)
	_guard_box_en(walkie_model, Vector3(0.01, 0.018, 0.01), Vector3(-0.012, -0.035, -0.02), _flat(Color(0.7, 0.12, 0.08), 0.4))

func _flat(color: Color, rough: float) -> StandardMaterial3D:
	var m := StandardMaterial3D.new()
	m.albedo_color = color
	m.roughness = rough
	return m

func _guard_box(size: Vector3, pos: Vector3, mat: Material) -> void:
	_guard_box_en(body_model, size, pos, mat)

func _guard_box_en(parent: Node3D, size: Vector3, pos: Vector3, mat: Material) -> MeshInstance3D:
	var mi := MeshInstance3D.new()
	var box := BoxMesh.new()
	box.size = size
	mi.mesh = box
	mi.material_override = mat
	mi.position = pos
	parent.add_child(mi)
	return mi

func _crear_pierna(x: float, material_pantalon: Material, material_bota: Material) -> Node3D:
	var pivote := Node3D.new()
	pivote.position = Vector3(x, 0.86, 0)
	body_model.add_child(pivote)
	_guard_box_en(pivote, Vector3(0.14, 0.78, 0.2), Vector3(0, -0.39, 0), material_pantalon)
	_guard_box_en(pivote, Vector3(0.16, 0.14, 0.28), Vector3(0, -0.72, -0.03), material_bota)
	return pivote

func _crear_brazo(x: float, uniforme: Material, piel: Material, derecho: bool) -> Node3D:
	var pivote := Node3D.new()
	pivote.position = Vector3(x, 1.42, 0)
	body_model.add_child(pivote)
	_guard_box_en(pivote, Vector3(0.14, 0.4, 0.15), Vector3(0, -0.18, 0), uniforme)
	var codo := Node3D.new()
	codo.position = Vector3(0, -0.36, 0)
	pivote.add_child(codo)
	_guard_box_en(codo, Vector3(0.11, 0.32, 0.12), Vector3(0, -0.14, 0), uniforme)
	_guard_box_en(codo, Vector3(0.105, 0.12, 0.12), Vector3(0, -0.34, -0.015), piel)
	if derecho:
		codo_derecho = codo
		mano_derecha = Node3D.new()
		mano_derecha.position = Vector3(0, -0.25, -0.04)
		codo.add_child(mano_derecha)
	else:
		codo_izquierdo = codo
	return pivote


func _animar_guardia(delta: float, velocidad: float, corriendo: bool) -> void:
	_anim_t += delta
	var actividad_objetivo := clampf(velocidad / maxf(player.velocidad_caminar, 0.1), 0.0, 1.5)
	_intensidad_movimiento = move_toward(_intensidad_movimiento, actividad_objetivo, 5.0 * delta)
	if _intensidad_movimiento > 0.025:
		var ritmo := 8.0 if corriendo else 6.1
		_fase_pasos = fposmod(_fase_pasos + delta * ritmo * (0.7 + _intensidad_movimiento * 0.3), TAU)
	var amplitud := (0.38 if not corriendo else 0.58) * minf(_intensidad_movimiento, 1.2)
	var paso := sin(_fase_pasos) * amplitud
	pierna_izquierda.rotation.x = paso
	pierna_derecha.rotation.x = -paso
	brazo_izquierdo.rotation.x = -paso * 0.72
	if flashlight_model.visible:
		brazo_derecho.rotation.x = lerpf(brazo_derecho.rotation.x, 0.3 + paso * 0.12, 10.0 * delta)
	else:
		brazo_derecho.rotation.x = -paso * 0.72
	if is_instance_valid(brazo_izquierdo_vista):
		brazo_izquierdo_vista.rotation.x = brazo_izquierdo.rotation.x
		brazo_derecho_vista.rotation.x = brazo_derecho.rotation.x
	codo_izquierdo.rotation.x = 0.12 + absf(paso) * 0.25
	codo_derecho.rotation.x = 0.12 + absf(paso) * 0.25
	var inclinacion := -0.035 * _intensidad_movimiento - (0.045 if corriendo else 0.0)
	torso_model.rotation.x = lerpf(torso_model.rotation.x, inclinacion, 7.0 * delta)
	var inclinacion_lateral := -Input.get_axis("move_left", "move_right") * 0.04
	var balanceo := sin(_fase_pasos) * 0.025 * _intensidad_movimiento
	torso_model.rotation.z = lerpf(torso_model.rotation.z, inclinacion_lateral + balanceo, 8.0 * delta)
	body_model.position.y = absf(sin(_fase_pasos)) * 0.045 * _intensidad_movimiento + sin(_anim_t * 2.0) * 0.008
	cabeza_model.rotation.x = clampf(-look_pitch * 0.12, -0.08, 0.08)
	cabeza_model.rotation.y = sin(_anim_t * 0.65) * 0.035 * (1.0 - minf(_intensidad_movimiento, 1.0))

func _connect_estado() -> void:
	estado.mensaje.connect(hud.show_message)
	estado.radio.connect(_on_radio)
	estado.nota.connect(note_viewer.abrir)
	estado.pedir_codigo.connect(code_lock.abrir)
	estado.sonido.connect(Sfx.tocar.bind(0.0))
	estado.despertar.connect(func(grupo: String): _despertar(grupo, "", ""))
	estado.inventario_cambio.connect(_on_inventario)
	estado.recargar_bateria.connect(func(p: float): battery = minf(100.0, battery + p))
	hud.set_objetivo_texto(estado.objetivo_actual())

## Zonas de activacion e interactivos que estan puestos en la escena (visibles en el Scene Tree).
func _connect_escena() -> void:
	var n_zonas := 0
	for nodo in get_tree().get_nodes_in_group("zonas"):
		var zona := nodo as ZonaActivacion
		zona.zona_activada.connect(_on_zona_activada)
		n_zonas += 1
	var n_obj := 0
	for nodo in get_tree().get_nodes_in_group("interactivos"):
		var obj := nodo as ObjetoInteractivo
		obj.interactuado.connect(_on_objeto_interactuado)
		n_obj += 1
	var n_enem := 0
	for nodo in get_tree().get_nodes_in_group("enemigos"):
		var e := nodo as EstatuaEnemiga
		e.atrapo_al_jugador.connect(_on_enemigo_atrapo)
		e.se_acerca.connect(_on_enemigo_se_acerca)
		e.congelada.connect(_on_enemigo_congelada)
		e.sonido_paso.connect(_on_enemigo_paso)
		n_enem += 1
	print("[JUEGO] Escena lista: jugador '%s', %d zonas de activacion, %d interruptores, %d estatuas." % [player.name, n_zonas, n_obj, n_enem])

# EVENTO: el jugador entro a una zona de activacion -> Roberto habla por radio (una sola vez)
func _on_zona_activada(id_zona: String, mensaje: String) -> void:
	if mensaje != "":
		estado.radio_una_vez("zona_" + id_zona, mensaje)
	# Las estatuas de un cuarto despiertan unos segundos despues de que el jugador entra a su zona
	match id_zona:
		"vestibulo":
			get_tree().create_timer(14.0).timeout.connect(_despertar.bind("wake_vestibulo", "bustos_despiertan", "ROBERTO (radio): «Alex... en las cámaras del vestíbulo... los bustos. Se movieron. Dime que estoy viendo mal. [estática] No los pierdas de vista.»"))
		"sala":
			get_tree().create_timer(14.0).timeout.connect(_despertar.bind("wake_sala", "estatuas_despiertan", "ROBERTO (radio): «Alex, la sala... las estatuas de la sala se están moviendo en las cámaras. [estática] Ve con cuidado, no les des la espalda.»"))
		"galeria":
			estado.poner_flag("piso2_visitado")
			control.activar_camaras_piso2()
			hud.show_message("Nivel 2: Galería Medieval.")
			get_tree().create_timer(10.0).timeout.connect(_despertar.bind("wake_galeria", "armaduras_despiertan", "ROBERTO (radio): «¡Alex, las armaduras se mueven! Se oyen hasta por el walkie. Usa el reflector de cada una... y no corras de espaldas.»"))
		"armeria":
			get_tree().create_timer(8.0).timeout.connect(_despertar.bind("wake_armeria", "armeria_despierta", "ROBERTO (radio): «Dos armaduras en esos pasillos, Alex. Elige una ruta y fija a la de esa ruta con su reflector.»"))

# EVENTO: el jugador uso un interruptor de la escena -> prender / apagar las luces de ESA sala
func _on_objeto_interactuado(nombre: String, encendido: bool, id_luces: String) -> void:
	if id_luces == "danado":
		hud.show_message("%s: está dañado, solo chispea." % nombre)
		return
	var salas := {"vestibulo": lobby, "control": control, "oficina_dra": curator, "restauracion": restoration}
	if not salas.has(id_luces):
		return
	var sala: RoomBase = salas[id_luces]
	sala.set_luces(encendido)
	if encendido:
		_turnos_luz[id_luces] = int(_turnos_luz.get(id_luces, 0)) + 1
		_establecer_proteccion_luz(sala, true)
		_iniciar_apagado_luces(id_luces, sala, int(_turnos_luz[id_luces]))
		hud.show_message("%s: luces encendidas. Las criaturas quedan inmóviles por unos segundos." % nombre)
	else:
		_turnos_luz[id_luces] = int(_turnos_luz.get(id_luces, 0)) + 1
		_establecer_proteccion_luz(sala, false)
		hud.show_message("%s: luces apagadas." % nombre)
		estado.radio_una_vez("luces_off", "ROBERTO (radio): «¿Se fue la luz otra vez? Es el generador nuevo, Alex... no te asustes. Prende el interruptor.»")


func _establecer_proteccion_luz(sala: RoomBase, activa: bool) -> void:
	for nodo in get_tree().get_nodes_in_group("enemigos"):
		var enemigo := nodo as EstatuaEnemiga
		if enemigo and sala.is_ancestor_of(enemigo) and not enemigo.fijada:
			enemigo.protegida_por_luz = activa


func _iniciar_apagado_luces(id_luces: String, sala: RoomBase, turno: int) -> void:
	await get_tree().create_timer(DURACION_LUZ_SEGURA).timeout
	if not is_instance_valid(sala) or int(_turnos_luz.get(id_luces, -1)) != turno or not sala.luces_encendidas:
		return
	sala.set_luces(false)
	_establecer_proteccion_luz(sala, false)
	_turnos_luz[id_luces] = turno + 1
	var interruptores := {"vestibulo": "InterruptorVestibulo", "control": "InterruptorControl", "oficina_dra": "InterruptorOficinaDra", "restauracion": "InterruptorRestauracion"}
	var nodo_interruptor := get_node_or_null("Interactivos/" + String(interruptores.get(id_luces, ""))) as ObjetoInteractivo
	if nodo_interruptor:
		nodo_interruptor.forzar(false)
	hud.show_message("Las luces se apagaron. Las criaturas pueden volver a moverse.")

## Roberto habla por el walkie: se abre el canal (squelch), sale el subtitulo y se cierra con un pitido.
func _on_radio(texto: String) -> void:
	Sfx.tocar("radio_in")
	var dur := clampf(float(texto.length()) * 0.055, 4.0, 9.0)
	hud.show_radio(texto, dur)
	get_tree().create_timer(dur).timeout.connect(func(): Sfx.tocar("radio_out", -4.0))

func _on_inventario(item: String) -> void:
	hud.set_objetivo_texto(estado.objetivo_actual())
	match item:
		"linterna":
			if not flashlight_model.visible:
				flashlight_on = true
				flashlight.visible = true
				flashlight_model.visible = true
				_sync_linterna_vista()
		"walkie":
			walkie_model.visible = true
			_actualizar_walkie_vista()
		"fragmento":
			get_tree().create_timer(6.0).timeout.connect(func():
				estado.radio_una_vez("reliquia_acelera", "ROBERTO (radio): «Alex... las estatuas se aceleraron en cuanto tomaste eso. [estática fuerte] Corre... pero sin darles la espalda.»"))

func _apply_settings() -> void:
	camera.fov = Settings.fov
	hall.environment.adjustment_brightness = Settings.brightness
	hall.environment.glow_enabled = Settings.quality >= 1
	flashlight.shadow_enabled = Settings.quality >= 1

func _on_settings_changed(_key: String) -> void:
	_apply_settings()

func _physics_process(delta: float) -> void:
	if not is_instance_valid(player) or not mouse_captured or game_over_activo:
		return
	estado.avanzar_reloj(delta)
	_t_senuelo = maxf(0.0, _t_senuelo - delta)
	if not estado.tiene("espejo"):
		_espejo_solicitado = false
		player.espejo_levantado = false

	# Movimiento relativo a hacia donde mira el guardia (W = hacia adelante)
	var input_vec := Input.get_vector("move_left", "move_right", "move_forward", "move_back")
	var running := Input.is_physical_key_pressed(KEY_SHIFT) and stamina > 5.0 and input_vec != Vector2.ZERO
	if running:
		stamina = maxf(0.0, stamina - 22.0 * delta)
	else:
		stamina = minf(100.0, stamina + 12.0 * delta)
	var speed := player.velocidad_correr if running else player.velocidad_caminar
	if player.espejo_levantado:
		speed *= 0.65   # con el espejo en alto caminas mas lento
	var direction := player.global_transform.basis * Vector3(input_vec.x, 0, input_vec.y)
	var aceleracion := 20.0 if input_vec != Vector2.ZERO else 26.0
	player.velocity.x = move_toward(player.velocity.x, direction.x * speed, aceleracion * delta)
	player.velocity.z = move_toward(player.velocity.z, direction.z * speed, aceleracion * delta)
	player.velocity.y = -0.5
	player.move_and_slide()
	var velocidad_plana := Vector2(player.velocity.x, player.velocity.z).length()
	var sprint_activo := running and velocidad_plana > 0.2 and not player.espejo_levantado
	_animar_guardia(delta, velocidad_plana, sprint_activo)
	if velocidad_plana > 0.5:
		_t_pisada -= delta
		if _t_pisada <= 0.0:
			Sfx.tocar("paso_jugador", -13.0 if sprint_activo else -17.0)
			_t_pisada = 0.39 if sprint_activo else 0.52
	else:
		_t_pisada = 0.08

	# Linterna: apunta con la misma inclinacion que la vista y gasta bateria
	flashlight.rotation.x = look_pitch
	if flashlight_on:
		battery = maxf(0.0, battery - 1.5 * delta * (0.6 if estado.flag("bateria_ampliada") else 1.0))
		if battery <= 0.0:
			flashlight_on = false
			flashlight.visible = false
			hud.show_message("La linterna se quedó sin batería")

	# Mundo: puerta automatica, camaras de seguridad y objeto al que tiene enfrente el guardia
	office.actualizar(delta, player.global_position)
	cctv.set_jugador(player.global_position)
	_update_camera(delta)
	_update_espejo()
	_actualizar_walkie_vista()
	# Las búsquedas incluyen varias pruebas de línea de visión. 12 Hz mantiene la
	# respuesta inmediata al apuntar sin repetir el barrido completo cada física.
	_acc_interaccion += delta
	if _acc_interaccion >= 0.083:
		_acc_interaccion = 0.0
		_actualizar_objetivo()

	hud.set_bateria(battery)
	hud.set_energia(stamina)
	_tick_hud(delta)
	_tension(delta)

func _tick_hud(delta: float) -> void:
	hud.set_reloj(estado.hora_texto())
	_acc_hud += delta
	if _acc_hud > 0.5:
		_acc_hud = 0.0
		hud.set_objetivo_texto(estado.objetivo_actual())
	_acc_cuenta += delta
	if _acc_cuenta > 1.0:
		_acc_cuenta = 0.0
		lobby.set_cuenta_regresiva(estado.faltan_texto())

func _update_camera(delta: float) -> void:
	var pivot := player.global_position + Vector3(0, CAM_PIVOT_HEIGHT, 0)
	if primera_persona:
		# Pequeño balanceo al caminar, con la misma dirección que el cuerpo y la linterna.
		pivot.y += sin(_fase_pasos) * 0.018 * _intensidad_movimiento
		var hacia_delante := player.global_transform.basis * Vector3(0, sin(look_pitch), -cos(look_pitch))
		camera.global_position = pivot + player.global_transform.basis * Vector3(0, 0, -0.04)
		camera.look_at(camera.global_position + hacia_delante)
		body_model.visible = false
		_actualizar_brazos_vista(delta)
		return
	# Camara detras y arriba del guardia. Si una pared la obstruye, se acerca y luego se aleja suave.
	var elevation := -look_pitch
	var back := player.global_transform.basis * Vector3(0, sin(elevation), cos(elevation))
	var query := PhysicsRayQueryParameters3D.create(pivot, pivot + back * CAM_DISTANCE)
	query.exclude = [player.get_rid()]
	query.collision_mask = 1
	var hit := get_world_3d().direct_space_state.intersect_ray(query)
	var dist := CAM_DISTANCE
	if not hit.is_empty():
		dist = maxf(pivot.distance_to(hit.position) - 0.25, 0.3)
	if dist < cam_dist_now:
		cam_dist_now = dist
	else:
		cam_dist_now = minf(dist, cam_dist_now + 6.0 * delta)
	camera.global_position = pivot + back * cam_dist_now
	camera.look_at(pivot)
	# Si la camara queda pegada al guardia, se oculta su modelo para no tapar la vista.
	body_model.visible = cam_dist_now > 0.9
	brazo_izquierdo_vista.visible = false
	brazo_derecho_vista.visible = false
	espejo_modelo_vista.visible = false


func _alternar_vista() -> void:
	primera_persona = not primera_persona
	cam_dist_now = 0.0 if primera_persona else 0.75
	flashlight.position = Vector3(0.0, CAM_PIVOT_HEIGHT - 0.06, -0.12) if primera_persona else linterna_pos_tercera
	if is_instance_valid(pause_view_button):
		pause_view_button.text = "USAR TERCERA PERSONA" if primera_persona else "USAR PRIMERA PERSONA"
	_update_camera(1.0 / 60.0)
	if mouse_captured:
		hud.show_message("Vista de primera persona." if primera_persona else "Vista de tercera persona.")

func _actualizar_brazos_vista(delta: float) -> void:
	var pasos := sin(_fase_pasos) * 0.018 * _intensidad_movimiento
	var temblor := sin(_anim_t * 27.0) * _peligro_actual * 0.012
	var deriva := Vector3(_sway_mouse.x, -_sway_mouse.y, 0.0)
	brazo_izquierdo_vista.position = Vector3(-0.48, -0.56 + pasos + temblor, -0.62) + deriva
	brazo_derecho_vista.position = Vector3(0.48, -0.56 - pasos + temblor, -0.62) - deriva
	brazo_izquierdo_vista.rotation = Vector3(brazo_izquierdo.rotation.x + temblor, 0.0, deg_to_rad(3.0) + _sway_mouse.x * 0.12)
	brazo_derecho_vista.rotation = Vector3(brazo_derecho.rotation.x - temblor, 0.0, deg_to_rad(-3.0) - _sway_mouse.x * 0.12)
	_sway_mouse = _sway_mouse.lerp(Vector2.ZERO, minf(1.0, delta * 8.0))
	_acc_brazos_occlusion += delta
	if _acc_brazos_occlusion >= 0.075:
		_acc_brazos_occlusion = 0.0
		_brazo_izq_tapado = _vista_bloqueada(brazo_izquierdo_vista)
		_brazo_der_tapado = _vista_bloqueada(brazo_derecho_vista)
	brazo_izquierdo_vista.visible = not _brazo_izq_tapado
	brazo_derecho_vista.visible = not _brazo_der_tapado
	espejo_modelo_vista.visible = player.espejo_levantado and not _brazo_izq_tapado

func _vista_bloqueada(modelo: Node3D) -> bool:
	var espacio := get_world_3d().direct_space_state
	var origen := camera.global_position
	var puntos := [
		modelo.to_global(Vector3(0.0, 0.0, 0.0)),
		modelo.to_global(Vector3(0.0, 0.18, 0.0)),
		modelo.to_global(Vector3(0.0, 0.32, 0.0)),
		modelo.to_global(Vector3(0.0, 0.60, 0.0)),
	]
	for punto in puntos:
		var query := PhysicsRayQueryParameters3D.create(origen, punto)
		query.exclude = [player.get_rid()]
		query.collision_mask = 1
		var hit := espacio.intersect_ray(query)
		if not hit.is_empty() and origen.distance_to(hit.position) < origen.distance_to(punto) - 0.025:
			return true
	return false

func _actualizar_walkie_vista() -> void:
	if not is_instance_valid(walkie_vista):
		return
	walkie_vista.visible = primera_persona and estado.tiene("walkie") and look_pitch < deg_to_rad(-20.0)

# ---------------------------------------------------------------- objetivo de interaccion

## Elige UN objetivo (el que tienes enfrente y mas cerca; lo que se agarra gana a notas y puertas, y
## estas a los interruptores) y muestra en pantalla exactamente lo que hara E.
func _actualizar_objetivo() -> void:
	var direccion_mira := -camera.global_transform.basis.z
	target = registry.buscar(player.global_position, camera.global_position, direccion_mira, player.get_rid(), get_world_3d())
	registry.resaltar(target)
	if target.is_empty():
		hud.set_prompt("")
	else:
		hud.set_prompt("[E]  " + String(target["texto"]))

# ---------------------------------------------------------------- espejo de inspeccion sostenido (V)

func _build_espejo() -> void:
	# Vista de atrás: resolución reducida y actualización suspendida mientras el espejo está abajo.
	espejo_vp = SubViewport.new()
	espejo_vp.size = Vector2i(192, 256)
	espejo_vp.render_target_update_mode = SubViewport.UPDATE_DISABLED
	espejo_vp.msaa_3d = Viewport.MSAA_DISABLED
	espejo_vp.screen_space_aa = Viewport.SCREEN_SPACE_AA_DISABLED
	add_child(espejo_vp)
	espejo_cam = Camera3D.new()
	espejo_cam.fov = 76.0
	espejo_cam.cull_mask = 1
	espejo_vp.add_child(espejo_cam)
	espejo_cam.current = true
	player.camara_espejo = espejo_cam

func _update_espejo() -> void:
	var bloqueado := primera_persona and is_instance_valid(brazo_izquierdo_vista) and not brazo_izquierdo_vista.visible
	var arriba := estado.tiene("espejo") and _espejo_solicitado and not bloqueado
	player.espejo_levantado = arriba
	hud.set_espejo(arriba and not primera_persona, espejo_vp.get_texture())
	if is_instance_valid(material_niebla_espejo):
		material_niebla_espejo.set_shader_parameter("nivel", clampf((_peligro_actual - 0.18) * 1.45, 0.0, 0.72) if arriba else 0.0)
	espejo_vp.render_target_update_mode = SubViewport.UPDATE_ALWAYS if arriba and not bloqueado else SubViewport.UPDATE_DISABLED
	if arriba:
		var base_espejo := camera.global_transform.basis * Basis(Vector3.UP, PI)
		var pos := espejo_modelo_vista.global_position if primera_persona else player.global_position + Vector3(0, CAM_PIVOT_HEIGHT, 0)
		pos += base_espejo.z * 0.04
		espejo_cam.global_transform = Transform3D(base_espejo, pos)

# ---------------------------------------------------------------- estatuas: dificultad

## Despierta a las estatuas de un grupo ("wake_vestibulo", "wake_galeria"...). Las que ya fueron fijadas
## por un reflector no se despiertan nunca.
func _despertar(grupo: String, id_radio: String, texto: String) -> void:
	for nodo in get_tree().get_nodes_in_group(grupo):
		var e := nodo as EstatuaEnemiga
		if e.velocidad > 0.0 and not e.fijada:
			e.activa = true
	print("[ENEMIGOS] Despiertan: %s" % grupo)
	if id_radio != "":
		estado.radio_una_vez(id_radio, texto)

## Tension: borde rojo, latido, arrastre de piedra y estatica del walkie segun lo cerca que esta una estatua.
func _tension(delta: float) -> void:
	var peligro := 0.0
	var acelerar := 1.0 + 0.15 * minf(float(estado.fragmentos_total()), 3.0)   # +15% por fragmento
	for nodo in get_tree().get_nodes_in_group("enemigos"):
		var e := nodo as EstatuaEnemiga
		e.multiplicador = acelerar
		if not e.activa:
			continue
		var d := e.global_position.distance_to(player.global_position)
		if not e.observada and d < 10.0:
			peligro = maxf(peligro, 1.0 - d / 10.0)
	hud.set_peligro(peligro)
	_peligro_actual = peligro
	_t_latido -= delta
	_t_static -= delta
	if peligro > 0.12 and _t_latido <= 0.0:
		Sfx.tocar("latido", lerpf(-16.0, -2.0, peligro))
		_t_latido = lerpf(1.1, 0.45, peligro)
	if estado.tiene("walkie") and peligro > 0.2 and _t_static <= 0.0:
		Sfx.tocar("static", lerpf(-26.0, -10.0, peligro))
		_t_static = 1.6

## Pasos de las estatuas: arrastre de piedra, o golpes de metal si es una armadura (se oyen de lejos).
func _on_enemigo_paso(e: Node3D) -> void:
	var d := e.global_position.distance_to(player.global_position)
	var alcance := 22.0 if bool(e.get("ruidosa")) else 14.0
	if d > alcance:
		return
	var vol := lerpf(-4.0, -26.0, clampf(d / alcance, 0.0, 1.0))
	Sfx.tocar("clank" if bool(e.get("ruidosa")) else "arrastre", vol)

func _on_enemigo_congelada(_e: Node3D, motivo: String) -> void:
	if motivo == "linterna":
		estado.radio_una_vez("luz_congela", "ROBERTO (radio): «¡Eso! La luz los detiene. Y el espejo también, si no puedes mirarlos de frente. Mantenlos alumbrados.»")

## Un busto se acerca en el vestibulo: las luces se apagan "solas" y hay que volver a prenderlas.
func _on_enemigo_se_acerca(e: Node3D) -> void:
	var p := e.global_position
	if p.x > -9.0 and p.x < 9.0 and p.z > 16.25 and p.z < 30.25 and lobby.luces_encendidas:
		lobby.set_luces(false)
		_turnos_luz["vestibulo"] = int(_turnos_luz.get("vestibulo", 0)) + 1
		_establecer_proteccion_luz(lobby, false)
		($Interactivos/InterruptorVestibulo as ObjetoInteractivo).forzar(false)
		hud.show_message("¡Las luces del vestíbulo se apagaron! Busca el interruptor.")
		Sfx.tocar("beep_no")
		estado.radio_una_vez("luces_enemigo", "ROBERTO (radio): «¡Se apagaron las luces del vestíbulo! ¡Prende el interruptor, Alex, rápido! [estática]»")

func _on_enemigo_atrapo(e: Node3D) -> void:
	if game_over_activo:
		return
	game_over_activo = true
	Sfx.tocar("golpe")
	hud.set_peligro(1.0)
	hud.set_prompt("")
	registry.resaltar({})
	game_over_ui.mostrar("Un %s te alcanzó mientras no lo mirabas." % String(e.get("tipo")).to_lower())

## Walkie-talkie como senuelo: lo dejas sonando unos pasos al frente y las armaduras van hacia el pitido
## en vez de ir por ti (sirve para alejarlas de una puerta). Enfriamiento de 25 s.
func _lanzar_senuelo() -> void:
	if not estado.tiene("walkie"):
		return
	if _t_senuelo > 0.0:
		hud.show_message("El walkie aún se está recuperando (%d s)." % int(ceil(_t_senuelo)))
		return
	_t_senuelo = 25.0
	var pos := player.global_position + (-player.global_transform.basis.z) * 3.5
	var marcador := MeshInstance3D.new()
	var caja := BoxMesh.new()
	caja.size = Vector3(0.07, 0.17, 0.035)
	marcador.mesh = caja
	var mat := StandardMaterial3D.new()
	mat.albedo_color = Color(0.1, 0.1, 0.12)
	mat.emission_enabled = true
	mat.emission = Color(1.0, 0.2, 0.1)
	mat.emission_energy_multiplier = 2.0
	marcador.material_override = mat
	marcador.position = pos + Vector3(0, 0.09, 0)
	add_child(marcador)
	var n := 0
	for nodo in get_tree().get_nodes_in_group("enemigos"):
		var e := nodo as EstatuaEnemiga
		# Solo las armaduras del mismo cuarto (y piso) que el pitido lo oyen y pueden ir hacia el
		if e.tipo == "ARMADURA" and not e.fijada and e.region.has_point(Vector2(pos.x, pos.z)) and absf(e.global_position.y - player.global_position.y) < 3.5:
			e.atraer(pos, 8.0)
			n += 1
	hud.show_message("Señuelo: dejaste el walkie sonando. %d armadura(s) van hacia el pitido." % n)
	for k in 10:
		get_tree().create_timer(k * 0.8).timeout.connect(func(): Sfx.tocar("pitido", -6.0))
	get_tree().create_timer(8.0).timeout.connect(marcador.queue_free)

func _interact() -> void:
	_update_camera(0.0)
	_actualizar_objetivo()
	registry.interactuar(target)

func _toggle_flashlight() -> void:
	if not estado.tiene("linterna"):
		return
	if battery <= 0.0:
		hud.show_message("Sin batería")
		return
	flashlight_on = not flashlight_on
	flashlight.visible = flashlight_on
	_sync_linterna_vista()

func _alternar_espejo() -> void:
	if not estado.tiene("espejo"):
		hud.show_message("Aún no tienes el espejo de inspección.")
		return
	_espejo_solicitado = not _espejo_solicitado
	hud.show_message("Espejo levantado. Revisa detrás de ti." if _espejo_solicitado else "Espejo guardado.")

func _unhandled_input(event: InputEvent) -> void:
	if event is InputEventKey and event.pressed and not event.echo:
		match event.keycode:
			KEY_ESCAPE:
				_toggle_pause()
			KEY_E:
				if mouse_captured:
					_interact()
			KEY_F:
				if mouse_captured:
					_toggle_flashlight()
			KEY_R:
				if mouse_captured:
					_lanzar_senuelo()
			KEY_C:
				if mouse_captured:
					_alternar_vista()
			KEY_V:
				if mouse_captured:
					_alternar_espejo()
	elif event is InputEventMouseButton and event.pressed and mouse_captured:
		if event.button_index == MOUSE_BUTTON_LEFT:
			_interact()
		elif event.button_index == MOUSE_BUTTON_RIGHT:
			_toggle_flashlight()
	elif event is InputEventMouseMotion and mouse_captured:
		var sens := Settings.sensitivity
		_sway_mouse.x = clampf(_sway_mouse.x + event.relative.x * sens * 0.00022, -0.065, 0.065)
		_sway_mouse.y = clampf(_sway_mouse.y + event.relative.y * sens * 0.00018, -0.045, 0.045)
		player.rotate_y(deg_to_rad(-event.relative.x * sens))
		look_pitch = clampf(look_pitch - deg_to_rad(event.relative.y * sens), deg_to_rad(PITCH_MIN), deg_to_rad(PITCH_MAX))

func _build_ui() -> void:
	pause_layer = CanvasLayer.new()
	pause_layer.name = "PauseUI"
	pause_layer.process_mode = Node.PROCESS_MODE_ALWAYS
	pause_layer.layer = 10
	add_child(pause_layer)
	pause_backdrop = ColorRect.new()
	pause_backdrop.name = "PauseBackdrop"
	pause_backdrop.set_anchors_preset(Control.PRESET_FULL_RECT)
	pause_backdrop.color = Color(0.008, 0.012, 0.018, 0.78)
	pause_backdrop.mouse_filter = Control.MOUSE_FILTER_STOP
	pause_backdrop.visible = false
	pause_layer.add_child(pause_backdrop)

	pause_panel = _make_panel("PAUSA", [
		["CONTINUAR", Callable(self, "_resume")],
		["USAR PRIMERA PERSONA", Callable(self, "_alternar_vista")],
		["OPCIONES", Callable(self, "_show_options")],
		["CONTROLES", Callable(self, "_show_controls")],
		["MENU PRINCIPAL", Callable(self, "_back_to_menu")]
	])
	pause_panel.visible = false
	pause_layer.add_child(pause_panel)

	options_panel = _make_options_panel()
	options_panel.visible = false
	pause_layer.add_child(options_panel)

	controls_panel = _make_controls_panel()
	controls_panel.visible = false
	pause_layer.add_child(controls_panel)

func _make_panel(title: String, buttons: Array) -> Panel:
	var panel := Panel.new()
	var es_pausa := title == "PAUSA"
	var panel_size := _tamano_panel(title)
	panel.set_meta("tamano_panel", panel_size)
	panel.anchor_left = 0.5
	panel.anchor_right = 0.5
	panel.anchor_top = 0.5
	panel.anchor_bottom = 0.5
	panel.offset_left = -panel_size.x / 2.0
	panel.offset_right = panel_size.x / 2.0
	panel.offset_top = -panel_size.y / 2.0
	panel.offset_bottom = panel_size.y / 2.0
	var style := StyleBoxFlat.new()
	style.bg_color = Color(0.018, 0.026, 0.033, 0.98)
	style.border_color = Color(0.55, 0.39, 0.16, 0.85)
	style.set_border_width_all(1)
	style.border_width_left = 4
	style.set_corner_radius_all(10)
	style.set_content_margin_all(0)
	panel.add_theme_stylebox_override("panel", style)
	panel.mouse_filter = Control.MOUSE_FILTER_STOP

	var title_label := Label.new()
	title_label.text = title
	title_label.position = Vector2(34, 24)
	title_label.size = Vector2(panel_size.x - 68, 44)
	title_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	title_label.add_theme_font_size_override("font_size", 32 if es_pausa else 28)
	title_label.add_theme_color_override("font_color", Color(0.91, 0.77, 0.48))
	panel.add_child(title_label)

	var y := 90.0
	if es_pausa:
		var subtitulo := Label.new()
		subtitulo.text = "TURNO DE NOCHE  ·  EL MUSEO"
		subtitulo.position = Vector2(30, 65)
		subtitulo.size = Vector2(panel_size.x - 60, 20)
		subtitulo.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		subtitulo.add_theme_font_size_override("font_size", 12)
		subtitulo.add_theme_color_override("font_color", Color(0.57, 0.62, 0.62))
		panel.add_child(subtitulo)
		var divisor := ColorRect.new()
		divisor.color = Color(0.55, 0.39, 0.16, 0.68)
		divisor.position = Vector2(panel_size.x / 2.0 - 38.0, 96)
		divisor.size = Vector2(76, 1)
		panel.add_child(divisor)
		y = 116.0

	var alto_boton := 50.0 if es_pausa else 52.0
	var paso_boton := 64.0 if es_pausa else 66.0
	for entry in buttons:
		var button := Button.new()
		button.text = entry[0]
		button.position = Vector2(36, y)
		button.size = Vector2(panel_size.x - 72, alto_boton)
		button.add_theme_font_size_override("font_size", 16)
		button.add_theme_color_override("font_color", Color(0.87, 0.87, 0.83))
		button.add_theme_color_override("font_hover_color", Color(0.98, 0.89, 0.68))
		button.add_theme_color_override("font_pressed_color", Color(1.0, 0.95, 0.82))
		button.add_theme_stylebox_override("normal", _pause_button_style(false, false))
		button.add_theme_stylebox_override("hover", _pause_button_style(false, true))
		button.add_theme_stylebox_override("pressed", _pause_button_style(true, false))
		button.add_theme_stylebox_override("focus", _pause_button_style(false, true))
		if es_pausa and entry[0] == "CONTINUAR":
			pause_continue_button = button
			button.add_theme_color_override("font_color", Color(0.08, 0.07, 0.04))
			button.add_theme_color_override("font_hover_color", Color(0.08, 0.07, 0.04))
			button.add_theme_stylebox_override("normal", _pause_button_style(true, false))
			button.add_theme_stylebox_override("hover", _pause_button_style(true, true))
			button.add_theme_stylebox_override("pressed", _pause_button_style(true, true))
		elif es_pausa and entry[0] == "USAR PRIMERA PERSONA":
			pause_view_button = button
		button.pressed.connect(entry[1])
		panel.add_child(button)
		y += paso_boton

	if es_pausa:
		var pie := Label.new()
		pie.text = "ESC  ·  VOLVER AL JUEGO"
		pie.position = Vector2(30, panel_size.y - 36)
		pie.size = Vector2(panel_size.x - 60, 20)
		pie.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		pie.add_theme_font_size_override("font_size", 12)
		pie.add_theme_color_override("font_color", Color(0.48, 0.54, 0.55))
		panel.add_child(pie)
	return panel

func _tamano_panel(titulo: String) -> Vector2:
	var base := Vector2(480, 500)
	if titulo == "OPCIONES":
		base = Vector2(620, 600)
	elif titulo == "CONTROLES":
		base = Vector2(420, 540)
	var visible := get_viewport().get_visible_rect().size
	var limite := Vector2(maxf(1.0, visible.x - 40.0), maxf(1.0, visible.y - 40.0))
	return Vector2(minf(base.x, limite.x), minf(base.y, limite.y))

func _pause_button_style(primario: bool, iluminado: bool) -> StyleBoxFlat:
	var estilo := StyleBoxFlat.new()
	if primario:
		estilo.bg_color = Color(0.83, 0.65, 0.30) if not iluminado else Color(0.96, 0.78, 0.40)
		estilo.border_color = Color(1.0, 0.86, 0.55, 0.9)
	else:
		estilo.bg_color = Color(0.055, 0.074, 0.08, 0.94) if not iluminado else Color(0.10, 0.13, 0.13, 0.98)
		estilo.border_color = Color(0.34, 0.30, 0.22, 0.8) if not iluminado else Color(0.76, 0.59, 0.30, 0.95)
	estilo.set_border_width_all(1)
	estilo.set_corner_radius_all(6)
	estilo.content_margin_left = 16
	estilo.content_margin_right = 16
	return estilo

func _make_options_panel() -> Panel:
	# Mismo panel de opciones que el menu principal (se guarda y se aplica al instante)
	var panel := _make_panel("OPCIONES", [])
	var panel_size: Vector2 = panel.get_meta("tamano_panel")
	var scroll := ScrollContainer.new()
	scroll.position = Vector2(30, 82)
	scroll.size = Vector2(panel_size.x - 60, panel_size.y - 160)
	scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	scroll.vertical_scroll_mode = ScrollContainer.SCROLL_MODE_AUTO
	panel.add_child(scroll)
	var options := OptionsPanel.new()
	options.custom_minimum_size = Vector2(panel_size.x - 78, 0)
	options.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	scroll.add_child(options)
	var back := Button.new()
	back.text = "VOLVER"
	back.position = Vector2(30, panel_size.y - 64)
	back.size = Vector2(panel_size.x - 60, 44)
	back.pressed.connect(_hide_subpanels)
	panel.add_child(back)
	return panel

func _make_controls_panel() -> Panel:
	var panel := _make_panel("CONTROLES", [])
	var panel_size: Vector2 = panel.get_meta("tamano_panel")
	var info := Label.new()
	info.text = "W A S D   Moverse\nShift     Correr\nMouse     Cámara\nC         Cambiar vista\nV         Subir / bajar espejo\nE / Clic  Usar, recoger, leer\nF / Clic der.  Linterna\nR         Walkie como señuelo\nESC       Pausa\nF11       Pantalla completa\n\nLas estatuas solo se mueven\ncuando NO las miras."
	info.position = Vector2(30, 95)
	info.add_theme_font_size_override("font_size", 18)
	panel.add_child(info)
	var back := Button.new()
	back.text = "VOLVER"
	back.position = Vector2(30, panel_size.y - 68)
	back.size = Vector2(panel_size.x - 60, 44)
	back.pressed.connect(_hide_subpanels)
	panel.add_child(back)
	return panel

func _toggle_pause() -> void:
	if options_panel.visible or controls_panel.visible:
		_hide_subpanels()
		return
	if pause_panel.visible:
		_resume()
	else:
		pause_panel.visible = true
		pause_backdrop.visible = true
		mouse_captured = false
		Input.mouse_mode = Input.MOUSE_MODE_VISIBLE
		get_tree().paused = true
		pause_continue_button.call_deferred("grab_focus")

func _resume() -> void:
	_hide_subpanels()
	pause_panel.visible = false
	pause_backdrop.visible = false
	mouse_captured = true
	Input.mouse_mode = Input.MOUSE_MODE_CAPTURED
	get_tree().paused = false

func _show_options() -> void:
	pause_panel.visible = false
	options_panel.visible = true

func _show_controls() -> void:
	pause_panel.visible = false
	controls_panel.visible = true

func _hide_subpanels() -> void:
	options_panel.visible = false
	controls_panel.visible = false
	pause_panel.visible = true

func _back_to_menu() -> void:
	Sfx.zumbido(false)
	pause_backdrop.visible = false
	get_tree().paused = false
	Input.mouse_mode = Input.MOUSE_MODE_VISIBLE
	get_tree().change_scene_to_file("res://scenes/main_menu.tscn")
