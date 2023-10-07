extends Node2D

# BUILT-IN FUNCTIONS
func _ready():
	$UI.load_dialog("introduction")

# CONNECTED SIGNALS
func _on_ui_dialog_complete(dialog_name):
	print("Dialog complete: ", dialog_name)
	match dialog_name:
		"introduction": 
			_start_character_select()

func _on_ui_dialog_event(event_name):
	print("Dialog event triggered: ", event_name)

# PRIVATE FUNCTIONS
func _start_character_select():
	$UI.load_dialog("character_select_intro", false)



