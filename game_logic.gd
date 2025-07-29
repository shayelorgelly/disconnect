extends Node3D
# apologies for the weird things like bitflags and the C++ like naming conventons


# objects we use alot
@onready var area_triggers: Node3D = $area_triggers
@onready var cameras: Node3D = $cameras
@onready var world_environment: WorldEnvironment = $WorldEnvironment
@onready var blinds: Node3D = $dwad/blinds
@onready var character_body_3d: CharacterBody3D = $CharacterBody3D
@onready var tasks: CanvasLayer = $CharacterBody3D/ui/TASKS

# dogs
@onready var dog_dead: MeshInstance3D = $dwad/dog_dead
@onready var dog_front_door: MeshInstance3D = $dwad/dog_front_door
@onready var dog_bed: MeshInstance3D = $dwad/dog_bed
var dogs = []

# constants
const CUTSCENE_1_COMPLETE = 1 << 0 # bit shift operator
const CUTSCENE_BED_1_COMPLETE = 1 << 1 # 0x02 (00000010)
const CUTSCENE_GRANDMOTHER  = 1 << 2  # 0x04 (00000100)
const SCENE_BED_2_COMPLETE = 1 << 3 # 0x08 (00001000)
const CUTSCENE_BED_2_COMPLETE = 1 <<  4 # 00010000
const CUTSCENE_DOG_DYING_COMPLETE = 1 << 5 #00100000)
const SCENE_BED_2_START = 1 << 6 


# here we use bitflags to track game progression. this is so we can have side quests 
# or quests added in the future without using loads of booleans or having to shift numbers around
# in the future to make room for other quests
var STORY_STAGE = 0 # this is more efficient than booleans as well


func set_player_movement(s):
	assert(typeof(s) == TYPE_BOOL, "[TOGGLE PLAYER MOVEMENT]: expected a bool value")
	character_body_3d.movement_enabled = s
class Scene:
	var owner # script which called the class
	var camera
	var player_camera
	var cbody3d
	var disable_movement_on_start
	var started
	func _init(_owner ,_camera, _player_camera, _cbody3d, _disable_movement_on_start): # naming convention to avoid overwriting variable names in this scope
		owner = _owner
		camera = _camera
		player_camera = _player_camera
		disable_movement_on_start = _disable_movement_on_start
		cbody3d = _cbody3d
		camera.make_current()
		if disable_movement_on_start:
			owner.set_player_movement(false)
	
	
	func enable_movement():
		owner.set_player_movement(true)
		
		
	func disable_movement():
		owner.set_player_movement(false)
		
		
	func cleanup():
		player_camera.make_current()
		owner.set_player_movement(true)

func delay(msec):
	await get_tree().create_timer(msec / 1000).timeout # use godot internal timer because sleep doesnt work

func set_bitflag(flags, flag):
	return flags | flag # bitwise or of flag

func remove_bitflag(flags, flag):
	return flags & ~flag # bitwise not of flag
	
func check_bitflag(flags, flag):
	return (flags & flag) != 0 # if any of the bits in flag are set in flags
	



func cutscene_1():
	if not check_bitflag(STORY_STAGE, CUTSCENE_1_COMPLETE):
		print("[CUTSCENE_1]: entered")
		STORY_STAGE = set_bitflag(STORY_STAGE, CUTSCENE_1_COMPLETE) # lock the scene so it cant start twice
		$area_triggers/trigger_argument_1.monitoring = false 
		tasks.tasks_visible(false)
		var scene = Scene.new(self, $cameras/cam_3, $CharacterBody3D/neck/Camera3D, $CharacterBody3D, true)
		$sounds/bedroom_door_creak.play() # play the creaking noise
		await delay(1500) # wait a second and a half
		$dwad/door2.rotation_degrees = Vector3(-90, -165, 0) # open door slightly
		await delay(1500)
		$sounds/argument_1.play() # self explanatory
		await delay(45000) # the audio is 47 seconds long
		$dwad/doorp.rotation_degrees = Vector3(0,0,0) # slam parents door
		await delay(3000) # there is 3 seconds left in the audio
		scene.cleanup()
		#setup the next event
		tasks.set_text("Task: Go to bed.")
		tasks.tasks_visible(true)
		$dwad/door2.rotation_degrees = Vector3(-90, 24.6, 0) # open the door for the next part of the story
		
		
func cutscene_bed_1():
	if not check_bitflag(STORY_STAGE, CUTSCENE_BED_1_COMPLETE) and check_bitflag(STORY_STAGE, CUTSCENE_1_COMPLETE):
		print("[CUTSCENE_BED_1]: entered")
		STORY_STAGE = set_bitflag(STORY_STAGE, CUTSCENE_BED_1_COMPLETE)
		tasks.tasks_visible(false)
		$dwad/dog_bed.visible = true
		var scene = Scene.new(self, $cameras/cam_2, $CharacterBody3D/neck/Camera3D, $CharacterBody3D, true) # setup the scene
		$sounds/dog_bed_bark.play()
		await delay(10000)
		$CharacterBody3D/ui/sleep.fade_out(3) # this doesnt block the thread
		await delay(1000 + 3000) # so we need to add the delay manually
		$dwad/dog_bed.visible = false
		scene.cleanup()
		$CharacterBody3D/ui/sleep.fade_in(3)
		await delay(7000 + 3000) # add fade in delay
		tasks.set_text("Investigate the knocking")
		tasks.tasks_visible(true)
		

func cutscene_grandmother():
	if not check_bitflag(STORY_STAGE, CUTSCENE_GRANDMOTHER) and check_bitflag(STORY_STAGE, CUTSCENE_BED_1_COMPLETE): # check if we are up to the right point
		STORY_STAGE = set_bitflag(STORY_STAGE, CUTSCENE_GRANDMOTHER) # make sure we dont trigger this twice
		var scene = Scene.new(self, $cameras/cam_1, $CharacterBody3D/neck/Camera3D, $CharacterBody3D, true)
		tasks.tasks_visible(false)
		$dwad/dog_front_door.visible = true
		$sounds/dog_bed_bark.play() # not best practice but i need dog barking
		await delay(3000) # 3000ms
		$sounds/grandmother.play()
		await delay(3000) 
		$cash_stack.visible = true
		await delay(7000)
		$cash_stack.visible = false
		scene.cleanup()
		$dwad/dog_front_door.visible = false
		$CharacterBody3D.global_transform.origin = Vector3(3.763, 0.502, -0.716) # teleport the player
		tasks.set_text("Task: Go to your bedroom.")
		tasks.tasks_visible(true)

func scene_bedroom_2():
	if not check_bitflag(STORY_STAGE, SCENE_BED_2_START) and check_bitflag(STORY_STAGE, CUTSCENE_GRANDMOTHER):
		print("[SCENE_BED_2]: entered")
		STORY_STAGE = set_bitflag(STORY_STAGE, SCENE_BED_2_START)
		tasks.tasks_visible(false)
		$sounds/argument_2.play()
		await delay(25000) # sound is 25 seconds long
		tasks.set_text("Task: Go to sleep")
		tasks.tasks_visible(true)
		STORY_STAGE = set_bitflag(STORY_STAGE, SCENE_BED_2_COMPLETE)
		
func cutscene_bed_2():
	if not check_bitflag(STORY_STAGE, CUTSCENE_BED_2_COMPLETE) and check_bitflag(STORY_STAGE, SCENE_BED_2_COMPLETE):
		print("[CUTSCENE_BED_2]: entered")
		STORY_STAGE = set_bitflag(STORY_STAGE, CUTSCENE_BED_2_COMPLETE)
		tasks.tasks_visible(false)
		var scene = Scene.new(self, $cameras/cam_2, $CharacterBody3D/neck/Camera3D, $CharacterBody3D, true) # setup the scene
		$CharacterBody3D/ui/sleep.fade_out(3) # this doesnt block the thread
		await delay(1000 + 3000) # so we need to add the delay manually
		$dwad/dog_dead.visible = true
		scene.cleanup()
		$CharacterBody3D/ui/sleep.fade_in(3)
		await delay(7000 + 3000) # add fade in delay
		tasks.set_text("Task: whats that sound?")
		tasks.tasks_visible(true)
		blinds.set_day()
		$sounds/dog_dying.play()
		
func cutscene_dog_dying():
	if not check_bitflag(STORY_STAGE, CUTSCENE_DOG_DYING_COMPLETE) and check_bitflag(STORY_STAGE, CUTSCENE_BED_2_COMPLETE):
		print("[CUTSCENE_DOG_DYING]: entered")
		STORY_STAGE = set_bitflag(STORY_STAGE, CUTSCENE_DOG_DYING_COMPLETE)
		var scene = Scene.new(self, $cameras/cam_0, $CharacterBody3D/neck/Camera3D, $CharacterBody3D, true)
		tasks.tasks_visible(false)
		$sounds/dog_dying.play()
		await delay(8000)
		$CharacterBody3D/ui/sleep.fade_out(3) 
		# credits
		await delay(3000) # wait for fade out as its non blocking
		$CharacterBody3D/ui/credits.visible = true
		
	
func _ready() -> void:
	# DEBUG: start game after cutscene 1
	#if OS.is_debug_build():
		#STORY_STAGE = STORY_STAGE | CUTSCENE_1_COMPLETE
	dogs = [dog_dead, dog_front_door, dog_bed]
	for dog in dogs: # make dogs invisible
		dog.visible = false
	# yes, my custom listen_signal supports multiple functions connected to the same trigger
	area_triggers.listen_signal("trigger_argument_1", cutscene_1) # connect the area trigger to the cutscene function
	area_triggers.listen_signal("trigger_bed", cutscene_bed_1) 
	area_triggers.listen_signal("trigger_bed", cutscene_bed_2) # this is intentional
	area_triggers.listen_signal("trigger_bedroom", scene_bedroom_2)
	area_triggers.listen_signal("trigger_grandmother", cutscene_grandmother)
	area_triggers.listen_signal("trigger_dog_dead", cutscene_dog_dying)
	blinds.set_night() # remove emissive object behind blinds
	
	
