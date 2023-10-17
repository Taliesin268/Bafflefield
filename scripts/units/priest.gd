class_name Priest extends Unit

# CONSTANTS

## If is 0 or less, can revive. Set to 2 on reviving.
var revive_counter := 0

# PUBLIC FUNCTIONS
## Gets the [PackedScene] that contains a unit with this script.
static func get_scene() -> PackedScene:
	return load("res://scenes/units/priest.tscn")


## Decrements the revive counter. Called when a turn starts.
func on_turn_start(_color: bool) -> void:
	if _color == color:
		revive_counter -= 1


# PRIVATE FUNCTIONS
func _get_unit_type_name() -> String:
	return "priest"


## Whether the provided [Unit] can be revived by this priest at this moment.
func _can_be_revived(unit: Unit) -> bool:
	return unit.color == color and unit.defeated and revive_counter <= 0


## Highlights all [Cell]s this unit can act upon.
func _highlight_action_cells(board: Board, previous_action: GameAction) -> void:
	# Highlight all dead, friendly units in range if revive is available
	for _cell in board.get_movement_cells(cell):
		if _cell.contains_unit() and _can_be_revived(_cell.unit):
			_cell.highlight_based_on_action(previous_action)
