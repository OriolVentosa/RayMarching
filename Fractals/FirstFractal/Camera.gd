extends Camera

var lookAt = Vector3(0,0,0)
var up = Vector3(0,1,0)
var alpha = 0
var theta = 0
var radius = 1

export var velocity = 1.0

func _calculatePos():
	return Vector3(radius * cos(alpha)*sin(theta), radius * sin(alpha) * sin(theta), radius * cos(theta))

func _process(delta):
	self.look_at(lookAt, up)
	translation = _calculatePos()
	buttonsPressed()

func buttonsPressed():
	if $CanvasLayer/Down.is_pressed():
		theta -= velocity * get_process_delta_time()
	if $CanvasLayer/Up.is_pressed():
		theta += velocity * get_process_delta_time()
	if $CanvasLayer/Left.is_pressed():
		alpha -= velocity * get_process_delta_time()
	if $CanvasLayer/Right.is_pressed():
		alpha += velocity * get_process_delta_time()
	if $CanvasLayer/Minus.is_pressed():
		radius += velocity * get_process_delta_time()
		radius = clamp(radius,0.5, 2.0)
	if $CanvasLayer/Plus.is_pressed():
		radius -= velocity * get_process_delta_time()
		radius = clamp(radius,0.5, 2.0)
