extends CharacterBody3D

@export var walk_speed: float = 3.5
@export var run_speed: float = 6.5

@onready var nav_agent: NavigationAgent3D = $NavigationAgent3D

var current_speed: float = 3.5
var gravity: float = ProjectSettings.get_setting("physics/3d/default_gravity")

func _ready() -> void:
	nav_agent.path_desired_distance = 0.25
	nav_agent.target_desired_distance = 0.25
	
	# Keeps the player glued to slopes when walking downhill
	floor_max_angle = deg_to_rad(45.0)
	floor_snap_length = 0.4

func move_to(target_pos: Vector3, run: bool = false) -> void:
	current_speed = run_speed if run else walk_speed
	nav_agent.target_position = target_pos

func _physics_process(delta: float) -> void:
	# Apply gravity so the player follows slopes/stairs downward
	if not is_on_floor():
		velocity.y -= gravity * delta
	else:
		velocity.y = 0.0

	if nav_agent.is_navigation_finished():
		velocity.x = 0.0
		velocity.z = 0.0
		move_and_slide()
		return

	var next_pos := nav_agent.get_next_path_position()
	var direction := next_pos - global_position
	direction.y = 0.0 # Let physics + floor_snap handle the Y axis

	if direction.length_squared() > 0.001:
		var horizontal := direction.normalized() * current_speed
		velocity.x = horizontal.x
		velocity.z = horizontal.z
	else:
		velocity.x = 0.0
		velocity.z = 0.0

	move_and_slide()
