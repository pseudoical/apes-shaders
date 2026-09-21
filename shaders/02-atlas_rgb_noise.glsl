//! bundle game editor
//! priority 3
precision highp float;
precision highp int;
#ifdef VERTEX
in vec3 a_position;
void main(){
gl_Position.xyz = a_position;
gl_Position.w = 1.0;
}
#endif
#ifdef FRAGMENT
vec3 hash(vec3 p) {
return fract(
sin(vec3(dot(p, vec3(1.0, 57.0, 113.0)), dot(p, vec3(57.0, 113.0, 1.0)),
dot(p, vec3(113.0, 1.0, 57.0)))) *
43758.5453);
}
uint pcg3d16(uvec3 p)
{
uvec3 v = p * 1664525u + 1013904223u;
v.x += v.y*v.z; v.y += v.z*v.x; v.z += v.x*v.y;
v.x += v.y*v.z;
return v.x;
}
layout(location = 0) out vec4 o_color;
uniform vec3 u_granularity;
uniform int u_seed;
const vec3 Tex2World[39] = vec3[39](vec3(1,0,0),vec3(0,1,0),vec3(0,0,1),vec3(-1,0,0),vec3(0,-0,1),vec3(0,1,0),vec3(1,0,0),vec3(0,1,-1),vec3(0,0,1),vec3(1,0,-0),vec3(-0,1,1),vec3(0,0,1),vec3(0,1,0),vec3(0,0,1),vec3(1,0,0),vec3(0,1,0),vec3(-1,0,1),vec3(1,0,0),vec3(-0,1,-0),vec3(1,-0,1),vec3(-1,-0,-0),vec3(0,0,1),vec3(1,-1,0),vec3(0,1,0),vec3(-1,1,0),vec3(-1,0,1),vec3(1,0,0),vec3(1,-1,0),vec3(1,0,1),vec3(-1,0,0),vec3(0,-0,1),vec3(1,1,-0),vec3(0,1,0),vec3(1,1,-0),vec3(-0,1,1),vec3(0,-1,0),vec3(-1,-1,0),vec3(0,-1,1),vec3(0,1,-0));
mat3 tex2World(int tile){
return mat3(Tex2World[tile*3],Tex2World[tile*3+1],Tex2World[tile*3+2]);
}
void main(){
ivec2 pix = ivec2(gl_FragCoord.xy);
const int ATLAS_PERIOD = 4;
int tile_width = 16*ATLAS_PERIOD;
int tile = pix.y/tile_width;
vec3 uvloc = vec3((float(pix.x%tile_width)+0.5)/float(16),(float(pix.y%tile_width)+0.5)/float(16),float(pix.x/tile_width%ATLAS_PERIOD));
vec3 loc = tex2World(tile)*uvloc;
uvec3 uloc = uvec3(ivec3(loc*16.0)+tile_width)%uint(tile_width);
uint hash1 = pcg3d16(uloc+uint(u_seed));
uint hash2 = pcg3d16(uloc+uint(tile_width)+uint(u_seed));
vec3 v = vec3(uvec3(hash1>>16,hash1>>24,hash2>>16)&255u)/255.0;
o_color = vec4(v,1.0);
}
#endif