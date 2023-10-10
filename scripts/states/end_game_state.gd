class_name EndGameState
extends State

# OVERRIDE FUNCTIONS
func _enter_state() -> void:
	_ui.set_button(0,"Restart Game")
	_ui.get_node("Button").pressed.connect(_context.get_tree().reload_current_scene)
