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
var _previous_action: GameAction

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
	for cell in _board.get_cells_with_units():
		cell.unit.on_turn_start(_turn_color) # Decrements revive counters
	
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
			and _selected_unit.color == _turn_color
	):
		_selected_unit.highlight_cells(_board, _previous_action)


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
		_previous_action = GameAction.new(unit, from_cell, target)
		_process_ability(target, from_cell, _turn_color, false)
	else:
		_previous_action = GameAction.new(unit, from_cell, target, ABILITY)
		_process_ability(target, from_cell, _turn_color, true)
	
	_post_process_action(turn_ending_action)

func _post_process_action(turn_ending_action: bool):
	# After processing actions, remove all highlights
	_board.remove_highlight_from_cells()
	for cell in _board.get_cells_with_units():
		cell.unit.on_action_performed(_board)
	
	# Check if it's the end of the game, or the end of the turn
	if victory_condition_met(): 
		end_game()
		return
	if turn_ending_action or not _are_valid_actions(): 
		_end_turn()
		return
	
	_ui.set_button("End Turn Early", _end_turn)

func _process_ability(target: Cell, source: Cell, originator: bool, ability: bool):
	if ability:
		source.unit.reveal()
	
	# Check if the target contains a friendly unit
	if target.contains_unit():
		if target.unit.color == originator:
			# If the friendly unit is dead, revive them
			if target.unit.defeated:
				target.unit.defeated = false
				(source.unit as Priest).revive_counter = 2
			# If the friendly unit isn't dead, swap places with them
			else: 
				# Get a reference to the target unit before removing it
				var target_unit = target.unit
				target.unit = null
				
				# Move the unit, then put the reference into the current
				_board.move_unit(source, target)
				source.unit = target_unit
		# If the target is a unit of the opposite color, defeat it
		else:
			target.unit.defeated = true
	else:
		# If there is no unit in the target, just move there.
		_board.move_unit(source, target)

## Checks if either win condition has been met. (Monarch at enemy baseline, or
## all enemy units are dead)
func victory_condition_met():
	# If there are no enemy units left alive, return true
	if _board.get_cells_with_living_units_by_color(not _turn_color).is_empty():
		return true
	
	# If a monarch has reached the opposite edge, return true
	for cell in _board.get_cells_with_living_units_by_color(_turn_color):
		var unit := cell.unit
		if unit is Monarch:
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
