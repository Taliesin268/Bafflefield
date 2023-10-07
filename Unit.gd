extends Sprite2D
class_name Unit

# ENUMS
enum UnitType {ARCHER,ASSASSIN,KNIGHT,MAGICIAN,MONARCH,PRIEST}

# PUBLIC VARIABLES
var defeated: bool = false:
	set(value):
		defeated = value
		_update_unit_sprite()

# PRIVATE VARIABLES
var _hidden: bool = false
var _unit_type: UnitType
var _sprite_set: UnitSpriteSet
var _white: bool = false

# PUBLIC FUNCTIONS
func init(unit_type: UnitType, white = false):
	_unit_type = unit_type
	_set_unit_sprite_values()
	_white = white
	_update_unit_sprite()

func reveal():
	_hidden = false
	_update_unit_sprite()

func get_unit_name():
	return UnitType.keys()[_unit_type].to_lower()

# PRIVATE FUNCTIONS
func _update_unit_sprite():
	if _white:
		if defeated:
			texture = _sprite_set.white_defeated_sprite
		elif _hidden:
			texture = _sprite_set.white_hidden_sprite
		else:
			texture = _sprite_set.white_sprite
	else:
		if defeated:
			texture = _sprite_set.defeated_sprite
		elif _hidden:
			texture = _sprite_set.hidden_sprite
		else:
			texture = _sprite_set.base_sprite

func _set_unit_sprite_values():
	_sprite_set = UnitSpriteSet.new()
	var base_path = str("res://assets/units/",get_unit_name(),"/",get_unit_name())
	_sprite_set.base_sprite = load(str(base_path,".png"))
	_sprite_set.white_sprite = load(str(base_path,"-white.png"))
	_sprite_set.hidden_sprite = load(str(base_path,"-hidden.png"))
	_sprite_set.white_hidden_sprite = load(str(base_path,"-hidden-white.png"))
	_sprite_set.defeated_sprite = load(str(base_path,"-defeated.png"))
	_sprite_set.white_defeated_sprite = load(str(base_path,"-defeated-white.png"))

# SUBCLASSES
class UnitSpriteSet:
	var base_sprite
	var white_sprite
	var hidden_sprite
	var white_hidden_sprite
	var defeated_sprite
	var white_defeated_sprite
