@tool
extends GeometryInstance3D

@export_group("外轮廓")
@export_range(0.0, 1.0, 0.001) var outer_outline_width := 0.001
@export_group("内轮廓")
@export_range(0.0, 1.0, 0.001) var inner_outline_width := 0.18
@export_range(0.0, 1.0, 0.001) var inner_outline_softness := 0.2
@export_group("等高线")
@export var contour_spacing := 0.22
@export_range(0.0, 1.0, 0.001) var contour_line_width := 0.14
@export var contour_axis := Vector3(0.0, 1.0, 0.0)
@export var contour_axis_world_space := true

var _last_applied_outer_outline_width := -1.0
var _last_applied_inner_outline_width := -1.0
var _last_applied_inner_outline_softness := -1.0
var _last_applied_contour_spacing := -1.0
var _last_applied_contour_line_width := -1.0
var _last_applied_contour_axis := Vector3.INF
var _last_applied_contour_axis_world_space := true

func _enter_tree() -> void:
	set_process(true)
	_apply_outline(true)


func _ready() -> void:
	_apply_outline(true)


func _process(_delta: float) -> void:
	_apply_outline(false)


func _apply_outline(force: bool) -> void:
	var outer_changed := not is_equal_approx(outer_outline_width, _last_applied_outer_outline_width)
	var inner_width_changed := not is_equal_approx(inner_outline_width, _last_applied_inner_outline_width)
	var inner_softness_changed := not is_equal_approx(inner_outline_softness, _last_applied_inner_outline_softness)
	if not force and not outer_changed and not inner_width_changed and not inner_softness_changed:
		_apply_contour_spacing(false)
		return

	_last_applied_outer_outline_width = outer_outline_width
	_last_applied_inner_outline_width = inner_outline_width
	_last_applied_inner_outline_softness = inner_outline_softness

	# next_pass 材质收不到 instance 参数，外轮廓通过材质 uniform 设置
	if force or outer_changed:
		var mat := get_material_override()
		if mat:
			mat = mat.duplicate()
			var next_pass := mat.get_next_pass()
			if next_pass:
				next_pass = next_pass.duplicate()
				next_pass.set_shader_parameter(&"outer_outline_width", outer_outline_width)
				mat.next_pass = next_pass
			set_material_override(mat)

	set_instance_shader_parameter(&"inner_outline_width", inner_outline_width)
	set_instance_shader_parameter(&"inner_outline_softness", inner_outline_softness)
	_apply_contour_spacing(force)


func _apply_contour_spacing(force: bool) -> void:
	if not force and is_equal_approx(contour_spacing, _last_applied_contour_spacing):
		_apply_contour_line_width(false)
		return

	_last_applied_contour_spacing = contour_spacing
	set_instance_shader_parameter(&"contour_spacing", contour_spacing)
	_apply_contour_line_width(force)


func _apply_contour_line_width(force: bool) -> void:
	if not force and is_equal_approx(contour_line_width, _last_applied_contour_line_width):
		_apply_contour_axis(false)
		return

	_last_applied_contour_line_width = contour_line_width
	set_instance_shader_parameter(&"contour_line_width", contour_line_width)
	_apply_contour_axis(force)


func _apply_contour_axis(force: bool) -> void:
	var axis_changed := not contour_axis.is_equal_approx(_last_applied_contour_axis)
	var space_changed := contour_axis_world_space != _last_applied_contour_axis_world_space
	if not force and not axis_changed and not space_changed:
		return

	_last_applied_contour_axis = contour_axis
	_last_applied_contour_axis_world_space = contour_axis_world_space
	set_instance_shader_parameter(&"contour_axis", contour_axis)
	set_instance_shader_parameter(&"contour_axis_world_space", contour_axis_world_space)
