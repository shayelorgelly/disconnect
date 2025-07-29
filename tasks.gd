extends CanvasLayer

func set_text(_text):
	$Control/Label.text = _text
	
func tasks_visible(_bool):
	$".".visible = _bool
