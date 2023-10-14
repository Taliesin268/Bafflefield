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
## A quick reference to the child Board component.
var board: Board

# ON-READY VARIABLES
## A quick reference to the child UI component.
@onready var ui := $UI as UI

# BUILT-IN FUNCTIONS
func _ready():
	# Setting the board in ready so that it's available to the CharacterSelectState
	board = $Board
	state = CharacterSelectState.new(self)
