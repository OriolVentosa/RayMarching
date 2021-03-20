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
	uniform float minRadius2 = 0.1;
	uniform float fixedRadius2 = 1.0;
	uniform float foldingLimit = 0.5;
	
float sdBox( vec3 p, vec3 b )
{
  vec3 q = abs(p) - b;
  return length(max(q,0.0)) + min(max(q.x,max(q.y,q.z)),0.0);
}

void sphereFold(inout vec3 z, inout float dz) {
	float r2 = dot(z,z);
	if (r2<minRadius2) { 
		// linear inner scaling
		float temp = (fixedRadius2/minRadius2);
		z *= temp;
		dz*= temp;
	} else if (r2<fixedRadius2) { 
		// this is the actual sphere inversion
		float temp =(fixedRadius2/r2);
		z *= temp;
		dz*= temp;
	}
}

void boxFold(inout vec3 z, inout float dz) {
	z = clamp(z, -foldingLimit, foldingLimit) * 2.0 - z;
}

float DE(vec3 position, int its)
{
  // precomputed somewhere
  vec4 scalevec = vec4(Scale, Scale, Scale, abs(Scale)) / minRadius2;
  float C1 = abs(Scale-1.0), C2 = pow(abs(Scale), float(1-its));

  // distance estimate
  vec4 p = vec4(position.xyz, 1.0), p0 = vec4(position.xyz, 1.0);  // p.w is knighty's DEfactor
  for (int i=0; i<its; i++) {
    p.xyz = clamp(p.xyz, -1.0, 1.0) * 2.0 - p.xyz;  // box fold: min3, max3, mad3
    float r2 = dot(p.xyz, p.xyz);  // dp3
    p.xyzw *= clamp(max(minRadius2/r2, minRadius2), 0.0, 1.0);  // sphere fold: div1, max1.sat, mul4
    p.xyzw = p*scalevec + p0;  // mad4
  }
  return (length(p.xyz) - C1) / p.w - C2;
}

float GetDist(vec3 pos){
	float d = DE(pos,Iterations);
	return d;
}

float map( in vec3 rayP)
{
	return GetDist(rayP/Scale)*Scale;
}


vec3 GetNormal(vec3 p){
	vec2 e = vec2(0.01, 0); 
	vec3 n = GetDist(p)-vec3(
		map(p - e.xyy),
		map(p - e.yxy),
		map(p - e.yyx)
	);
	return normalize(n);
}


vec2 interesct( in vec3 ro, in vec3 rd, in float tmax, in int its)
{
    float t = 0.0;
	float i=0.0;
	for( i=0.0; i<128.0; i++ )
	{
        vec3 rayP = ro + t*rd;
		float d = DE(rayP,its);
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
	vec2 rayData = interesct(ro, rd, tmax, Iterations);
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
		
		col = solidColor * combinedShading;


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