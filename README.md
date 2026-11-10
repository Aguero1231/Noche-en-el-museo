# TURNO DE NOCHE: EL MUSEO

Juego 3D de suspenso con cámara en primera o tercera persona, hecho en Godot 4.7 (renderer Compatibility).
*"Lo que no miras, se mueve."*

## Historia
Viernes 13 de octubre de 2026, 00:00 a 06:00. Alex, guardia novato, hace su primera noche en el Museo de
Historia y Antigüedades Metropolitanas. Una reliquia (la "Lágrima de Osiris") despierta a medianoche y las
estatuas se mueven cuando nadie las mira. Una falla de energía sella las salidas hasta las 06:00.
Hay que reunir 4 fragmentos del amuleto de sellado y colocarlos en el Pedestal de Sellado.

## Niveles jugables
**Nivel 1 "El Despertar" (planta baja):** oficina de seguridad, Vestíbulo, Sala de Control (cámaras en vivo),
oficina de la Dra. Torres (candado 1310), Sala de Restauración (fragmento 1) y Sala Egipcia (Pedestal de Sellado).
Recompensa: tarjeta azul, que abre la escalera de servicio.

**Nivel 2 "Pasillos de Acero" (piso 2):** escalera en U (9 m) -> Galería Medieval (tumba de Sir Edric, fragmento 2)
y Armería (laberinto de pasillos de 2.5 m, fragmento 3; reja con código 1348 grabado en el escudo del fundador).
Armaduras ruidosas y rápidas, reflectores de exhibición, interruptor dañado.
Recompensa (con 3 fragmentos en el pedestal): tarjeta roja y batería de linterna ampliada.
Piso 3 (Paleontología y Bóveda): todavía no construido (la puerta roja del piso 2 lo anuncia).

## Controles
- WASD moverse (hacia donde mira el guardia) · Shift correr (energía STA) · Mouse girar/cámara
- E o clic izquierdo: usar, recoger, leer, abrir. En pantalla siempre dice qué hará E; lo que se agarra tiene
  prioridad sobre los interruptores, y cuenta mucho hacia dónde miras.
- F o clic derecho: linterna (batería BAT; las pilas AA la recargan)
- V: subir o bajar el espejo de inspección (caminas más lento mientras lo sostienes)
- C: cambiar entre primera y tercera persona
- R: dejar el walkie sonando como señuelo (atrae armaduras del mismo cuarto 8 s; enfriamiento 25 s)
- Esc pausa (con opciones) · F11 pantalla completa

## Las estatuas (scripts/enemies/estatua_enemiga.gd)
Bustos, estatua egipcia, momia, estatua cubierta y armaduras solo avanzan cuando NADIE las observa.
Se congelan si están delante del guardia y en pantalla, si las alumbra la linterna, si salen en el espejo
(V) o si un reflector las fija para siempre. Las que están detrás del guardia se mueven aunque las veas.
Si te alcanzan: pantalla TE ATRAPARON.
- Navegación A* calculada de la geometría real (rodean muebles, columnas y paredes).
- Despiertan segundos después de entrar a su zona (Area3D). Cada fragmento acelera a todas un 15%.
- Los bustos apagan las luces del vestíbulo al acercarse (hay que volver a prender el interruptor).
- Tensión: borde rojo, latido, arrastre de piedra / golpes de metal y estática del walkie.
- Modelos esculpidos por código en scripts/environment/estatua_modelos.gd (rostro, sábana, caballero).

## Reflectores (Nivel 2)
Cada reflector (scripts/game/reflector.gd) se gira con su panel entre N, E, S y O. Si el haz toca a una
armadura, la inmoviliza para siempre. Solo un rumbo funciona; las pistas están en los diarios de la doctora.

## Opciones (menú y pausa; se guardan en user://settings.cfg)
Pantalla completa, VSync, volumen, sensibilidad, FOV, brillo, calidad gráfica y FPS.
Dentro del editor con "Embed Game" la pantalla completa no funciona (limitación de Godot).

## Estructura
- scenes/museum.tscn: escena principal; todo el juego como nodos (Mundo, Guardia, Zonas, Interactivos, HUD...).
- scripts/museum.gd: conecta la escena, cámara en tercera persona, espejo, señuelo, tensión, pausa.
- scripts/environment/: museum_builder (Sala Egipcia), office_builder, room_*.gd (vestíbulo, control, curadora,
  restauración, escalera, galería, armería sobre room_base.gd), cctv_system, build_utils, estatua_modelos.
- scripts/game/: game_state, interactables, zona_activacion, objeto_interactivo, reflector.
- scripts/ui/, scripts/audio/sfx.gd (sonidos generados por código; sin voces), legacy/ (archivos viejos).
- docs/RUBRICA.md: cómo cumple la rúbrica del mini prototipo.

## Pendiente
Piso 3, uso extendido del walkie, modelos y audio reales, personajes.
