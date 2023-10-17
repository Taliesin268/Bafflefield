extends Control
class_name Lobby

const HOTSEAT = preload("res://scenes/bafflefield.tscn")
const PORT = 50268

@onready var buttons := $Buttons as Control

@onready var join_server_control := $JoinServer as Control
@onready var provided_ip := $JoinServer/ProvidedIP as LineEdit
@onready var join_button := $JoinServer/Join as Button

@onready var server := $Server as Control
@onready var server_ip := $Server/ServerIP as Label

func _ready():
	multiplayer.peer_connected.connect(on_peer_connected)


func _on_hot_seat_pressed():
	get_tree().change_scene_to_packed(HOTSEAT)


func _on_join_server_pressed():
	buttons.visible = false
	join_server_control.visible = true


func _on_back_button_pressed():
	buttons.visible = true
	join_server_control.visible = false
	server.visible = false


func _on_create_server_pressed():
	buttons.visible = false
	server.visible = true
	server_ip.text = "Running local server"
	create_server()


static func is_valid_ip_address(ip_string: String) -> bool:
	var parts = ip_string.split(".")
	
	if parts.size() != 4:
		return false

	for part in parts:
		var num = int(part)
		if not part.is_valid_int() or num < 0 or num > 255:
			return false

	return true

func join_server(ip: String):
	var peer = ENetMultiplayerPeer.new()
	peer.create_client(ip, PORT)
	multiplayer.multiplayer_peer = peer

func create_server():
	var peer = ENetMultiplayerPeer.new()
	peer.create_server(PORT, 2)
	multiplayer.multiplayer_peer = peer

func _on_provided_ip_text_changed(new_text):
	join_button.disabled = not Lobby.is_valid_ip_address(new_text)


func _on_join_pressed():
	server_ip.text = "Server IP: %s" % provided_ip.text
	join_server_control.visible = false
	server.visible = true
	join_server(provided_ip.text)

func on_peer_connected(id: int):
	print("peer connected %s" % id)
