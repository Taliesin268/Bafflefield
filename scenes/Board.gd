extends Node2D
class_name Board

# CONSTANTS
const CELL_SCENE = preload("res://scenes/cell.tscn")

# PRIVATE VARIABLES
var _cells: Array = []
var _selected_cell: Cell
var _cells_with_units: Array = []
var _highlighted_cells: Array = []

# BUILT-IN FUNCTIONS
func _ready():
	_create_board()

# CONNECTED SIGNALS
func _cell_clicked(cell):
	if _selected_cell != null:
		_selected_cell.set_selected(false)
	
	cell.set_selected(true)
	_selected_cell = cell

# PUBLIC FUNCTIONS
func get_cell(index: int) -> Cell:
	return _cells[index]
	
func spawn_unit(cell_index: int, unit_type: Unit.UnitType, white: bool = false):
	var cell = get_cell(cell_index)
	cell.spawn_unit(unit_type, white)
	_cells_with_units.append(cell)
	
func highlight_cell(index: int):
	var cell = get_cell(index)
	cell.highlight_cell()
	_highlighted_cells.append(cell)

# PRIVATE FUNCTIONS
func _create_board():
	for column in 10:
		for row in 10:
			var cell = CELL_SCENE.instantiate()
			cell.row = row
			cell.column = column
			_cells.append(cell)
			add_child(cell)
			
			cell.clicked.connect(_cell_clicked.bind(cell))
