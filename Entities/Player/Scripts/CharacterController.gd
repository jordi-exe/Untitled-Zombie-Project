extends CharacterBody3D

# # Mechanics: Walking, Sprinting, Crouching, Proning, Jumping, Camera Swap (FPS to TPS and vice-versa)

# State Variables
enum STATE { GROUND, WALK, SPRINT, CROUCH, PRONE, JUMP, FALL, CAMERA_SWAP }
var activeState := STATE.FALL

# Player Variables
# # @export_custom is to show the variable in the inspector while leaving it as read only
@export_custom(PROPERTY_HINT_NONE, "", PROPERTY_USAGE_DEFAULT | PROPERTY_USAGE_READ_ONLY)
var CURRENT_SPEED = 0.0

@export var PRONE_SPEED = 1.0
@export var CROUCH_SPEED = 2.0
@export var WALK_SPEED = 4.0
@export var RUN_SPEED = 8.0
@export var JUMP_VELOCITY = 4.5

# Player Collision Variables
# # collision.set_deferred is used to change collision settings safely
@onready var col_prone: CollisionShape3D = $Col_Prone
@onready var col_crouch: CollisionShape3D = $Col_Crouch
@onready var col_stand: CollisionShape3D = $Col_Stand


# Camera Variables
@onready var head: Node3D = $Head

func _ready() -> void:
	CURRENT_SPEED = WALK_SPEED
	col_prone.set_deferred("disabled", true)

func _physics_process(delta: float) -> void:
	# Add the gravity.
	if not is_on_floor():
		velocity += get_gravity() * delta
	
	ProcessState(delta)
	move_and_slide()

func HandleMovement() -> void:
	# Get the input direction and handle the movement/deceleration.
	var input_dir := Input.get_vector("left", "right", "up", "down")
	var direction = (head.transform.basis * Vector3(input_dir.x, 0, input_dir.y)).normalized()
	
	if direction:
		velocity.x = direction.x * CURRENT_SPEED
		velocity.z = direction.z * CURRENT_SPEED
	else:
		velocity.x = move_toward(velocity.x, 0, CURRENT_SPEED)
		velocity.z = move_toward(velocity.z, 0, CURRENT_SPEED)

func ProcessState(delta: float) -> void:
	match activeState:
		# Horizontal States
		STATE.WALK:
			CURRENT_SPEED = WALK_SPEED
			HandleMovement()
			
			if Input.is_action_just_pressed("sprint"):
				SwitchState(STATE.SPRINT)
			
			if not is_on_floor():
				SwitchState(STATE.FALL)
			elif Input.is_action_just_pressed("jump"):
				SwitchState(STATE.JUMP)
			elif Input.is_action_just_pressed("crouch"):
				SwitchState(STATE.CROUCH)
		STATE.SPRINT:
			CURRENT_SPEED = RUN_SPEED
			HandleMovement()
			
			if Input.is_action_just_released("sprint"):
				SwitchState(STATE.WALK)
			
			if not is_on_floor():
				SwitchState(STATE.FALL)
			elif Input.is_action_just_pressed("jump"):
				SwitchState(STATE.JUMP)
		STATE.CROUCH:
			CURRENT_SPEED = CROUCH_SPEED
			HandleMovement()
			
			if Input.is_action_just_pressed("crouch"):
				SwitchState(STATE.PRONE)
		STATE.PRONE:
			CURRENT_SPEED = PRONE_SPEED
			HandleMovement()
			
			if Input.is_action_just_pressed("crouch"):
				SwitchState(STATE.WALK)
		
		# Vertical states
		STATE.JUMP:
			HandleMovement()
			
			if velocity.y <= 0:
				SwitchState(STATE.FALL)
		STATE.FALL:
			HandleMovement()
			
			#Detects whether or not to continue sprinting after a jump if the key is pressed
			if is_on_floor():
				if Input.is_action_pressed("sprint"):
					SwitchState(STATE.SPRINT)
				else:
					SwitchState(STATE.WALK)
		
		

func SwitchState(toState: STATE) -> void:
	var previousState := activeState
	activeState = toState
	
	match activeState:
		STATE.WALK:
			head.Height_To_Standing()
			col_crouch.set_deferred("disabled", false)
			col_stand.set_deferred("disabled", false)
			col_prone.set_deferred("disabled", true)
		STATE.CROUCH:
			head.Height_To_Crouching()
			col_stand.set_deferred("disabled", true)
			
		STATE.PRONE:
			head.Height_To_Proning()
			col_crouch.set_deferred("disabled", true)
			col_prone.set_deferred("disabled", false)
		
		STATE.JUMP:
			# Handle jump.
			velocity.y = JUMP_VELOCITY
			print_debug("Jumped!")
		STATE.FALL:
			print_debug("Falling!")
