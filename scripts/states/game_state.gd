class_name GameState
extends State

# OVERRIDE FUNCTIONS
func _enter_state() -> void:
	_prompt_game_start()

func _exit_state() -> void:
	_board.cell_selected.disconnect(_on_cell_selected)

var _current_turn_white: bool
var selected_cell: Cell
var _previous_action: Action
var selected_unit: Unit:
	get:
		if selected_cell == null:
			return null
		return selected_cell.unit
var revive_counter = {
	true: 0,
	false: 0
}

func _prompt_game_start():
	_ui.set_button(0,"Start Game")
	_ui.get_node("Button").pressed.connect(_start_game)

func _start_game():
	# Move to Game state
	_ui.get_node("Button").pressed.disconnect(_start_game)
	_ui.print_message("Black will go first. The White player should look away from the screen now.")
	_ui.set_button(0,"Black: Start Turn")
	_ui.get_node("Button").pressed.connect(_start_turn)

func _start_turn(white: bool = false):
	_current_turn_white = white
	_previous_action = null
	_board.change_visibility_by_color(white)
	_ui.get_node("Button").pressed.disconnect(_start_turn)
	_ui.set_button(0,"",false)
	_board.cell_selected.connect(_on_cell_selected)
	if white: _ui.print_message("It's White's turn!")
	else: _ui.print_message("It's Black's turn!")
	revive_counter[white] -= 1
	if not _check_for_valid_actions():
		end_game(true)

func _end_turn():
	_board.cell_selected.disconnect(_on_cell_selected)
	_board.change_visibility(Board.BoardVisibility.NONE)
	if _current_turn_white:
		_ui.set_button(0,"Black: Start Turn")
	else:
		_ui.set_button(0,"White: Start Turn")
	_ui.get_node("Button").pressed.connect(_start_turn.bind(!_current_turn_white))

func _on_cell_selected(cell: Cell):
	if cell.is_highlighted():
		_process_unit_action(cell)
		return
	
	if (
		cell.contains_unit() 
		and cell.unit._white == _current_turn_white
		and !cell.unit.defeated
	):
		_on_unit_selected(cell)
	else:
		_deselect_unit()

func _on_unit_selected(cell: Cell):
	_deselect_unit()
	selected_cell = cell
	_highlight_movement_cells()
	if _unit_can_act():
		_highlight_cells_based_on_unit()

func _deselect_unit():
	if selected_cell == null:
		return
	
	_board.remove_highlight_from_cells()
	selected_cell = null

func _highlight_movement_cells():
	if _unit_can_move():
		for index in selected_cell.get_movement_range():
			var cell = _board.get_cell(index)
			if cell.contains_unit() or cell.is_black(): continue
			_board.highlight_cell(index, get_highlight_level(false))

func _highlight_cells_based_on_unit():
	var unit_type = selected_cell.unit._unit_type
	match unit_type:
		Unit.UnitType.MONARCH: _highlight_monarch_cells()
		Unit.UnitType.ARCHER: _highlight_archer_cells()
		Unit.UnitType.KNIGHT: _highlight_knight_cells()
		Unit.UnitType.ASSASSIN: _highlight_assassin_cells()
		Unit.UnitType.PRIEST: _highlight_priest_cells()
		Unit.UnitType.MAGICIAN: _highlight_magician_cells()

func _highlight_monarch_cells():
	if _previous_action != null:
		if _previous_action._unit == selected_cell.unit or _previous_action._ability:
			return
	
	for movement_cell in selected_cell.get_movement_range():
		if _board.get_cell(movement_cell).contains_unit():
			var hop_over_cell_index = selected_cell.index + (movement_cell - selected_cell.index) * 2
			if (
				Cell.is_valid_cell_index(hop_over_cell_index) 
				and !_board.get_cell(hop_over_cell_index).contains_unit() 
				and _previous_action == null
			):
				_board.highlight_cell(hop_over_cell_index, 3)

func _highlight_archer_cells():
	if (
		_previous_action != null 
		and _previous_action._unit == selected_cell.unit
	):
		return
	
	for movement_cell_index in selected_cell.get_movement_range():
		var movement_cell = _board.get_cell(movement_cell_index)
		if movement_cell.contains_unit():
			if movement_cell.unit._white == _current_turn_white: continue
			if movement_cell.unit.defeated : continue
			if _previous_action != null:
				_board.highlight_cell(movement_cell_index,3)
			else:
				_board.highlight_cell(movement_cell_index,2)

func _highlight_knight_cells():
	for cell_index in selected_cell.get_touching_squares():
		var cell = _board.get_cell(cell_index)
		if cell.contains_unit():
			if cell.unit._white == _current_turn_white: continue
			if cell.unit.defeated: continue
			if _previous_action == null:
				_board.highlight_cell(cell_index,2)
				continue
			if (
				(!_previous_action._ability and _previous_action._unit == selected_cell.unit)
				or (_previous_action._ability and _previous_action._unit != selected_cell.unit)
			):
				_board.highlight_cell(cell_index,3)
	
	if _previous_action != null:
		if !_previous_action._ability and _previous_action._unit == selected_cell.unit:
			for cell_index in selected_cell.get_diagonal_squares():
				var cell = _board.get_cell(cell_index)
				if !cell.contains_unit(): 
					_board.highlight_cell(cell_index,3)

func _highlight_assassin_cells():
	# Check movement cells (including black because is assassin)
	for index in (
		selected_cell.get_movement_range() 
		+ selected_cell.get_touching_black_squares()
	):
		var cell = _board.get_cell(index)
		if cell.contains_unit(): continue
		if cell.is_black():
			_board.highlight_cell(index, get_highlight_level())
			
	# Check attacking cells
	for index in selected_cell.get_touching_squares():
		var cell = _board.get_cell(index)
		if cell.contains_unit(not selected_unit._white):
			_board.highlight_cell(index, get_highlight_level())

func _highlight_priest_cells():
	for index in selected_cell.get_movement_range():
		var cell = _board.get_cell(index)
		if (
			cell.contains_unit(selected_unit._white)
			and cell.unit.defeated
			and revive_counter[selected_unit._white] <= 0
		):
			_board.highlight_cell(index, get_highlight_level())

func _highlight_magician_cells():
	for cell in _board._cells_with_units:
		var unit = cell.unit as Unit
		if (
			unit._white == selected_unit._white 
			and not unit.defeated
			and not unit == selected_unit
			and not cell.is_black()
			):
			_board.highlight_cell(cell.index, get_highlight_level())

func _unit_can_move() -> bool:
	return (
		_previous_action == null
		or (
			_previous_action.was_move()
			and not _previous_action.was_unit(selected_unit)
		)
	)
	
func _unit_can_act() -> bool:
	return (
		_previous_action == null
		or (
			_previous_action.was_move()
			and _previous_action.was_unit(selected_unit)
		)
		or (
			_previous_action.was_ability()
			and not _previous_action.was_unit(selected_unit)
		)
	)

func get_highlight_level(ability: bool = true):
	if not ability:
		if _previous_action != null:
			return Cell.HighlightLevel.FINAL_MOVE
		return Cell.HighlightLevel.MOVE
	if _previous_action != null:
		return Cell.HighlightLevel.FINAL_ACT
	return Cell.HighlightLevel.ACT

func _process_unit_action(target: Cell):
	var turn_ending_action = target.highlight_level > 2
	
	if target.highlight_level == 2 or target.highlight_level == 3:
		selected_cell.unit.reveal()
		_previous_action = Action.new(selected_cell.unit, selected_cell, target, true)
	
	if target.highlight_level == 1 or target.highlight_level == 4:
		_previous_action = Action.new(selected_cell.unit, selected_cell, target)
		_board.move_selected_unit(target.index)
	else:
		# If the target is a unit of the same color
		if target.contains_unit(selected_unit._white):
			if target.unit.defeated:
				target.unit.defeated = false
				revive_counter[_current_turn_white] = 2
			else: 
				var invisible_cell = Cell.new()
				invisible_cell.unit = target.unit
				target.unit = null
				_board.move_selected_unit(target.index)
				selected_cell.unit = invisible_cell.unit
				invisible_cell.free()
		# If the target is a unit of the opposite color
		elif target.contains_unit(not selected_unit._white):
			target.unit.defeated = true
		else:
			_board.move_selected_unit(target.index)
	
	_board.remove_highlight_from_cells()
	selected_cell = null
	if victory_condition_met(): end_game()
	if turn_ending_action or !_check_for_valid_actions(): _end_turn()

func victory_condition_met():
	if _board.get_living_unit_cells(not _current_turn_white).is_empty():
		return true
	
	for cell in _board.get_living_unit_cells(_current_turn_white):
		var unit = cell.unit as Unit
		if unit._unit_type == Unit.UnitType.MONARCH:
			if (unit._white and cell.row == 9) or (not unit._white and cell.row == 0):
				return true
	
	return false

func end_game(stalemate: bool = false):
	if stalemate:
		_ui.print_message("Stalemate :O")
	elif _current_turn_white:
		_ui.print_message("White wins!")
	else:
		_ui.print_message("Black wins!")
	_board.change_visibility(Board.BoardVisibility.ALL)
	_context.state = EndGameState.new(_context)

func _check_for_valid_actions() -> bool:
	for cell in _board._cells_with_units:
		var unit = cell.unit
		if unit._white != _current_turn_white or unit.defeated: continue
		selected_cell = cell
		_highlight_movement_cells()
		if _unit_can_act():
			_highlight_cells_based_on_unit()
		selected_cell = null
	
	if _board._highlighted_cells.is_empty():
		_ui.print_message("No valid moves left - ending turn...")
		return false
	else:
		_board.remove_highlight_from_cells()
		return true

class Action:
	var _unit: Unit
	var _ability: bool # True if ability, false if move
	var _from: Cell
	var _to: Cell
	
	func _init(unit: Unit, from: Cell, to: Cell, ability:bool = false):
		_unit = unit
		_from = from
		_to = to
		_ability = ability
	
	func was_move():
		return !_ability
	
	func was_ability():
		return _ability
	
	func was_unit(unit: Unit):
		return _unit == unit
