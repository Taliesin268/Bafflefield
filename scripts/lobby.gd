extends Control
class_name Lobby

const HOTSEAT = preload("res://scenes/bafflefield.tscn")

@onready var buttons := $Buttons as Control

@onready var join_server_control := $JoinServer as Control
@onready var provided_ip := $JoinServer/ProvidedIP as LineEdit
@onready var join_button := $JoinServer/Join as Button

@onready var server_section := $Server as Control
@onready var server_status := $Server/Status as Label
@onready var server_ip := $Server/ServerIP as Label
@onready var start_game_button := $Server/Start

@onready var server := get_parent() as Multiplayer

func _process(_delta):
	start_game_button.disabled = not server.is_server_full()
	if server.is_server_full(): 
		server_status.text = "Opponent found!"
	else:
		server_status.text = "Waiting for opponent..."

func _on_start_game():
	server.trigger_start_game()

func _on_hot_seat_pressed():
	get_tree().change_scene_to_packed(HOTSEAT)


func _on_join_server_pressed():
	buttons.visible = false
	join_server_control.visible = true


func _on_back_button_pressed():
	buttons.visible = true
	join_server_control.visible = false
	server_section.visible = false


func _on_create_server_pressed():
	buttons.visible = false
	server_section.visible = true
	server_ip.text = "Running local server"
	server.host_multiplayer_server()


static func is_valid_ip_address(ip_string: String) -> bool:
	var parts = ip_string.split(".")
	
	if parts.size() != 4:
		return false

	for part in parts:
		var num = int(part)
		if not part.is_valid_int() or num < 0 or num > 255:
			return false

	return true

func _on_provided_ip_text_changed(new_text):
	join_button.disabled = not Lobby.is_valid_ip_address(new_text)


func _on_join_pressed():
	server_ip.text = "Server IP: %s" % provided_ip.text
	join_server_control.visible = false
	server_section.visible = true
	server.join_server(provided_ip.text)
