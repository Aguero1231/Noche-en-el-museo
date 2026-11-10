extends "res://scripts/environment/room_base.gd"

## ESCALERA DE SERVICIO: sube de la planta baja al PISO 2 (9 m) en dos tramos en "U".
## La puerta del vestibulo se abre con la tarjeta azul (recompensa del nivel 1).
##   Tramo A (carril oeste): sube hacia el sur de y=0 a y=4.5
##   Descanso:                 y=4.5
##   Tramo B (carril este):  sube hacia el norte de y=4.5 a y=9.0 y sale a la Galeria Medieval.
## Cada tramo tiene una colision inclinada bajo los escalones para que el personaje pueda subirlos.

const PISO2 := 9.0
const SUBIDA := 4.5
const ANCHO_CARRIL := 1.5
const CANT_PELDANOS := 30
const X_A := -7.15         # primer tramo, alineado con la puerta inferior
const X_B := -5.025        # segundo tramo, alineado con la salida al piso 2
const Z_INI := 31.5
const Z_FIN := 38.25
const TOPE := 14.8         # altura total de la torre (techo)


func build() -> void:
	var piedra := u.stone(Color(0.72, 0.72, 0.8), 0.3)
	var peldano := u.stone(Color(0.5, 0.5, 0.56), 0.5)
	var bronce := u.metal(Color(0.34, 0.25, 0.12))

	u.box(self, Vector3(-6.0, -0.25, 35.5), Vector3(5.0, 0.5, 10.0), u.marble(Color(0.55, 0.57, 0.66), 0.2), true, Vector3.ZERO, "Piso")
	u.box(self, Vector3(-6.0, TOPE - 0.2, 35.5), Vector3(5.0, 0.4, 10.0), u.stone(Color(0.2, 0.21, 0.26), 0.3), true, Vector3.ZERO, "Techo")
	wall_z(-8.25, 30.5, 40.5, 0.5, TOPE, piedra)
	wall_z(-3.75, 30.5, 40.5, 0.5, TOPE, piedra)
	wall_x(40.25, -8.5, -3.5, 0.5, TOPE, piedra)
	# El vestibulo y la galeria ya construyen esta pared con sus respectivas puertas.
	# No agregar aqui una franja flotante: tapaba visualmente el acceso entre ambos pisos.
	# Molduras sencillas a la altura del pasamanos para dar continuidad a los muros.
	u.box(self, Vector3(-7.99, 1.18, 35.5), Vector3(0.035, 0.07, 9.0), bronce)
	u.box(self, Vector3(-4.01, 1.18, 35.5), Vector3(0.035, 0.07, 9.0), bronce)

	_tramo(X_A, Z_INI, Z_FIN, 0.0, SUBIDA, peldano, bronce)
	_tramo(X_B, Z_FIN, Z_INI, SUBIDA, 2.0 * SUBIDA, peldano, bronce)
	# Descanso de giro ancho y profundo: une ambos tramos con una zona plana amplia.
	u.box(self, Vector3(-6.0, SUBIDA - 0.1, 39.125), Vector3(4.0, 0.2, 1.75), peldano, true, Vector3.ZERO, "Descanso")
	# El descanso se prolonga dentro de la galeria y se solapa con su suelo para
	# eliminar cualquier junta/hueco en la salida de la escalera.
	u.box(self, Vector3(X_B, PISO2 - 0.2, 30.4), Vector3(1.75, 0.4, 2.2), peldano, true, Vector3.ZERO, "DescansoSuperior")
	_barandales_descanso_superior()

	# Rotulos y luces
	u.text3d(self, "PLANTA BAJA", Vector3(-7.95, 2.6, 32.4), 90.0, 40, Color(0.9, 0.9, 0.85), 0.005)
	u.text3d(self, "PISO 2\nGALERÍA MEDIEVAL", Vector3(-4.05, 11.0, 32.6), -90.0, 40, Color(0.95, 0.75, 0.3), 0.005)
	var l1 := u.omni(self, Vector3(-6.0, 3.3, 33.0), Color(0.85, 0.92, 1.0), 1.1, 7.5)
	parpadear(l1, 7.0, true)
	u.omni(self, Vector3(-6.0, 7.2, 35.0), Color(0.85, 0.92, 1.0), 0.9, 7.0)
	u.omni(self, Vector3(-5.0, 10.4, 32.3), Color(1.0, 0.72, 0.4), 0.9, 5.0)
	# Aplique de pared en el giro: luz cálida útil, sin la figura luminosa que estorbaba.
	var vidrio_lampara := u.mat(Color(1.0, 0.74, 0.42), 0.35, 0.0, Color(1.0, 0.55, 0.22), 1.2)
	u.box(self, Vector3(-7.965, 6.65, 39.1), Vector3(0.07, 0.38, 0.34), bronce)
	u.box(self, Vector3(-7.89, 6.65, 39.1), Vector3(0.14, 0.30, 0.22), vidrio_lampara)
	u.omni(self, Vector3(-7.72, 6.65, 39.1), Color(1.0, 0.72, 0.42), 1.65, 7.0)


## Un tramo de escalera: rampa con colision + escalones visibles. x = centro del carril.
func _tramo(x: float, z0: float, z1: float, y0: float, y1: float, peldano: Material, bronce: Material) -> void:
	var dz := z1 - z0
	var dy := y1 - y0
	var sgn := signf(dz)
	var largo := sqrt(dz * dz + dy * dy)
	var ang := atan2(dy, absf(dz))
	var cuerpo := StaticBody3D.new()
	cuerpo.name = "ColisionRampa"
	var cs := CollisionShape3D.new()
	var bs := BoxShape3D.new()
	bs.size = Vector3(ANCHO_CARRIL, 0.2, largo)
	cs.shape = bs
	cuerpo.add_child(cs)
	# La cara superior de la rampa acompaña el centro de las huellas y queda bajo los escalones.
	var media_subida_peldano := dy / (2.0 * CANT_PELDANOS)
	cuerpo.position = Vector3(x, (y0 + y1) / 2.0 - 0.1 * cos(ang) + media_subida_peldano, (z0 + z1) / 2.0 + 0.1 * sin(ang) * sgn)
	cuerpo.rotation.x = -ang * sgn
	add_child(cuerpo)
	for i in CANT_PELDANOS:
		var t := (float(i) + 0.5) / CANT_PELDANOS
		var alto := dy / CANT_PELDANOS
		var top := y0 + dy * float(i + 1) / CANT_PELDANOS
		var z_pelda := lerpf(z0, z1, t)
		var huella := absf(dz) / CANT_PELDANOS
		u.box(self, Vector3(x, top - alto / 2.0, z_pelda), Vector3(ANCHO_CARRIL, alto, huella), peldano)
		# Perfil de bronce en la nariz de cada huella: ordena visualmente los peldaños.
		var borde_z := z_pelda + signf(dz) * (huella / 2.0 - 0.012)
		u.box(self, Vector3(x, top - 0.018, borde_z), Vector3(ANCHO_CARRIL, 0.036, 0.024), bronce)
	_barandales_tramo(x, z0, z1, y0, y1, ang)


## Protege ambos lados del último descanso y continúa la baranda hasta la galería.
func _barandales_descanso_superior() -> void:
	var metal := u.metal(Color(0.22, 0.22, 0.25))
	var z0 := 30.5
	var z1 := Z_INI
	var separacion := ANCHO_CARRIL / 2.0 - 0.07
	for lado in [-1.0, 1.0]:
		var x_baranda: float = X_B + float(lado) * separacion
		for i in range(5):
			var z_baranda := lerpf(z0, z1, float(i) / 4.0)
			u.box(self, Vector3(x_baranda, PISO2 + 0.52, z_baranda), Vector3(0.055, 0.84, 0.055), metal, true)
		u.box(self, Vector3(x_baranda, PISO2 + 0.94, (z0 + z1) / 2.0), Vector3(0.08, 0.08, z1 - z0), metal, true)


func _barandales_tramo(x: float, z0: float, z1: float, y0: float, y1: float, ang: float) -> void:
	var dz := z1 - z0
	var sgn := signf(dz)
	var largo := sqrt(dz * dz + (y1 - y0) * (y1 - y0))
	var metal := u.metal(Color(0.22, 0.22, 0.25))
	for lado in [-1.0, 1.0]:
		# `lado` proviene de un Array literal (Variant); declarar el resultado evita
		# que GDScript no pueda inferir el tipo durante la compilación.
		var x_baranda: float = x + float(lado) * (ANCHO_CARRIL / 2.0 - 0.07)
		for i in range(9):
			var t := float(i) / 8.0
			var y_pelda := lerpf(y0, y1, t)
			var z_pelda := lerpf(z0, z1, t)
			u.box(self, Vector3(x_baranda, y_pelda + 0.52, z_pelda), Vector3(0.055, 0.84, 0.055), metal, true)
		u.box(self, Vector3(x_baranda, (y0 + y1) / 2.0 + 0.94, (z0 + z1) / 2.0), Vector3(0.08, 0.08, largo), metal, true, Vector3(rad_to_deg(-ang * sgn), 0, 0))
