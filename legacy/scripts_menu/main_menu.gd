extends Control

@onready var background: TextureRect = $Background
@onready var modal: PanelContainer = $Modal
@onready var modal_title: Label = $Modal/Margin/VBox/Title
@onready var modal_text: Label = $Modal/Margin/VBox/Text

func _ready() -> void:
	$ButtonLayer/PlayButton.grab_focus()
	modal.visible = false

func _on_play_pressed() -> void:
	get_tree().change_scene_to_file("res://scenes/game/museum.tscn")

func _on_options_pressed() -> void:
	_show_modal("OPCIONES", "Aquí podrás configurar volumen, pantalla completa y calidad gráfica.\n\nEsta sección queda preparada para agregar las opciones definitivas.")

func _on_controls_pressed() -> void:
	_show_modal("CONTROLES", "W A S D  —  Moverse\nMouse  —  Mirar\nQ  —  Mirar atrás\nE  —  Interactuar\nF  —  Linterna\nR  —  Usar espejo de inspección\n\nLa mecánica de línea de visión se incorporará en la escena 3D.")

func _on_credits_pressed() -> void:
	_show_modal("CRÉDITOS", "TURNO DE NOCHE: EL MUSEO\n\nAventura / Supervivencia / Misterio\n\nProyecto desarrollado en Godot 4.7\n\n" + "Una noche. Cuatro piezas. Una salida.")

func _on_exit_pressed() -> void:
	get_tree().quit()

func _show_modal(title_text: String, body_text: String) -> void:
	modal_title.text = title_text
	modal_text.text = body_text
	modal.visible = true
	$Modal/Margin/VBox/Close.grab_focus()

func _on_close_pressed() -> void:
	modal.visible = false
	$ButtonLayer/PlayButton.grab_focus()
