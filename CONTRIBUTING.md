# Guía de contribución

Gracias por colaborar en **Turno de Noche: El Museo**. Esta guía resume el flujo; el detalle está en `docs/`.

## Antes de empezar
1. Instala **Godot 4.7** (la misma versión para todo el equipo).
2. Clona el repositorio y ejecuta `bash scripts/dev/setup-repo.sh` para activar los hooks.
3. Abre la carpeta con Godot (Importar proyecto) y presiona F5 para comprobar que el juego corre.

## Flujo de trabajo
1. Toma o crea un **issue** (plantillas en `.github/ISSUE_TEMPLATE/`).
2. Crea tu rama desde `develop`: `feature/<nombre>`, `fix/<nombre>` o `docs/<nombre>`.
3. Haz commits pequeños con el formato `tipo(alcance): resumen` (ver `docs/FLUJO-GIT.md`).
4. Ejecuta las pruebas antes de subir:
   ```bash
   godot --headless --path . --script res://tests/smoke/load_all.gd
   godot --headless --path . --script res://tests/run_tests.gd
   ```
5. Abre un **Pull Request** hacia `develop`, llena la plantilla y espera el CI en verde y 1 aprobación.

## Estilo de código (GDScript)
- Indentación con tabulaciones; codificación UTF-8 y fin de línea LF (`.editorconfig`).
- Nombres en `snake_case` para variables y funciones, `PascalCase` para clases y nodos, constantes en `MAYUSCULAS`.
- Comentarios `##` encima de funciones y clases importantes.
- Sin emojis en el juego ni en los textos de la interfaz.
- Líneas de máximo 160 caracteres (`.gdlintrc`).

## Escenas
Una sola persona edita una escena `.tscn` a la vez. Avisa en el grupo antes de modificar `scenes/museum.tscn`.

## Pruebas
Si agregas lógica nueva, agrega pruebas en `tests/unit/` y regístralas en `SUITES` dentro de `tests/run_tests.gd`.
Los casos manuales viven en `docs/PLAN-DE-PRUEBAS.md`.
