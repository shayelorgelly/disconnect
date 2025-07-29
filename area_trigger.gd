extends Area3D
@onready var triggers: Node3D = get_parent()


func _on_body_entered(body):
	var prefix = ("[TRIGGER: %s]") % $".".name
	print("%s ACTIVATED" % prefix)
	if body.name == "CharacterBody3D":
		print("%s CHARACTERBODY3D PRESENT" % prefix)
		triggers.emit_signal("area_trigger_fired", {"name": $".".name})
