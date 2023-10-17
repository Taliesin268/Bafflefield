class_name Monarch extends Unit

## Gets the [PackedScene] that contains a unit with this script.
static func get_scene() -> PackedScene:
	return load("res://scenes/units/monarch.tscn")


# PRIVATE FUNCTIONS
func _get_unit_type_name() -> String:
	return "monarch"


## Highlights all [Cell]s this unit can act upon.
func _highlight_action_cells(board: Board, previous_action: GameAction) -> void:
	for _cell in board.get_movement_cells(cell):
		if _cell.contains_unit():
			# Get the next cell in the same direction as the identified unit
			var bounce_cell = board.get_next_white_cell(cell, _cell)
			if (
				bounce_cell
				and not bounce_cell.contains_unit()
				# Check that no other action taken yet
				and not previous_action
			):
				# This counts as an action and a move, so use final act
				bounce_cell.highlight(Cell.HighlightLevel.FINAL_ACT)
