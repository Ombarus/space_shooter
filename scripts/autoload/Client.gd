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
	if not is_server:
		BehaviorEvents.connect("OnServerConnected", self, "OnServerConnected_Callback")
	if not is_server and not is_debug_client:
		if debug_local_server:
			debug_server_pid = OS.execute(OS.get_executable_path(), ["--server", "res://scenes/Server.tscn"], false)
			yield(get_tree().create_timer(4.0), "timeout")
		if debug_second_player and not "no_debug_player" in OS.get_cmdline_args():
			debug_client_pid = OS.execute(OS.get_executable_path(), ["no_debug_player"], false)
	if is_debug_client:
		OS.set_window_title("no_debug_player")
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

remote func request_completed(requester : int, callback_name : String, param):
	instance_from_id(requester).call(callback_name, param)
	
func OnServerConnected_Callback():
	get_welcome_message(get_instance_id(), "DisplayWelcomMessage_Callback")
	
func DisplayWelcomMessage_Callback(msg):
	print(msg)
