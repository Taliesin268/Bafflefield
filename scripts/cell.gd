class_name Cell extends Area2D
## A cell in the game board.

# SIGNALS
## Fired when a cell is selected.
signal clicked()

# ENUMS
## Text definitions for the different highlight integers.
enum HighlightLevel {NONE,MOVE,ACT,FINAL_ACT,FINAL_MOVE}

# CONSTANTS
## Each of the highlight colors by index. See [enum HighlightLevel]
const HIGHLIGHT_COLORS: Array[Color] = [
	Color.WHITE, #0. Not highlighted - base color
	Color("#0000FF"), # 1. Blue (Move Action)
	Color("#FFA500"), # 2. Orange (Action)
	Color("#FF0000"), # 3. Red (Turn Ending Action)
	Color("#800080") # 4. Purple (Turn Ending Move)
]
## The color of a selected cell.
const SELECTED_COLOR := Color("#00FF00BB")

# EXPORT VARS
## The scene to use for units
@export var unit_scene: PackedScene

# PUBLIC VARS
var row: int = 0
var column: int = 0
## A reference to the unit on this cell.
var unit: Unit:
	set(value):
		if value == null && unit != null:
			remove_child(unit)
			remove_from_group("contains_unit")
		elif value != null:
			add_child(value)
			add_to_group("contains_unit")
		unit = value
## A computed property to get the index based on the row and column.
var index: int:
	get:
		return Cell.convert_pos_to_index(row, column)
## What level of highlight this cell has. See the [enum HighlightLevel] enum.
var highlight_level := 0:
	set(value):
		if value == 0:
			remove_from_group("is_highlighted")
		else:
			add_to_group("is_highlighted")
		highlight_level = value
		_update_color()
## True if this cell has the mouse hovering over it. Only used for display.
var hovered := false:
	set(value):
		hovered = value
		_update_color()
## Whether this cell should have the selection color.
var selected := false:
	set(value):
		selected = value
		_update_color()


# BUILT-IN FUNCTIONS
func _ready():
	# Set the color scheme based on the index of the cell
	_update_color()
	
	# Adjust the position based on the index
	position.x += column*100
	position.y += row*100


# CONNECTED SIGNALS
func _on_input_event(_viewport, event, _shape_idx):
	# If the cell is clicked, call select()
	if event is InputEventMouseButton && event.pressed:
		select()


func _on_mouse_entered():
	hovered = true


func _on_mouse_exited():
	hovered = false


# PUBLIC FUNCTIONS
## Selects this cell by coloring it, and emitting the [signal clicked] signal.
func select():
	selected = true
	clicked.emit()


## Removes the selection color from this cell (but doesn't emit anything).
func deselect():
	selected = false


## Creates a brand new [Unit] in this cell.
func spawn_unit(unit_type: Unit.UnitType, color):
	var new_unit: Unit = unit_scene.instantiate()
	new_unit.init(unit_type, color)
	unit = new_unit


## Highlights this cell by the provided level. See [enum HighlightLevel].
func highlight(level: int = 1):
	highlight_level = level


## Returns true if this cell contains a [Unit].
func contains_unit() -> bool:
	return unit != null


## Returns true if this cell is black.
func is_black() -> bool:
	return (row + column) % 2 == 0


# Returns true if this cell is highlighted.
func is_highlighted() -> bool:
	return highlight_level > 0

func get_movement_range() -> Array[int]:
	var valid_cell_indexes: Array[int] = []
	
	if Cell.is_valid_pos(row - 2, column): 
		valid_cell_indexes.append(Cell.convert_pos_to_index(row - 2, column))
	if Cell.is_valid_pos(row + 2, column): 
		valid_cell_indexes.append(Cell.convert_pos_to_index(row + 2, column))
	if Cell.is_valid_pos(row, column - 2): 
		valid_cell_indexes.append(Cell.convert_pos_to_index(row, column - 2))
	if Cell.is_valid_pos(row, column + 2): 
		valid_cell_indexes.append(Cell.convert_pos_to_index(row, column + 2))
	
	valid_cell_indexes.append_array(get_diagonal_squares())
	
	return valid_cell_indexes

func get_adjacent_black_cells() -> Array[int]:
	var valid_cell_indexes: Array[int] = []
	
	if Cell.is_valid_pos(row - 1, column): 
		valid_cell_indexes.append(Cell.convert_pos_to_index(row - 1, column))
	if Cell.is_valid_pos(row + 1, column): 
		valid_cell_indexes.append(Cell.convert_pos_to_index(row + 1, column))
	if Cell.is_valid_pos(row, column - 1): 
		valid_cell_indexes.append(Cell.convert_pos_to_index(row, column - 1))
	if Cell.is_valid_pos(row, column + 1): 
		valid_cell_indexes.append(Cell.convert_pos_to_index(row, column + 1))
	
	return valid_cell_indexes

func get_adjacent_cells() -> Array[int]:
	var touching_squares = get_adjacent_black_cells()
	touching_squares.append_array(get_diagonal_squares())
	return touching_squares

func get_diagonal_squares() -> Array[int]:
	var valid_cell_indexes: Array[int] = []
	
	if Cell.is_valid_pos(row - 1, column - 1): 
		valid_cell_indexes.append(Cell.convert_pos_to_index(row - 1, column - 1))
	if Cell.is_valid_pos(row - 1, column + 1): 
		valid_cell_indexes.append(Cell.convert_pos_to_index(row - 1, column + 1))
	if Cell.is_valid_pos(row + 1, column - 1): 
		valid_cell_indexes.append(Cell.convert_pos_to_index(row + 1, column - 1))
	if Cell.is_valid_pos(row + 1, column + 1): 
		valid_cell_indexes.append(Cell.convert_pos_to_index(row + 1, column + 1))
	
	return valid_cell_indexes


## Converts a row and column into an index.
static func convert_pos_to_index(row: int, column: int) -> int:
	return row * 10 + column

static func is_valid_pos(_row: int, _column: int) -> bool:
	return _row >= 0 and _row < 10 and _column >= 0 && _column < 10

# PRIVATE FUNCTIONS
func _update_color():
	var new_color := HIGHLIGHT_COLORS[highlight_level]
	
	if selected:
		new_color = new_color.blend(SELECTED_COLOR)
	
	if is_black():
		new_color = new_color.darkened(0.75)
	
	if hovered:
		new_color = new_color.darkened(0.4)
		
	$Sprite2D.modulate = new_color
