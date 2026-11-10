# Rúbrica: mini prototipo interactivo — todo dentro del videojuego

No hay nada aparte: los elementos de la rúbrica son parte del juego y están en la escena principal
`scenes/museum.tscn` (se ven en el Scene Tree del editor).

## 1. Proyecto funcional
Godot 4.7 (renderer Compatibility). Menú principal → carga → `scenes/museum.tscn`.

## 2. Escena: jugador, objeto interactivo y zona de activación
Scene Tree de `museum.tscn`:

```
Museum
├─ Estado · RegistroInteractivos · CCTV
├─ Mundo
│  ├─ SalaEgipcia · Vestibulo · SalaDeControl · OficinaDraTorres · SalaDeRestauracion
│  └─ EscaleraDeServicio · GaleriaMedieval · Armeria · OficinaSeguridad
├─ Guardia                      ← JUGADOR (CharacterBody3D, grupo "jugador")
├─ Zonas                        ← ZONAS DE ACTIVACION (Area3D + CollisionShape3D)
│  ├─ ZonaVestibulo · ZonaSalaEgipcia · ZonaOficinaDra · ZonaRestauracion
│  └─ ZonaGaleria · ZonaArmeria
├─ Interactivos                 ← OBJETOS INTERACTIVOS (Area3D): interruptores de luz
│  ├─ InterruptorVestibulo · InterruptorControl · InterruptorOficinaDra
│  └─ InterruptorRestauracion · InterruptorGaleria (dañado)
└─ HUD · VisorDeNotas · Candado
```

| Elemento | Escena / script |
|---|---|
| Jugador | `scenes/player/guardia.tscn` + `scripts/player/guardia.gd` (velocidades en el Inspector) |
| Zona de activación | `scenes/zonas/zona_activacion.tscn` + `scripts/game/zona_activacion.gd` |
| Objeto interactivo | `scenes/interactivos/objeto_interactivo.tscn` + `scripts/game/objeto_interactivo.gd` |

## 3. Programación
| Requisito | Dónde está |
|---|---|
| **Variable** | `veces_activada`, `jugador_dentro` (zona); `encendido`, `jugador_cerca` (interruptor); `luces_encendidas` (cada sala); batería, energía, inventario |
| **Evento** | señales `body_entered` / `body_exited` de los `Area3D`; señales propias `zona_activada` e `interactuado`; `museum.gd` las recibe en `_on_zona_activada` y `_on_objeto_interactuado` |
| **Condición if** | `if body.is_in_group("jugador")` (zona e interruptor) · distancia, dirección de cámara y línea de visión en `interactables.gd` · `if encendido:` en `_on_objeto_interactuado` · `if observada:` en `estatua_enemiga.gd` |
| **Acción** | entrar a una zona → Roberto habla por radio; presionar E en un interruptor → `set_luces()` prende/apaga las luces de esa sala (`room_base.gd`) y cambia el LED |

## 4. Evidencias (qué capturar)
| Captura | Cómo sacarla |
|---|---|
| **1. Escena completa** | Ejecutar el juego (F5), caminar al vestíbulo y capturar la ventana (se ve el interruptor, el HUD y las luces) |
| **2. Jerarquía / Scene Tree** | Abrir `scenes/museum.tscn` y capturar el panel *Escena* con los nodos `Guardia`, `Zonas` e `Interactivos` desplegados |
| **3. Inspector** | Seleccionar `Interactivos/InterruptorVestibulo` (Nombre Objeto, Id Luces, Texto Aviso, colores) o `Zonas/ZonaVestibulo` (Id Zona, Mensaje Radio, Una Sola Vez, Tamano) |
| **4. Script** | Abrir `scripts/game/objeto_interactivo.gd` o `scripts/game/zona_activacion.gd` (comentarios EVENTO / CONDICION / ACCION) |
| **5. Consola / Output** | Ejecutar el juego, salir de la oficina (activa la zona) y usar el interruptor junto a la puerta de Seguridad. Salen `[ZONA] ...`, `[DETECCION] ...` y `[INTERACCION] ...` |

## 5. Explicación (respuestas modelo)
- **¿Qué evento utilizaste?** La señal `body_entered` del `Area3D` (un cuerpo entra al área) y las señales propias `zona_activada` e `interactuado`, que avisan al script principal del juego (`museum.gd`).
- **¿Qué objeto detecta al jugador?** Los nodos `Area3D`: las zonas de activación y el área de cada interruptor. El jugador es el `CharacterBody3D` `Guardia`, del grupo `jugador`.
- **¿Qué condición utilizaste?** `if body.is_in_group("jugador")` (solo cuenta el jugador, no las paredes); para interactuar, el registro valida distancia, dirección de la cámara y que no haya obstáculos. Además, las estatuas usan `if observada:` para quedarse quietas.
- **¿Qué acción se ejecuta?** Al entrar a una zona: se cuenta la activación, se imprime en consola y Roberto habla por radio. Al presionar E en un interruptor: cambia la variable `encendido`, cambia el LED y se prenden o apagan las luces de esa sala.
- **¿Qué componente permite realizar la interacción?** El `Area3D` con su `CollisionShape3D` (detecta al jugador), el registro de interactivos (`interactables.gd`, elige UN objetivo y muestra su texto), la acción de entrada `interactuar` (tecla E, en *Proyecto → Configuración → Mapa de entradas*) y las señales de Godot.
