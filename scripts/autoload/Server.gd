extends Node

var network := NetworkedMultiplayerENet.new()
var port := 1909
var max_players := 100

func _ready():
	if "--server" in OS.get_cmdline_args():
		OS.window_size = Vector2(640,480)
		StartServer()
	
func StartServer():
	network.create_server(port, max_players)
	get_tree().set_network_peer(network)
	print("Server Started")
	
	network.connect("peer_connected", self, "peer_connected_Callback")
	network.connect("peer_disconnected", self, "peer_disconnected_Callback")
	
func peer_connected_Callback(player_id):
	print("User %d Connected" % [player_id])
	
func peer_disconnected_Callback(player_id):
	print("User %d Disconnected" % [player_id])

remote func s_get_welcome_message(requester, callback_name):
	var player_id : int = get_tree().get_rpc_sender_id()
	var msg := "Welcome to 127.0.0.1!!! and die!"
	Client.rpc_id(player_id, "request_completed", requester, callback_name, msg)
	print("sending welcome message to %d" % [player_id])
