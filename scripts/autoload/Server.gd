extends Node

var network := NetworkedMultiplayerENet.new()
var port := 1909
var max_players := 100
var is_single_player := false
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
	print("player " + str(player) + " loading done")
	player_info[player]["loading"] = false
	waiting_for_player -= 1
	if waiting_for_player == 0:
		print("all player done")
		BehaviorEvents.emit_signal("OnAllPlayerDone")
	

remote func s_start_game():
	print("Server starting launching game")
	get_tree().change_scene("res://scenes/Visuals.tscn")
	Client.rpc("c_change_scene", "res://scenes/Visuals.tscn")
	waiting_for_player = player_info.size()
	for player in player_info:
		player_info[player]["loading"] = true
		
# Maybe networked Object can ask the server for an ID and we use a dictionary so instead of passing a long string of paths we can just use custom IDs
remote func s_update_object(object_path : String, params : Array):
	if has_node(object_path):
		get_node(object_path).client_data_received(params)
		
remote func s_reset():
	var spawn_node : Spatial = get_parent().find_node("SpawnPoints", true, false)
	var objects_in_spawn = spawn_node.get_children()
	var player_idx = 0
	for obj in objects_in_spawn:
		if obj.name == "1" or obj.name == "2":
			continue
		if obj is Player3D:
			var p = obj as Player3D
			obj.transform = (spawn_node.get_child(player_idx) as Spatial).transform
			p.cur_hp = p.max_hp
			p.weapon_cur_energy = p.weapon_max_energy
			p.weapon_recharging = false
			player_idx += 1
		else:
			obj.queue_free()
			
		
#remote func s_update_input(touch : bool, just_released : bool, ui_accept : bool, dir : Vector2, mouse_phi : float):
#	var player_id : int = get_tree().get_rpc_sender_id()
#	var player : Player3D = get_parent().find_node(str(player_id), true, false)
#	player.should_fire = touch
#	player.should_stop_fire = just_released
#	player.ui_accept = ui_accept
#	player.apply_force = Vector3(dir.x, 0.0, dir.y)
#	player.phi = mouse_phi
		
