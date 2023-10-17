class_name Knight extends Unit

## Gets the [PackedScene] that contains a unit with this script.
static func get_scene() -> PackedScene:
	return load("res://scenes/units/knight.tscn")
	

func _get_unit_type_name() -> String:
	return "knight"


## Highlights all [Cell]s this unit can act upon.
func _highlight_action_cells(board: Board, previous_action: GameAction) -> void:
	# Target all enemy units in diagonal cells
	for _cell in board.get_diagonal_cells(cell):
		if _cell.unit and is_living_enemy(_cell.unit):
			_cell.highlight_based_on_action(previous_action)
	
	# If this unit has already moved, target all empty diagonal cells
	if (
			previous_action
			and previous_action.was_move() 
			and previous_action.was_unit(self)
	):
		for _cell in board.get_diagonal_cells(cell):
			if not _cell.contains_unit(): 
				_cell.highlight_based_on_action(previous_action)
