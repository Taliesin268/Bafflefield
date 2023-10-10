class_name CharacterSelectState
extends State

var SUBSTATES = [
		[ { "func": _spawn_characters, "args": [] }, { "func": _highlight_cell, "args": [ 90 ] } ],
		[ { "func": _highlight_cell, "args": [ 92 ] } ],
		[ { "func": _highlight_cell, "args": [ 94 ] } ],
		[ { "func": _highlight_cell, "args": [ 96 ] } ],
		[ { "func": _highlight_cell, "args": [ 98 ] } ],
		[ 
			{ "func": _remove_leftover_unit, "args": [] }, 
			{ "func": _hide_units, "args": [] },
			{ "func": _change_visibility, "args": [ Board.BoardVisibility.WHITE ] },
			{ "func": _spawn_characters, "args": [ true ] },
			{ "func": _highlight_cell, "args": [ 9 ] }
		],
		[ { "func": _highlight_cell, "args": [ 7 ] } ],
		[ { "func": _highlight_cell, "args": [ 5 ] } ],
		[ { "func": _highlight_cell, "args": [ 3 ] } ],
		[ { "func": _highlight_cell, "args": [ 1 ] } ],
		[
			{ "func": _remove_leftover_unit, "args": [] },
			{ "func": _hide_units, "args": [] },
			{ "func": _change_visibility, "args": [ Board.BoardVisibility.NONE ] },
			{ "func": _remove_highlight_from_cells, "args": [] }
		]
	]
	
var _current_substate = 0
var _current_highlighted_cell_index: int
var _white: bool = false

# OVERRIDE FUNCTIONS
func _enter_state() -> void:
	_process_substate()
	_board.cell_selected.connect(_on_cell_selected)

func _exit_state() -> void:
	if _board.cell_selected.is_connected(_on_cell_selected):
		_board.cell_selected.disconnect(_on_cell_selected)
	var button = _ui.get_node("Button") as Button
	if button.pressed.is_connected(_on_unit_chosen):
		button.pressed.disconnect(_on_unit_chosen)

# CONNECTED SIGNALS
func _on_cell_selected(cell: Cell):
		var button = _ui.get_node("Button") as Button
		if button.pressed.is_connected(_on_unit_chosen):
			button.pressed.disconnect(_on_unit_chosen)
			
		if cell.contains_unit() && cell.unit._white == _white:
			_ui.set_button(0,str("Select ", cell.unit.unit_type_name.capitalize()))
			button.pressed.connect(_on_unit_chosen)
		else:
			_ui.set_button(0,"",false)

func _on_unit_chosen():
		_board.move_selected_unit(_current_highlighted_cell_index)
		_ui.set_button(0,"",false)
		_process_substate()
		if _ui.get_node("Button").pressed.is_connected(_on_unit_chosen):
			_ui.get_node("Button").pressed.disconnect(_on_unit_chosen)

func _spawn_characters(white: bool = false):
		_board.spawn_unit(42, Unit.UnitType.ARCHER, white)
		_board.spawn_unit(43, Unit.UnitType.ASSASSIN, white)
		_board.spawn_unit(44, Unit.UnitType.KNIGHT, white)
		_board.spawn_unit(45, Unit.UnitType.MAGICIAN, white)
		_board.spawn_unit(46, Unit.UnitType.MONARCH, white)
		_board.spawn_unit(47, Unit.UnitType.PRIEST, white)
		_white = white
		if white:
			_ui.print_message("Now it's White's turn. Black, avert your eyes.")
		
func _process_substate():
	var operations = SUBSTATES[_current_substate]
	for operation in operations:
		operation.func.callv(operation.args)
	
	_current_substate += 1
	
	if _current_substate == SUBSTATES.size():
		_context.state = GameState.new(_context)
	
func _highlight_cell(index: int):
	_board.remove_highlight_from_cells()
	_board.highlight_cell(index)
	_current_highlighted_cell_index = index

func _remove_highlight_from_cells(): _board.remove_highlight_from_cells()
func _remove_leftover_unit(): _board.remove_leftover_unit()
func _hide_units(): _board.hide_units()
func _change_visibility(setting: Board.BoardVisibility): _board.change_visibility(setting)
