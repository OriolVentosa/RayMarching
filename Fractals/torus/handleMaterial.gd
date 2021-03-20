extends CSGMesh

onready var parent = get_parent()
onready var camera = parent.get_node("Camera")

func _process(delta):
	material.set_shader_param("cameraTransform", camera.translation-self.translation)
