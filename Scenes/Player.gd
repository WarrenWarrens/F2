extends CharacterBody3D

@export var walk_speed: float = 3.5
@export var run_speed: float = 6.5

@onready var nav_agent: NavigationAgent3D = $NavigationAgent3D

var current_speed: float = 3.5
var gravity: float = ProjectSettings.get_setting("physics/3d/default_gravity")
var pending_target: Node3D = null
var hud_ref: CanvasLayer = null

func _ready() -> void:
	nav_agent.path_desired_distance = 0.5
	nav_agent.target_desired_distance = 0.5
	nav_agent.path_height_offset = 0.5 
	floor_max_angle = deg_to_rad(45.0)
	floor_snap_length = 0.4

func move_to(target_pos: Vector3, run: bool = false) -> void:
	pending_target = null
	current_speed = run_speed if run else walk_speed
	nav_agent.target_position = target_pos
	print("Target: ", target_pos, " | Reachable: ", nav_agent.is_target_reachable(), " | Finished: ", nav_agent.is_navigation_finished())

func interact_with(target: Node3D, hud: CanvasLayer, run: bool = false) -> void:
	pending_target = target
	hud_ref = hud
	current_speed = run_speed if run else walk_speed
	nav_agent.target_position = target.global_position

func _physics_process(delta: float) -> void:
	if not is_on_floor():
		velocity.y -= gravity * delta
	else:
		velocity.y = 0.0

	# Check if we arrived at an interactable object
	if pending_target:
		var flat_dist := Vector2(global_position.x, global_position.z).distance_to(
			Vector2(pending_target.global_position.x, pending_target.global_position.z)
		)
		if flat_dist <= pending_target.interact_distance:
			if hud_ref:
				hud_ref.log_message(pending_target.interact_message)
			pending_target = null
			nav_agent.target_position = global_position # Stop walking
			velocity.x = 0.0
			velocity.z = 0.0
			move_and_slide()
			return

	if nav_agent.is_navigation_finished():
		velocity.x = 0.0
		velocity.z = 0.0
		move_and_slide()
		return

	var next_pos := nav_agent.get_next_path_position()
	var direction := next_pos - global_position
	direction.y = 0.0

	if direction.length_squared() > 0.001:
		var horizontal := direction.normalized() * current_speed
		velocity.x = horizontal.x
		velocity.z = horizontal.z
	else:
		velocity.x = 0.0
		velocity.z = 0.0

	#print("Pos: ", global_position, " | Next: ", next_pos, " | Vel: ", velocity, " | PathPts: ", nav_agent.get_current_navigation_path().size())
	move_and_slide()
