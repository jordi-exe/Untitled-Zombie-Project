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

# Player Animation
@onready var animation_player: AnimationPlayer = $AnimationPlayer
@onready var animation_tree: AnimationTree = $AnimationTree
var state_machine : AnimationNodeStateMachinePlayback


# Camera Variables
@onready var head: Node3D = $Armature/GeneralSkeleton/BoneAttachment3D/Head

func _ready() -> void:
	state_machine = $AnimationTree.get("parameters/playback") as AnimationNodeStateMachinePlayback
	#animation_player.play("Idle")
	#PrepareAnims()
	
	CURRENT_SPEED = WALK_SPEED
	col_prone.set_deferred("disabled", true)

func PrepareAnims() -> void:
	animation_player.set_blend_time("Idle", "Crouch_Enter", 0.5)
	animation_player.set_blend_time("Crouch_Enter", "Crouch_Idle", 0.5)
	animation_player.set_blend_time("Crouch_Idle", "Crawl_Enter", 0.5)
	animation_player.set_blend_time("Crawl_Enter", "Crawl_Idle", 0.5)
	animation_player.set_blend_time("Crawl_Idle", "Crawl_Exit", 0.5)
	animation_player.set_blend_time("Crawl_Exit", "Idle", 0.5)

func _physics_process(delta: float) -> void:
	# Add the gravity.
	if not is_on_floor():
		velocity += get_gravity() * delta
	
	ProcessState(delta)
	move_and_slide()

func HandleMovement() -> void:
	# Get the input direction and handle the movement/deceleration.
	var input_dir := Input.get_vector("left", "right", "up", "down")
	var direction = (transform.basis * -Vector3(input_dir.x, 0, input_dir.y)).normalized()
	
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
			elif Input.is_action_just_pressed("prone"):
				SwitchState(STATE.PRONE)
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
				SwitchState(STATE.WALK)
		STATE.PRONE:
			CURRENT_SPEED = PRONE_SPEED
			HandleMovement()
			
			if Input.is_action_just_pressed("prone"):
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
			
			if previousState == STATE.PRONE:
				animation_tree.set("parameters/Crawl/ExitCrawl/request", AnimationNodeOneShot.ONE_SHOT_REQUEST_FIRE)
				animation_tree.set("parameters/conditions/isProning", false)
				animation_tree.set("parameters/conditions/isStanding", true)
			elif previousState == STATE.CROUCH:
				animation_tree.set("parameters/Crouch/ExitCrouch/request", AnimationNodeOneShot.ONE_SHOT_REQUEST_FIRE)
				animation_tree.set("parameters/conditions/isCrouching", false)
				animation_tree.set("parameters/conditions/isStanding", true)
		STATE.CROUCH:
			head.Height_To_Crouching()
			col_stand.set_deferred("disabled", true)
			
			animation_tree.set("parameters/conditions/isStanding", false)
			animation_tree.set("parameters/conditions/isCrouching", true)
			#animation_player.play("Crouch_Enter")
			#animation_player.queue("Crouch_Idle")
		STATE.PRONE:
			head.Height_To_Proning()
			col_crouch.set_deferred("disabled", true)
			col_prone.set_deferred("disabled", false)
			
			animation_tree.set("parameters/conditions/isStanding", false)
			animation_tree.set("parameters/conditions/isProning", true)
			#animation_player.play("Crawl_Enter")
			#animation_player.queue("Crawl_Idle")
		
		STATE.JUMP:
			# Handle jump.
			velocity.y = JUMP_VELOCITY
			print_debug("Jumped!")
		STATE.FALL:
			print_debug("Falling!")
