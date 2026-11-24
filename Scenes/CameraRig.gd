extends Node3D

@export var player: CharacterBody3D
@export var hud: CanvasLayer
@export var pan_speed: float = 12.0
@export var edge_margin: int = 12 # pixels from screen edge for edge-scrolling

@onready var camera: Camera3D = $Camera3D

func _process(delta: float) -> void:
	_handle_panning(delta)

	# Snap camera back to player with Space
	if Input.is_action_just_pressed("ui_accept") and player:
		global_position = Vector3(player.global_position.x, 0.0, player.global_position.z)

func _unhandled_input(event: InputEvent) -> void:
	if event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_LEFT and event.pressed:
		var hit := _raycast_floor(event.position)
		if hit:
			var is_running: bool = event.double_click
			player.move_to(hit.position, is_running)
			if hud:
				hud.log_message("Running..." if is_running else "Walking...")

func _raycast_floor(mouse_pos: Vector2) -> Dictionary:
	var from := camera.project_ray_origin(mouse_pos)
	var to := from + camera.project_ray_normal(mouse_pos) * 1000.0
	var query := PhysicsRayQueryParameters3D.create(from, to)
	query.collision_mask = 1 # Only hit Collision Layer 1 (Floor)
	return get_world_3d().direct_space_state.intersect_ray(query)

func _handle_panning(delta: float) -> void:
	var input_dir := Vector2.ZERO
	
	# Keyboard panning (WASD / Arrows)
	input_dir.x = Input.get_axis("ui_left", "ui_right")
	input_dir.y = Input.get_axis("ui_up", "ui_down")

	# Classic Fallout edge-scrolling (optional — comment out while testing in windowed mode if annoying)
	var mouse_pos := get_viewport().get_mouse_position()
	var view_size := get_viewport().get_visible_rect().size
	if mouse_pos.x <= edge_margin:
		input_dir.x -= 1.0
	elif mouse_pos.x >= view_size.x - edge_margin:
		input_dir.x += 1.0
	if mouse_pos.y <= edge_margin:
		input_dir.y -= 1.0
	elif mouse_pos.y >= view_size.y - edge_margin:
		input_dir.y += 1.0

	if input_dir != Vector2.ZERO:
		input_dir = input_dir.normalized()
		# Move relative to the camera rig's Y rotation so "up" always pans up-screen
		var move_vec := (global_basis.x * input_dir.x) + (global_basis.z * input_dir.y)
		global_position += Vector3(move_vec.x, 0.0, move_vec.z) * pan_speed * delta
