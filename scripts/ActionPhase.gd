extends Spatial

func _ready():
	if not Server.is_server:
		Server.rpc_id(1, "s_loading_done")
		return
	
	# server doesn't need to have any visuals
	if not Server.is_single_player:
		visible = false
	
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
		var n : Spatial = scene.instance()
		n.name = str(player)
		n.global_transform = (spawn_root.get_child(index) as Spatial).global_transform
		if index == 0:
			n.cur_weapon = n.larpa
			n.weapon_recharge_rate = 60.0
		else:
			n.cur_weapon = n.laser
			n.weapon_recharge_rate = 40.0
		spawn_root.call_deferred("add_child", n)
		print("server is spawning player %s" % [n.name])
		Client.rpc("c_spawn", "res://scenes/Player3d.tscn", n.transform, player, spawn_root.get_path())
		index += 1
