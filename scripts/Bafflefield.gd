extends Node2D
class_name Bafflefield

# PRIVATE VARIABLES
var state: BaseState

# BUILT-IN FUNCTIONS
func _ready():
	$UI.load_dialog("introduction")
	_enter_state(IntroductionState)

# CONNECTED SIGNALS
func _on_ui_dialog_complete(dialog_name):
	print("Dialog complete: ", dialog_name)
	match dialog_name:
		"introduction": 
			_start_character_select()

func _on_ui_dialog_event(event_name):
	print("Dialog event triggered: ", event_name)
	state.handle_event(event_name)
	
func _on_state_switched(new_state):
	_enter_state(new_state)

# PRIVATE FUNCTIONS
func _enter_state(new_state):
	if state != null:
		state.exit_state()
	
	state = new_state.new() as BaseState
	state.switched_state.connect(_on_state_switched)
	state.enter_state($Board, $UI)

func _start_character_select():
	$UI.load_dialog("character_select_intro")

# CLASSES
class BaseState:
	var state_name: String = "Base State"
	signal switched_state(state)
	var _game_board: Board
	var _ui: UI
	func enter_state(game_board: Board, ui: UI): 
		print("Entering state ", state_name)
		_game_board = game_board
		_ui = ui
	func exit_state():
		print("Leaving state ", state_name)
	func handle_event(event_name: String):
		print("Unhandled event received: ", event_name)
	func switch_state(state): 
		switched_state.emit(state)

class IntroductionState extends BaseState:
	func enter_state(game_board: Board, ui: UI):
		state_name = "Introduction State"
		super.enter_state(game_board, ui)
	
	func handle_event(event_name: String):
		if event_name == "spawn_characters":
			switch_state(CharacterSelectState)
			return
			
		super.handle_event(event_name)

class CharacterSelectState extends BaseState:
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
			{ "func": _remove_highlight_from_cells, "args": [] }, 
			{ "func": switch_state, "args": [ GameState ] },
		]
	]
	
	var _current_substate = 0
	var _current_highlighted_cell_index: int
	var _white: bool = false
	
	func exit_state():
		if _game_board.cell_selected.is_connected(_on_cell_selected):
			_game_board.cell_selected.disconnect(_on_cell_selected)
		var button = _ui.get_node("Button") as Button
		if button.pressed.is_connected(_on_unit_chosen):
			button.pressed.disconnect(_on_unit_chosen)
		super.exit_state()
	
	func enter_state(game_board: Board, ui: UI):
		state_name = "Character Select State"
		super.enter_state(game_board, ui)
		_process_substate()
		_game_board.cell_selected.connect(_on_cell_selected)
		
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
		_game_board.move_selected_unit(_current_highlighted_cell_index)
		_ui.set_button(0,"",false)
		_process_substate()
		if _ui.get_node("Button").pressed.is_connected(_on_unit_chosen):
			_ui.get_node("Button").pressed.disconnect(_on_unit_chosen)

	func _spawn_characters(white: bool = false):
		_game_board.spawn_unit(42, Unit.UnitType.ARCHER, white)
		_game_board.spawn_unit(43, Unit.UnitType.ASSASSIN, white)
		_game_board.spawn_unit(44, Unit.UnitType.KNIGHT, white)
		_game_board.spawn_unit(45, Unit.UnitType.MAGICIAN, white)
		_game_board.spawn_unit(46, Unit.UnitType.MONARCH, white)
		_game_board.spawn_unit(47, Unit.UnitType.PRIEST, white)
		_white = white
		if white:
			_ui.print_message("Now it's White's turn. Black, avert your eyes.")
		
	func _process_substate():
		var operations = SUBSTATES[_current_substate]
		for operation in operations:
			operation.func.callv(operation.args)
		
		_current_substate += 1
		
	func _highlight_cell(index: int):
		_game_board.remove_highlight_from_cells()
		_game_board.highlight_cell(index)
		_current_highlighted_cell_index = index
	
	func _remove_highlight_from_cells(): _game_board.remove_highlight_from_cells()
	func _remove_leftover_unit(): _game_board.remove_leftover_unit()
	func _hide_units(): _game_board.hide_units()
	func _change_visibility(setting: Board.BoardVisibility): _game_board.change_visibility(setting)

class GameState extends BaseState:
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
	
	func enter_state(game_board: Board, ui: UI):
		state_name = "Game State"
		super.enter_state(game_board, ui)
		_prompt_game_start()
	
	func exit_state():
		_game_board.change_visibility(Board.BoardVisibility.ALL)
		_game_board.cell_selected.disconnect(_on_cell_selected)
	
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
		_game_board.change_visibility_by_color(white)
		_ui.get_node("Button").pressed.disconnect(_start_turn)
		_ui.set_button(0,"",false)
		_game_board.cell_selected.connect(_on_cell_selected)
		if white: _ui.print_message("It's White's turn!")
		else: _ui.print_message("It's Black's turn!")
		revive_counter[white] -= 1
		if not _check_for_valid_actions():
			end_game(true)
	
	func _end_turn():
		_game_board.cell_selected.disconnect(_on_cell_selected)
		_game_board.change_visibility(Board.BoardVisibility.NONE)
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
		
		_game_board.remove_highlight_from_cells()
		selected_cell = null
	
	func _highlight_movement_cells():
		if _unit_can_move():
			for index in selected_cell.get_movement_range():
				var cell = _game_board.get_cell(index)
				if cell.contains_unit() or cell.is_black(): continue
				_game_board.highlight_cell(index, get_highlight_level(false))
	
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
			if _game_board.get_cell(movement_cell).contains_unit():
				var hop_over_cell_index = selected_cell.index + (movement_cell - selected_cell.index) * 2
				if (
					Cell.is_valid_cell_index(hop_over_cell_index) 
					and !_game_board.get_cell(hop_over_cell_index).contains_unit() 
					and _previous_action == null
				):
					_game_board.highlight_cell(hop_over_cell_index, 3)

	func _highlight_archer_cells():
		if (
			_previous_action != null 
			and _previous_action._unit == selected_cell.unit
		):
			return
		
		for movement_cell_index in selected_cell.get_movement_range():
			var movement_cell = _game_board.get_cell(movement_cell_index)
			if movement_cell.contains_unit():
				if movement_cell.unit._white == _current_turn_white: continue
				if movement_cell.unit.defeated : continue
				if _previous_action != null:
					_game_board.highlight_cell(movement_cell_index,3)
				else:
					_game_board.highlight_cell(movement_cell_index,2)

	func _highlight_knight_cells():
		for cell_index in selected_cell.get_touching_squares():
			var cell = _game_board.get_cell(cell_index)
			if cell.contains_unit():
				if cell.unit._white == _current_turn_white: continue
				if cell.unit.defeated: continue
				if _previous_action == null:
					_game_board.highlight_cell(cell_index,2)
					continue
				if (
					(!_previous_action._ability and _previous_action._unit == selected_cell.unit)
					or (_previous_action._ability and _previous_action._unit != selected_cell.unit)
				):
					_game_board.highlight_cell(cell_index,3)
		
		if _previous_action != null:
			if !_previous_action._ability and _previous_action._unit == selected_cell.unit:
				for cell_index in selected_cell.get_diagonal_squares():
					var cell = _game_board.get_cell(cell_index)
					if !cell.contains_unit(): 
						_game_board.highlight_cell(cell_index,3)

	func _highlight_assassin_cells():
		# Check movement cells (including black because is assassin)
		for index in (
			selected_cell.get_movement_range() 
			+ selected_cell.get_touching_black_squares()
		):
			var cell = _game_board.get_cell(index)
			if cell.contains_unit(): continue
			if cell.is_black():
				_game_board.highlight_cell(index, get_highlight_level())
				
		# Check attacking cells
		for index in selected_cell.get_touching_squares():
			var cell = _game_board.get_cell(index)
			if cell.contains_unit(not selected_unit._white):
				_game_board.highlight_cell(index, get_highlight_level())
	
	func _highlight_priest_cells():
		for index in selected_cell.get_movement_range():
			var cell = _game_board.get_cell(index)
			if (
				cell.contains_unit(selected_unit._white)
				and cell.unit.defeated
				and revive_counter[selected_unit._white] <= 0
			):
				_game_board.highlight_cell(index, get_highlight_level())
	
	func _highlight_magician_cells():
		for cell in _game_board._cells_with_units:
			var unit = cell.unit as Unit
			if (
				unit._white == selected_unit._white 
				and not unit.defeated
				and not unit == selected_unit
				and not cell.is_black()
				):
				_game_board.highlight_cell(cell.index, get_highlight_level())
	
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
			_game_board.move_selected_unit(target.index)
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
					_game_board.move_selected_unit(target.index)
					selected_cell.unit = invisible_cell.unit
					invisible_cell.free()
			# If the target is a unit of the opposite color
			elif target.contains_unit(not selected_unit._white):
				target.unit.defeated = true
			else:
				_game_board.move_selected_unit(target.index)
		
		_game_board.remove_highlight_from_cells()
		selected_cell = null
		if victory_condition_met(): end_game()
		if turn_ending_action or !_check_for_valid_actions(): _end_turn()

	func victory_condition_met():
		if _game_board.get_living_unit_cells(not _current_turn_white).is_empty():
			return true
		
		for cell in _game_board.get_living_unit_cells(_current_turn_white):
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
		switch_state(EndGameState)

	func _check_for_valid_actions() -> bool:
		for cell in _game_board._cells_with_units:
			var unit = cell.unit
			if unit._white != _current_turn_white or unit.defeated: continue
			selected_cell = cell
			_highlight_movement_cells()
			if _unit_can_act():
				_highlight_cells_based_on_unit()
			selected_cell = null
		
		if _game_board._highlighted_cells.is_empty():
			_ui.print_message("No valid moves left - ending turn...")
			return false
		else:
			_game_board.remove_highlight_from_cells()
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

class EndGameState extends BaseState:
	var bafflefield: Bafflefield
	
	func enter_state(game_board: Board, ui: UI):
		state_name = "Game State"
		super.enter_state(game_board, ui)
		ui.set_button(0,"Restart Game")
		ui.get_node("Button").pressed.connect(ui.get_parent().get_tree().reload_current_scene)
