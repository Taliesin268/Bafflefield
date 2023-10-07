extends Node2D
class_name Board

# CONSTANTS
const CELL_SCENE = preload("res://scenes/cell.tscn")

# PRIVATE VARIABLES
var _cells = []
var _selected_cell

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
