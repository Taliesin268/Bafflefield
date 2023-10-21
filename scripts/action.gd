class_name GameAction
## A structure for storing the relevant information about a previous action.

var _unit: Unit
var _ability: bool # True if ability, false if move
var _from: Cell
var _to: Cell


func _init(unit: Unit, from: Cell, to: Cell, ability: bool = false):
	_unit = unit
	_from = from
	_to = to
	_ability = ability


## Returns true if this action was a move action.
func was_move() -> bool:
	return not _ability


## Returns true if this action was an ability.
func was_ability() -> bool:
	return _ability


## Checks if the supplied unit is the one that performed this action.
func was_unit(unit: Unit) -> bool:
	return _unit == unit


func get_target() -> Cell:
	return _to
	
func get_source() -> Cell:
	return _from
