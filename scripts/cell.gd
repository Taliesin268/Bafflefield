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


## Returns true if this cell is highlighted.
func is_highlighted() -> bool:
	return highlight_level > 0


## Converts a row and column into an index.
static func convert_pos_to_index(row: int, column: int) -> int:
	return row * 10 + column


# PRIVATE FUNCTIONS
## Updates the sprite for this cell based on its state.
func _update_color():
	# Set the base color based on the highlight level
	var new_color := HIGHLIGHT_COLORS[highlight_level]
	
	# Add in the selected color (so something can be highlighted and selected)
	if selected:
		new_color = new_color.blend(SELECTED_COLOR)
	
	# Severely darken all black squares
	if is_black():
		new_color = new_color.darkened(0.75)
	
	# Slightly darken hovered squares
	if hovered:
		new_color = new_color.darkened(0.4)
		
	$Sprite2D.modulate = new_color
