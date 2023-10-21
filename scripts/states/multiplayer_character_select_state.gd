class_name MultiplayerCharacterSelectState extends CharacterSelectState

func _enter_state():
	_color = _context.game_server.color
	_board.change_visibility_by_color(_color)
	super._enter_state()

func _end_current_selection():
	_ui.disable_button()
	
	# Clean up the board
	_remove_leftover_unit()
	_board.hide_units()
	_board.remove_highlight_from_cells()
	_board.deselect_cell()
	
	# Disconnect the board interaction
	_board.cell_selected.disconnect(_on_cell_selected)
	
	# Get the list of selected units
	var units := {}
	for i in 5:
		var cell: Cell
		if _color == WHITE:
			cell = _board.get_cell(i * 2 + 1)
		else:
			cell = _board.get_cell(i * 2 + 90)
		units[cell.unit._get_unit_type_name()] = cell.index
	
	# Start listening to the transition command
	_context.game_server.game_started.connect(_transition_to_game_state)
	
	# Tell the server which units we selected
	_context.game_server.set_characters_selected.rpc_id(1, JSON.stringify(units))

func _transition_to_game_state():
	_context.state = MultiplayerGameState.new(_context)
