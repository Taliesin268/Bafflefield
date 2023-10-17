class_name Archer extends Unit

## Gets the [PackedScene] that contains a unit with this script.
static func get_scene() -> PackedScene:
	return load("res://scenes/units/archer.tscn")

func _get_unit_type_name() -> String:
	return "archer"


## Checks if the unit can use their ability based on the provided previous 
## [GameAction].
func can_move(previous_action: GameAction) -> bool:
	# An archer can't move after attacking
	return not previous_action or (
			super.can_move(previous_action)
			and not previous_action.was_unit(self)
	)


## Checks if the unit can use their ability based on the provided previous 
## [GameAction].
func can_act(previous_action: GameAction) -> bool:
	return not previous_action or (
			super.can_act(previous_action)
			and not previous_action.was_unit(self)
	)


## Highlights all [Cell]s this unit can act upon.
func _highlight_action_cells(board: Board, previous_action: GameAction) -> void:
	for _cell in board.get_cells_in_range(cell):
		if _cell.unit and is_living_enemy(_cell.unit):
			_cell.highlight_based_on_action(previous_action)
