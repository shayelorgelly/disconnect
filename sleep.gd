extends CanvasLayer

@onready var color_rect: ColorRect = $ColorRect
var fade_target_alpha = 0.0
var fade_speed = 0.0
var fading = false
const ALPHA_THRESHOLD: float = 0.01
# didnt have enough time to use tween

func _process(delta: float):
	if fading:
		var current_alpha = color_rect.modulate.a
		var diff = fade_target_alpha - current_alpha
		if abs(diff) < 0.01:
			color_rect.modulate.a = fade_target_alpha
			fading = false
			if fade_target_alpha == 0.0:
				color_rect.visible = false
		else:
			color_rect.modulate.a = lerp(current_alpha, fade_target_alpha, min(1.0, fade_speed * delta))


func fade_to(target_alpha: float, duration: float):
	color_rect.visible = true
	fade_target_alpha = clamp(target_alpha, 0.0, 1.0)
	fade_speed = 1.0 / max(duration, 0.001)
	fading = true

func fade_out(duration: float = 1.0):
	color_rect.modulate.a = 0.0
	fade_to(1.0, duration)

func fade_in(duration: float = 1.0):
	color_rect.modulate.a = 1.0
	fade_to(0.0, duration)
