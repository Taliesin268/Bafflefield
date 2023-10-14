class_name CharacterSelectState
extends State
## The initial state of the game for selecting your characters.
##
## State that allows you to pick which units, and where you want them to be
## positioned. Moves into [GameState] once done.

# CONSTANTS
const WHITE = true
const BLACK = false

# PRIVATE VARIABLES
var _color := BLACK

# OVERRIDE FUNCTIONS
func _enter_state() -> void:
	_spawn_units()
	_board.cell_selected.connect(_on_cell_selected)


func _exit_state() -> void:
	_board.remove_highlight_from_cells()
	_board.cell_selected.disconnect(_on_cell_selected)
	var button = _ui.get_node("Button") as Button


# CONNECTED SIGNALS
func _on_cell_selected() -> void:
	# If a highlighed cell was selected, move the unit to that cell
	if _board.selected_cell.is_highlighted():
		_board.move_unit()
		_board.remove_highlight_from_cells()
		
		# If all characters are in position now, prompt the next step
		if _characters_selected():
			_ui.set_button("Done")
			if not _ui.button.pressed.is_connected(_end_current_selection):
				_ui.button.pressed.connect(_end_current_selection)
		else:
			_ui.disable_button()
			if _ui.button.pressed.is_connected(_end_current_selection):
				_ui.button.pressed.disconnect(_end_current_selection)
		return
	
	_board.remove_highlight_from_cells()
	
	# If a valid unit was selected, highlight all the empty valid cells
	if _board.selected_cell.contains_unit() and _board.selected_cell.unit.color == _color:
		_highlight_cells()


# PRIVATE FUNCTIONS
## Spawns units of each type in the middle of the board.
func _spawn_units():
		_board.spawn_unit(42, Unit.UnitType.ARCHER, _color)
		_board.spawn_unit(43, Unit.UnitType.ASSASSIN, _color)
		_board.spawn_unit(44, Unit.UnitType.KNIGHT, _color)
		_board.spawn_unit(45, Unit.UnitType.MAGICIAN, _color)
		_board.spawn_unit(46, Unit.UnitType.MONARCH, _color)
		_board.spawn_unit(47, Unit.UnitType.PRIEST, _color)
		if _color == WHITE:
			_ui.print_message("Now it's White's turn. Black, avert your eyes.")


## Either swaps to White selecting their units, or starts the game.
func _end_current_selection():
	_ui.button.pressed.disconnect(_end_current_selection)
	_remove_leftover_unit()
	_board.hide_units()
	_board.remove_highlight_from_cells()
	if _color == BLACK:
		_color = WHITE
		_board.change_visibility(Board.BoardVisibility.WHITE)
		_spawn_units()
	else:
		_board.change_visibility(Board.BoardVisibility.NONE)
		_context.state = GameState.new(_context)


## Highlights the cells based on whose turn it is, and where units are.
func _highlight_cells():
	# Highlight all the middle cells (where the units spawn)
	for i in 6:
		_highlight_cell_if_empty(42 + i)
	
	# Highlight the white cells in the current colors baseline
	for i in 5:
		if _color == WHITE:
			_highlight_cell_if_empty(i * 2 + 1)
		else:
			_highlight_cell_if_empty(i * 2 + 90)


## Highlights the cell at the provided index if it doesn't contain a unit.
func _highlight_cell_if_empty(index: int) -> void:
	if not _board.get_cell(index).contains_unit():
			_board.highlight_cell(index)


## Removes the unit left in the center of the board.
func _remove_leftover_unit():
	for i in 6:
		var cell := _board.get_cell(42+i)
		if cell.contains_unit():
			cell.unit = null
			return


## Returns true if all characters in the current baseline have been placed
func _characters_selected() -> bool:
	for i in 5:
		if _color == WHITE and not _board.get_cell(i * 2 + 1).contains_unit():
			return false
		elif not _board.get_cell(i * 2 + 90).contains_unit():
			return false
	
	return true
