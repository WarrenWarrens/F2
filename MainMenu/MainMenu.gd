extends Node2D

var level: int = 1
@onready var music_slider = $Background/CenterContainer



#func _ready() -> void:
	#$CenterContainer/SettingsMenu/Fullscreen.button_pressed = true if DisplayServer.window_get_mode() == DisplayServer.WINDOW_MODE_EXCLUSIVE_FULLSCREEN else false

func _on_play_pressed() -> void:
	$Background/CenterContainer/MenuButtons.visible = false
	$Background/CenterContainer/LevelsMenu.visible = true

func _on_options_pressed() -> void:
	$Background/CenterContainer/MenuButtons.visible = false
	$Background/CenterContainer/SettingsMenu.visible = true

func _on_credits_pressed() -> void:
	$Background/CenterContainer/MenuButtons.visible = false
	$Background/CenterContainer/CreditsMenu.visible = true

func _on_exit_pressed() -> void:
	get_tree().quit()
	

func _on_button_pressed() -> void:
	$Background/CenterContainer/MenuButtons.visible = true
	$Background/CenterContainer/SettingsMenu.visible = false
	$Background/CenterContainer/CreditsMenu.visible = false


func _on_fullscreen_toggled(toggled_on: bool) -> void:
	if toggled_on:
		DisplayServer.window_set_mode(DisplayServer.WINDOW_MODE_EXCLUSIVE_FULLSCREEN)
	else:
		DisplayServer.window_set_mode(DisplayServer.WINDOW_MODE_MAXIMIZED)


func _on_test_level_button_pressed() -> void:
	get_tree().change_scene_to_file("res://Scenes/World.tscn")




func _on_back_button_pressed() -> void:
	$Background/CenterContainer/MenuButtons.visible = true
	$Background/CenterContainer/SettingsMenu.visible = false
	$Background/CenterContainer/CreditsMenu.visible = false
	$Background/CenterContainer/LevelsMenu.visible = false
