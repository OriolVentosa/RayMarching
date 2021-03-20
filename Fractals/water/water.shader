shader_type canvas_item;

uniform vec2 tile_factor = vec2(2.0,2.0);
uniform float aspect_ratio = 0.5;

uniform vec2 offset_scale = vec2(2.0,1.0);

void fragment(){
	vec2 tiled_uvs = UV * tile_factor - vec2(float(int(UV.x * tile_factor.x)),float(int(UV.y * tile_factor.y)));
	tiled_uvs.y *= aspect_ratio;
	
	vec2 waves_uv_offset;
	waves_uv_offset.x = cos((TIME + tiled_uvs.x +tiled_uvs.y)*offset_scale.x);
	waves_uv_offset.y = sin((TIME + tiled_uvs.x +tiled_uvs.y)*offset_scale.y);
	

	COLOR = texture(TEXTURE , tiled_uvs + waves_uv_offset * 0.1);
//	COLOR = vec4(tiled_uvs, 0.0 , 1.0);
//	COLOR = vec4(tiled_uvs + waves_uv_offset, 0.0 , 1.0);
}