class_name Multiplayer extends Node

# SIGNALS
signal game_started
signal game_ended(winner: bool)
signal turn_started
signal opponent_acted(source: int, target: int, ability: bool)

# CONSTANTS
const PORT = 50268
const BAFFLEFIELD_SCENE = preload("res://scenes/bafflefield.tscn")
const WHITE = true
const BLACK = false

# PUBLIC VARIABLES
var players: Dictionary = {}
var player_characters_selected: Dictionary = {}
var color: bool

var current_turn := WHITE

# PRIVATE VARIABLES
var _context: Bafflefield

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
	return multiplayer.is_server()
	
func is_player() -> bool:
	return multiplayer.get_unique_id() in players

func is_server_full() -> bool:
	if not is_server():
		return false
	return players.size() == (2 if is_player() else 3)

func get_current_player_id() -> int:
	for player in players.keys():
		if players[player] == current_turn:
			return player
	return 1

func get_opposing_player_id() -> int:
	for player in players.keys():
		if players[player] != current_turn:
			return player
	return 1

func trigger_start_game():
	print("Starting game")
	# Copy the playerlist to the characters selected dict before setting colors
	var player_ids = players.keys()
	for player_id in player_ids:
		player_characters_selected[player_id] = false
	
	# Randomise the order and thus the color of the player keys.
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
	
	_context = BAFFLEFIELD_SCENE.instantiate()
	add_child(_context)

@rpc("any_peer","call_local","reliable")
func set_characters_selected(characters: String):
	print("%s just selected their units: %s" % [
			multiplayer.get_remote_sender_id(),
			characters
	])
	player_characters_selected[multiplayer.get_remote_sender_id()] = true
	add_selected_units_to_board.rpc(
			characters,
			players[multiplayer.get_remote_sender_id()]
	)
	if _all_characters_selected():
		start_battle.rpc()

@rpc("authority","call_local","reliable")
func start_battle():
	game_started.emit()
	
@rpc("authority","call_local","reliable")
func add_selected_units_to_board(units_json: String, _color: bool):
	var units = JSON.parse_string(units_json)
	for unit_type in units.keys():
		var unit_class = Unit.get_class_by_unit_type_string(unit_type)
		var unit_scene = unit_class.get_scene()
		var cell = _context.board.get_cell(units[unit_type])
		
		if not cell.contains_unit():
			cell.spawn_unit(unit_scene, _color, true)
			
		_context.board.change_visibility_by_color(color)

@rpc("any_peer","call_local","reliable")
func end_game(winner: bool):
	game_ended.emit(winner)
	
@rpc("any_peer","call_local","reliable")
func end_current_turn():
	if multiplayer.get_remote_sender_id() != get_current_player_id():
		return
		
	current_turn = not current_turn
	trigger_turn_start.rpc_id(get_current_player_id())

@rpc("authority","call_local","reliable")
func trigger_turn_start():
	turn_started.emit()

func process_action(action: GameAction):
	send_action_details.rpc_id(
			1, 
			action.get_source().index,
			action.get_target().index,
			action.was_ability()
	)

@rpc("any_peer","call_local","reliable")
func send_action_details(source: int, target: int, ability: bool):
	handle_opposing_action.rpc_id(get_opposing_player_id(), source, target, ability)

@rpc("authority","call_local","reliable")
func handle_opposing_action(source: int, target: int, ability: bool):
	opponent_acted.emit(source, target, ability)

# PRIVATE FUNCTIONS
func _all_characters_selected():
	for player in player_characters_selected:
		if not player_characters_selected[player]:
			return false
	return true

func _on_peer_connected(id: int):
	players[id] = null
	print("Player %s just connected to the server" % id)
	print("The current playerlist is now %s" % JSON.stringify(players))

func _on_peer_disconnected(id: int):
	print("Player %s just disconnected from the server" % id)
	players.erase(id)
	print("The current playerlist is now %s" % JSON.stringify(players))
