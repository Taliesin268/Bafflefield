extends Node2D
class_name Board
## For creating an managing the board of [Cell]s.
##
## Handles all functions that pertain to multiple [Cell]s.

# SIGNALS
## When any [Cell] in the board is selected, this signal is emitted.
signal cell_selected()

# ENUMS
## Whose perspective to show hidden [Unit]s.
enum BoardVisibility {NONE,BLACK,WHITE,ALL}

# CONSTANTS
const CELL_SCENE = preload("res://scenes/cell.tscn")
const WHITE = true
const BLACK = false

# PUBLIC VARIABLES
## The currently selected [Cell].
var selected_cell: Cell:
	set(value):
		previous_cell = selected_cell
		selected_cell = value
## The [Cell] that was selected before the current one.
var previous_cell: Cell

# SHORTCUT VARIABLES
## Shortcut for [member selected_cell].unit.
var selected_unit: Unit:
	get:
		if selected_cell == null:
			return null
		return selected_cell.unit
## Shortcut for [member previous_cell].unit.
var previous_unit: Unit:
	get:
		if previous_cell == null:
			return null
		return previous_cell.unit

# PRIVATE VARIABLES
var _cells: Array[Cell] = []

# BUILT-IN FUNCTIONS
func _ready():
	_create_board()

# CONNECTED SIGNALS
func _cell_clicked(cell: Cell):
	# If there is already a selected cell, deselect it.
	if selected_cell != null:
		selected_cell.deselect()
	
	# If clicking the same cell twice, it stay deselected.
	if selected_cell == cell:
		selected_cell = null
	else:
		selected_cell = cell
	
	cell_selected.emit()

# PUBLIC FUNCTIONS
## Removes the selection from the current [Cell].
func deselect_cell():
	if selected_cell != null:
		selected_cell.deselect()
	selected_cell = null
	previous_cell = null


## Returns all [Cell]s in the "contains_unit" group.
func get_cells_with_units() -> Array[Cell]:
	var cells: Array[Cell] = []
	cells.assign(get_tree().get_nodes_in_group("contains_unit"))
	return cells


## Returns all [Cell]s in the "is_highlighted" group.
func get_highlighted_cells() -> Array[Cell]:
	var cells: Array[Cell] = []
	cells.assign(get_tree().get_nodes_in_group("is_highlighted"))
	return cells


## Returns all [Cell]s that contain a [Unit] of the provided color that is not
## [member Unit.defeated]
func get_cells_with_living_units_by_color(color: bool) -> Array[Cell]:
	var cells: Array[Cell] = []
	for cell in get_cells_with_units():
		var unit := cell.unit as Unit
		if unit.color == color and not unit.defeated: 
			cells.append(cell)
	return cells


## Gets the [Cell] at the provided index. Returns null if invalid index.
func get_cell(index: int) -> Cell:
	if index > 99 or index < 0:
		return null
	return _cells[index]


## Sets all [Cell]s to [enum Cell.HighlightLevel] 0.
func remove_highlight_from_cells():
	for cell in get_highlighted_cells():
		cell.highlight(0)


## Moves the previously selected unit ([member previous_unit]) to the currently
## selected cell ([member selected_cell]).
func move_unit():
	# Throw an error if either the previous current cell are missing
	assert(
			previous_cell != null and selected_cell != null, 
			"Error: Could not move unit. Previous cell or current cell do not exist."
	)
	
	var unit := previous_unit
	previous_cell.unit = null
	
	selected_cell.unit = unit


## Hides all [Unit]s. Used for initialising the game.
func hide_units():
	for cell in get_cells_with_units():
		cell.unit.hide_unit()


## Changes the visibility to the specified [enum BoardVisibility].
func change_visibility(setting: BoardVisibility):
	for cell in get_cells_with_units():
		cell.unit.update_visibility(setting)


## Changes the visibility to the specified color.
func change_visibility_by_color(color: bool = false):
	var visibility: BoardVisibility = BoardVisibility.NONE
	
	if color == WHITE: 
		visibility = BoardVisibility.WHITE
	elif color == BLACK: 
		visibility = BoardVisibility.BLACK
	
	for cell in get_cells_with_units():
		cell.unit.update_visibility(visibility)


## Gets [Cell]s based on the provided list of [Vector2i] offsets
func get_cells_by_offsets(from: Cell, offsets: Array[Vector2i]) -> Array[Cell]:
	var cells: Array[Cell] = []

	for offset in offsets:
		var cell = get_cell_by_pos(from.row + offset.x, from.column + offset.y)
		if cell != null:
			cells.append(cell)
	
	return cells


## Gets all adjacent [Cell]s of the opposite color.
func get_inverse_cells(from: Cell) -> Array[Cell]:
	return get_cells_by_offsets(
		from,
		[Vector2i(1, 0), Vector2i(-1, 0), Vector2i(0, 1), Vector2i(0, -1)]
	)


## Gets all diagonal [Cell]s of the same color.
func get_diagonal_cells(from: Cell) -> Array[Cell]:
	return get_cells_by_offsets(
		from,
		[Vector2i(1, 1), Vector2i(1, -1), Vector2i(-1, 1), Vector2i(-1, -1)]
	)


## Gets the next [Cell] of the same color in each cardinal direction.
func get_ranged_cells(from: Cell) -> Array[Cell]:
	return get_cells_by_offsets(
		from,
		[Vector2i(2, 0), Vector2i(-2, 0), Vector2i(0, 2), Vector2i(0, -2)]
	)


## Gets all adjacent [Cell]s regardless of color.
func get_adjacent_cells(from: Cell) -> Array[Cell]:
	return get_inverse_cells(from) + get_diagonal_cells(from) 


## Gets all [Cell]s in a unit's range.
func get_cells_in_range(from: Cell) -> Array[Cell]:
	return get_adjacent_cells(from) + get_ranged_cells(from)


## Gets all [Cell]s of the same color in a unit's range.
func get_movement_cells(from: Cell) -> Array[Cell]:
	return get_adjacent_cells(from) + get_ranged_cells(from)


## Given two [Cell]s that are in neighbouring white [Cell]s, returns the next white
## [Cell] in sequence.
func get_next_white_cell(first: Cell, second: Cell) -> Cell:
	# Find the direction of the second cell from the first
	var row_direction = second.row - first.row
	var column_direction = second.column - first.column
	
	# Get the row and column one further in the direction of the second cell
	var column = second.column + column_direction
	var row = second.row + row_direction
	
	return get_cell_by_pos(row, column)


## Returns the [Cell] in the given position, or null if the position is invalid.
func get_cell_by_pos(row: int, column: int) -> Cell:
	# If position is out of bounds, return null
	if column > 9 or column < 0 or row > 9 or row < 0:
		return null
	
	return get_cell(Cell.convert_pos_to_index(row, column))


# PRIVATE FUNCTIONS
## Creates the game board by instantiating 100 [Cell]s.
func _create_board():
	for row in 10:
		for column in 10:
			var cell: Cell = CELL_SCENE.instantiate() as Cell
			cell.row = row
			cell.column = column
			_cells.append(cell)
			add_child(cell)
			
			cell.clicked.connect(_cell_clicked.bind(cell))

