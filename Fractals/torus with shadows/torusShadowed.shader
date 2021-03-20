shader_type spatial;

uniform int MAX_STEPS = 100;
uniform float MAX_DIST = 100.0;
uniform float SURF_DIST = 0.001;

void vertex(){
	
}

float smoothMin(float dstA, float dstB, float k){
	float h = max(k-abs(dstA-dstB),0)/k;
	return min(dstA,dstB) - h*h*h*k*(1.0/6.0);
}

float GetDist(vec3 p){
	float d1 = length(vec2(length((p+vec3(0.0,10.0,0.0)).xz)-3.0, p.y))-0.5;
	float d2 = p.y+1.0;
	float d3 = length(p + vec3(0,0,4)) - 3.0;
	float min1 = min(d3,d1);
	float min2 = smoothMin(d3,d1,2);
	return min(d2, min2);
}

float Raymarch(vec3 ro, vec3 rd){
	float dO = 0.0;
	float dS;
	for(int i = 0; i<MAX_STEPS; i++){
		vec3 p = ro +dO*rd;
		dS = GetDist(p);
		dO += dS;
		if(dS < SURF_DIST || dO>MAX_DIST) break;
	}
	return dO;
}

vec3 GetNormal(vec3 p){
	vec2 e = vec2(0.01, 0); 
	vec3 n = GetDist(p)-vec3(
		GetDist(p - e.xyy),
		GetDist(p - e.yxy),
		GetDist(p - e.yyx)
	);
	return normalize(n);
}

float GetLight(vec3 p) {
    vec3 lightPos = vec3(0, 5, 3);
    vec3 l = normalize(lightPos-p);
    vec3 n = GetNormal(p);
    
    float dif = clamp(dot(n, l), 0., 1.);
    float d = Raymarch(p+n*2.*0.01, l);
    if(d<length(lightPos-p)) dif *= .1;
	
    return dif;
}

void fragment(){
	vec2 centeredUV;
	centeredUV.x = UV.x*3.0 - float(int(UV.x*3.0));
	centeredUV.y = UV.y*2.0 - float(int(UV.y*2.0));
	centeredUV -= 0.5;

	vec3 ro = (CAMERA_MATRIX*vec4(0.0,0.0,0.0,1.0)).xyz;
	vec3 hitPos = (CAMERA_MATRIX*vec4(VERTEX,1.0)).xyz;
	vec3 rd = normalize(hitPos-ro);//normalize(vec3(centeredUV.x, centeredUV.y,1));
	
	float d = Raymarch(ro,rd);
	vec3 col = vec3(0,0,0);
	 
	if(d<MAX_DIST){
		vec3 p = ro + rd * d;
		vec3 n = GetNormal(p);
		float dif = GetLight(p);
		col = vec3(dif);
	}
	else{
		ALPHA = 0.0;
	}
	ALBEDO = vec3(col);
}