shader_type spatial;

uniform int MAX_STEPS = 100;
uniform float MAX_DIST = 100.0;
uniform float SURF_DIST = 0.0001;
uniform int Iterations = 20;
uniform float Power = 10;

uniform vec3 cameraTransform = vec3(0.0,0.0,0.0);


void vertex(){
	
}

float smoothMin(float dstA, float dstB, float k){
	float h = max(k-abs(dstA-dstB),0)/k;
	return min(dstA,dstB) - h*h*h*k*(1.0/6.0);
}

float GetDist(vec3 p){
	float d1 = length(vec2(length(p.xz)-5.0, p.y))-1.0;
	float d2 = length(p + vec3(0,0,6)) - 3.0;
	float d3 = length(vec2(length((p + vec3(0,-3,12)).xy) -5.0, p.z))-1.0;
	float min1 = smoothMin(d1,d2,15);
	return smoothMin(min1,d3,3);
}

float GetDist2(vec3 pos) {
	vec3 z = pos;
	float dr = 1.0;
	float r = 0.0;
	for (int i = 0; i < Iterations ; i++) {
		r = length(z);
		if (r>10000.0) break;
		
		// convert to polar coordinates
		float theta = acos(z.z/r);
		float phi = atan(z.y,z.x);
		dr =  pow( r, Power-1.0)*Power*dr + 1.0;
		
		// scale and rotate the point
		float zr = pow( r,Power);
		theta = theta*Power;
		phi = phi*Power;
		
		// convert back to cartesian coordinates
		z = zr*vec3(sin(theta)*cos(phi), sin(phi)*sin(theta), cos(theta));
		z+=pos;
	}
	return 0.5*log(r)*r/dr;
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
	return n;
}

void fragment(){
	vec2 centeredUV;
	centeredUV.x = UV.x*3.0 - float(int(UV.x*3.0));
	centeredUV.y = UV.y*2.0 - float(int(UV.y*2.0));
	centeredUV -= 0.5;

	vec3 ro = cameraTransform;
	vec3 hitPos = VERTEX;
	vec3 rd = normalize(hitPos-ro);//normalize(vec3(centeredUV.x, centeredUV.y,1));
	
	float d = Raymarch(ro,rd);
	vec3 col = vec3(0,0,0);
	 
	if(d<MAX_DIST){
		vec3 p = ro + rd * d;
		vec3 n = GetNormal(p);
		col = normalize(n);
	}
	else{
		ALPHA = 0.0;
	}
	ALBEDO = vec3(col);
}