float rand13(vec3 p) {
	p = fract(p * 0.1031);
	p += dot(p, p.yzx + 31.32);
	return fract((p.x + p.y) * p.z);
}

float smooth_rand13(vec3 p) {
	vec3 cell = floor(p);
	vec3 f = fract(p);
	vec3 u = f * f * (3.0 - 2.0 * f);

	float n000 = rand13(cell + vec3(0.0, 0.0, 0.0));
	float n100 = rand13(cell + vec3(1.0, 0.0, 0.0));
	float n010 = rand13(cell + vec3(0.0, 1.0, 0.0));
	float n110 = rand13(cell + vec3(1.0, 1.0, 0.0));
	float n001 = rand13(cell + vec3(0.0, 0.0, 1.0));
	float n101 = rand13(cell + vec3(1.0, 0.0, 1.0));
	float n011 = rand13(cell + vec3(0.0, 1.0, 1.0));
	float n111 = rand13(cell + vec3(1.0, 1.0, 1.0));

	float nx00 = mix(n000, n100, u.x);
	float nx10 = mix(n010, n110, u.x);
	float nx01 = mix(n001, n101, u.x);
	float nx11 = mix(n011, n111, u.x);
	float nxy0 = mix(nx00, nx10, u.y);
	float nxy1 = mix(nx01, nx11, u.y);

	return mix(nxy0, nxy1, u.z);
}

float smooth_fbm13(vec3 p) {
	float sum = 0.0;
	float weight = 0.5;
	float total_weight = 0.0;

	for (int i = 0; i < 4; i++) {
		sum += smooth_rand13(p) * weight;
		total_weight += weight;
		p = p * 2.03 + vec3(11.2, 7.3, 5.4);
		weight *= 0.5;
	}

	return sum / total_weight;
}
