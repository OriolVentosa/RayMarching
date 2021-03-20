extends RigidBody

var speed = 0

func _process(delta):
	if Input.is_key_pressed(KEY_E):
		speed = speed + .1
	if Input.is_key_pressed(KEY_Q):
		speed = speed - .1
	if Input.is_key_pressed(KEY_S):
		rotate_x(delta/.8)
	if Input.is_key_pressed(KEY_W):
		rotate_x(-delta/.8) 
	if Input.is_key_pressed(KEY_A):
		rotate_z(delta/.8) 
	if Input.is_key_pressed(KEY_Z):
		rotate_y(-delta/.8) 
	if Input.is_key_pressed(KEY_X):
		rotate_y(delta/.8) 
		
	translate(Vector3(0,0,delta*speed))

