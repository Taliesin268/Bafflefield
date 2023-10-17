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


# PRIVATE FUNCTIONS
## Sets the sprites based on the unit type. Uses [method _get_unit_type_name]
## to dynamically get the file paths.
@warning_ignore("static_called_on_instance")
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
static func _get_unit_type_name() -> String:
	return "unit"
