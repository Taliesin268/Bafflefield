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
		return row*10+column

# PRIVATE VARS
var _colors = {
	CellState.BASE: Color.WHITE,
	CellState.SELECTED: Color.GREEN,
	CellState.HIGHLIGHTED: Color("#FFA500BB")
}
var _states = {
	CellState.HOVERED: false,
	CellState.SELECTED: false,
	CellState.HIGHLIGHTED: false
}

# BUILT-IN FUNCTIONS
func _ready():
	# Set the color scheme based on the index of the cell
	_update_color()
	
	# Adjust the position based on the index
	position.x += row*100
	position.y += column*100

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
	
func highlight_cell(state: bool = true):
	_states[CellState.HIGHLIGHTED] = state
	_update_color()

func contains_unit():
	return unit != null

func is_black() -> bool:
	return (row + column) % 2 == 0

# PRIVATE FUNCTIONS
func _update_color():
	var new_color = _colors[CellState.BASE] as Color
	
	if _states[CellState.SELECTED]:
		new_color = _colors[CellState.SELECTED]
		
	if _states[CellState.HIGHLIGHTED]:
		new_color = new_color.blend(_colors[CellState.HIGHLIGHTED])
	
	if is_black():
		new_color = new_color.darkened(0.75)
	
	if _states[CellState.HOVERED]:
		new_color = new_color.darkened(0.4)
		
	$Sprite2D.modulate = new_color
