//! bundle game
precision highp float;
precision highp int;
uint pcg3d16(uvec3 p)
{
uvec3 v = p * 1664525u + 1013904223u;
v.x += v.y*v.z; v.y += v.z*v.x; v.z += v.x*v.y;
v.x += v.y*v.z;
return v.x;
}
ivec3 from_u16(uvec3 val){
val = val&65535u;
uvec3 s = val>>15;
val |= uvec3(4294934528u) * s;
return ivec3(val);
}
uvec4 pack_buf(vec3 pos, vec3 vel, uint time){
return uvec4(
packHalf2x16(pos.xy),
packHalf2x16(vec2(pos.z, vel.x)),
packHalf2x16(vel.yz),
time
);
}
vec3 get_pos(uvec4 buf){
return vec3(unpackHalf2x16(buf.x),unpackHalf2x16(buf.y).x);
}
vec3 get_vel(uvec4 buf){
return vec3(unpackHalf2x16(buf.y).y,unpackHalf2x16(buf.z));
}
#ifdef VERTEX
in vec3 a_position;
void main(){
gl_Position.xyz = a_position;
gl_Position.w = 1.0;
}
#endif
#ifdef FRAGMENT
layout(location = 0) out highp uvec4 out_buf;
uniform highp usampler2D u_in_buf;
uniform highp usampler2D u_blocks;
uniform highp sampler3D u_turbulence;
uniform int u_time_millis;
uniform float u_delta_time;
void main() {
ivec2 coord = ivec2(gl_FragCoord.xy);
uvec4 v = texelFetch(u_in_buf,coord,0);
if(v.w==0u){
out_buf = uvec4(0);
return;
}
uvec4 block = texelFetch(u_blocks, coord>>3,0);
float life_millis = float(uint(u_time_millis) & 65535u)- float(block.w>>16);
if(life_millis<-32768.0){
life_millis+=65535.0;
}
float life = life_millis / float(v.w & 65535u);
if(life<0.0 || life>=1.0){
out_buf = uvec4(0);
return;
}
vec3 pos = get_pos(v);
vec3 vel = get_vel(v);
float air_resistance = float((block.y>>24)&255u)/255.0;
float gravity = float((block.z>>8)&255u)/16.0;
float turbulence = float((block.z>>16)&255u)/16.0;
float turbulence_size = float((block.z>>24)&255u)/16.0;
uint hash = (block.w>>8)&255u;
vec3 turb_off = (vec3(hash&3u, (hash>>2)&3u, (hash>>4)&3u)-1.5)*1.1;
float t=u_delta_time;
pos+=vel*t*pow(1.0-life,float(block.w&255u)/16.0);
vel+=(texture(u_turbulence, pos/8.0*turbulence_size+turb_off).xyz*2.0-1.0)*turbulence;
vel*=pow(air_resistance,60.0*u_delta_time);
vel.z-=gravity*gravity*t;
out_buf = pack_buf(pos,vel,v.w);
}
#endif