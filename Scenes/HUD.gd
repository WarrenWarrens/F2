extends CanvasLayer

@onready var message_log: RichTextLabel = $Control/BottomBar/HBoxContainer/MessageLog

func _ready() -> void:
	message_log.scroll_following = true
	log_message("Prototype initialized. Left-click to walk, double-click to run.")

func log_message(text: String) -> void:
	message_log.append_text("[color=#33ff33]> %s[/color]\n" % text)
