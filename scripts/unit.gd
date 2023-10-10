class_name Unit
extends Sprite2D

# ENUMS
enum UnitType {ARCHER,ASSASSIN,KNIGHT,MAGICIAN,MONARCH,PRIEST}

# PUBLIC VARIABLES
var defeated: bool = false:
	set(value):
		defeated = value
		_hidden = false
		_update_unit_sprite()
var unit_type_name: String:
	get:
		return UnitType.keys()[_unit_type]


# PRIVATE VARIABLES
var _visible: bool = true
var _hidden: bool = false
var _unit_type: UnitType
var _sprite_set: UnitSpriteSet
var _white: bool = false

# PUBLIC FUNCTIONS
func init(unit_type: UnitType, white = false):
	_unit_type = unit_type
	_white = white
	_set_unit_sprite_values()
	_update_unit_sprite()

func reveal():
	_hidden = false
	_update_unit_sprite()

func hide_unit():
	_hidden = true
	_update_unit_sprite()

func update_visibility(visibility: Board.BoardVisibility):
	match visibility:
		Board.BoardVisibility.ALL: _visible = true
		Board.BoardVisibility.NONE: _visible = false
		Board.BoardVisibility.WHITE:
			if _white: _visible = true
			else: _visible = false
		Board.BoardVisibility.BLACK:
			if _white: _visible = false
			else: _visible = true
	_update_unit_sprite()

func get_unit_name():
	return UnitType.keys()[_unit_type].to_lower()

# PRIVATE FUNCTIONS
func _update_unit_sprite():
	if defeated:
		texture = _sprite_set.defeated_sprite
	elif _hidden:
		if _visible:
			texture = _sprite_set.hidden_sprite
		else:
			texture = _sprite_set.unknown_sprite
	else:
		texture = _sprite_set.base_sprite

func _set_unit_sprite_values():
	_sprite_set = UnitSpriteSet.new() as UnitSpriteSet
	var ending = ".png"
	if _white:
		ending = "-white.png"
	var base_path = str("res://assets/units/",get_unit_name(),"/",get_unit_name())
	_sprite_set.base_sprite = load(str(base_path,ending))
	_sprite_set.hidden_sprite = load(str(base_path,"-hidden",ending))
	_sprite_set.defeated_sprite = load(str(base_path,"-defeated",ending))
	_sprite_set.unknown_sprite = load(str("res://assets/units/hidden-piece",ending))

# SUBCLASSES
class UnitSpriteSet:
	var base_sprite
	var hidden_sprite
	var defeated_sprite
	var unknown_sprite
