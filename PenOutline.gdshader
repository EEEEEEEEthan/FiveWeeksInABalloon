shader_type spatial;
render_mode unshaded, cull_front, depth_prepass_alpha;

#include "res://ShaderRandom.gdshaderinc"

uniform vec4 ink_color : source_color = vec4(0.05, 0.06, 0.08, 1.0);
uniform float outline_width : hint_range(0.001, 1.0, 0.001) = 0.22;
uniform float stroke_scale : hint_range(0.001, 1.0, 0.001) = 0.45;
uniform float stroke_strength : hint_range(0.001, 1.0, 0.001) = 0.28;

varying vec3 local_pos;
varying vec3 relative_pos;
varying vec3 world_normal;
varying vec3 world_pos;

float brush_noise(vec3 p) {
	float large = smooth_fbm13(p + vec3(1.7, 4.3, 8.1));
	float medium = smooth_fbm13(p * 2.07 + vec3(11.4, 6.8, 3.2));
	float detail = smooth_rand13(p * 4.1 + vec3(5.9, 13.1, 2.7));
	return large * 0.55 + medium * 0.3 + detail * 0.15;
}

void vertex() {
	float width = mix(0.002, 0.09, outline_width);
	local_pos = VERTEX;
	relative_pos = normalize(VERTEX);
	world_normal = normalize(MODEL_NORMAL_MATRIX * NORMAL);
	VERTEX += NORMAL * width;
	world_pos = (MODEL_MATRIX * vec4(VERTEX, 1.0)).xyz;
}

void fragment() {
	float scale = mix(0.8, 10.0, stroke_scale);
	float strength = mix(0.0, 0.42, stroke_strength);
	vec3 n = normalize(world_normal);
	vec3 view_dir = normalize(CAMERA_POSITION_WORLD - world_pos);
	float rim = 1.0 - max(dot(n, view_dir), 0.0);
	float edge_band = smoothstep(0.8, 0.995, rim);
	vec3 brush_pos = relative_pos * scale;
	float brush = brush_noise(brush_pos);
	float keep = brush + (1.0 - strength * edge_band);

	if (keep < 0.92) {
		discard;
	}

	float ink_mix = mix(0.84, 1.0, brush);
	ALBEDO = ink_color.rgb * ink_mix;
	ALPHA = ink_color.a;
}
