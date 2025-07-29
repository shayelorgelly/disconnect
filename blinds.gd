extends Node3D

@onready var blinds_closed: MeshInstance3D = $blinds_closed
@onready var blinds_open: MeshInstance3D = $blinds_open

const OPEN_STATE = true
const CLOSED_STATE = false
const DEFAULT_STATE = OPEN_STATE
var state: bool = DEFAULT_STATE

func _ready() -> void:
	if DEFAULT_STATE == OPEN_STATE:
		open_blinds()
	elif DEFAULT_STATE == CLOSED_STATE:
		close_blinds()
	else:
		push_error("INVALID BLINDS STATE")


func close_blinds():
	state = CLOSED_STATE
	blinds_open.visible = false
	blinds_closed.visible = true
	
func open_blinds():
	state = OPEN_STATE
	blinds_open.visible = true
	blinds_closed.visible = false

func set_day():
	close_blinds()
	$day.visible = true

func set_night():
	open_blinds() # idk this looks kinda cool at night
	$day.visible = false
