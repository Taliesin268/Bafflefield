class_name State

# PRIVATE VARIABLES
var _context: Bafflefield
var _board: Board:
	get:
		return _context.board
var _ui: UI:
	get:
		return _context.ui

# BUILT-IN FUNCTIONS
func _init(context: Bafflefield):
	_context = context

# PUBLIC FUNCTIONS
func _enter_state() -> void:
	pass

func _exit_state() -> void:
	pass
