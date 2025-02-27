shader_type spatial;
render_mode unshaded, depth_test_disabled;

//ray marching parameters
uniform int MAX_STEPS = 100;
uniform float MAX_DIST = 100.0;
uniform float Collision_thres = 0.01;
uniform float BLEND = 1.0;
uniform int POWER = 8; 
uniform int MAX_ITERS = 15;
uniform vec3 LightDir = vec3(0.0);
uniform vec3 colorAmix = vec3(0.0);
uniform vec3 colorBmix = vec3(0.0);
uniform int darkness = 75;
uniform float animationtime = 0.02f;

vec2 mandelbulbSDF(vec3 p)
{
	float r;
	float dr = 1.0;
	float n = float(POWER) + animationtime * TIME;
	vec3 v = p;
	int i = 0;
	
	for(; i < MAX_ITERS; i++)
	{
		//convert to polar
		r = length(v);
		if(r>2.0)
			break;
		float phi = atan(v.y/v.x);
		float theta = acos(v.z/r);
		dr =  pow( r, n-1.0)* n *dr + 1.0;
		
		//get v^n
		float rn = pow(r,n);
		float vx = rn * sin(n*theta) * cos(n*phi);
		float vy = rn * sin(n*theta) * sin(n*phi);
		float vz = rn * cos(n*theta);
		
		vec3 vn = vec3(vx,vy,vz);
		
		//v^n + c
		v = vn + p;
		
		
	}
	
	return vec2(0.5*log(r)*r/dr, float(i));
}

vec2 testmandelbulbSDF(vec3 pos)
{
	vec3 z = pos;
	float dr = 1.0;
	float r = 0.0;
	float Power = float(POWER);
	for (int i = 0; i < MAX_ITERS ; i++) {
		r = length(z);
		if (r>2.0) break;
		
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
	return vec2(0.5*log(r)*r/dr,0.0);
}

float Union(float d1, float d2)
{
	return min(d1,d2);
}

float S_Union(float d1, float d2, float k)
{
	float h = clamp(0.5 + 0.5 *(d2-d1)/k,0.0,1.0);
	return mix(d2,d1,h) - k*h*(1.0-h);
}

float Difference(float d1, float d2)
{
	return max(-d1, d2);
}

float S_Difference(float d1, float d2, float k)
{
    float h = clamp( 0.5 - 0.5*(d2+d1)/k, 0.0, 1.0 );
    return mix( d2, -d1, h ) + k*h*(1.0-h);
}

float Intersection(float d1, float d2)
{
	return max(d1,d2);
}

float S_Intersection(float d1, float d2, float k)
{
    float h = clamp( 0.5 - 0.5*(d2-d1)/k, 0.0, 1.0 );
    return mix( d2, d1, h ) + k*h*(1.0-h);
}

vec2 sceneSDF(vec3 p)
{
	
	vec2 bulb = mandelbulbSDF(p);
	
	return bulb;
}

vec3 RayMarch(vec3 ro, vec3 rd)
{
	float dist = 0.0;
	vec2 sceneInfo;
	int x =0;
	for(; x < MAX_STEPS; x++)
	{
		sceneInfo = sceneSDF(ro + dist*rd);
		float SurfaceDist = sceneInfo.x;
		
		dist += SurfaceDist;
		if(dist > MAX_DIST || SurfaceDist < Collision_thres) 
			break;
	}
	
	return vec3(dist, sceneInfo.y,float(x));
}

vec3 estimateNormal(vec3 p) {
    return normalize(vec3(
        sceneSDF(vec3(p.x + Collision_thres, p.y, p.z)).x - sceneSDF(vec3(p.x - Collision_thres, p.y, p.z)).x,
        sceneSDF(vec3(p.x, p.y + Collision_thres, p.z)).x - sceneSDF(vec3(p.x, p.y - Collision_thres, p.z)).x,
        sceneSDF(vec3(p.x, p.y, p.z  + Collision_thres)).x - sceneSDF(vec3(p.x, p.y, p.z - Collision_thres)).x
    ));
}

void fragment() 
{
	vec3 wd_pixel_pos = ((INV_VIEW_MATRIX * vec4(VERTEX,1.0)).xyz);
	vec3 ro = CAMERA_POSITION_WORLD;
	vec3 rd = normalize(wd_pixel_pos - ro);
	
	vec3 d = RayMarch(ro,rd);
	
	if(d.x < MAX_DIST)
	{
		ALPHA = 1.0;
	    vec3 normal = estimateNormal(ro-rd*Collision_thres*2.0);

	    float colorA = clamp(dot(normal*.5+.5,-LightDir), 0.0, 1.0);
	    float colorB = clamp(d.y/16.0, 0.0,1.0);
	    vec3 colormix = clamp(colorA * colorAmix + colorB * colorBmix, 0.0,1.0);
		
		
		vec3 n = estimateNormal(ro+rd*d.x);
		//ALBEDO = n;
		ALBEDO = mix(colormix,vec3(1.0),vec3(0.0)) * (d.z/float(darkness));
	}
	else
	{
		ALPHA = 0.0;
		ALBEDO = vec3(0.0);
	}

	
}