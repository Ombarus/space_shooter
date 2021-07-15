extends Node

func _ready():
	if not Server.is_server:
		Server.rpc_id(1, "s_loading_done")
		return
	
	if Server.waiting_for_player > 0:
		BehaviorEvents.connect("OnAllPlayerDone", self, "OnAllPlayerDone_Callback")
	else:
		OnAllPlayerDone_Callback()
	

func OnAllPlayerDone_Callback():
	if BehaviorEvents.is_connected("OnAllPlayerDone", self, "OnAllPlayerDone_Callback"):
		BehaviorEvents.disconnect("OnAllPlayerDone", self, "OnAllPlayerDone_Callback")
	var scene = preload("res://scenes/Player3d.tscn")
	var index : int = 0
	var spawn_root : Spatial = get_node("SpawnPoints")
	for player in Server.player_info:
		var n = scene.instance()
		n.name = str(player)
		spawn_root.get_child(index).call_deferred("add_child", n)
		print("server is spawning player %s" % [n.name])
		Client.rpc("c_spawn", "res://scenes/Player3d.tscn", spawn_root.get_child(index).get_path(), player)
		index += 1
