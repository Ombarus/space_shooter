extends Node

func _ready():
	BehaviorEvents.connect("PlayerInfoChanged", self, "PlayerInfoChanged_Callback")

func _on_Button_pressed():
	Server.rpc_id(1, "s_start_game")

func PlayerInfoChanged_Callback():
	var txt := "Server Status: [color=lime]Online[/color]\n"
	txt += "Connected Players : " + str(Server.player_info.size()) + " / 4\n"
	for player in Server.player_info:
		txt += str(player) + ": " + str(Server.player_info[player]) + "\n"
		
	get_node("CanvasLayer/HBoxContainer/VBoxContainer/RichTextLabel").bbcode_text = txt
