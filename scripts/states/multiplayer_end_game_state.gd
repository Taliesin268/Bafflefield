class_name MultiplayerEndGameState extends EndGameState

# OVERRIDE FUNCTIONS
func _enter_state() -> void:
	# Set the UI button to reset the game by resetting the [Bafflefield] scene
	if _context.game_server.is_server():
		_ui.set_button("Restart Game", _context.game_server.trigger_start_game())
