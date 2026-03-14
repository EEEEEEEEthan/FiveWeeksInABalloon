@tool
extends Node3D

# 把 SubViewport 渲染的 sky 纹理赋给书页材质，用书页 UV 映射到表面

func _ready() -> void:
	var viewport: SubViewport = get_node("book content/SubViewport")
	var mesh_instance: MeshInstance3D = get_node("book content")
	var mat: ShaderMaterial = mesh_instance.material_override as ShaderMaterial
	if viewport and mat:
		mat.set_shader_parameter("viewport_tex", viewport.get_texture())
