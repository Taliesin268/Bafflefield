extends Node2D

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
	var _selected_unit_cell: Cell
	var _previous_action: Action
	
	func enter_state(game_board: Board, ui: UI):
		state_name = "Game State"
		super.enter_state(game_board, ui)
		_prompt_game_start()
	
	func _prompt_game_start():
		_ui.set_button(0,"Start Game")
		_ui.get_node("Button").pressed.connect(_start_game)
	
	func _start_game():
		# Move to Game state
		_ui.print_message("Starting game...")
		_ui.get_node("Button").pressed.disconnect(_start_game)
		_ui.print_message("Black will go first. The White player should look away from the screen now.")
		_ui.set_button(0,"Black: Start Turn")
		_ui.get_node("Button").pressed.connect(_start_turn)
	
	func _start_turn(white: bool = false):
		_current_turn_white = white
		_game_board.change_visibility_by_color(white)
		_ui.get_node("Button").pressed.disconnect(_start_turn)
		_ui.set_button(0,"",false)
		_game_board.cell_selected.connect(_on_cell_selected)
	
	func _on_cell_selected(cell: Cell):
		if cell.contains_unit():
			_on_unit_selected(cell)
		else:
			_deselect_unit()
	
	func _on_unit_selected(cell: Cell):
		_deselect_unit()
		_selected_unit_cell = cell
		_highlight_cells_based_on_unit(cell)
		pass
	
	func _deselect_unit():
		if _selected_unit_cell == null:
			return
		
		_game_board.remove_highlight_from_cells()
		_selected_unit_cell = null
	
	func _highlight_cells_based_on_unit(cell: Cell):
		var unit_type = cell.unit._unit_type
		match unit_type:
			Unit.UnitType.MONARCH: _highlight_monarch_cells(cell)
			_: print("Unit type not supported: ", unit_type)

	func _highlight_monarch_cells(monarch_cell: Cell):
		for movement_cell in monarch_cell.get_movement_range():
			if _game_board.get_cell(movement_cell).contains_unit():
				var hop_over_cell_index = monarch_cell.index + (movement_cell - monarch_cell.index) * 2
				if Cell.is_valid_cell_index(hop_over_cell_index) && !_game_board.get_cell(hop_over_cell_index).contains_unit():
					_game_board.highlight_cell(hop_over_cell_index, 3)
			else: 
				_game_board.highlight_cell(movement_cell, 2)

	class Action:
		var unit: Unit
		var ability: bool # True if ability, false if move
		var from: Cell
		var to: Cell
