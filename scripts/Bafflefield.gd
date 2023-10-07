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
	
func _on_state_switched(state):
	_enter_state(state)

# PRIVATE FUNCTIONS
func _enter_state(new_state):
	if state != null:
		state.exit_state()
	
	state = new_state.new() as BaseState
	state.switched_state.connect(_on_state_switched)
	state.enter_state($Board)

func _start_character_select():
	$UI.load_dialog("character_select_intro", false)

# CLASSES
class BaseState:
	var state_name: String = "Base State"
	signal switched_state(state)
	var _game_board: Board
	func enter_state(game_board: Board): 
		print("Entering state ", state_name)
		_game_board = game_board
	func exit_state():
		print("Leaving state ", state_name)
	func handle_event(event_name: String):
		print("Unhandled event received: ", event_name)
	func switch_state(state): 
		switched_state.emit(state)

class IntroductionState extends BaseState:
	func enter_state(game_board: Board):
		state_name = "Introduction State"
		super.enter_state(game_board)
	
	func handle_event(event_name: String):
		if event_name == "spawn_characters":
			switch_state(CharacterSelectState)
			return
			
		super.handle_event(event_name)

class CharacterSelectState extends BaseState:
	func enter_state(game_board: Board):
		state_name = "Character Select State"
		super.enter_state(game_board)
		_spawn_characters()

	func _spawn_characters():
		_game_board.get_cell(42).spawn_unit(Unit.UnitType.ARCHER)
		_game_board.get_cell(43).spawn_unit(Unit.UnitType.ASSASSIN)
		_game_board.get_cell(44).spawn_unit(Unit.UnitType.KNIGHT)
		_game_board.get_cell(45).spawn_unit(Unit.UnitType.MAGICIAN)
		_game_board.get_cell(46).spawn_unit(Unit.UnitType.MONARCH)
		_game_board.get_cell(47).spawn_unit(Unit.UnitType.PRIEST)
		pass
