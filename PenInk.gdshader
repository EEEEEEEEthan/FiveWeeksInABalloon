shader_type spatial;
render_mode unshaded, blend_mix, depth_prepass_alpha, cull_back;

#include "res://ShaderRandom.gdshaderinc"

uniform vec4 ink_color : source_color = vec4(0.05, 0.06, 0.08, 1.0);
uniform vec4 fill_color : source_color = vec4(1.0, 1.0, 1.0, 1.0);
uniform float outline_width : hint_range(0.001, 1.0, 0.001) = 0.18;
uniform float outline_softness : hint_range(0.001, 1.0, 0.001) = 0.2;
uniform float wobble_scale : hint_range(0.001, 1.0, 0.001) = 0.4;
uniform float wobble_strength : hint_range(0.001, 1.0, 0.001) = 0.2;

varying vec3 world_pos;
varying vec3 world_normal;
varying vec3 local_pos;

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

	float wobble_noise = smooth_rand13(local_pos * noise_scale);
	float wobble = (wobble_noise - 0.5) * noise_strength;
	float edge_start = 1.0 - outline_width + wobble;
	float outline = smoothstep(edge_start - softness, edge_start, rim);

	vec4 final_color = mix(fill_color, ink_color, outline);
	ALBEDO = final_color.rgb;
	ALPHA = final_color.a;
}
