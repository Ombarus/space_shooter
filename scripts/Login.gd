extends Node

func _ready():
	BehaviorEvents.connect("OnServerConnected", self, "OnServerConnected_Callback")
	if not Client.debug_local_server:
		get_node("CanvasLayer/CenterContainer/VBoxContainer/IP/Text").text = "heady-goat.auto.playit.gg"
		get_node("CanvasLayer/CenterContainer/VBoxContainer/Port/Text").text = "57050"

func _on_Button_pressed():
	Client.ConnectToServer(get_node("CanvasLayer/CenterContainer/VBoxContainer/IP/Text").text, int(get_node("CanvasLayer/CenterContainer/VBoxContainer/Port/Text").text))

func OnServerConnected_Callback():
	get_tree().change_scene("res://scenes/Launcher.tscn")
