extends Control

# PRIVATE VARIABLES
var _dialog
var _current_message = 0

# BUILT-IN FUNCTIONS
func _ready():
	_load_dialog("introduction")

# CONNECTED SIGNALS
func _on_button_pressed():
	pass # Replace with function body.

# PRIVATE FUNCTIONS
func _load_dialog(dialog_name: String):
	var dialog_file = FileAccess.open(str("res://data/dialog/",dialog_name,".json"), FileAccess.READ)
	var json = JSON.new()
	json.parse(dialog_file.get_as_text())
	_dialog = json.data
	
	print(_dialog)

func _get_read_time(text: String):
	return _get_word_count(text) / 4

func _get_word_count(text: String):
	var words = text.split(" ",false)
	return words.size()

