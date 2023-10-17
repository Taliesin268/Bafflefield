class_name Magician extends Monarch

var monarch := false

## Gets the [PackedScene] that contains a unit with this script.
static func get_scene() -> PackedScene:
	return load("res://scenes/units/magician.tscn")


## After an action, check if I've turned into a [Monarch]. (all other friendly
## [Unit]s are defeated.
func on_action_performed(board: Board):
	# Loop through and see if there are any other living units of this color
	for _cell in board.get_cells_with_units():
		if (
				_cell.unit != self 
				and _cell.unit.color == color 
				and not _cell.unit.defeated
		):
			return
	
	monarch = true
	_init_sprites()
	_update_unit_sprite()

# PRIVATE FUNCTIONS
func _get_unit_type_name() -> String:
	return "monarch" if monarch else "magician"


## Highlights all [Cell]s this unit can act upon.
func _highlight_action_cells(board: Board, previous_action: GameAction) -> void:
	# Extends from Monarch, so if we're currently a monarch, call super.
	if monarch:
		super._highlight_action_cells(board, previous_action)
	else:
		_highlight_magician_cells(board, previous_action)


func _highlight_magician_cells(board: Board, previous_action: GameAction) -> void:
	# Highlight all other friendly, living units on black cells
	for _cell in board.get_cells_with_units():
		var unit := _cell.unit
		if (
			unit.color == color
			and not unit.defeated
			and not unit == self
			and not cell.is_black()
		):
			_cell.highlight_based_on_action(previous_action)
