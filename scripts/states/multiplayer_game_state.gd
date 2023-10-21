class_name MultiplayerGameState extends GameState

func _enter_state() -> void:
	_ui.print_message("White goes first.", false)
	if _context.game_server.color == WHITE:
		trigger_turn_start()
	else:
		_context.game_server.turn_started.connect(trigger_turn_start)
		_context.game_server.opponent_acted.connect(process_opposing_action)
	_context.game_server.game_ended.connect(_on_game_ended)

func trigger_turn_start() -> void:
	_turn_color = _context.game_server.color
	
	# Update Signals
	_board.cell_selected.connect(_on_cell_selected)
	if _context.game_server.turn_started.is_connected(trigger_turn_start):
		_context.game_server.turn_started.disconnect(trigger_turn_start)
	if _context.game_server.opponent_acted.is_connected(process_opposing_action):
		_context.game_server.opponent_acted.disconnect(process_opposing_action)
	
	# Reset Variables
	_previous_action = null
	for cell in _board.get_cells_with_units():
		cell.unit.on_turn_start(_turn_color) # Decrements revive counters
	
	# Update UI and Board
	_ui.disable_button()
	_ui.print_message("It's your turn!", false)
	
	# Check for stalemate
	if not _are_valid_actions():
		_context.game_server.end_game.rpc(null)

func end_game(stalemate: bool = false):
	if stalemate:
		_context.game_server.end_game.rpc(null)
	else:
		_context.game_server.end_game.rpc(_turn_color)

func _on_game_ended(winner: bool):
	if winner == null:
		_ui.print_message("Stalemate", false)
	else:
		_ui.print_message("%s wins!" % ("White" if winner == WHITE else "Black"), false)
	_board.change_visibility(Board.BoardVisibility.ALL)
	_context.state = MultiplayerEndGameState.new(_context)

## Ends the turn and prompts to start new turn.
func _end_turn() -> void:
	# Disable cell selection so player can't move without starting new turn
	if _board.cell_selected.is_connected(_on_cell_selected):
		_board.cell_selected.disconnect(_on_cell_selected)
		
	_board.deselect_cell()
	_board.remove_highlight_from_cells()
	
	_ui.print_message("Turn ended.", false)
	_context.game_server.end_current_turn.rpc_id(1)
	
	_context.game_server.turn_started.connect(trigger_turn_start)
	_context.game_server.opponent_acted.connect(process_opposing_action)
	_ui.disable_button()

func _post_process_action(turn_ending_action: bool):
	_context.game_server.process_action(_previous_action)
	
	super._post_process_action(turn_ending_action)

func process_opposing_action(from_index: int, to_index: int, ability: bool):
	_process_ability(
			_board.get_cell(to_index),
			_board.get_cell(from_index),
			not _context.game_server.color,
			ability
	)
