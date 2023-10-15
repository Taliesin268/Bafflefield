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
	
	selected_cell = cell
	
	cell_selected.emit()

# PUBLIC FUNCTIONS
func deselect_cell():
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
	
func spawn_unit(cell_index: int, unit_type: Unit.UnitType, white: bool = false):
	var cell = get_cell(cell_index)
	cell.spawn_unit(unit_type, white)


func remove_highlight_from_cells():
	for cell in get_highlighted_cells():
		cell.highlight(0)

func move_unit():
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

# PRIVATE FUNCTIONS
func _create_board():
	for row in 10:
		for column in 10:
			var cell: Cell = CELL_SCENE.instantiate() as Cell
			cell.row = row
			cell.column = column
			_cells.append(cell)
			add_child(cell)
			
			cell.clicked.connect(_cell_clicked.bind(cell))

