extends Node

func _on_Button_pressed():
	Server.rpc_id(1, "s_start_game")
