extends Node

var network := NetworkedMultiplayerENet.new()
var ip := "127.0.0.1"
var port := 1909

var debug_local_server := true
var debug_server_pid = -1
var debug_second_player := true
var debug_client_pid = -1

func _ready():
	var is_server : bool = "--server" in OS.get_cmdline_args()
	var is_debug_client : bool = "no_debug_player" in OS.get_cmdline_args()
	
	if is_debug_client:
		OS.window_size = Vector2(640,480)
		OS.window_position = Vector2(1900,5)
		OS.set_window_title("Debug Client #2 : Space Liero")
	if is_server:
		OS.window_size = Vector2(640,480)
		OS.window_position = Vector2(1900,800)
		OS.set_window_title("Server : Space Liero")
	if not is_server and not is_debug_client:
		OS.window_position = Vector2(0,0)
	
	if not is_server:
		BehaviorEvents.connect("OnServerConnected", self, "OnServerConnected_Callback")
	if not is_server and not is_debug_client:
		if debug_local_server:
			debug_server_pid = OS.execute(OS.get_executable_path(), ["--server", "res://scenes/Server.tscn"], false)
			yield(get_tree().create_timer(2.0), "timeout")
		if debug_second_player and not "no_debug_player" in OS.get_cmdline_args():
			debug_client_pid = OS.execute(OS.get_executable_path(), ["no_debug_player"], false)
	if not is_server:
		ConnectToServer()
	
func _exit_tree():
	if debug_server_pid >= 0:
		OS.kill(debug_server_pid)
		debug_server_pid = -1
	if debug_client_pid >= 0:
		OS.kill(debug_client_pid)
		debug_client_pid = -1
	
func ConnectToServer():
	network.create_client(ip, port)
	get_tree().set_network_peer(network)
	
	network.connect("connection_failed", self, "connection_failed_Callback")
	network.connect("connection_succeeded", self, "connection_succeeded_Callback")
	print("Client Started")
	
func connection_failed_Callback():
	print("Failed to Connect")
	
func connection_succeeded_Callback():
	print("Successfully Connected")
	BehaviorEvents.emit_signal("OnServerConnected")

func get_welcome_message(requester : int, callback_name : String):
	Server.rpc_id(1, "s_get_welcome_message", requester, callback_name)
	
func OnServerConnected_Callback():
	get_welcome_message(get_instance_id(), "DisplayWelcomMessage_Callback")
	
func DisplayWelcomMessage_Callback(msg):
	print(msg)

remote func request_completed(requester : int, callback_name : String, param):
	instance_from_id(requester).call(callback_name, param)
	
remote func c_change_scene(scene):
	if Server.is_server:
		return
		
	get_tree().change_scene(scene)

remote func c_spawn(scene, transform, name, parent):
	var n : Spatial = load(scene).instance()
	n.name = str(name)
	print("add child " + n.name + " to " + parent)
	call_deferred("spawn_finalize", n, get_node(parent), transform)
	
func spawn_finalize(n : Spatial, r : Node, t : Transform):
	r.add_child(n)
	n.transform = t
	
remote func c_update_object(object_path : String, params : Array):
	if has_node(object_path):
		get_node(object_path).server_data_received(params)
	
#remote func c_udpate_player(player_ref : String, t : Transform, fired : bool, stopped : bool):
#	var player : Player3D = get_parent().find_node(player_ref, true, false)
#	if player != null:
#		player.transform = t
#		#if fired:
#		#	player.fire(get_process_delta_time())
#		if stopped:
#			player.stop_fire()
