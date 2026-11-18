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
y Armería (laberinto de pasillos de 2.5 m; reja con código 1348 grabado en el escudo del fundador).
Armaduras ruidosas y rápidas, reflectores de exhibición, interruptor dañado. La cámara norte de la Armería guarda
la tarjeta roja que abre el piso 3; al colocar el fragmento 2 en el pedestal se amplía la batería de la linterna.
**Nivel 3 "Huesos en la oscuridad" (piso 3):** Pabellón de Paleontología, laboratorio de la doctora y Bóveda de Contención.
Un fósil depredador se mueve cuando no lo miras; la secuencia de placas óseas abre la bóveda, donde está el fragmento 3.
Una escalera protegida baja desde el pabellón hasta el sótano.

**Nivel 4 "La cripta" (sótano):** escalera de tres tramos, catacumba con sarcófagos y antorchas, registro sobre el sello y tres momias que despiertan al entrar. El fragmento 4 está al fondo; al tomarlo, el jugador vuelve a la Sala Egipcia para completar el pedestal.

**Final "El guardián":** al colocar las cuatro piezas, la salida se cierra, el gran Anubis despierta y los fragmentos se dispersan por la sala. Anubis persigue al guardia cuando no lo mira y lanza tres varillas con aviso previo. Hay que esquivarlas, reunir las cuatro piezas y cerrar de nuevo el sello.

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
- scripts/museum.gd: conecta la escena, cámaras, espejo, señuelo, tensión, pausa y final.
- scripts/environment/: museum_builder (Sala Egipcia), office_builder, room_*.gd (vestíbulo, control, curadora,
  restauración, escalera, galería, armería, paleontología y cripta sobre room_base.gd), cctv_system,
  build_utils, estatua_modelos.
- scripts/enemies/: estatua_enemiga (regla de observación y captura), anubis_boss (varillas y cierre final).
- scripts/game/: game_state, interactables, zona_activacion, objeto_interactivo, reflector.
- scripts/ui/, scripts/audio/sfx.gd (sonidos generados por código; sin voces), legacy/ (archivos viejos).
- docs/RUBRICA.md: cómo cumple la rúbrica del mini prototipo.

## Pendiente
Uso extendido del walkie, modelos y audio reales, personajes y balance final.
