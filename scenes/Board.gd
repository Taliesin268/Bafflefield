extends Node2D
class_name Board

# SIGNALS
signal cell_selected(cell: Cell)

# ENUMS
enum BoardVisibility {BLACK,WHITE,ALL,NONE}

# CONSTANTS
const CELL_SCENE = preload("res://scenes/cell.tscn")

# PUBLIC VARIABLES
var board_visibility: BoardVisibility = BoardVisibility.ALL

# PRIVATE VARIABLES
var _cells: Array = []
var _selected_cell: Cell
var _cells_with_units: Array = []
var _highlighted_cells: Array = []

# BUILT-IN FUNCTIONS
func _ready():
	_create_board()

# CONNECTED SIGNALS
func _cell_clicked(cell: Cell):
	cell_selected.emit(cell)
	
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
	
func highlight_cell(index: int, level: int = 1):
	var cell = get_cell(index)
	cell.highlight_cell(level)
	_highlighted_cells.append(cell)

func remove_highlight_from_cells():
	for cell in _highlighted_cells:
		cell.highlight_cell(0)
	_highlighted_cells = []

func move_selected_unit(to: int):
	var unit = _selected_cell.unit
	_selected_cell.unit = null
	_cells_with_units.erase(_selected_cell)
	var cell = get_cell(to)
	cell.unit = unit
	_cells_with_units.append(cell)
	
func remove_leftover_unit():
	for i in 6:
		var cell = get_cell(42+i)
		if cell.contains_unit():
			cell.unit = null
			_cells_with_units.erase(cell)
			return

func hide_units():
	for cell in _cells_with_units:
		cell.unit.hide_unit()

func change_visibility(setting: BoardVisibility):
	for cell in _cells_with_units:
		cell.unit.update_visibility(setting)
		
func change_visibility_by_color(white: bool = false):
	var visibility = BoardVisibility.NONE
	
	if white: visibility = BoardVisibility.WHITE
	else: visibility = BoardVisibility.BLACK
	
	for cell in _cells_with_units:
		cell.unit.update_visibility(visibility)

# PRIVATE FUNCTIONS
func _create_board():
	for row in 10:
		for column in 10:
			var cell = CELL_SCENE.instantiate()
			cell.row = row
			cell.column = column
			_cells.append(cell)
			add_child(cell)
			
			cell.clicked.connect(_cell_clicked.bind(cell))

