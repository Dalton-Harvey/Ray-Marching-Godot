# Ray Marching
---
## Summary:

Ray Marching is a technique for rendering geometry by "marching" a ray across a scene until it intersects a shape in the scene. The basic process goes like this, a ray is shot from each pixel on the scene similarly to the [[Ray Tracing]] technique. Each ray is then "marched" until it collides with a shape in the scene. The collision is detected using something called a SDF or signed distance function and is the backbone for this algorithm. This algorithm has a side effect of allowing for interesting results such as blending which allows for two objects being "blended" together which will be explained further in the implementation section. This algorithm is simple but can cost a lot of resources if not optimized.

## Implementation:
---
### SDFs:
To understand how to implement Ray Marching we first need to understand how how SDFs work. Signed Distance Functions are used to determine the distance between a given point and a surface. The Signed part is used to determine whether you've hit the surface or not, a positive number means you are **outside** the shape, zero means you are **on** the surface, and a negative number means you are **inside** the surface. For a list of SDFs and a deeper explanation of how they work and the different kinds refer to [Inigo Quilez's article](https://iquilezles.org/articles/distfunctions/) on SDFs. For the our purposes here understanding my explanation is good enough. We will be using a Sphere's SDF for our implementation with: p = Ray's current position, sp = sphere position, r = radius.
```c++
float sphereSDF(vec3 p, vec3 sp, float r)
{
	return length(sp-p) - r;
}
```

### Sphere Tracing:
In order to implement the Ray Marching part of this algorithm we need to determine our step length or how far we move the ray forward before using our SDF to see if we have collided with something. We could do this with a fixed step length where each march goes the exact same distance forward. There are two main issues with this, first that step length may go to far and either miss or go inside of our geometry. To solve this issue we can instead have a variable step length that changes depending on the closest object. In other words if we take the distance we get from our SDF and add it to our current position we can know the max distance we can safely move before hitting an object in our scene and as the distance grows very small we know we have collided with our object(s). Visually this process looking something like this:
![[Screenshot 2025-03-19 133931.png]]
### Ray Marching:
To Implement the Ray Marching algorithm using the Sphere Tracing optimization we first need to get the ray origin and the ray direction.
- Ray Origin - We can find this by simply getting the Camera's position in world space.
- Ray Direction - To find the ray direction we first need to know the pixels world position by inverting the view matrix and multiplying it by it's vertex. Finally we can normalize the pixel's position - the ray's origin and this will give us the ray's direction.
```c++
vec3 wd_pixel_pos = ((INV_VIEW_MATRIX * vec4(VERTEX,1.0)).xyz);
vec3 ro = CAMERA_POSITION_WORLD;
vec3 rd = normalize(wd_pixel_pos - ro);
```
Now that we have the ray origin and ray direction we can finally start the ray marching algorithm. We can start our loop by finding the position we are currently are checking. This can be found by taking the ray origin and adding it to the distance traveled multiplied by the ray direction. Taking that new position we can do a collision check. If we have hit something we return the distance we checked and that's it, if we didn't collide we can add the distance we got from the SDF to the distance variable and loop again. The code for that looks something like this:
```c++
float dist = 0.0;
vec3 pos;
for(int x = 0; x < MAX_STEPS; x++)
{
	pos = ro + dist*rd;
	float SurfaceDist = SphereSDF(pos);
	
	dist += SurfaceDist;
	if(dist > MAX_DIST || SurfaceDist < Collision_thres) 
		return dist;
		
}
```
If we make each pixel that collides have an ALPHA of 1 and whatever color we want we get an image that looks like this:
![[Screenshot 2025-03-19 141251.png]]
It may only look like a 2D circle but that's just because there isn't any lighting to add depth. If you want to add a gradiant to the sphere by estimating the normal for each of the points on the sphere like this:
```c++
vec3 estimateNormal(vec3 p) {
    return normalize(vec3(
        sceneSDF(vec3(p.x + Collision_thres, p.y, p.z)).x - sceneSDF(vec3(p.x -Collision_thres, p.y, p.z)).x,
        sceneSDF(vec3(p.x, p.y + Collision_thres, p.z)).x - sceneSDF(vec3(p.x, p.y - Collision_thres, p.z)).x,
        sceneSDF(vec3(p.x, p.y, p.z  + Collision_thres)).x - sceneSDF(vec3(p.x, p.y, p.z - Collision_thres)).x
    ));
}

vec3 n = estimateNormal(ro+dist*rd);
```
This will give us a nice gradient based on the normals allowing us to give our sphere some depth:
![[Screenshot 2025-03-19 141949.png]]

### Combinations:

#### "Rough" Combinations:
We can take multiple primitives rendered using Ray Marching and do some interesting combinations using Union, Subtraction, Intersection and their smooth versions. I will quickly cover what they do with some screenshots of the code and results.
- Union - Combines two primitives together intersecting them making them into one shape.
- Subtraction - Takes one object and makes it a "subtracting force" essentially making one object take out parts of another leaving a hole where it is. 
- Intersection - Makes it so an object is only rendered when intersected with anther object.
![[Screenshot 2025-03-19 143804.png]]
#### Smooth Combinations:
Smooth Combinations are used to make more organic combinations smoothing out the rough edges of each of the combination types allowing for more seamless transitions between shapes
![[Screenshot 2025-03-19 144051.png]]

#### Combination Implementation: 
To Implement these combinations we can use a sceneSDF function to return our distance this will look something like this:
```c++
float sceneSDF(vec3 p)
{
	float sphere = sphereSDF(p, sphere_pos, sphere_r);
	float box = boxSDF(p,box_pos, box_dims);
	return S_Union(sphere, box, BLEND);
	//OR
	return Union(sphere, box);
}
```
The BLEND variable is just used to change the strength of the blending between the objects.

## Conclusion:
Only the very basics of Ray Marching are covered here for further reading use the references listed below to go more in-depth. May update this notes page if I decide to go more in-depth.
# References:
-------------------------------
[Sebastian Lague Ray Marching Video](https://www.youtube.com/watch?v=Cp5WWtMoeKg)<br>
[It Takes Two Lava lamp ray marching recreation](https://www.youtube.com/watch?v=jH0MD8obOCQ&t=612s)<br>
[Ray Marching wiki](https://en.wikipedia.org/wiki/Ray_marching)
[Inigo Quilez Smooth Minimum](https://iquilezles.org/articles/smin/)
[Inigo Quilez Distance Functions](https://iquilezles.org/articles/distfunctions/)
