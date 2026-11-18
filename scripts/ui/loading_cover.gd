extends CanvasLayer

## Sobrevive al cambio de escena y cubre la generación síncrona del mundo.
func _ready() -> void:
	await get_tree().process_frame
	await get_tree().process_frame
	# CanvasLayer no tiene modulate; desvanecer los controles que dibuja.
	var fade_out := create_tween().set_parallel(true)
	for child in get_children():
		if child is CanvasItem:
			fade_out.tween_property(child, "modulate:a", 0.0, 0.45)
	await fade_out.finished
	queue_free()
