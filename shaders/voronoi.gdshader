shader_type canvas_item;

uniform int num_cities = 0;
uniform vec2 city_positions[100];
uniform vec4 city_colors[100];
uniform float city_powers[100]; 

uniform vec2 screen_size = vec2(1920.0, 1080.0);
uniform sampler2D noise_tex;
uniform float land_threshold = 0.4;

void fragment() {
	vec2 pos = UV * screen_size;
	
	float dist_uv = distance(UV, vec2(0.5, 0.5));
	float falloff = 1.0 - smoothstep(0.35, 0.5, dist_uv);
	
	float n = texture(noise_tex, UV).r; 
	n *= falloff;
	
	if (n < land_threshold) {
		vec3 deep_sea = vec3(0.05, 0.15, 0.3);
		vec3 shallow_sea = vec3(0.1, 0.35, 0.65);
		COLOR = vec4(mix(deep_sea, shallow_sea, n / land_threshold), 1.0);
	} else {
		float min_dist = 99999999.0;
		int closest_i = 0;
		
		float min_dist2 = 99999999.0;
		
		// ドメインワーピング1（大きくうねる空間の歪み）
		vec2 warp = vec2(
			texture(noise_tex, UV).r - 0.5,
			texture(noise_tex, vec2(UV.y, 1.0 - UV.x)).r - 0.5
		);
		// ドメインワーピング2（反転した座標からのノイズで鋭い凹凸を作る）
		vec2 warp2 = vec2(
			texture(noise_tex, vec2(1.0 - UV.x, 1.0 - UV.y)).r - 0.5,
			texture(noise_tex, vec2(1.0 - UV.y, UV.x)).r - 0.5
		);
		
		// 合成して大きな歪みと鋭い歪みを両立させる
		vec2 warped_pos = pos + warp * 300.0 + warp2 * 150.0;
		
		for (int i = 0; i < num_cities; i++) {
			float power = city_powers[i];
			float weight = max(power, 100.0); 
			
			float d = distance(warped_pos, city_positions[i]) / weight;
			
			if (d < min_dist) {
				min_dist2 = min_dist;
				min_dist = d;
				closest_i = i;
			} else if (d < min_dist2) {
				min_dist2 = d;
			}
		}
		
		vec3 color = city_colors[closest_i].rgb;
		
		float ratio = min_dist / max(min_dist2, 0.0001);
		color *= mix(1.0, 0.4, smoothstep(0.97, 1.0, ratio));
		
		color *= mix(0.7, 1.0, (n - land_threshold) / (1.0 - land_threshold));
		
		COLOR = vec4(color, 1.0);
	}
}
