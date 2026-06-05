shader_type canvas_item;

uniform int num_cities = 0;
uniform vec2 city_positions[100];
uniform vec4 city_colors[100];
uniform int city_factions[100];
uniform float faction_powers[5]; 

uniform vec2 screen_size = vec2(1920.0, 1080.0);
uniform sampler2D noise_tex;
uniform float land_threshold = 0.4; // 陸地のしきい値を調整

void fragment() {
	vec2 pos = UV * screen_size;
	
	// 滑らかなビネット（減衰）マスクで複数大陸を生成
	float dist_uv = distance(UV, vec2(0.5, 0.5));
	float falloff = 1.0 - smoothstep(0.35, 0.5, dist_uv);
	
	float n = texture(noise_tex, UV).r; 
	n *= falloff;
	
	if (n < land_threshold) {
		vec3 deep_sea = vec3(0.05, 0.15, 0.3);
		vec3 shallow_sea = vec3(0.1, 0.35, 0.65);
		COLOR = vec4(mix(deep_sea, shallow_sea, n / land_threshold), 1.0);
	} else {
		float min_dist = 999999.0;
		int closest_i = 0;
		
		float min_dist2 = 999999.0;
		
		for (int i = 0; i < num_cities; i++) {
			int fac = city_factions[i];
			float power = faction_powers[fac];
			
			float weight = max(power, 1.0);
			float d = distance(pos, city_positions[i]) - weight * 0.001;
			
			if (d < min_dist) {
				min_dist2 = min_dist;
				min_dist = d;
				closest_i = i;
			} else if (d < min_dist2) {
				min_dist2 = d;
			}
		}
		
		vec3 color = city_colors[closest_i].rgb;
		
		if (min_dist2 - min_dist < 3.0) {
			color = vec3(0.1, 0.1, 0.1); 
		}
		
		color *= mix(0.7, 1.0, (n - land_threshold) / (1.0 - land_threshold));
		
		COLOR = vec4(color, 1.0);
	}
}
