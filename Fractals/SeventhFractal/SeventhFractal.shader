shader_type spatial;

	//colors
	uniform vec3 skyColor = vec3(0.1);//vec3(0.56, 0.74, 0.53)*0.75;
	uniform vec3 solidColor = vec3(0.72, 0.86, 0.89);
	uniform float colorInvert = 0.0; // can be turned to zero, dont forget to switch minus signs then!
	uniform float glowRadius = 100.0;
	
	uniform sampler2D gradient;
	
	uniform vec3 color1 = vec3(0.5,0.4, 0);
	uniform vec3 color2 = vec3(0.5, 0, 0.5);
//Fractal
	uniform int Iterations = 8;
	uniform float Scale = 10.0;
float sdBox( vec3 p, vec3 b )
{
  vec3 q = abs(p) - b;
  return length(max(q,0.0)) + min(max(q.x,max(q.y,q.z)),0.0);
}

float DE(vec3 p, int it)
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

vec3 Iteration(vec3 point){
	if (point.x>1.0){
		point.x = 2.0 - point.x; 
	}
	else if (point.x < -1.0){
		point.x = -2.0 - point.x;
	}
	if (point.y>1.0){
		point.y = 2.0 - point.y; 
	}
	else if (point.y < -1.0){
		point.y = -2.0 - point.y;
	}
	if (point.z>1.0){
		point.z = 2.0 - point.z; 
	}
	else if (point.x < -1.0){
		point.z = -2.0 - point.z;
	}
	if (distance(point, vec3(0,0,0))<0.5)
	{
		point = point*4.0;
	}
	else if(distance(point, vec3(0,0,0))<1.0)
	{
		point = point/(distance(point, vec3(0,0,0))*distance(point, vec3(0,0,0)));
	}
	return point;
}

vec3 orbitTrap(vec3 point){
	float dist = 1.0;
	for(int i = 0 ; i<8 ; i++){
		point = Iteration(point);
		dist = (point.x + point.y) * dist;
	}
	return (texture(gradient,vec2(dist,0)).rgb);
}

float GetDist(vec3 pos){
	float d = DE(pos,Iterations);
	return d;
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

float map( in vec3 rayP)
{
	return GetDist(rayP/Scale)*Scale;
}

vec2 interesct( in vec3 ro, in vec3 rd, in float tmax )
{
    float t = 0.0;
	float i=0.0;
	for( i=0.0; i<128.0; i++ )
	{
        vec3 rayP = ro + t*rd;
		float d = map(rayP);
		if(d<(0.0001*t) ||  t>tmax ) return vec2(t, i);
		t += d;
	}

	return vec2(t, i);
}

vec4 render( in vec3 ro, in vec3 rd , vec3 vertex)
{
    //lights, point light at player position
	vec3 light = -normalize(rd);

    // bounding plane
    float tmax = 1024.0;

	vec3 col;
	vec2 rayData = interesct(ro, rd, tmax);
    float t = rayData.x;

	if( t>tmax)
    {
		col = skyColor;
	}
	else
	{
		//lighting
		vec3 rayP = ro + t*rd;
		vec3 nor = GetNormal(rayP);
		float distOcclusion = 1.0 - rayData.y * 2.0 / 256.0;
		float diffLighting = clamp(dot(light, nor), 0.0, 1.0);
		
		//inverted specular lighting, darkens the reflections, which lightens after inversion 
		float specLighting = colorInvert + pow(clamp(dot(nor, normalize(light-rd)),0.0,1.0), 32.0);

		float combinedShading = diffLighting * 0.65 + distOcclusion * 0.4 + specLighting * 0.15 + 0.1;
		vec3 colors = orbitTrap((rayP/Scale));
		col = colors * combinedShading;

		//apply fog
		float fogStrength = exp(-t*0.01);
		col = skyColor*(1.0-fogStrength) + col*fogStrength;
	}
	
	//inverting colors and contrast enhancing
	col = vec3(colorInvert) + col;
	col = vec3(col.x*col.x,col.y*col.y,col.z*col.z);
	vec4 colandi = vec4(col,rayData.y);
	return colandi;
}

void fragment(){
	vec2 centeredUV;
	centeredUV.x = UV.x*3.0 - float(int(UV.x*3.0));
	centeredUV.y = UV.y*2.0 - float(int(UV.y*2.0));
	centeredUV -= 0.5;

	vec3 ro = (CAMERA_MATRIX*vec4(0.0,0.0,0.0,1.0)).xyz;
	vec3 hitPos = (CAMERA_MATRIX*vec4(VERTEX,1.0)).xyz;
	vec3 rd = normalize(hitPos-ro);//normalize(vec3(centeredUV.x, centeredUV.y,1));
	
	vec4 renderResult = render(ro,rd,hitPos);
	ALBEDO.rgb = renderResult.xyz;
//	if(renderResult.w > glowRadius+1.0) EMISSION = vec3(1,1,1);
}