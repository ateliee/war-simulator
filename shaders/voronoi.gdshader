shader_type canvas_item;

uniform int num_cities = 0;
uniform vec2 city_positions[100];
uniform vec4 city_colors[100];
uniform vec2 screen_size = vec2(1152.0, 648.0);

uniform sampler2D noise_tex;
uniform float land_threshold = 0.525; 

void fragment() {
	vec2 pos = UV * screen_size;
	
	float n = texture(noise_tex, UV).r;
	if (n < land_threshold) {
		COLOR = vec4(0.1, 0.3, 0.6, 1.0);
	} else {
		float min_dist = 999999.0;
		int closest_i = 0;
		
		float min_dist2 = 999999.0;
		
		for (int i = 0; i < num_cities; i++) {
			float d = distance(pos, city_positions[i]);
			if (d < min_dist) {
				min_dist2 = min_dist;
				min_dist = d;
				closest_i = i;
			} else if (d < min_dist2) {
				min_dist2 = d;
			}
		}
		
		vec3 color = city_colors[closest_i].rgb;
		
		if (min_dist2 - min_dist < 2.0) {
			color = vec3(0.1, 0.1, 0.1); 
		}
		
		color *= mix(0.7, 1.0, (n - land_threshold) / (1.0 - land_threshold));
		
		COLOR = vec4(color, 1.0);
	}
}
