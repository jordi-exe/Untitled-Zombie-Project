extends Node3D

# Camera Variables
@onready var camera: Camera3D = $Camera3D
@export var SENSITIVITY = 0.003
@export var MIN_ANGLE_X = -40
@export var MAX_ANGLE_X = 60
@export var HEIGHT_SPEED = 1.0

# Player Camera Variables
@export var H_STAND = 0.0
@export var H_CROUCH = -0.5
@export var H_PRONE = -1.0
@onready var m_dummy_player: CharacterBody3D = $"../../../.."

var target_height = H_STAND

func _ready():
	Input.set_mouse_mode(Input.MOUSE_MODE_CAPTURED)
	camera.position.y = H_STAND

#func _process(delta: float):
	##Moves the camera position smoothly based on the current state
	#if camera.position.y != target_height:
		#camera.position.y = lerp(
			#camera.position.y,
			#target_height,
			#HEIGHT_SPEED * delta
			#)

func _unhandled_input(event):
	# Handles the camera rotation in FPS-mode, where the Y axis is controlled by the head, and the X axis is controlled by the camera
	# # This is to avoid weird rotational quirks if both axises were handled by the camera i.e. the camera begins to rotate diagonally
	if event is InputEventMouseMotion && Input.mouse_mode == Input.MOUSE_MODE_CAPTURED:
		m_dummy_player.rotate_y(-event.relative.x * SENSITIVITY)
		camera.rotate_x(-event.relative.y * SENSITIVITY)
		camera.rotation.x = clamp(camera.rotation.x, deg_to_rad(MIN_ANGLE_X), deg_to_rad(MAX_ANGLE_X))

func Height_To_Standing():
	target_height = H_STAND

func Height_To_Crouching():
	target_height = H_CROUCH

func Height_To_Proning():
	target_height = H_PRONE

# Unlocks the mouse for use within the editor, for debugging purposes only for now
func _input(event):
	if event.is_action_pressed("ui_cancel") && Input.mouse_mode == Input.MOUSE_MODE_CAPTURED:
		Input.mouse_mode = Input.MOUSE_MODE_VISIBLE
	elif event.is_action_pressed("ui_cancel") && Input.mouse_mode == Input.MOUSE_MODE_VISIBLE:
		Input.mouse_mode = Input.MOUSE_MODE_CAPTURED
