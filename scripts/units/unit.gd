class_name Unit extends Sprite2D

# CONSTANTS
const WHITE_SHADER = preload("res://shaders/unit.gdshader")
const WHITE = true
const BLACK = false

# PUBLIC VARIABLES
var defeated: bool = false:
	set(value):
		defeated = value
		_hidden = false
		_update_unit_sprite()
var color: bool:
	set(value):
		color = value
		_update_unit_sprite()

# PRIVATE VARIABLES
var _visible: bool = true:
	set(value):
		_visible = value
		_update_unit_sprite()
var _hidden: bool = false:
	set(value):
		_hidden = value
		_update_unit_sprite()

var _unknown_sprite := preload("res://assets/units/hidden-piece.png")
var _defeated_sprite: Resource
var _hidden_sprite: Resource
var _base_sprite: Resource

# PUBLIC FUNCTIONS
@warning_ignore("static_called_on_instance")
func init(_color = BLACK):
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
	color = _color
	if color == WHITE:
		material = ShaderMaterial.new()
		material.shader = WHITE_SHADER

func reveal():
	_hidden = false

func hide_unit():
	_hidden = true

func update_visibility(visibility: Board.BoardVisibility):
	match visibility:
		Board.BoardVisibility.ALL: _visible = true
		Board.BoardVisibility.NONE: _visible = false
		Board.BoardVisibility.WHITE: _visible = color == WHITE
		Board.BoardVisibility.BLACK: _visible = color == BLACK

# PRIVATE FUNCTIONS
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
