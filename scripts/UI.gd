extends Control

# PRIVATE VARIABLES
var _dialog
var _current_message = 0

# BUILT-IN FUNCTIONS
func _ready():
	_load_dialog("introduction")
	progress_dialog()
	
func _process(delta):
	if $Button/ButtonTimer.is_stopped(): return
	$Button/TimeoutButton.value = $Button/ButtonTimer.time_left

# CONNECTED SIGNALS
func _on_button_pressed():
	progress_dialog()
	
func _on_button_timer_timeout():
	_on_button_pressed()

# PUBLIC FUNCTIONS
func progress_dialog():
	if _dialog == null:
		print_message("...")
		return
	
	var message = "..."
	if _dialog[_current_message] is String: 
		message = _dialog[_current_message]
		set_button(_get_read_time(message))
	else: 
		message = _dialog[_current_message].message
		set_button()
	print_message(message)
	
	_current_message += 1
	
	if _current_message == _dialog.size():
		_dialog = null
		_current_message = 0
	
func print_message(message: String):
	var label = Label.new()
	label.text = message
	label.autowrap_mode = TextServer.AUTOWRAP_WORD
	$TextScroller/TextContainer.add_child(label)
	
func set_button(timeout: float = 0, text: String = "Continue", enabled: bool = true):
	$Button/TimeoutButton.max_value = timeout
	if timeout != 0:
		$Button/ButtonTimer.start(timeout)
	else:
		$Button/ButtonTimer.stop()
		$Button/TimeoutButton.value = 0
	$Button/ButtonLabel.text = text
	$Button.disabled = !enabled

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
