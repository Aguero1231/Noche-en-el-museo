# TURNO DE NOCHE: EL MUSEO

[![CI](https://github.com/OWNER/REPO/actions/workflows/ci.yml/badge.svg)](https://github.com/OWNER/REPO/actions/workflows/ci.yml)
[![Demo web](https://img.shields.io/badge/demo-GitHub%20Pages-blue)](https://OWNER.github.io/REPO/)

Juego 3D de suspenso en tercera persona hecho en **Godot 4.7** (renderer Compatibility).
*"Lo que no miras, se mueve."*

> Proyecto de la carrera de Desarrollo de Software, Universidad Tecnológica de Nogales (grupo IDGS 10-1), materia Gestión del Proceso de Desarrollo de Software, docente Martin Cuadras.
> Sustituye `OWNER/REPO` en los enlaces de arriba por tu usuario y repositorio.

## Estado del proyecto

| Versión | Contenido |
|---|---|
| `0.1.0` | Nivel 1 y Nivel 2 jugables. Piso 3 pendiente. Ver [CHANGELOG](CHANGELOG.md) |

## Requisitos

| Herramienta | Versión |
|---|---|
| [Godot Engine](https://godotengine.org/download) | 4.7 |
| Git | 2.40 o superior |
| Python (opcional, para `gdtoolkit`) | 3.9 o superior |
| Hardware mínimo | 4 núcleos, 8 GB de RAM, GPU con OpenGL 3.3 |

## Cómo ejecutar el juego

```bash
git clone https://github.com/OWNER/REPO.git
cd REPO
bash scripts/dev/setup-repo.sh      # activa hooks y plantilla de commits
```

1. Abre Godot 4.7 > **Importar** > selecciona `project.godot`.
2. Espera a que termine la importación de recursos (la primera vez tarda un momento).
3. Presiona **F5**. Escena principal: `scenes/main_menu.tscn`.

O descarga un build ya compilado en la pestaña **Releases**, o prueba la **demo web** en GitHub Pages.

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
- Q (sostener): espejo de inspección, ves lo que hay detrás (caminas más lento)
- R: dejar el walkie sonando como señuelo (atrae armaduras del mismo cuarto 8 s; enfriamiento 25 s)
- Esc pausa (con opciones) · F11 pantalla completa

## Las estatuas (scripts/enemies/estatua_enemiga.gd)
Bustos, estatua egipcia, momia, estatua cubierta y armaduras solo avanzan cuando NADIE las observa.
Se congelan si están delante del guardia y en pantalla, si las alumbra la linterna, si salen en el espejo
(Q) o si un reflector las fija para siempre. Las que están detrás del guardia se mueven aunque las veas.
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


## Estructura del repositorio

```
.
├── .github/              CI/CD (workflows), plantillas de issues y pull requests
├── .githooks/            Hooks de Git (pre-commit y commit-msg)
├── assets/               Texturas, menú, pantalla de carga
├── docs/                 Documentación de la Fase 1 (ver índice abajo)
├── scenes/               Escenas .tscn (museo, menú, jugador, zonas, interactivos)
├── scripts/
│   ├── audio/            Sonidos generados por código
│   ├── dev/              Scripts de apoyo (setup-repo.sh)
│   ├── enemies/          IA de las estatuas
│   ├── environment/      Construcción de salas y modelos por código
│   ├── game/             Estado, interactivos, zonas, reflectores
│   ├── player/           Guardia (jugador)
│   └── ui/               HUD, candado, notas, opciones, Game Over
├── tests/                Pruebas automáticas (unit/ y smoke/)
├── legacy/               Código antiguo sin uso (pendiente de eliminar)
├── CHANGELOG.md
├── CONTRIBUTING.md
├── export_presets.cfg    Presets de exportación (Windows, Linux, Web)
└── project.godot
```

Todo el juego vive como nodos en `scenes/museum.tscn`; `scripts/museum.gd` conecta la escena, la cámara en tercera
persona, el espejo, el señuelo, la tensión y la pausa. `docs/RUBRICA.md` explica cómo cumple la rúbrica del mini prototipo.

## Pruebas

```bash
godot --headless --path . --import                                  # primera vez
godot --headless --path . --script res://tests/smoke/load_all.gd    # humo: carga de escenas
godot --headless --path . --script res://tests/run_tests.gd         # unitarias
pip install "gdtoolkit==4.*" && gdparse $(find scripts tests -name "*.gd")   # sintaxis
```

Los casos manuales (49 en total) están en [`docs/PLAN-DE-PRUEBAS.md`](docs/PLAN-DE-PRUEBAS.md).

## Flujo de trabajo (resumen)

| Rama | Uso |
|---|---|
| `main` | Versión estable; cada commit lleva tag `vX.Y.Z` |
| `develop` | Integración |
| `feature/*`, `fix/*`, `docs/*` | Trabajo diario; PR hacia `develop` |
| `release/*`, `hotfix/*` | Preparación de versiones y correcciones urgentes |

Commits con formato `tipo(alcance): resumen` (Conventional Commits). Detalle en [`docs/FLUJO-GIT.md`](docs/FLUJO-GIT.md)
y [`CONTRIBUTING.md`](CONTRIBUTING.md).

## Despliegue

| Disparador | Resultado |
|---|---|
| Pull Request / push a `develop` | CI: lint, pruebas y builds de verificación |
| Push a `main` | Demo Web en GitHub Pages |
| Tag `vX.Y.Z` | GitHub Release con `.zip` de Windows, Linux y Web |

Detalle en [`docs/DESPLIEGUE.md`](docs/DESPLIEGUE.md).

## Documentación (Fase 1)

| Documento | Contenido |
|---|---|
| [`docs/FASE-1.md`](docs/FASE-1.md) | Índice y caso de estudio |
| [`docs/HERRAMIENTAS.md`](docs/HERRAMIENTAS.md) | Parámetros de configuración de las herramientas |
| [`docs/PLAN-DE-PRUEBAS.md`](docs/PLAN-DE-PRUEBAS.md) | Plan de pruebas y casos de prueba |
| [`docs/FLUJO-GIT.md`](docs/FLUJO-GIT.md) | Flujo de control de versiones |
| [`docs/DESPLIEGUE.md`](docs/DESPLIEGUE.md) | Estrategia de despliegue |
| [`docs/RUBRICA.md`](docs/RUBRICA.md) | Cumplimiento de la rúbrica del mini prototipo |

## Equipo

| Integrante | Rol |
|---|---|
| Angel Agüero | Desarrollo y documentación (roles compartidos) |
| Jose Oximea | Desarrollo y QA (roles compartidos) |

## Licencia
Por definir (agrega un archivo `LICENSE` antes de hacer público el repositorio).
