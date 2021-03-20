shader_type canvas_item;

uniform float time_factor = 4.0;
uniform vec2 amplitude = vec2(10.0, 5.0);

void vertex() {
	VERTEX.x += cos(TIME*time_factor) * amplitude.x;
	VERTEX.y += sin(TIME*time_factor) * amplitude.y;
}