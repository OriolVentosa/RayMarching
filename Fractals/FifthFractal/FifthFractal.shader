shader_type spatial;

//Raymarching
uniform int MAX_STEPS = 100;
uniform float MAX_DIST = 100.0;
uniform float SURF_DIST = 0.001;
uniform vec3 directionalLight =vec3(1,1,0);
uniform vec3 LightColor = vec3(1,1,1);
uniform vec3 MainColor = vec3(1,1,0);
uniform float LightIntensity = 1.0;
uniform vec2 ShadowDist = vec2(0.1, 2);
uniform float ShadowIntensity = 1.0;
uniform float aOStepsize = 0.5;
uniform int aOIterations = 100;
uniform float aOIntensity = 1.0;

//Fractal
uniform int Iterations = 4;
uniform float Bailout = 0.01;
uniform float Power = 8.0;

float smoothMin(float dstA, float dstB, float k){
	float h = max(k-abs(dstA-dstB),0)/k;
	return min(dstA,dstB) - h*h*h*k*(1.0/6.0);
}

float sdPyramid( vec3 p, float h)
{
  float m2 = h*h + 0.25;
    
  p.xz = abs(p.xz);
  p.xz = (p.z>p.x) ? p.zx : p.xz;
  p.xz -= 0.5;

  vec3 q = vec3( p.z, h*p.y - 0.5*p.x, h*p.x + 0.5*p.y);
   
  float s = max(-q.x,0.0);
  float t = clamp( (q.y-0.5*p.z)/(m2+0.25), 0.0, 1.0 );
    
  float a = m2*(q.x+s)*(q.x+s) + q.y*q.y;
  float b = m2*(q.x+0.5*t)*(q.x+0.5*t) + (q.y-m2*t)*(q.y-m2*t);
    
  float d2 = min(q.y,-q.x*m2-q.y*0.5) > 0.0 ? 0.0 : min(a,b);
  float preScale = sqrt( (d2+q.z*q.z)/m2 ) * sign(max(q.z,-p.y));
  return preScale;
}

float Sierpinski_tetrahedron(vec3 p, float h, int its)
{
	vec3 tetrahedron;
	float dist = sdPyramid(p,h);
	vec3 current_p = vec3(0,0,0);
	for(int i = 1; i<its+1; i++){
		for(int j = 1; j < i*i+1; j++){
			if ((j-1) % i == 0){
				current_p.x = -0.5 * float(i-1);
				current_p.z = -0.5 * float(i-1) + float((j-1)/i);
			}
			current_p.y = float(i-1);
			dist = min(dist,sdPyramid(p+current_p,h));
			current_p.x += 1.0;
		}
	}
	return dist;
}

float sdBox( vec3 p, vec3 b )
{
  vec3 q = abs(p) - b;
  return length(max(q,0.0)) + min(max(q.x,max(q.y,q.z)),0.0);
}

float DE(vec3 p)
{
	float d = sdBox(p, vec3(1.0));
	
	float s = 2.67;
   for( int m=0; m<8; m++ )
   {
      vec3 a = mod( p*s, 2.0 )-1.0;
      s *= 3.0;
      vec3 r = abs(1.0 - 3.0*abs(a));

      float da = max(r.x,r.y);
      float db = max(r.y,r.z);
      float dc = max(r.z,r.x);
      float c = (min(da,min(db,dc))-1.0)/s;

      d = max(d,c);
   }

   return d;
}

float sierpinski(vec3 pos)
{
   const float Scale = 1.85;
   const float Offset = 0.0;

   vec3 a1 = vec3(1,1,1);
	vec3 a2 = vec3(-1,-1,1);
	vec3 a3 = vec3(1,-1,-1);
	vec3 a4 = vec3(-1,1,-1);
	vec3 c;
	float dist, d;
	for (int n = 0; n < Iterations; n++)
	{
      if(pos.x+pos.y<0.) pos.xy = -pos.yx; // fold 1
      if(pos.x+pos.z<0.) pos.xz = -pos.zx; // fold 2
      if(pos.y+pos.z<0.) pos.zy = -pos.yz; // fold 3
      pos = pos*Scale - Offset*(Scale-1.0);
	}
	return length(pos) * pow(Scale, -float(Iterations));
}

float GetDist(vec3 pos){
	float d = DE(pos);
	return d;
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
float hardShadow(vec3 ro , vec3 rd, float mint, float maxt)
{
	for(float t = mint;t<maxt;t=t)
	{
		float h = GetDist(ro+rd*t);
		if(h<0.01)
		{
			return 0.0;
		}
		t+=h;
	}
	return 1.0;
}

float ambientOcclusion(vec3 p, vec3 n){
	float steps = aOStepsize;
	float ao = 0.0;
	float dist;
	for(int i= 1; i<=aOIterations ; i++){
		dist = steps * float(i);
		ao += max(0, dist - GetDist(p+n*dist))/dist;
	}
	
	return 1.0-ao * aOIntensity;
}

vec3 newLight(vec3 p, vec3 n){
	//Directional light
	vec3 light = (LightColor * dot(directionalLight,n)*0.5 + 0.5)*LightIntensity;
	//Shadow
	float shadow = hardShadow(p, directionalLight, ShadowDist.x, ShadowDist.y)*0.5+0.5;
	shadow = max(0.0, pow(shadow, ShadowIntensity));
	//Ambient Occlusion
	float ao = ambientOcclusion(p,n);
	
	light *= shadow;
	light *= ao;
	light *= MainColor;
	return light;
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
		
		//Shading
		vec3 n = GetNormal(p);
		vec3 s = newLight(p,n);
		col = s;
	}
	else{
		ALPHA = 0.0;
	}
	ALBEDO = vec3(col);
}