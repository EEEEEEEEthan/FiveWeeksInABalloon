@tool
extends GeometryInstance3D

@export var contour_spacing := 0.22
@export var contour_line_width := 0.14
@export var contour_axis := Vector3(0.0, 1.0, 0.0)
@export var contour_axis_world_space := true

var _last_applied_contour_spacing := -1.0
var _last_applied_contour_line_width := -1.0
var _last_applied_contour_axis := Vector3.INF
var _last_applied_contour_axis_world_space := true

func _enter_tree() -> void:
	set_process(true)
	_apply_contour_spacing(true)


func _ready() -> void:
	_apply_contour_spacing(true)


func _process(_delta: float) -> void:
	_apply_contour_spacing(false)


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
