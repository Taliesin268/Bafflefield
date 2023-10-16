extends Node2D
class_name Board

# SIGNALS
signal cell_selected()

# ENUMS
enum BoardVisibility {NONE,BLACK,WHITE,ALL}

# CONSTANTS
const CELL_SCENE = preload("res://scenes/cell.tscn")

# PUBLIC VARIABLES
var board_visibility: BoardVisibility = BoardVisibility.ALL
var selected_cell: Cell:
	set(value):
		previous_cell = selected_cell
		selected_cell = value
var previous_cell: Cell

# SHORTCUT VARIABLES
var selected_unit: Unit:
	get:
		if selected_cell == null:
			return null
		return selected_cell.unit
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
	if selected_cell != null:
		selected_cell.deselect()
		
	if selected_cell == cell:
		selected_cell = null
	else:
		selected_cell = cell
	
	cell_selected.emit()

# PUBLIC FUNCTIONS
func deselect_cell():
	if selected_cell != null:
		selected_cell.deselect()
	selected_cell = null
	previous_cell = null

func get_cells_with_units() -> Array[Cell]:
	var cells: Array[Cell] = []
	cells.assign(get_tree().get_nodes_in_group("contains_unit"))
	return cells

func get_highlighted_cells() -> Array[Cell]:
	var cells: Array[Cell] = []
	cells.assign(get_tree().get_nodes_in_group("is_highlighted"))
	return cells

func get_cells_with_living_units_by_color(color) -> Array[Cell]:
	var arr: Array[Cell] = []
	for cell in get_cells_with_units():
		var unit := cell.unit as Unit
		if color != null and unit._white != color as bool: continue
		if unit.defeated: continue
		arr.append(cell)
	return arr

func get_cell(index: int) -> Cell:
	return _cells[index]


func remove_highlight_from_cells():
	for cell in get_highlighted_cells():
		cell.highlight(0)

func move_unit():
	# Throw an error if either the previous current cell are missing
	assert(
			previous_cell != null and selected_cell != null, 
			"Error: Could not move unit. Previous cell or current cell do not exist."
	)
	
	var unit := previous_unit
	previous_cell.unit = null
	
	selected_cell.unit = unit

func hide_units():
	for cell in get_cells_with_units():
		cell.unit.hide_unit()

func change_visibility(setting: BoardVisibility):
	for cell in get_cells_with_units():
		cell.unit.update_visibility(setting)
		
func change_visibility_by_color(white: bool = false):
	var visibility: BoardVisibility = BoardVisibility.NONE
	
	if white: visibility = BoardVisibility.WHITE
	else: visibility = BoardVisibility.BLACK
	
	for cell in get_cells_with_units():
		cell.unit.update_visibility(visibility)


## Gets all adjacent cells of the opposite color.
func get_inverse_cells(from: Cell) -> Array[Cell]:
	var cells: Array[Cell] = []
	
	cells.append(get_cell_by_pos(from.row + 1, from.column))
	cells.append(get_cell_by_pos(from.row - 1, from.column))
	cells.append(get_cell_by_pos(from.row, from.column + 1))
	cells.append(get_cell_by_pos(from.row, from.column - 1))
	
	return cells


## Gets all diagonal cells of the same color.
func get_diagonal_cells(from: Cell) -> Array[Cell]:
	var cells: Array[Cell] = []
	
	cells.append(get_cell_by_pos(from.row + 1, from.column + 1))
	cells.append(get_cell_by_pos(from.row + 1, from.column - 1))
	cells.append(get_cell_by_pos(from.row - 1, from.column + 1))
	cells.append(get_cell_by_pos(from.row - 1, from.column - 1))
	
	return cells


## Gets all adjacent cells regardless of color.
func get_adjacent_cells(from: Cell) -> Array[Cell]:
	return get_inverse_cells(from) + get_diagonal_cells(from) 


## Gets the next cell of the same color in each cardinal direction.
func get_ranged_cells(from: Cell) -> Array[Cell]:
	var cells: Array[Cell] = []
	
	cells.append(get_cell_by_pos(from.row + 2, from.column))
	cells.append(get_cell_by_pos(from.row - 2, from.column))
	cells.append(get_cell_by_pos(from.row, from.column + 2))
	cells.append(get_cell_by_pos(from.row, from.column - 2))
	
	return cells


## Gets all cells in a unit's range.
func get_cells_in_range(from: Cell) -> Array[Cell]:
	return get_adjacent_cells(from) + get_ranged_cells(from)


## Gets all cells of the same color in a unit's range.
func get_movement_cells(from: Cell) -> Array[Cell]:
	return get_diagonal_cells(from) + get_ranged_cells(from)


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


## Returns the cell in the given position, or null if the position is invalid.
func get_cell_by_pos(row: int, column: int) -> Cell:
	# If position is out of bounds, return null
	if column > 9 or column < 0 or row > 9 or row < 0:
		return null
	
	return get_cell(Cell.convert_pos_to_index(row, column))


# PRIVATE FUNCTIONS
## Creates the game board by instantiating 100 cells.
func _create_board():
	for row in 10:
		for column in 10:
			var cell: Cell = CELL_SCENE.instantiate() as Cell
			cell.row = row
			cell.column = column
			_cells.append(cell)
			add_child(cell)
			
			cell.clicked.connect(_cell_clicked.bind(cell))

