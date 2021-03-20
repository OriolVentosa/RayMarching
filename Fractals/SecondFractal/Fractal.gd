extends CSGMesh


var fractalOn = false
var Iterations = 1000
var Timer = 0
var currentIteration = 1
# Called when the node enters the scene tree for the first time.
func _process(delta):
	if !fractalOn:
		return
	Timer += delta
	if(Timer>1.0):
		if(currentIteration>Iterations):
			 return
		if currentIteration>20 and currentIteration< 100:
			currentIteration += 10
		elif currentIteration >= 100 and currentIteration < 1000:
			currentIteration+=100
		else:
			currentIteration += 1
		material.set_shader_param("Iterations", currentIteration)
		Timer = 0
		print_debug(currentIteration)
# Called every frame. 'delta' is the elapsed time since the previous frame.
#func _process(delta):
#	pass


func _on_Button_button_up():
	fractalOn = true
