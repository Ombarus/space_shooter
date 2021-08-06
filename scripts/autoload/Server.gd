extends Node

var network := NetworkedMultiplayerENet.new()
var port := 1909
var max_players := 100
var is_single_player := true
var is_server := false
var player_info := {}
var waiting_for_player = 0

func _ready():
	if is_single_player:
		is_server = true
	if "--server" in OS.get_cmdline_args():
		is_server = true
		StartServer()
	
func StartServer():
	network.create_server(port, max_players)
	get_tree().set_network_peer(network)
	print("Server Started")
	
	network.connect("peer_connected", self, "peer_connected_Callback")
	network.connect("peer_disconnected", self, "peer_disconnected_Callback")
	
func peer_connected_Callback(player_id):
	player_info[player_id] = {}
	print("User %d Connected" % [player_id])
	
func peer_disconnected_Callback(player_id):
	player_info.erase(player_id)
	print("User %d Disconnected" % [player_id])

remote func s_get_welcome_message(requester, callback_name):
	var player_id : int = get_tree().get_rpc_sender_id()
	var msg := "Welcome to 127.0.0.1!!! and die!"
	Client.rpc_id(player_id, "request_completed", requester, callback_name, msg)
	print("sending welcome message to %d" % [player_id])
	
remote func s_loading_done():
	var player : int = get_tree().get_rpc_sender_id()
	player_info[player]["loading"] = false
	waiting_for_player -= 1
	if waiting_for_player == 0:
		print("all player done")
		BehaviorEvents.emit_signal("OnAllPlayerDone")
	

remote func s_start_game():
	get_tree().change_scene("res://scenes/Visuals.tscn")
	Client.rpc("c_change_scene", "res://scenes/Visuals.tscn")
	waiting_for_player = player_info.size()
	for player in player_info:
		player_info[player]["loading"] = true
		
remote func s_update_input(touch : bool, ui_accept : bool, dir : Vector2, mouse_phi : float):
	var player_id : int = get_tree().get_rpc_sender_id()
	var player : Player3D = get_parent().find_node(str(player_id), true, false)
	player.should_fire = touch
	player.ui_accept = ui_accept
	player.apply_force = Vector3(dir.x, 0.0, dir.y)
	player.phi = mouse_phi
		
