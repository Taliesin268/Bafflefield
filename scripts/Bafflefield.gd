class_name Bafflefield
extends Node2D

# PRIVATE VARIABLES
var state: State:
	set(value):
		if state != null:
			state._exit_state()
		state = value
		state._enter_state()

# ON-READY VARIABLES
@onready var ui: UI = $UI
@onready var board: Board = $Board

# BUILT-IN FUNCTIONS
func _ready():
	state = CharacterSelectState.new(self)
