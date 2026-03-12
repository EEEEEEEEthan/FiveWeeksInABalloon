shader_type spatial;
render_mode unshaded, blend_mix, depth_prepass_alpha, cull_back;

#include "res://ShaderRandom.gdshaderinc"

uniform vec4 ink_color : source_color = vec4(0.05, 0.06, 0.08, 1.0);
uniform vec4 fill_color : source_color = vec4(1.0, 1.0, 1.0, 1.0);
uniform float outline_width : hint_range(0.001, 1.0, 0.001) = 0.18;
uniform float outline_softness : hint_range(0.001, 1.0, 0.001) = 0.2;
uniform float wobble_scale : hint_range(0.001, 1.0, 0.001) = 0.4;
uniform float wobble_strength : hint_range(0.001, 1.0, 0.001) = 0.2;
uniform vec3 contour_axis = vec3(0.0, 1.0, 0.0);
uniform bool contour_use_uv = false;
uniform float contour_spacing : hint_range(0.02, 2.0, 0.01) = 0.22;
uniform float contour_line_width : hint_range(0.0, 1.0, 0.001) = 0.14;
uniform float contour_distance_compensation : hint_range(0.0, 1.0, 0.001) = 0.82;

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

void vertex() {
	world_pos = (MODEL_MATRIX * vec4(VERTEX, 1.0)).xyz;
	world_normal = normalize(MODEL_NORMAL_MATRIX * NORMAL);
	local_pos = VERTEX;
}

void fragment() {
	vec3 n = normalize(world_normal);
	vec3 view_dir = normalize(CAMERA_POSITION_WORLD - world_pos);
	float rim = 1.0 - max(dot(n, view_dir), 0.0);
	float softness = mix(0.002, 0.08, outline_softness);
	float noise_scale = mix(0.5, 18.0, wobble_scale);
	float noise_strength = mix(0.0, 0.12, wobble_strength);
	float spacing = max(contour_spacing, 0.0001);
	float contour_base_width = mix(0.008, 0.08, contour_line_width);
	float contour_pixel_width = mix(0.75, 6.0, contour_line_width);
	float contour_noise_scale = mix(0.5, 14.0, wobble_scale);
	float contour_noise_strength = mix(0.0, 0.35, wobble_strength) * spacing;

	float wobble_noise = smooth_rand13(local_pos * noise_scale);
	float wobble = (wobble_noise - 0.5) * noise_strength;
	float edge_start = 1.0 - outline_width + wobble;
	float outline = smoothstep(edge_start - softness, edge_start, rim);

	vec3 axis = contour_axis / max(length(contour_axis), 0.0001);
	vec2 uv_axis = contour_axis_to_uv_axis(axis);
	vec3 contour_noise_input = contour_use_uv
		? vec3(UV * contour_noise_scale, 0.0)
		: local_pos * contour_noise_scale;
	float contour_noise = smooth_fbm13(contour_noise_input + vec3(9.3, 2.1, 5.7));
	float contour_coord = contour_use_uv
		? dot(UV, uv_axis) + (contour_noise - 0.5) * contour_noise_strength
		: dot(local_pos, axis) + (contour_noise - 0.5) * contour_noise_strength;
	float contour_phase = contour_coord / spacing;
	float contour_distance = abs(fract(contour_phase + 0.5) - 0.5);
	float contour_aa = max(fwidth(contour_phase), 0.001);
	float compensated_width = contour_aa * contour_pixel_width;
	float line_half_width = mix(contour_base_width, compensated_width, contour_distance_compensation);
	float contour_line = 1.0 - smoothstep(line_half_width, line_half_width + contour_aa, contour_distance);

	vec4 final_color = mix(fill_color, ink_color, outline);
	final_color.rgb = mix(final_color.rgb, ink_color.rgb, contour_line);
	ALBEDO = final_color.rgb;
	ALPHA = final_color.a;
}
