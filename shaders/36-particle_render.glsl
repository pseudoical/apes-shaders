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
in uint a_position;
uniform ivec2 u_buf_access;
uniform highp usampler2D u_blocks;
uniform highp usampler2D u_in_buf;
uniform sampler2D u_color_lookup;
uniform mat4 u_mvp;
out vec4 v_color;
uniform float u_scale;
uniform int u_time_millis;
void main(){
const float COLORS = 128.0;
ivec2 coord = ivec2(a_position&uint(u_buf_access.x),a_position>>uint(u_buf_access.y));
int sub = gl_VertexID&63;
uvec4 v = texelFetch(u_in_buf,coord,0);
if(v.w==0u){
gl_Position = vec4(vec3(0.0,0.0,-2.0),1.0);
gl_PointSize = 0.0;
return;
}
vec3 pos = get_pos(v);
uvec4 block = texelFetch(u_blocks, coord>>3,0);
float color_slot = float((block.y>>16u) & 255u);
float particle_size = float(block.z & 255u)/255.0;
vec3 block_pos = vec3(from_u16(uvec3(block.x, block.x>>16, block.y)));
float life_millis = float(uint(u_time_millis) & 65535u)- float(block.w>>16);
if(life_millis<-32768.0){
life_millis+=65535.0;
}
uint particle_life = v.w & 65535u;
float life = 1.0;
if(particle_life!=0u){
life = life_millis / float(particle_life);
}
if(life<0.0){
life = 1.0;
}
pos+=block_pos;
gl_Position = u_mvp*vec4(pos,1.0*float(life<1.0));
gl_PointSize=max(1.0,particle_size*u_scale/gl_Position.w);
v_color = texture(u_color_lookup, vec2(life, (0.5+color_slot)/COLORS));
v_color.a = max(1.0/255.0,v_color.a);
}
#endif
#ifdef FRAGMENT
out vec4 o_color;
in vec4 v_color;
void main() {
o_color = v_color;
}
#endif