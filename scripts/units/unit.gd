class_name Unit extends Sprite2D
## The base class for other units to extend.

# CONSTANTS
## The shader used to invert the colors of the sprite. (Change Black to White)
const WHITE_SHADER = preload("res://shaders/unit.gdshader")
const WHITE = true
const BLACK = false


# PUBLIC VARIABLES
var defeated: bool = false:
	set(value):
		defeated = value
		_hidden = false
		_update_unit_sprite()
## The color of the unit. See [constant WHITE] and [constant BLACK].
var color: bool:
	set(value):
		color = value
		_update_unit_sprite()
## The [Cell] this unit is on.
var cell: Cell

# PRIVATE VARIABLES
var _visible: bool = true:
	set(value):
		_visible = value
		_update_unit_sprite()
var _hidden: bool = false:
	set(value):
		_hidden = value
		_update_unit_sprite()

## The sprite used for a piece that is unknown to the current player.
var _unknown_sprite := preload("res://assets/units/hidden-piece.png")
## The sprite used when the unit has been defeated
var _defeated_sprite: Resource
## The sprite used when unit is hidden, but visible to current player.
var _hidden_sprite: Resource
## The sprite used when unit is not hidden or defeated.
var _base_sprite: Resource


# PUBLIC FUNCTIONS
func init(_cell: Cell,_color = BLACK):
	_init_sprites()
	color = _color
	cell = _cell
	if color == WHITE:
		material = ShaderMaterial.new()
		material.shader = WHITE_SHADER


## Called when a turn starts for the provided color. Only really used for the 
## [Priest] revive counter.
func on_turn_start(_color: bool) -> void:
	pass


## Called after an action has been performed. Used to convert [Magician] into
## [Monarch].
func on_action_performed(_board: Board) -> void:
	pass


## Sets the [member _hidden] property to false. Reveals the unit without 
## shadowing [member Sprite2D.hidden] or directly accessing private var 
## [member _hidden].
func reveal():
	_hidden = false


## Sets the [member _hidden] property to true. Hides the unit without shadowing
## in-built [method CanvasItem.hide], shadowing [member Sprite2D.hidden] or
## directly accessing private var [member _hidden].
func hide_unit():
	_hidden = true


## Sets [member _visible] based on the provided [enum Board.BoardVisibility].
func update_visibility(visibility: Board.BoardVisibility):
	match visibility:
		Board.BoardVisibility.ALL: _visible = true
		Board.BoardVisibility.WHITE: _visible = color == WHITE
		Board.BoardVisibility.BLACK: _visible = color == BLACK
		Board.BoardVisibility.NONE: _visible = false


## Checks if this unit can move based on the provided previous [GameAction].
func can_move(previous_action: GameAction) -> bool:
	return not defeated and (
		previous_action == null
		or not (previous_action.was_unit(self) and previous_action.was_move())
	)


## Checks if the unit can use their ability based on the provided previous 
## [GameAction].
func can_act(previous_action: GameAction) -> bool:
	return not defeated and (
		previous_action == null
		or not (previous_action.was_unit(self) and previous_action.was_ability())
	)


## Highlights all [Cell]s this unit can act upon or move to.
func highlight_cells(board: Board, previous_action: GameAction) -> void:
	if can_move(previous_action):
		_highlight_movement_cells(board, previous_action)
	if can_act(previous_action):
		_highlight_action_cells(board, previous_action)


# PRIVATE FUNCTIONS
## Highlights all [Cell]s this unit can move to.
func _highlight_movement_cells(board: Board, previous_action: GameAction) -> void:
	for _cell in board.get_cells_in_range(cell):
		# If the cell is an empty, white cell, highlight it.
		if not _cell.contains_unit() and not _cell.is_black():
			if previous_action:
				_cell.highlight(Cell.HighlightLevel.FINAL_MOVE)
			else:
				_cell.highlight(Cell.HighlightLevel.MOVE)


## Highlights all [Cell]s this unit can act upon.
@warning_ignore("unused_parameter")
func _highlight_action_cells(board: Board, previous_action: GameAction) -> void:
	pass


## Returns true if the provided unit is a living enemy of this unit.
func is_living_enemy(unit: Unit) -> bool:
	return unit.color != color and not unit.defeated


## Sets the sprites based on the unit type. Uses [method _get_unit_type_name]
## to dynamically get the file paths.
func _init_sprites():
	_base_sprite = load(
		"res://assets/units/{unit}/{unit}.png".format(
					{"unit": _get_unit_type_name()}
			)
	)
	_hidden_sprite = load(
		"res://assets/units/{unit}/{unit}-hidden.png".format(
					{"unit": _get_unit_type_name()}
			)
	)
	_defeated_sprite = load(
			"res://assets/units/{unit}/{unit}-defeated.png".format(
					{"unit": _get_unit_type_name()}
			)
	)


## Updates the sprite based on the current status.
func _update_unit_sprite():
	if defeated:
		texture = _defeated_sprite
	elif _hidden:
		if _visible:
			texture = _hidden_sprite
		else:
			texture = _unknown_sprite
	else:
		texture = _base_sprite


## To be overidden by children for the sake of identify asset names.
func _get_unit_type_name() -> String:
	return "unit"


## Gets the [PackedScene] that contains a unit with this script.
static func get_scene() -> PackedScene:
	return load("res://scenes/units/unit.tscn")
