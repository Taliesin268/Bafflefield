extends Area2D

# SIGNALS
signal clicked()

# ENUMS
enum CellState {BASE,SELECTED,HOVERED}

# CONSTANTS
const DARK_COLORS = {
	CellState.BASE: Color.BLACK,
	CellState.SELECTED: Color.DARK_GREEN,
	CellState.HOVERED: Color.DARK_BLUE
}
const LIGHT_COLORS = {
	CellState.BASE: Color.WHITE,
	CellState.SELECTED: Color.GREEN,
	CellState.HOVERED: Color.AQUA
}

# EXPORT VARS
@export var row = 0
@export var column = 0

# PRIVATE VARS
var _colors
var _states = {
	CellState.HOVERED: false,
	CellState.SELECTED: false
}

# BUILT-IN FUNCTIONS
func _ready():
	# Set the color scheme based on the index of the cell
	if (row + column) % 2 == 0:
		_colors = DARK_COLORS
	else:
		_colors = LIGHT_COLORS
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

# PRIVATE FUNCTIONS
func _update_color():
	if _states[CellState.SELECTED]:
		$Sprite2D.modulate = _colors[CellState.SELECTED]
	elif _states[CellState.HOVERED]:
		$Sprite2D.modulate = _colors[CellState.HOVERED]
	else:
		$Sprite2D.modulate = _colors[CellState.BASE]



