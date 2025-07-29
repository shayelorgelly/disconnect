extends CharacterBody3D

const SPEED = 1.4
const JUMP_VELOCITY = 4
const ACCELERATION = 15.0
const DECELERATION = 10
const DECELERATION_AIR = 0.85
const STEP_HEIGHT = 0.35
const MOUSE_SENSITIVITY = 0.006
const MOUSE_SMOOTHING = 80
var movement_enabled = true
var gravity = ProjectSettings.get_setting("physics/3d/default_gravity")
var smoothed_mouse_delta := Vector2.ZERO
var raw_mouse_delta := Vector2.ZERO

@onready var neck := $neck
@onready var camera := $neck/Camera3D

func _unhandled_input(event: InputEvent) -> void:
	if event is InputEventMouseButton:
		if event.button_index == MOUSE_BUTTON_LEFT and event.pressed:
			Input.set_mouse_mode(Input.MOUSE_MODE_CAPTURED)
	elif event.is_action_pressed("ui_cancel"):
		Input.set_mouse_mode(Input.MOUSE_MODE_VISIBLE)

	# Capture raw delta once per frame
	if movement_enabled:
		if Input.get_mouse_mode() == Input.MOUSE_MODE_CAPTURED and event is InputEventMouseMotion:
			raw_mouse_delta += event.relative

func _push_away_rigid_bodies():
	for i in get_slide_collision_count():
		var collision := get_slide_collision(i)
		if collision.get_collider() is RigidBody3D:
			var normal = -collision.get_normal()
			var velocity_diff = velocity.dot(normal) - collision.get_collider().linear_velocity.dot(normal)
			velocity_diff = max(0.0, velocity_diff)

			const player_weight = 80.0
			var ratioofweight = min(1.0, player_weight / collision.get_collider().mass)
			normal.y = 0.0
			var push_force = ratioofweight * 5.0
			collision.get_collider().apply_impulse(
				normal * velocity_diff * push_force,
				collision.get_position() - collision.get_collider().global_position
			)

func _physics_process(delta: float) -> void:
	# smooth mouse delta
	smoothed_mouse_delta = smoothed_mouse_delta.lerp(raw_mouse_delta, MOUSE_SMOOTHING * delta)
	raw_mouse_delta = Vector2.ZERO  # reset for next frame

	# apply rotation
	if Input.get_mouse_mode() == Input.MOUSE_MODE_CAPTURED:
		neck.rotate_y(-smoothed_mouse_delta.x * MOUSE_SENSITIVITY)
		camera.rotate_x(-smoothed_mouse_delta.y * (MOUSE_SENSITIVITY * 0.86))
		camera.rotation.x = clamp(camera.rotation.x, deg_to_rad(-80), deg_to_rad(80))

	# gravity
	if not is_on_floor():
		velocity.y -= gravity * delta
	else:
		velocity.y = 0.0

	# Jump
	if movement_enabled:
		if Input.is_action_just_pressed("ui_accept") and is_on_floor():
			velocity.y = JUMP_VELOCITY

		# Movement
		var input_dir = Input.get_vector("left", "right", "forward", "back")
		var move_dir = (neck.transform.basis * Vector3(input_dir.x, 0, input_dir.y)).normalized()

		if move_dir != Vector3.ZERO:
			velocity.x = move_toward(velocity.x, move_dir.x * SPEED, ACCELERATION * delta)
			velocity.z = move_toward(velocity.z, move_dir.z * SPEED, ACCELERATION * delta)
		else:
			if not is_on_floor():
				velocity.x = move_toward(velocity.x, 0, 0.85 * delta)
				velocity.z = move_toward(velocity.z, 0, DECELERATION_AIR * delta)
			else:
				velocity.x = move_toward(velocity.x, 0, DECELERATION * delta)
				velocity.z = move_toward(velocity.z, 0, DECELERATION * delta)

	_push_away_rigid_bodies()
	move_and_slide()
