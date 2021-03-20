extends Sprite

onready var amplitude = material.get_shader_param("amplitude")

func _ready():
	print(amplitude)
	assert(amplitude != null)


func _on_Interface_amplitude_changed(amplitude_x):
	amplitude.x = amplitude_x
	material.set_shader_param("amplitude", amplitude)
