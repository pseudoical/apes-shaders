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
uniform vec4 u_offset;
out vec2 v_coord;
void main(){
vec2 uv = a_position.xy*0.5+0.5;
gl_Position.xy = (uv*u_offset.xy+u_offset.zw)*2.0-1.0;
v_coord = uv*vec2(8.0,8.0);
gl_Position.z=0.0;
gl_Position.w = 1.0;
}
#endif
#ifdef FRAGMENT
layout(location = 0) out highp uvec4 out_buf;
uniform highp usampler2D u_in_buf;
uniform highp usampler2D u_blocks;
in vec2 v_coord;
uniform vec3 u_start;
uniform vec3 u_end;
uniform vec2 u_init_rand_spd;
uniform ivec2 u_lifetime_millis;
uniform vec2 u_start_offset;
uniform vec3 u_init_vel;
uniform int u_count;
void main() {
int ti = int(v_coord.x)+int(v_coord.y)*8;
if(ti >= u_count){
out_buf = uvec4(0u);
return;
}
float t = clamp(float(ti)/float(max(u_count-1,1)),0.0,1.0);
uint rand1 = pcg3d16(uvec3(ti, ivec2(gl_FragCoord)));
uint rand2 = pcg3d16(uvec3(ti, ivec2(gl_FragCoord))+uvec3(1245125,4356423,124));
uint rand3 = pcg3d16(uvec3(ti, ivec2(gl_FragCoord))+uvec3(64326,23,7578854));
float rand_life = float((rand1>>16) & 255u)/255.0 * float(u_lifetime_millis.y);
vec3 rand_dir = normalize(vec3(uvec3(rand1>>24,rand2>>16,rand2>>24)&255u)/255.0*2.0-1.0);
float rand_offset = float((rand3>>16)&255u)/255.0;
float rand_spd = float((rand3>>24)&255u)/255.0;
uint lifetime = uint(u_lifetime_millis.x)+uint(rand_life);
uvec4 block = texelFetch(u_blocks, ivec2(gl_FragCoord)>>3,0);
vec3 block_pos = vec3(from_u16(uvec3(block.x, block.x>>16, block.y)));
vec3 pos = mix(u_start,u_end,t)-block_pos+rand_dir*(u_start_offset.x+rand_offset*u_start_offset.y);
vec3 vel = u_init_vel+rand_dir*(u_init_rand_spd.x+u_init_rand_spd.y*rand_spd);
out_buf = pack_buf(pos,vel,lifetime);
}
#endif