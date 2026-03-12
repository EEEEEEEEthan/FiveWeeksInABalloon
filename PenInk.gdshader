shader_type spatial;
render_mode unshaded, blend_mix, depth_prepass_alpha, cull_back;

#include "res://ShaderRandom.gdshaderinc"

global uniform vec3 pen_ink_light_direction;
uniform sampler2D scene_normal_texture : hint_normal_roughness_texture, repeat_disable, filter_linear;

uniform vec4 ink_color : source_color = vec4(0.05, 0.06, 0.08, 1.0);
uniform vec4 fill_color : source_color = vec4(1.0, 1.0, 1.0, 1.0);
uniform sampler2D fill_texture : source_color, hint_default_white, repeat_disable, filter_linear_mipmap;
uniform float outline_width : hint_range(0.001, 1.0, 0.001) = 0.18;
uniform float outline_softness : hint_range(0.001, 1.0, 0.001) = 0.2;
uniform float hard_edge_width : hint_range(0.0, 1.0, 0.001) = 0.35;
uniform float hard_edge_threshold : hint_range(0.001, 1.0, 0.001) = 0.18;
uniform float wobble_scale : hint_range(0.001, 1.0, 0.001) = 0.4;
uniform float wobble_strength : hint_range(0.001, 1.0, 0.001) = 0.2;
instance uniform vec3 contour_axis = vec3(0.0, 1.0, 0.0);
uniform bool contour_use_uv = false;
instance uniform float contour_spacing : hint_range(0.001, 10.0, 0.001) = 0.22;
instance uniform float contour_line_width : hint_range(0.0, 1.0, 0.001) = 0.14;
uniform float contour_distance_compensation : hint_range(0.0, 1.0, 0.001) = 0.82;
uniform float contour_far_spacing_compensation : hint_range(0.0, 1.0, 0.001) = 0.7;
uniform sampler2D contour_light_threshold_curve : hint_default_white;

varying vec3 world_pos;
varying vec3 world_normal;
varying vec3 local_pos;

vec2 contour_axis_to_uv_axis(vec3 axis) {
	vec2 axis_xy = axis.xy;
	if (length(axis_xy) > 0.0001) {
		return normalize(axis_xy);
	}

	vec2 axis_xz = axis.xz;
	if (length(axis_xz) > 0.0001) {
		return normalize(axis_xz);
	}

	vec2 axis_yz = axis.yz;
	if (length(axis_yz) > 0.0001) {
		return normalize(axis_yz);
	}

	return vec2(1.0, 0.0);
}

vec3 sample_scene_normal(vec2 screen_uv) {
	vec3 encoded_normal = texture(scene_normal_texture, screen_uv).xyz;
	return normalize(encoded_normal * 2.0 - 1.0);
}

void vertex() {
	world_pos = (MODEL_MATRIX * vec4(VERTEX, 1.0)).xyz;
	world_normal = normalize(MODEL_NORMAL_MATRIX * NORMAL);
	local_pos = VERTEX;
}

void fragment() {
	vec3 n = normalize(world_normal);
	vec3 view_dir = normalize(CAMERA_POSITION_WORLD - world_pos);
	vec3 light_direction = pen_ink_light_direction / max(length(pen_ink_light_direction), 0.0001);
	vec3 axis = contour_axis / max(length(contour_axis), 0.0001);
	vec2 uv_axis = contour_axis_to_uv_axis(axis);
	float axis_world_scale = max(length((MODEL_MATRIX * vec4(axis, 0.0)).xyz), 0.0001);
	float contour_coord_spacing = contour_use_uv ? max(contour_spacing, 0.0001) : max(contour_spacing / axis_world_scale, 0.0001);
	float rim = 1.0 - max(dot(n, view_dir), 0.0);
	float softness = mix(0.002, 0.08, outline_softness);
	float noise_scale = mix(0.5, 18.0, wobble_scale);
	float noise_strength = mix(0.0, 0.12, wobble_strength);
	float contour_base_width = mix(0.008, 0.08, contour_line_width);
	float contour_pixel_width = mix(0.75, 6.0, contour_line_width);
	float contour_noise_scale = mix(0.5, 14.0, wobble_scale);
	float contour_noise_strength = mix(0.0, 0.35, wobble_strength) * contour_coord_spacing;

	float wobble_noise = smooth_rand13(local_pos * noise_scale);
	float wobble = (wobble_noise - 0.5) * noise_strength;
	float rim_aa = max(fwidth(rim), 0.001);
	float outline_wobble = wobble * 0.35;
	float edge_start = 1.0 - outline_width + outline_wobble;
	float outline_transition = max(softness + rim_aa * 1.5, 0.001);
	float outline = smoothstep(edge_start - outline_transition, edge_start, rim);
	float hard_edge_line = 0.0;
	if (hard_edge_width > 0.0 && hard_edge_threshold < 1.0) {
		float hard_edge_wobble_noise = smooth_fbm13(local_pos * contour_noise_scale + vec3(4.7, 8.1, 1.3));
		float hard_edge_wobble = (hard_edge_wobble_noise - 0.5) * mix(0.0, 0.04, wobble_strength);
		vec2 screen_pixel = 1.0 / VIEWPORT_SIZE;
		float hard_edge_radius = max(mix(0.75, 2.5, hard_edge_width) + hard_edge_wobble * 2.0, 0.25);
		vec2 hard_edge_offset = screen_pixel * hard_edge_radius;
		vec3 normal_px = sample_scene_normal(SCREEN_UV + vec2(hard_edge_offset.x, 0.0));
		vec3 normal_nx = sample_scene_normal(SCREEN_UV - vec2(hard_edge_offset.x, 0.0));
		vec3 normal_py = sample_scene_normal(SCREEN_UV + vec2(0.0, hard_edge_offset.y));
		vec3 normal_ny = sample_scene_normal(SCREEN_UV - vec2(0.0, hard_edge_offset.y));
		vec3 normal_pp = sample_scene_normal(SCREEN_UV + hard_edge_offset);
		vec3 normal_nn = sample_scene_normal(SCREEN_UV - hard_edge_offset);
		vec3 normal_pn = sample_scene_normal(SCREEN_UV + vec2(hard_edge_offset.x, -hard_edge_offset.y));
		vec3 normal_np = sample_scene_normal(SCREEN_UV + vec2(-hard_edge_offset.x, hard_edge_offset.y));
		float hard_edge_signal = 0.0;
		hard_edge_signal = max(hard_edge_signal, length(normal_px - normal_nx));
		hard_edge_signal = max(hard_edge_signal, length(normal_py - normal_ny));
		hard_edge_signal = max(hard_edge_signal, length(normal_pp - normal_nn));
		hard_edge_signal = max(hard_edge_signal, length(normal_pn - normal_np));
		float hard_edge_threshold_value = max(hard_edge_threshold + hard_edge_wobble * 0.35, 0.0001);
		float hard_edge_transition = max(hard_edge_threshold_value * 0.18 + fwidth(hard_edge_signal) * 1.5, 0.0001);
		hard_edge_line = smoothstep(hard_edge_threshold_value, hard_edge_threshold_value + hard_edge_transition, hard_edge_signal);
		hard_edge_line *= 1.0 - outline;
	}

	vec3 contour_noise_input = contour_use_uv
		? vec3(UV * contour_noise_scale, 0.0)
		: local_pos * contour_noise_scale;
	float contour_noise = smooth_fbm13(contour_noise_input + vec3(9.3, 2.1, 5.7));
	float contour_coord = contour_use_uv
		? dot(UV, uv_axis) + (contour_noise - 0.5) * contour_noise_strength
		: dot(local_pos, axis) + (contour_noise - 0.5) * contour_noise_strength;
	float contour_phase = contour_coord / contour_coord_spacing;
	float contour_distance = abs(fract(contour_phase + 0.5) - 0.5);
	float contour_aa = max(fwidth(contour_phase), 0.001);
	float compensated_width = contour_aa * contour_pixel_width;
	float line_half_width = mix(contour_base_width, compensated_width, contour_distance_compensation);
	float signed_light_alignment = dot(n, -light_direction);
	float surface_light = signed_light_alignment * 0.5 + 0.5;
	float curve_contour_threshold = texture(contour_light_threshold_curve, vec2(clamp(surface_light, 0.0, 1.0), 0.5)).r;
	float light_adjusted_line_half_width = mix(-contour_aa, line_half_width, curve_contour_threshold);
	float contour_line = 1.0 - smoothstep(light_adjusted_line_half_width, light_adjusted_line_half_width + contour_aa, contour_distance);
	float contour_coverage = clamp(max(light_adjusted_line_half_width, 0.0) * 2.0, 0.0, 1.0);
	float contour_filter_start = mix(0.55, 0.25, contour_far_spacing_compensation);
	float contour_filter_end = mix(1.6, 0.75, contour_far_spacing_compensation);
	float contour_filter = smoothstep(contour_filter_start, contour_filter_end, contour_aa);
	float filtered_contour_line = mix(contour_line, contour_coverage, contour_filter);

	vec4 fill_sample = texture(fill_texture, SCREEN_UV) * fill_color;
	vec4 final_color = mix(fill_sample, ink_color, outline);
	final_color.rgb = mix(final_color.rgb, ink_color.rgb, hard_edge_line);
	final_color.rgb = mix(final_color.rgb, ink_color.rgb, filtered_contour_line);
	ALBEDO = final_color.rgb;
	ALPHA = final_color.a;
}
