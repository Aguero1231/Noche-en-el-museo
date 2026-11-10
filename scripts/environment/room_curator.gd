extends "res://scripts/environment/room_base.gd"

## OFICINA DE LA DRA. ELENA TORRES (curadora principal, desaparecida).
## Aqui estan sus notas, su credencial, la grabadora y la TARJETA DORADA que abre Restauracion.
## La puerta (en el vestibulo) tiene candado: 1310 (13 de octubre).

const X0 := -16.5
const X1 := -9.5
const Z0 := 16.75
const Z1 := 23.0
const H := 3.6


func build() -> void:
	var piedra := u.stone(Color(1.0, 0.88, 0.74), 0.35)
	var top := H + 0.4

	u.box(self, Vector3(-13.0, -0.25, 19.9), Vector3(7.5, 0.5, 6.7), u.marble(Color(0.95, 0.85, 0.75), 0.2), true, Vector3.ZERO, "Piso")
	u.box(self, Vector3(-13.0, H + 0.2, 19.9), Vector3(7.5, 0.4, 6.7), u.stone(Color(0.3, 0.27, 0.27), 0.3), true, Vector3.ZERO, "Techo")
	wall_x(16.5, -17.0, -9.5, 0.5, top, piedra)
	wall_x(23.25, -17.0, -9.5, 0.5, top, piedra)
	wall_z(-16.75, 16.25, 23.5, 0.5, top, piedra)
	for z in [18.5, 21.5]:
		u.box(self, Vector3(-13.0, H - 0.1, z), Vector3(7.0, 0.2, 0.3), u.wood())

	zocalo_x(Z0, 1.0, X0, X1)
	zocalo_x(Z1, -1.0, X0, X1)
	zocalo_z(X0, 1.0, Z0, Z1)
	zocalo_z(X1, -1.0, Z0, Z1, [{"a": 19.7, "b": 21.3}])
	banda(Vector3(-13.0, 3.05, Z0 + 0.012), 0.0, 7.0, 0.28)
	banda(Vector3(X0 + 0.012, 3.05, 19.9), 90.0, 6.25, 0.28)

	# Luz calida del despacho
	var l := u.omni(self, Vector3(-13.0, 3.1, 19.9), Color(1.0, 0.72, 0.42), 1.0, 7.5)
	parpadear(l, 6.0, true)

	_escritorio_principal()
	_pizarra()
	_estantes_y_extras()
	_escritorio_lateral()


func _escritorio_principal() -> void:
	# Escritorio junto a la pared oeste (su frente mira hacia +x: hacia la puerta)
	var d := escritorio(Vector3(-15.1, 0, 20.0), 90.0, 2.4, 1.0, 0.76)
	silla(Vector3(-13.9, 0, 20.0), 90.0, Color(0.25, 0.1, 0.08))
	lampara_escritorio(self, Vector3(-15.4, 0.76, 18.95), 0.7)
	var oro := u.gold()

	# Credencial (portagafete) de la Dra. Torres, con su foto
	var cred := u.node3d(self, "Credencial", Vector3(-14.8, 0.775, 19.6), 80.0)
	u.box(cred, Vector3.ZERO, Vector3(0.1, 0.005, 0.14), u.mat(Color(0.9, 0.9, 0.85), 0.5))
	u.box(cred, Vector3(0, 0.004, -0.02), Vector3(0.06, 0.004, 0.06), u.mat(Color(0.45, 0.5, 0.6), 0.6))
	u.cyl(cred, Vector3(0, 0.008, -0.075), 0.012, 0.012, 0.01, oro, Vector3(90, 0, 0))
	var c_txt := "[center][b]MUSEO DE HISTORIA Y ANTIGÜEDADES METROPOLITANAS[/b][/center]\n\n"
	c_txt += "[b]Nombre:[/b] Dra. Elena Torres\n"
	c_txt += "[b]Cargo:[/b] Curadora Principal\n"
	c_txt += "[b]Edad:[/b] 44 años\n"
	c_txt += "[b]Acceso:[/b] Nivel 3 (todas las salas)\n\n"
	c_txt += "[i]Detrás de la credencial, con lápiz: «Si la reliquia despierta, no la mires directo. Usa un espejo.»[/i]"
	nota(cred, "Examinar credencial", "Credencial de la Dra. Torres", c_txt, "credencial", "", cred)

	# Diario #1
	var diario := hoja_papel(self, Vector3(-14.7, 0.775, 20.7), -15.0, Vector2(0.22, 0.3))
	var t := "[b]DIARIO DE LA DRA. ELENA TORRES - 1[/b]\n\n"
	t += "Tres años de trabajo y por fin lo tengo: el [b]amuleto de sellado[/b], partido en cuatro fragmentos que los antiguos repartieron en cuatro lugares distintos. Uno por cada sección del museo.\n\n"
	t += "Nadie me cree. Dicen que la «Lágrima de Osiris» es solo una joya ceremonial. Yo he leído las inscripciones: la reliquia [b]despierta[/b] cuando se reúne con luz artificial nocturna, y lo que despierta no es la joya, es lo que la rodea.\n\n"
	t += "Esta noche llega a Restauración. Mañana pensaba escribirlo todo con calma. Si alguien lee esto antes... reúnan los cuatro fragmentos.\n\n"
	t += "[i]Los dejé a salvo. Las llaves de la doctora no se pierden: la tarjeta dorada está en la mesa lateral.[/i]"
	nota(diario, "Leer diario", "Diario de la Dra. Torres (1)", t, "papel", "", diario)

	# Grabadora de voz
	var grab := u.box(self, Vector3(-15.0, 0.79, 19.0), Vector3(0.14, 0.04, 0.08), u.mat(Color(0.15, 0.15, 0.17), 0.4, 0.5))
	u.cyl(self, Vector3(-15.0, 0.81, 18.97), 0.012, 0.012, 0.012, u.mat(Color(0.3, 0, 0), 0.5, 0.0, Color(1, 0.1, 0.1), 2.0))
	var g := "REGISTRO DE VOZ - DRA. E. TORRES\nVIE 13/10/2026  22:41\n"
	g += "----------------------------------------\n"
	g += "«...pruebas de grabación. El paquete llegó antes de lo previsto, y con luz de noche. No debí abrir la caja en el vestíbulo, pero la luz de los pasillos ya la había tocado.\n\n"
	g += "...siento un zumbido en los dientes. Las estatuas de la Sala Egipcia están... distintas. Las miré hace diez minutos y estaban de frente. Ahora están de perfil.\n\n"
	g += "Si alguien escucha esto: mientras las miren no se mueven. Una luz fuerte o un espejo también las detiene. Reúnan los fragmentos. Colóquenlos en el pedestal de la sala principal.\n\n"
	g += "Roberto, si me oyes por el walkie... perdón por lo del candado. Es la fecha de hoy.»\n"
	g += "[ fin de la grabación ]"
	nota(grab, "Escuchar grabadora", "GRABADORA", g, "terminal", "", grab, Callable(self, "_grabadora"))


func _grabadora() -> void:
	Sfx.tocar("static")
	estado.radio_una_vez("grabadora", "ROBERTO (radio): «...¿Alex? Escucho estática. ¿Es la grabadora de la doctora? Qué voz tan rara, ¿no?»")


func _pizarra() -> void:
	# Pizarra blanca en la pared norte con las reglas que descubrio la doctora
	var p := u.node3d(self, "Pizarra", Vector3(-12.2, 1.9, Z0 + 0.03))
	u.box(p, Vector3.ZERO, Vector3(2.4, 1.3, 0.04), u.mat(Color(0.14, 0.12, 0.1), 0.5))
	var hoja := u.mat(Color(0.7, 0.7, 0.66), 0.7)
	u.box(p, Vector3(0, 0, 0.025), Vector3(2.3, 1.2, 0.01), hoja)
	# Notitas y flechas
	var rojo := u.mat(Color(0.7, 0.1, 0.1), 0.6)
	var azul := u.mat(Color(0.1, 0.2, 0.6), 0.6)
	u.box(p, Vector3(-0.7, 0.25, 0.035), Vector3(0.7, 0.02, 0.003), azul)
	u.box(p, Vector3(-0.8, 0.0, 0.035), Vector3(0.5, 0.02, 0.003), azul)
	u.box(p, Vector3(0.5, 0.3, 0.035), Vector3(0.9, 0.02, 0.003), rojo)
	u.box(p, Vector3(0.6, -0.15, 0.035), Vector3(0.6, 0.02, 0.003), rojo)
	u.cyl(p, Vector3(0.7, 0.45, 0.04), 0.1, 0.1, 0.003, rojo, Vector3(90, 0, 0), 24)
	var t := "[b]PIZARRA DE LA DRA. TORRES[/b]\n\n"
	t += "[b]REGLAS DE LAS ESTATUAS[/b]\n"
	t += "1. Solo se mueven cuando NADIE las observa.\n"
	t += "2. Un espejo o una luz intensa las paraliza igual que la vista.\n"
	t += "3. Pueden apagar las luces cercanas.\n"
	t += "4. Los reflectores de exhibición fijados sobre ellas las inmovilizan para siempre.\n\n"
	t += "[b]FRAGMENTOS DEL AMULETO (4)[/b]\n"
	t += "· 1 → Restauración (Planta baja)\n"
	t += "· 2 y 3 → Galería Medieval / Armería (Piso 2)\n"
	t += "· 4 → Bóveda (Piso 3)\n\n"
	t += "[b]PEDESTAL DE SELLADO[/b]: Sala Egipcia, frente al gran Anubis.\n"
	t += "[i]Hora límite: antes de las 06:00, cuando se desbloquean las puertas.[/i]"
	var obj := u.node3d(self, "Pizarra_Objetivo", Vector3(-12.2, 1.4, Z0 + 0.6))
	nota(obj, "Leer pizarra", "Pizarra", t, "papel")


func _estantes_y_extras() -> void:
	librero(Vector3(-15.3, 0, Z0 + 0.25), 0.0, 2.2, 2.3)
	librero(Vector3(-10.25, 0, Z0 + 0.25), 0.0, 1.4, 2.3)
	librero(Vector3(-14.0, 0, Z1 - 0.25), 180.0, 2.4, 2.0)
	# Alfombra del museo bajo el escritorio
	var alf := MeshInstance3D.new()
	var plano := PlaneMesh.new()
	plano.size = Vector2(2.2, 4.4)
	alf.mesh = plano
	alf.material_override = u.carpet(1.0)
	alf.position = Vector3(-13.4, 0.012, 20.0)
	add_child(alf)
	# Globo terraqueo
	var g := u.node3d(self, "Globo", Vector3(-12.2, 0, 22.3))
	u.cyl(g, Vector3(0, 0.45, 0), 0.03, 0.18, 0.9, u.wood())
	u.sphere(g, Vector3(0, 1.1, 0), 0.25, u.mat(Color(0.15, 0.3, 0.45), 0.5))
	examinar(g, "Examinar globo", "Un globo terráqueo antiguo. Egipto está marcado con una chincheta roja.", g, Vector3(0, 1.0, 0))
	# Percha con la bata de la doctora
	var pe := u.node3d(self, "Percha", Vector3(-16.1, 0, 22.4))
	u.cyl(pe, Vector3(0, 0.9, 0), 0.025, 0.025, 1.8, u.wood())
	u.box(pe, Vector3(0, 1.3, 0.08), Vector3(0.45, 0.8, 0.08), u.mat(Color(0.85, 0.85, 0.8), 0.95))
	examinar(pe, "Examinar bata", "La bata de la Dra. Torres. En el bolsillo hay un pañuelo y un boleto de «Nilo Express».", pe, Vector3(0, 1.2, 0))


func _escritorio_lateral() -> void:
	# Escritorio lateral con la tarjeta dorada (la de la escena 2 del storyboard)
	var d := escritorio(Vector3(-10.5, 0, 22.65), 180.0, 1.4, 0.6, 0.75)
	lampara_escritorio(self, Vector3(-9.95, 0.75, 22.75), 0.5)
	var tarjeta := u.node3d(self, "TarjetaDorada", Vector3(-10.7, 0.765, 22.55), 15.0)
	var oro_t := u.mat(Color(0.9, 0.7, 0.2), 0.3, 0.8, Color(0.8, 0.55, 0.1), 0.6)
	u.box(tarjeta, Vector3.ZERO, Vector3(0.14, 0.006, 0.09), oro_t)
	u.box(tarjeta, Vector3(0.03, 0.005, 0), Vector3(0.04, 0.002, 0.04), u.mat(Color(0.2, 0.15, 0.05), 0.4))
	pickup(tarjeta, "Tomar tarjeta dorada", "tarjeta_dorada", "Alex: «Bien, la tarjeta dorada...»  (abre Restauración)", 1, Callable(self, "_tomo_tarjeta"))


func _tomo_tarjeta() -> void:
	estado.radio_una_vez("tarjeta", "ROBERTO (radio): «Esa tarjeta abre Restauración. Pero, Alex... mejor ni entres, ¿eh? Es zona de la doctora.»")
