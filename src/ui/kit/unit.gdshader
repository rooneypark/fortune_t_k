shader_type canvas_item;
// Unit / portrait look: hue shift (temporary art variants), white hit flash,
// fade, grey (respawn / locked) and a dark silhouette (not owned).
uniform float hue : hint_range(0.0, 1.0) = 0.0;
uniform float flash : hint_range(0.0, 1.0) = 0.0;
uniform float alpha : hint_range(0.0, 1.0) = 1.0;
uniform float gray : hint_range(0.0, 1.0) = 0.0;
uniform float silhouette : hint_range(0.0, 1.0) = 0.0;
uniform vec4 tint : source_color = vec4(1.0);

vec3 rgb2hsv(vec3 c) {
	vec4 K = vec4(0.0, -1.0 / 3.0, 2.0 / 3.0, -1.0);
	vec4 p = mix(vec4(c.bg, K.wz), vec4(c.gb, K.xy), step(c.b, c.g));
	vec4 q = mix(vec4(p.xyw, c.r), vec4(c.r, p.yzx), step(p.x, c.r));
	float d = q.x - min(q.w, q.y);
	float e = 1.0e-10;
	return vec3(abs(q.z + (q.w - q.y) / (6.0 * d + e)), d / (q.x + e), q.x);
}

vec3 hsv2rgb(vec3 c) {
	vec4 K = vec4(1.0, 2.0 / 3.0, 1.0 / 3.0, 3.0);
	vec3 p = abs(fract(c.xxx + K.xyz) * 6.0 - K.www);
	return c.z * mix(K.xxx, clamp(p - K.xxx, 0.0, 1.0), c.y);
}

void fragment() {
	vec4 c = texture(TEXTURE, UV) * COLOR;
	if (hue > 0.001) {
		vec3 hsv = rgb2hsv(c.rgb);
		// keep skin / outlines: only shift saturated pixels
		float k = smoothstep(0.18, 0.35, hsv.y);
		vec3 shifted = hsv2rgb(vec3(fract(hsv.x + hue), hsv.y, hsv.z));
		c.rgb = mix(c.rgb, shifted, k);
	}
	c.rgb *= tint.rgb;
	float g = dot(c.rgb, vec3(0.299, 0.587, 0.114));
	c.rgb = mix(c.rgb, vec3(g * 0.8 + 0.1), gray);
	c.rgb = mix(c.rgb, vec3(0.08, 0.1, 0.16), silhouette);
	c.rgb = mix(c.rgb, vec3(1.0), flash);
	c.a *= alpha;
	COLOR = c;
}
