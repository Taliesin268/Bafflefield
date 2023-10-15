class_name GameState extends State
## State that processes the main game.
##
## State that handles moving units around and performing game actions.

# CONSTANTS
const WHITE = true
const BLACK = false
const ABILITY = true
const MOVE = false

# PRIVATE VARIABLES
var _turn_color: bool = WHITE
var _previous_action: Action
var _revive_counter = {
	WHITE: 0,
	BLACK: 0
}

# SHORTCUT VARIABLES
var _selected_cell: Cell:
	get:
		return _board.selected_cell
var _selected_unit: Unit:
	get:
		return _board.selected_unit


# OVERRIDE FUNCTIONS
func _enter_state() -> void:
	_end_turn()


func _exit_state() -> void:
	_board.cell_selected.disconnect(_on_cell_selected)


# PRIVATE FUNCTIONS
## Starts the new turn and checks for stalemates.
func _start_turn() -> void:
	# Update Signals
	_board.cell_selected.connect(_on_cell_selected)
	
	# Reset Variables
	_turn_color = not _turn_color # Switches color
	_previous_action = null
	_revive_counter[_turn_color] -= 1
	
	# Update UI and Board
	_ui.disable_button()
	_ui.print_message(
			"It's %s's turn" % ("White" if _turn_color == WHITE else "Black")
	)
	_board.change_visibility_by_color(_turn_color)
	
	# Check for stalemate
	if not _are_valid_actions():
		end_game(true)


## Ends the turn and prompts to start new turn.
func _end_turn() -> void:
	# Disable cell selection so player can't move without starting new turn
	if _board.cell_selected.is_connected(_on_cell_selected):
		_board.cell_selected.disconnect(_on_cell_selected)
	
	# Update UI and Board
	_board.change_visibility(Board.BoardVisibility.NONE)
	_ui.set_button(
			"%s: Start Turn" % ("Black" if _turn_color == WHITE else "White"),
			_start_turn
	)


func _on_cell_selected() -> void:
	# If a highlighted cell has been clicked, an action should be performed.
	if _selected_cell != null and _selected_cell.is_highlighted():
		_process_action()
		return

	# Remove the highlight and check for a unit
	_board.remove_highlight_from_cells()
	if (
			_selected_cell != null
			and _selected_cell.contains_unit() 
			and _selected_cell.unit.color == _turn_color
			and not _selected_cell.unit.defeated
	):
		_highlight_movement_cells()
		_highlight_action_cells()


## Highlights all cells the currently selected unit can move to
func _highlight_movement_cells():
	if not _unit_can_move():
		return
		
	for index in _selected_cell.get_movement_range():
		var cell = _board.get_cell(index)
		# If the cell is an empty, white cell, highlight it.
		if not cell.contains_unit() and not cell.is_black(): 
			cell.highlight(_get_highlight_level(MOVE))


## Highlights all cells the currently selected unit can affect with their 
## action. Defers to other functions based on the unit type.
func _highlight_action_cells():
	if not _unit_can_act():
		return
	var unit_type = _selected_unit.type
	match unit_type:
		Unit.UnitType.MONARCH: _highlight_monarch_cells()
		Unit.UnitType.ARCHER: _highlight_archer_cells()
		Unit.UnitType.KNIGHT: _highlight_knight_cells()
		Unit.UnitType.ASSASSIN: _highlight_assassin_cells()
		Unit.UnitType.PRIEST: _highlight_priest_cells()
		Unit.UnitType.MAGICIAN: _highlight_magician_cells()

## Highlights action cells for the Monarch unit.
func _highlight_monarch_cells():
	for index in _selected_cell.get_movement_range():
		var cell = _board.get_cell(index)
		if cell.contains_unit():
			# Get the next cell in the same direction as the identified unit
			var bounce_cell = _board.get_next_white_cell(_selected_cell, cell)
			if (
				bounce_cell != null
				and not bounce_cell.contains_unit()
				# Check that no other action taken yet
				and _previous_action == null
			):
				# This counts as an action and a move, so use final act
				bounce_cell.highlight(Cell.HighlightLevel.FINAL_ACT)


## Highlights action cells for the Archer unit.
func _highlight_archer_cells():
	if _previous_action != null and _previous_action.was_unit(_selected_unit):
		return # If the archer has already moved, they cannot act
	
	for index in _selected_cell.get_movement_range():
		var cell = _board.get_cell(index)
		if _cell_contains_living_enemy_unit(cell):
			cell.highlight(_get_highlight_level())


## Highlights action cells for the Knight unit.
func _highlight_knight_cells():
	# Target all enemy units in adjacent cells
	for index in _selected_cell.get_adjacent_cells():
		var cell = _board.get_cell(index)
		if _cell_contains_living_enemy_unit(cell):
			cell.highlight(_get_highlight_level())
	
	# If this unit has already moved, target all empty diagonal cells
	if (
			_previous_action != null
			and _previous_action.was_move() 
			and _previous_action.was_unit(_selected_unit)
	):
		for index in _selected_cell.get_diagonal_squares():
			var cell = _board.get_cell(index)
			if not cell.contains_unit(): 
				cell.highlight(_get_highlight_level())


## Highlights action cells for the Assassin unit.
func _highlight_assassin_cells():
	# Highlight all black and white cells in range
	for index in (
			_selected_cell.get_movement_range() 
			+ _selected_cell.get_adjacent_black_cells()
	):
		var cell = _board.get_cell(index)
		if cell.is_black() and not cell.contains_unit():
			cell.highlight(_get_highlight_level())
			
	# Highlight all adjacent enemy units
	for index in _selected_cell.get_adjacent_cells():
		var cell = _board.get_cell(index)
		if _cell_contains_living_enemy_unit(cell):
			cell.highlight(_get_highlight_level())


## Highlights action cells for the Priest unit.
func _highlight_priest_cells():
	# Highlight all dead, friendly units in range if revive is available
	for index in _selected_cell.get_movement_range():
		var cell = _board.get_cell(index)
		if (
				cell.contains_unit()
				and cell.unit.color == _turn_color
				and cell.unit.defeated
				and _revive_counter[_selected_unit._white] <= 0
		):
			cell.highlight(_get_highlight_level())


## Highlights action cells for the Magician unit.
func _highlight_magician_cells():
	# Highlight all other friendly, living units on black cells
	for cell in _board.get_cells_with_units():
		var unit := cell.unit
		if (
			unit.color == _turn_color
			and not unit.defeated
			and not unit == _selected_unit
			and not cell.is_black()
		):
			cell.highlight(_get_highlight_level())


## Returns true if the provided cell contains a living enemy unit.
func _cell_contains_living_enemy_unit(cell: Cell) -> bool:
	return (
			cell.contains_unit()
			and cell.unit.color != _turn_color 
			and not cell.unit.defeated
	)


## Checks if the selected unit can move.
func _unit_can_move() -> bool:
	return (
		_previous_action == null
		or (
			_previous_action.was_move()
			and not _previous_action.was_unit(_selected_unit)
		)
	)


## Checks if the selected unit can use their ability.
func _unit_can_act() -> bool:
	return (
		_previous_action == null
		or (
			_previous_action.was_move()
			and _previous_action.was_unit(_selected_unit)
		)
		or (
			_previous_action.was_ability()
			and not _previous_action.was_unit(_selected_unit)
		)
	)


## Returns the appropriate highlight level based for a move or ability.
func _get_highlight_level(ability: bool = true):
	if ability:
		if _previous_action != null:
			return Cell.HighlightLevel.FINAL_ACT
		return Cell.HighlightLevel.ACT

	if _previous_action != null:
		return Cell.HighlightLevel.FINAL_MOVE
	return Cell.HighlightLevel.MOVE


## Handles the action of the previously selected unit based on the chosen
## highlighted cell.
func _process_action():
	var target := _selected_cell
	var unit := _board.previous_unit
	var from_cell := _board.previous_cell
	
	# Check if this was a turn-ending action
	var turn_ending_action = target.highlight_level > 2

	# If it was a move action, just move the unit to the cell
	if target.highlight_level == 1 or target.highlight_level == 4:
		_previous_action = Action.new(unit, from_cell, target)
		_board.move_unit()
	else:
		unit.reveal()
		_previous_action = Action.new(unit, from_cell, target, ABILITY)
		# Check if the target contains a friendly unit
		if target.contains_unit():
			if target.unit.color == _turn_color:
				# If the friendly unit is dead, revive them
				if target.unit.defeated:
					target.unit.defeated = false
					_revive_counter[_turn_color] = 2
				# If the friendly unit isn't dead, swap places with them
				else: 
					# Get a reference to the target unit before removing it
					var target_unit = target.unit
					target.unit = null
					
					# Move the unit, then put the reference into the current
					_board.move_unit()
					from_cell.unit = target_unit
			# If the target is a unit of the opposite color, defeat it
			else:
				target.unit.defeated = true
		else:
			# If there is no unit in the target, just move there.
			_board.move_unit()
	
	# After processing actions, remove all highlights
	_board.remove_highlight_from_cells()
	
	# Check if it's the end of the game, or the end of the turn
	if victory_condition_met(): 
		end_game()
		return
	if turn_ending_action or not _are_valid_actions(): 
		_end_turn()
		return
	
	_ui.set_button("End Turn Early", _end_turn)



## Checks if either win condition has been met. (Monarch at enemy baseline, or
## all enemy units are dead)
func victory_condition_met():
	# If there are no enemy units left alive, return true
	if _board.get_cells_with_living_units_by_color(not _turn_color).is_empty():
		return true
	
	# If a monarch has reached the opposite edge, return true
	for cell in _board.get_cells_with_living_units_by_color(_turn_color):
		var unit := cell.unit
		if unit.type == Unit.UnitType.MONARCH:
			if (
					(unit.color == WHITE and cell.row == 9 )
					or (unit.color == BLACK and cell.row == 0)
			):
				return true
	
	# If neither win con has been met, then return false
	return false


## Ends the game. Prints an end game message then moves into the End Game state.
func end_game(stalemate: bool = false):
	if stalemate:
		_ui.print_message("Stalemate :O")
	else:
		_ui.print_message(
				"%s wins!" % ("White" if _turn_color == WHITE else "Black")
		)
	_board.change_visibility(Board.BoardVisibility.ALL)
	_context.state = EndGameState.new(_context)


## Checks if there are any valid actions left by selecting all units and
## testing if they highlight any cells.
func _are_valid_actions() -> bool:
	for cell in _board.get_cells_with_units():
		cell.select()
		# If some cells were highlighted, it means there are valid actions
		if not _board.get_highlighted_cells().is_empty():
			_board.remove_highlight_from_cells()
			_board.deselect_cell()
			return true
		# Remove the highlights so that actions aren't performed
		_board.remove_highlight_from_cells()
	_ui.print_message("No valid moves left - ending turn...")
	_board.deselect_cell()
	return false

## A structure for storing the relevant information about a previous action.
class Action:
	var _unit: Unit
	var _ability: bool # True if ability, false if move
	var _from: Cell
	var _to: Cell
	
	
	func _init(unit: Unit, from: Cell, to: Cell, ability: bool = false):
		_unit = unit
		_from = from
		_to = to
		_ability = ability
	
	
	## Returns true if this action was a move action.
	func was_move():
		return not _ability
	
	
	## Returns true if this action was an ability.
	func was_ability():
		return _ability
	
	
	## Checks if the supplied unit is the one that performed this action.
	func was_unit(unit: Unit):
		return _unit == unit
