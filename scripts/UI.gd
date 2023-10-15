class_name UI extends Control

# ON-READY VARIABLES
@onready var button := $Button as Button
@onready var textContainer := $TextScroller/TextContainer as VBoxContainer
@onready var textScroller := $TextScroller as ScrollContainer

## Adds a message to the message pane, and scrolls to the bottom of the pane.
func print_message(message: String):
	# Add a new label object to the textbox
	var label = Label.new()
	label.text = message
	label.autowrap_mode = TextServer.AUTOWRAP_WORD
	textContainer.add_child(label)
	
	# Scroll to the bottom of the scrollbar
	@warning_ignore("narrowing_conversion")
	textScroller.scroll_vertical = textScroller.get_v_scroll_bar().max_value


## Sets the text of the button, and the "pressed" signal
func set_button(text: String, callable: Callable):
	if not button.pressed.is_connected(callable):
		button.pressed.connect(callable)
	button.text = text
	button.disabled = false


## Disabled the button and disconnects "pressed" signals.
func disable_button():
	for conn in button.pressed.get_connections():
		button.pressed.disconnect(conn.callable)
	button.text = ""
	button.disabled = true
