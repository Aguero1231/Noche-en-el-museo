extends CharacterBody3D

## ALEX, EL GUARDIA (jugador). Esta en el grupo "jugador", que es lo que detectan las zonas
## de activacion y los objetos interactivos.
## El movimiento y la camara los maneja museum.gd; aqui viven los datos que se ajustan
## en el Inspector (velocidades) para poder cambiarlos sin tocar codigo.

@export var velocidad_caminar := 3.0
@export var velocidad_correr := 5.5

## Estado que leen las estatuas para saber si el jugador las "esta observando".
var espejo_levantado := false          # se alterna con V
var camara_espejo: Camera3D            # camara de la vista de atras (la pone museum.gd)
