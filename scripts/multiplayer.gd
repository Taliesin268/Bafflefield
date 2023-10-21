class_name Multiplayer extends Node

# CONSTANTS
const PORT = 50268
const BAFFLEFIELD_SCENE = preload("res://scenes/bafflefield.tscn")
const WHITE = true
const BLACK = false

# PUBLIC VARIABLES
var players: Dictionary = {}
var color: bool

# PUBLIC FUNCTIONS
func host_multiplayer_server(as_player := true) -> Error:
	print("Starting Server")
	var peer = ENetMultiplayerPeer.new()
	var error = peer.create_server(PORT, 1 if as_player else 2)
	multiplayer.multiplayer_peer = peer
	if as_player:
		players[multiplayer.get_unique_id()] = null
		
	multiplayer.peer_connected.connect(_on_peer_connected)
	multiplayer.peer_disconnected.connect(_on_peer_disconnected)
	
	return error

func join_server(ip: String) -> Error:
	print("Joining Server: %s" % ip)
	var peer = ENetMultiplayerPeer.new()
	var error = peer.create_client(ip, PORT)
	multiplayer.multiplayer_peer = peer

	return error

func is_server() -> bool:
	return multiplayer.get_unique_id() == 1
	
func is_player() -> bool:
	return multiplayer.get_unique_id() in players

func is_server_full() -> bool:
	if not is_server():
		return false
	return players.size() == (2 if is_player() else 3)

func trigger_start_game():
	print("Starting game")
	# Get the players IDs, and randomise their order.
	var player_ids = players.keys()
	player_ids.shuffle()
	
	# Set the first player to white and start their game.
	players[player_ids[0]] = WHITE
	start_game.rpc_id(player_ids[0], WHITE)
	
	# Set the second player to black and start their game.
	players[player_ids[1]] = BLACK
	start_game.rpc_id(player_ids[1], BLACK)

@rpc("authority","call_local","reliable")
func start_game(_color: bool):
	for child in get_children():
		child.queue_free()
	
	color = _color
	
	add_child(BAFFLEFIELD_SCENE.instantiate())

# PRIVATE FUNCTIONS
func _on_peer_connected(id: int):
	players[id] = null
	print("Player %s just connected to the server" % id)
	print("The current playerlist is now %s" % JSON.stringify(players))

func _on_peer_disconnected(id: int):
	print("Player %s just disconnected from the server" % id)
	players.erase(id)
	print("The current playerlist is now %s" % JSON.stringify(players))
