extends Node3D

@export var player: CharacterBody3D
@export var hud: CanvasLayer
@export var pan_speed: float = 12.0
@export var edge_margin: int = 12

@export_group("Zoom")
@export var zoom_step: float = 2.0
@export var min_zoom: float = 8.0
@export var max_zoom: float = 30.0

@export_group("Cursors")
@export var cursor_default: Texture2D   # e.g., red Fallout circle/hex
@export var cursor_interact: Texture2D  # e.g., yellow/green hand or target icon

@onready var camera: Camera3D = $Camera3D

var hovered_interactable: Node3D = null

func _ready() -> void:
	if cursor_default:
		Input.set_custom_mouse_cursor(cursor_default, Input.CURSOR_ARROW, cursor_default.get_size() / 2.0)

func _process(delta: float) -> void:
	_handle_panning(delta)
	_update_hover()

	if Input.is_action_just_pressed("ui_accept") and player:
		global_position = Vector3(player.global_position.x, 0.0, player.global_position.z)

func _unhandled_input(event: InputEvent) -> void:
	if event is InputEventMouseButton and event.pressed:
		# Scroll wheel zoom
		if event.button_index == MOUSE_BUTTON_WHEEL_UP:
			camera.size = clamp(camera.size - zoom_step, min_zoom, max_zoom)
			return
		elif event.button_index == MOUSE_BUTTON_WHEEL_DOWN:
			camera.size = clamp(camera.size + zoom_step, min_zoom, max_zoom)
			return

		# Left-click: interactable first, then floor
		if event.button_index == MOUSE_BUTTON_LEFT and player:
			var is_running: bool = event.double_click
			var interact_hit := _raycast(event.position, 4) # Bit 3 = Collision Layer 3
			if interact_hit and interact_hit.collider.has_method("get") and "interact_message" in interact_hit.collider:
				player.interact_with(interact_hit.collider, hud, is_running)
				return

			var floor_hit := _raycast(event.position, 1) # Bit 1 = Collision Layer 1
			if floor_hit:
				player.move_to(floor_hit.position, is_running)
				if hud:
					hud.log_message("Running..." if is_running else "Walking...")

func _update_hover() -> void:
	var mouse_pos := get_viewport().get_mouse_position()
	var hit := _raycast(mouse_pos, 4) # Collision Layer 3
	var target: Node3D = hit.collider if hit else null

	if target != hovered_interactable:
		hovered_interactable = target
		if hovered_interactable and cursor_interact:
			Input.set_custom_mouse_cursor(cursor_interact, Input.CURSOR_ARROW, cursor_interact.get_size() / 2.0)
		elif cursor_default:
			Input.set_custom_mouse_cursor(cursor_default, Input.CURSOR_ARROW, cursor_default.get_size() / 2.0)

func _raycast(mouse_pos: Vector2, mask: int) -> Dictionary:
	var from := camera.project_ray_origin(mouse_pos)
	var to := from + camera.project_ray_normal(mouse_pos) * 1000.0
	var query := PhysicsRayQueryParameters3D.create(from, to)
	query.collision_mask = mask
	return get_world_3d().direct_space_state.intersect_ray(query)

func _handle_panning(delta: float) -> void:
	var input_dir := Vector2.ZERO
	input_dir.x = Input.get_axis("ui_left", "ui_right")
	input_dir.y = Input.get_axis("ui_up", "ui_down")

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
		var move_vec := (global_basis.x * input_dir.x) + (global_basis.z * input_dir.y)
		global_position += Vector3(move_vec.x, 0.0, move_vec.z) * pan_speed * delta


#extends Node3D
#
#@export var player: CharacterBody3D
#@export var hud: CanvasLayer
#@export var pan_speed: float = 12.0
#@export var edge_margin: int = 12 # pixels from screen edge for edge-scrolling
#
#@onready var camera: Camera3D = $Camera3D
#
#func _process(delta: float) -> void:
	#_handle_panning(delta)
#
	## Snap camera back to player with Space
	#if Input.is_action_just_pressed("ui_accept") and player:
		#global_position = Vector3(player.global_position.x, 0.0, player.global_position.z)
#
#func _unhandled_input(event: InputEvent) -> void:
	#if event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_LEFT and event.pressed:
		#var hit := _raycast_floor(event.position)
		#if hit:
			#var is_running: bool = event.double_click
			#player.move_to(hit.position, is_running)
			#if hud:
				#hud.log_message("Running..." if is_running else "Walking...")
#
#func _raycast_floor(mouse_pos: Vector2) -> Dictionary:
	#var from := camera.project_ray_origin(mouse_pos)
	#var to := from + camera.project_ray_normal(mouse_pos) * 1000.0
	#var query := PhysicsRayQueryParameters3D.create(from, to)
	#query.collision_mask = 1 # Only hit Collision Layer 1 (Floor)
	#return get_world_3d().direct_space_state.intersect_ray(query)
#
#func _handle_panning(delta: float) -> void:
	#var input_dir := Vector2.ZERO
	#
	## Keyboard panning (WASD / Arrows)
	#input_dir.x = Input.get_axis("ui_left", "ui_right")
	#input_dir.y = Input.get_axis("ui_up", "ui_down")
#
	## Classic Fallout edge-scrolling (optional — comment out while testing in windowed mode if annoying)
	#var mouse_pos := get_viewport().get_mouse_position()
	#var view_size := get_viewport().get_visible_rect().size
	#if mouse_pos.x <= edge_margin:
		#input_dir.x -= 1.0
	#elif mouse_pos.x >= view_size.x - edge_margin:
		#input_dir.x += 1.0
	#if mouse_pos.y <= edge_margin:
		#input_dir.y -= 1.0
	#elif mouse_pos.y >= view_size.y - edge_margin:
		#input_dir.y += 1.0
#
	#if input_dir != Vector2.ZERO:
		#input_dir = input_dir.normalized()
		## Move relative to the camera rig's Y rotation so "up" always pans up-screen
		#var move_vec := (global_basis.x * input_dir.x) + (global_basis.z * input_dir.y)
		#global_position += Vector3(move_vec.x, 0.0, move_vec.z) * pan_speed * delta
