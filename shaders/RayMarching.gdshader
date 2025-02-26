shader_type spatial;
render_mode unshaded, depth_test_disabled;

uniform int MAX_STEPS = 100;
uniform float MAX_DIST = 100.0;
uniform float Collision_thres = 0.01;

float sphereSDF(vec3 p, vec3 sp, float r)
{
	return length(sp-p) - r;
}

float sceneSDF(vec3 p)
{
	float sphere = sphereSDF(p,vec3(0.0,0.0,0.0), 1.0);
	return sphere;
}

float testRayMarch(vec3 ro, vec3 rd)
{
	float depth = 0.0;
	
	for(int x = 0; x < MAX_STEPS; x++)
	{
		float dist = sphereSDF(ro + depth*rd,vec3(0.5,0.7,1.0), 1.0);
	
		if(dist < Collision_thres)
			return depth;
		
		depth += dist;
		
		if(depth >= MAX_DIST)
			return depth;
		
	}
	
	return depth;
}

float RayMarch(vec3 ro, vec3 rd)
{
	float dist = 0.0;
	
	for(int x = 0; x < MAX_STEPS; x++)
	{
		float SurfaceDist = sceneSDF(ro + dist*rd);
		
		dist += SurfaceDist;
		if(dist > MAX_DIST || SurfaceDist < Collision_thres) 
			break;
	}
	
	return dist;
}

vec3 estimateNormal(vec3 p) {
    return normalize(vec3(
        sceneSDF(vec3(p.x + Collision_thres, p.y, p.z)) - sceneSDF(vec3(p.x - Collision_thres, p.y, p.z)),
        sceneSDF(vec3(p.x, p.y + Collision_thres, p.z)) - sceneSDF(vec3(p.x, p.y - Collision_thres, p.z)),
        sceneSDF(vec3(p.x, p.y, p.z  + Collision_thres)) - sceneSDF(vec3(p.x, p.y, p.z - Collision_thres))
    ));
}

void fragment() 
{
	vec3 wd_pixel_pos = ((INV_VIEW_MATRIX * vec4(VERTEX,1.0)).xyz);
	vec3 ro = CAMERA_POSITION_WORLD;
	vec3 rd = normalize(wd_pixel_pos - ro);
	
	float d = RayMarch(ro,rd);
	
	if(d < MAX_DIST)
		ALPHA = 1.0;
		
	else
		ALPHA = 0.0;
	
	vec3 n = estimateNormal(ro+rd*d);
	ALBEDO = n;
	
}