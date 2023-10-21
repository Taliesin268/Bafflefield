class_name Bafflefield extends Node
## The state machine that controls the whole Bafflefield game.
##
## This is a node that utilises the State Machine design pattern to switch 
## between selecting characters (see [CharacterSelectState]), playing the game 
## (see [GameState]), and the end game (see [EndGameState]).
##
## @tutorial(State Machines): https://refactoring.guru/design-patterns/state

# PUBLIC VARIABLES
## The state the game is currently in.
var state: State:
	set(value):
		if state != null:
			state._exit_state()
		state = value
		state._enter_state()

# ON-READY VARIABLES
var game_server: Multiplayer
## A quick reference to the child UI component.
@onready var ui := $UI as UI
## A quick reference to the child Board component.
@onready var board := $Board as Board

# BUILT-IN FUNCTIONS
func _ready():
	var parent = get_parent()
	if parent and parent is Multiplayer:
		game_server = parent
		ui.hotseat = false
		state = MultiplayerCharacterSelectState.new(self)
	else:
		state = CharacterSelectState.new(self)
