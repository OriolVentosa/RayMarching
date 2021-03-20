shader_type spatial;

uniform int MAX_STEPS = 100;
uniform float MAX_DIST = 100.0;
uniform float SURF_DIST = 0.001;
uniform int Iterations = 4;
uniform float Bailout = 0.01;
uniform float Power = 8.0;
uniform vec3 backGround = vec3(0,0,0);


//Blinn-Phong-reflection

uniform vec3 lightPos = vec3(5.0, 5.0, 5.0);
uniform vec3 lightColor = vec3(1.0, 1.0, 1.0);
uniform float lightPower = 40.0;
uniform vec3 ambientColor = vec3(0.1, 0.0, 0.0);
uniform vec3 diffuseColor = vec3(0.5, 0.0, 0.0);
uniform vec3 specColor = vec3(1.0, 1.0, 1.0);
uniform float shininess = 16.0;
const float screenGamma = 2.2; // Assume the monitor is calibrated to the sRGB color space


float GetDist(vec3 pos){
	vec3 z = pos;
	float dr = 1.0;
	float r = 0.0;
	for (int i = 0; i < Iterations ; i++) {
		r = length(z);
		if (r>Bailout) break;
		
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
	return normalize(n);
}

float GetLight(vec3 p) {
    vec3 l = normalize(lightPos-p);
    vec3 n = GetNormal(p);
    
    float dif = clamp(dot(n, l), 0., 1.);
    float d = Raymarch(p+n*2.*0.01, l);
    if(d<length(lightPos-p)) dif *= .6;
    return dif;
}

float orbitTrap(vec3 trap, vec3 point){
	float dist = 1e20;
	vec3 vector = vec3(0,0,0);
	for(int i = 0; i<MAX_STEPS; i++){
		vector = vector * vector;
		vector += trap;
		vec3 zMinus = -point;
		float zMinusModulus = distance(vec3(0,0,0),zMinus);
		if(zMinusModulus<dist) dist = zMinusModulus;
	}
	return dist;
}

vec3 processLight(vec3 normalInterp, vec3 vertPos){
	vec3 normal = normalize(normalInterp);
	vec3 lightDir = lightPos - vertPos;
	float distance = length(lightDir);
	distance = distance * distance;
	lightDir = normalize(lightDir);
	
	float lambertian = max(dot(lightDir, normal), 0.0);
	float specular = 0.0;
	
	if (lambertian > 0.0) {
		vec3 viewDir = normalize(-vertPos);
		vec3 halfDir = normalize(lightDir + viewDir);
		float specAngle = max(dot(halfDir, normal), 0.0);
		specular = pow(specAngle, shininess);
	}

  vec3 colorLinear = ambientColor +
                     diffuseColor * lambertian * lightColor * lightPower / distance +
                     specColor * specular * lightColor * lightPower / distance;
 	 vec3 colorGammaCorrected = pow(colorLinear, vec3(1.0 / screenGamma));
	return colorGammaCorrected;
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
	vec3 col = backGround;
	 
	if(d<MAX_DIST){
		vec3 p = ro + rd * d;
		vec3 n = GetNormal(p);
		col = processLight(n,p);
	}
	else{
		ALPHA = 0.0
	}
	ALBEDO.rgb = col;
}