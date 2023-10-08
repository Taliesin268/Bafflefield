extends Area2D
class_name Cell

# SIGNALS
signal clicked()

# ENUMS
enum CellState {BASE,SELECTED,HOVERED,HIGHLIGHTED}

# EXPORT VARS
@export var unit_scene: PackedScene

# PUBLIC VARS
var row: int = 0
var column: int = 0
var unit: Unit:
	set(value):
		if value == null && unit != null:
			remove_child(unit)
		else:
			add_child(value)
		unit = value
var index: int:
	get:
		return (row*10)+column

# PRIVATE VARS
var _colors = {
	CellState.BASE: Color.WHITE,
	CellState.SELECTED: Color.GREEN,
	CellState.HIGHLIGHTED: [
		Color("#FFA500BB"), # 1. Orange
		Color("#0000FFBB"), # 2. Blue
		Color('#FF0000BB') # 3. Red
	]
}
var _states = {
	CellState.HOVERED: false,
	CellState.SELECTED: false,
	CellState.HIGHLIGHTED: 0
}

# BUILT-IN FUNCTIONS
func _ready():
	# Set the color scheme based on the index of the cell
	_update_color()
	
	# Adjust the position based on the index
	position.x += column*100
	position.y += row*100

# CONNECTED SIGNALS
func _on_input_event(_viewport, event, _shape_idx):
	if event is InputEventMouseButton && event.pressed:
		clicked.emit()

func _on_mouse_entered():
	_states[CellState.HOVERED] = true
	_update_color()

func _on_mouse_exited():
	_states[CellState.HOVERED] = false
	_update_color()

# PUBLIC FUNCTIONS
func set_selected(selected: bool):
	_states[CellState.SELECTED] = selected
	_update_color()
	
func spawn_unit(unit_type: Unit.UnitType, white = false):
	var new_unit: Unit = unit_scene.instantiate()
	new_unit.init(unit_type, white)
	unit = new_unit
	
func highlight_cell(level: int = 1):
	_states[CellState.HIGHLIGHTED] = level
	_update_color()

func contains_unit():
	return unit != null

func is_black() -> bool:
	return (row + column) % 2 == 0

func is_highlighted() -> bool:
	return _states[CellState.HIGHLIGHTED] > 0

func get_movement_range(include_black: bool = false):
	var valid_cell_indexes = []
	if include_black:
		if is_valid_cell_index(index - 1): valid_cell_indexes.append(index - 1)
		if is_valid_cell_index(index - 10): valid_cell_indexes.append(index - 10)
		if is_valid_cell_index(index + 1): valid_cell_indexes.append(index + 1)
		if is_valid_cell_index(index + 10): valid_cell_indexes.append(index + 10)
	
	if is_valid_cell_index(index - 2): valid_cell_indexes.append(index - 2)
	if is_valid_cell_index(index - 9): valid_cell_indexes.append(index - 9)
	if is_valid_cell_index(index - 11): valid_cell_indexes.append(index - 11)
	if is_valid_cell_index(index - 20): valid_cell_indexes.append(index - 20)
	if is_valid_cell_index(index + 2): valid_cell_indexes.append(index + 2)
	if is_valid_cell_index(index + 9): valid_cell_indexes.append(index + 9)
	if is_valid_cell_index(index + 11): valid_cell_indexes.append(index + 11)
	if is_valid_cell_index(index + 20): valid_cell_indexes.append(index + 20)
	
	return valid_cell_indexes
	
static func is_valid_cell_index(cell_index: int):
	return cell_index >= 0 && cell_index < 100

# PRIVATE FUNCTIONS
func _update_color():
	var new_color = _colors[CellState.BASE] as Color
	
	if _states[CellState.SELECTED]:
		new_color = _colors[CellState.SELECTED]
		
	if is_highlighted():
		new_color = new_color.blend(_colors[CellState.HIGHLIGHTED][_states[CellState.HIGHLIGHTED]-1])
	
	if is_black():
		new_color = new_color.darkened(0.75)
	
	if _states[CellState.HOVERED]:
		new_color = new_color.darkened(0.4)
		
	$Sprite2D.modulate = new_color
