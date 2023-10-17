class_name Assassin extends Unit

## Gets the [PackedScene] that contains a unit with this script.
static func get_scene() -> PackedScene:
	return load("res://scenes/units/assassin.tscn")


func _get_unit_type_name() -> String:
	return "assassin"


## Highlights all [Cell]s this unit can act upon.
func _highlight_action_cells(board: Board, previous_action: GameAction) -> void:
	# Highlight all black cells in range
	for _cell in board.get_cells_in_range(cell):
		if _cell.is_black() and not _cell.contains_unit():
			_cell.highlight_based_on_action(previous_action)
			
	# If on a black cell, cannot attack, so skip next section
	if cell.is_black():
		return
	
	# Highlight all diagonal enemy units
	for _cell in board.get_diagonal_cells(cell):
		if _cell.unit and is_living_enemy(_cell.unit):
			_cell.highlight_based_on_action(previous_action)
