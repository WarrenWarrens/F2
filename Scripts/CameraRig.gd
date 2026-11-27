extends Node3D

@export var player: CharacterBody3D
@export var hud: CanvasLayer
@export var pan_speed: float = 12.0
@export var edge_margin: int = 12

@export_group("Zoom")
@export var zoom_step: float = 2.0
@export var min_zoom: float = 8.0
@export var max_zoom: float = 30.0
var in_first_person: bool = false


@export_group("Cursors")
@export var cursor_default: Texture2D  
@export var cursor_interact: Texture2D 
@export var mouse_sensitivity: float = 0.003
@onready var camera: Camera3D = $Camera3D

var hovered_interactable: Node3D = null

func _ready() -> void:
	if cursor_default:
		Input.set_custom_mouse_cursor(cursor_default, Input.CURSOR_ARROW, cursor_default.get_size() / 2.0)

func _process(delta: float) -> void:
	if in_first_person:
		return
	
	_handle_panning(delta)
	_update_hover()

	if Input.is_action_just_pressed("ui_accept") and player:
		global_position = Vector3(player.global_position.x, 0.0, player.global_position.z)

func _unhandled_input(event: InputEvent) -> void:
	if event is InputEventKey and event.keycode == KEY_CTRL and not event.echo:
		if event.pressed and not in_first_person and player:
			_enter_first_person()
		elif not event.pressed and in_first_person:
			_exit_first_person()
		return
		
	if in_first_person:
		if event is InputEventMouseMotion:
			var fp_cam: Camera3D = player.get_node("FirstPersonCamera")
			fp_cam.rotate_y(-event.relative.x * mouse_sensitivity)
			fp_cam.rotation.x = clamp(fp_cam.rotation.x - event.relative.y * mouse_sensitivity, deg_to_rad(-70), deg_to_rad(70))
		elif (event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_WHEEL_DOWN and event.pressed) or event.is_action_pressed("ui_cancel"):
			_exit_first_person()
		return
	
	if event is InputEventMouseButton and event.pressed:
		if event.button_index == MOUSE_BUTTON_WHEEL_UP:
			if camera.size <= min_zoom and player:
				var player_hit := _raycast(event.position, 2)
				if player_hit and player_hit.collider == player:
					_enter_first_person()
					return
			_zoom_towards_mouse(-zoom_step, event.position)
			return
		elif event.button_index == MOUSE_BUTTON_WHEEL_DOWN:
			_zoom_towards_mouse(zoom_step, event.position)
			return

		if event.button_index == MOUSE_BUTTON_LEFT and player:
			var is_running: bool = event.double_click
			var interact_hit := _raycast(event.position, 4)
			if interact_hit and interact_hit.collider.has_method("get") and "interact_message" in interact_hit.collider:
				player.interact_with(interact_hit.collider, hud, is_running)
				return

			var floor_hit := _raycast(event.position, 1)
			if floor_hit:
				player.move_to(floor_hit.position, is_running)
				if hud:
					hud.log_message("Running..." if is_running else "Walking...")

func _update_hover() -> void:
	var mouse_pos := get_viewport().get_mouse_position()
	var hit := _raycast(mouse_pos, 4) 
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

func _zoom_towards_mouse(zoom_delta: float, mouse_pos: Vector2) -> void:
	var ground_plane := Plane(Vector3.UP, 0.5)
	var before = ground_plane.intersects_ray(
		camera.project_ray_origin(mouse_pos),
		camera.project_ray_normal(mouse_pos)
	)

	camera.size = clamp(camera.size + zoom_delta, min_zoom, max_zoom)

	var after = ground_plane.intersects_ray(
		camera.project_ray_origin(mouse_pos),
		camera.project_ray_normal(mouse_pos)
	)

	if before != null and after != null:
		var offset = before - after
		global_position += Vector3(offset.x, 0.0, offset.z)
		
func _enter_first_person() -> void:
	in_first_person = true
	var fp_cam: Camera3D = player.get_node("FirstPersonCamera")
	fp_cam.make_current()
	player.get_node("Sprite3D").visible = false
	Input.mouse_mode = Input.MOUSE_MODE_CAPTURED
	if hud:
		hud.visible = false

func _exit_first_person() -> void:
	in_first_person = false
	camera.make_current()
	player.get_node("Sprite3D").visible = true
	Input.mouse_mode = Input.MOUSE_MODE_VISIBLE
	if hud:
		hud.visible = true
		
