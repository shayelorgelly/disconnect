extends Node3D
signal area_trigger_fired(name)

var listeners = []

func _ready() -> void:
	connect("area_trigger_fired", Callable(self, "on_trigger_fired"))

func on_trigger_fired(trigger):
	for listener in listeners:
		if listener.get("name") == trigger.name:
			listener.get("callback").call()

func listen_signal(name, cb):
	listeners.append({"name": name, "callback": cb})
