class_name State
## The abstract base state for the Bafflefield state machine.

# PRIVATE VARIABLES
## The Bafflefield context (for accessing the UI, Board, and Tree).
var _context: Bafflefield
## A simple getter for accessing the board without having to use 
## [code]_context.board[/code].
@warning_ignore("unused_private_class_variable") # Is used in descendents
var _board: Board:
	get:
		return _context.board
## A simple getter for accessing the UI without having to use 
## [code]_context.ui[/code].
@warning_ignore("unused_private_class_variable") # Is used in descendents
var _ui: UI:
	get:
		return _context.ui
## A simple getter for accessing the UI's button without having to use 
## [code]_context.ui.button[/code].
@warning_ignore("unused_private_class_variable") # Is used in descendents
var _button: Button:
	get:
		return _ui.button


# BUILT-IN FUNCTIONS
## Constructor for all states. Simply loads the context as a member.
func _init(context: Bafflefield):
	_context = context


# PUBLIC FUNCTIONS
## Called by the Bafflefield context when entering this state.
func _enter_state() -> void:
	pass


## Called by the Bafflefield context when exiting this state.
func _exit_state() -> void:
	pass
