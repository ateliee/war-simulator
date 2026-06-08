shader_type canvas_item;

uniform int num_cities = 0;
uniform vec2 city_positions[300];
uniform vec4 city_colors[300];
uniform float city_powers[300]; 

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
		// 海岸線（海側）の色味
		vec3 deep_sea = vec3(0.05, 0.15, 0.3);
		vec3 shallow_sea = vec3(0.15, 0.4, 0.7);
		COLOR = vec4(mix(deep_sea, shallow_sea, n / land_threshold), 1.0);
	} else {
		float min_dist = 99999999.0;
		int closest_i = 0;
		float min_dist2 = 99999999.0;
		
		vec2 warp = vec2(
			texture(noise_tex, UV).r - 0.5,
			texture(noise_tex, vec2(UV.y, 1.0 - UV.x)).r - 0.5
		);
		vec2 warp2 = vec2(
			texture(noise_tex, vec2(1.0 - UV.x, 1.0 - UV.y)).r - 0.5,
			texture(noise_tex, vec2(1.0 - UV.y, UV.x)).r - 0.5
		);
		
		vec2 warped_pos = pos + warp * 300.0 + warp2 * 150.0;
		
		for (int i = 0; i < num_cities; i++) {
			// 変動するpower（兵力）によるウェイト計算を削除し、純粋なボロノイ図にする
			// これにより「部隊が進行していないのに領土がグネグネ変わる」不自然さを解消
			float d = distance(warped_pos, city_positions[i]);
			
			if (d < min_dist) {
				min_dist2 = min_dist;
				min_dist = d;
				closest_i = i;
			} else if (d < min_dist2) {
				min_dist2 = d;
			}
		}
		
		vec3 color = city_colors[closest_i].rgb;
		
		// 陸地が青系勢力の場合に海と同化するのを防ぐため、陸地ベース色とブレンド
		vec3 base_land = vec3(0.85, 0.8, 0.7); 
		color = mix(base_land, color, 0.65); 
		
		// 海岸線（陸側）に黒くはっきりした輪郭線を描画して陸と海の切れ目を明確にする
		if (n - land_threshold < 0.008) {
			color = vec3(0.1, 0.1, 0.15); // 黒い縁取り
		} else {
			color *= mix(0.85, 1.0, (n - land_threshold) / (1.0 - land_threshold));
		}
		
		COLOR = vec4(color, 1.0);
	}
}
