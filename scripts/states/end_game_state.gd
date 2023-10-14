class_name EndGameState extends State
## The final state of the game.
##
## The final state of the game. Used for removing all input handling from other
## states, and to allow the user to restart the game.

# OVERRIDE FUNCTIONS
func _enter_state() -> void:
	_ui.set_button("Restart Game")
	# Set the UI button to reset the game by resetting the [Bafflefield] scene
	_ui.get_node("Button").pressed.connect(_context.get_tree().reload_current_scene)
