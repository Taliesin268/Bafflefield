extends Control

# SIGNALS
signal dialog_complete(dialog_name)
signal dialog_event(event_name)

# PRIVATE VARIABLES
var _dialog
var _current_message = 0
var _dialog_name

# BUILT-IN FUNCTIONS
func _process(delta):
	if $Button/ButtonTimer.is_stopped(): return
	$Button/TimeoutButton.value = $Button/ButtonTimer.time_left

# CONNECTED SIGNALS
func _on_button_pressed():
	if _current_message == _dialog.size():
		_dialog = null
		_current_message = 0
		dialog_complete.emit(_dialog_name)
	progress_dialog()
	
func _on_button_timer_timeout():
	_on_button_pressed()

# PUBLIC FUNCTIONS
func progress_dialog():
	if _dialog == null:
		print_message("...")
		return
	
	print(_dialog[_current_message])
	
	var message = "..."
	if _dialog[_current_message] is String: 
		message = _dialog[_current_message]
		set_button(_get_read_time(message))
		print_message(message)
		_current_message += 1
	else: 
		message = _dialog[_current_message].message
		if _dialog[_current_message].has("timeout") && _dialog[_current_message].timeout == false:
			set_button()
		else:
			set_button(_get_read_time(message))
		
		print_message(message)
		_current_message += 1
		
		if _dialog[_current_message - 1].has("event"):
			dialog_event.emit(_dialog[_current_message - 1].event)

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

func load_dialog(dialog_name: String, progress: bool = true):
	var dialog_file = FileAccess.open(str("res://data/dialog/",dialog_name,".json"), FileAccess.READ)
	var json = JSON.new()
	json.parse(dialog_file.get_as_text())
	_dialog = json.data
	_dialog_name = dialog_name
	if progress:
		progress_dialog()

# PRIVATE FUNCTIONS
func _get_read_time(text: String):
	return float(_get_word_count(text)) / 4

func _get_word_count(text: String):
	var words = text.split(" ",false)
	return words.size()
