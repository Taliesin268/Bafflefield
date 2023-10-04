extends Node2D

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
	print("Clicked (",cell.row,",",cell.column,")")
	if _selected_cell != null:
		_selected_cell.set_selected(false)
	
	cell.set_selected(true)
	_selected_cell = cell

# PRIVATE FUNCTIONS
func _create_board():
	for row in 10:
		for column in 10:
			var cell = CELL_SCENE.instantiate()
			cell.row = row
			cell.column = column
			_cells.append(cell)
			$Board.add_child(cell)
			
			cell.clicked.connect(_cell_clicked.bind(cell))
