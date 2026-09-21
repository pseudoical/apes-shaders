//! bundle game
//! queue particle
precision highp float;
precision highp int;
#ifdef VERTEX
#define varying out
#else
#define varying in
#endif
uniform float u_fade;
uniform mat4 u_model;
uniform mat4 u_mvp;
uniform vec3 u_cam_pos;
uniform highp isampler2D u_tex;
uniform sampler2D u_anim_counters;
uniform int u_ex_1;
uniform int u_ex_2;
uniform int u_group_id;
uniform int u_spawn_z_offset;
uniform float u_time_since_spawn;
uniform vec3 u_rel_player_pos;
uniform float u_attenuate;
uniform float u_pip_scale;
uniform float u_blink;
varying vec3 v_normal;
varying vec2 v_uv;
varying vec3 v_worldPos;
varying vec3 v_color;
#ifdef VERTEX
in vec3 a_position;
in vec3 a_normal;
in vec2 a_uv;
uint pcg3d16(uvec3 p)
{
uvec3 v = p * 1664525u + 1013904223u;
v.x += v.y*v.z; v.y += v.z*v.x; v.z += v.x*v.y;
v.x += v.y*v.z;
return v.x;
}
void main() {
vec2 group_offset = vec2(0);
if (u_group_id>0){
group_offset = vec2((u_group_id-1) & 1, ((u_group_id-1)>>1) & 1) * 8.0-4.0;
}
ivec2 coord = ivec2(floor(a_position.xy+4.0));
vec2 center_xy = vec2(coord.x,coord.y)-3.5;
int bit = coord.x+coord.y*8;
uint mask = uint(u_ex_1);
if (bit >31){
bit-=32;
mask = uint(u_ex_2);
}
float degen = 1.0;
float anim = texelFetch(u_anim_counters, coord,0).r;
if (((mask>>bit) & 1u)==0u || anim==1.0){
degen = 0.0;
}
int height = texelFetch(u_tex, coord, 0).r;
anim = clamp(anim,0.0,1.0);
anim = anim*anim;
vec4 vertexPos = vec4( a_position, 1 );
vertexPos.xy -= center_xy;
center_xy+=group_offset;
float ease_out = 1.0-pow(1.0-clamp(u_time_since_spawn,0.0,1.0),2.0);
mat2 rot;
uint full_hash = pcg3d16(uvec3(ivec3(coord,height)));
float anim_offset = float(full_hash & 65535u)/255.0;
float theta = u_time_since_spawn*3.14159*2.0+anim_offset;
float cos_theta = cos(theta);
float sin_theta = sin(theta);
rot[0] = vec2(cos_theta,sin_theta);
rot[1] = vec2(-sin_theta,cos_theta);
vertexPos.xy = rot*vertexPos.xy;
vertexPos.xyz*=0.4+u_pip_scale*1.4;
vec3 diff = vec3(center_xy*ease_out, max(float(u_spawn_z_offset)+u_time_since_spawn*10.0-27.0*0.5 * u_time_since_spawn*u_time_since_spawn, float(height)+0.5));
uint hash = full_hash>>16;
diff.x += float(hash & 15u)/15.0-0.5;
diff.y += float((hash>>4) & 15u)/15.0-0.5;
v_color = vec3(float((hash>>8) & 3u), float((hash>>10) & 3u), float((hash>>12) & 3u))/3.0;
diff.z += sin(u_time_since_spawn*3.14+anim_offset)*0.5+0.5;
vertexPos.xyz+=mix(diff,u_rel_player_pos,anim);
v_uv = a_uv;
v_normal = a_normal;
v_normal = ( u_model * vec4( v_normal, 0 )).xyz;
vec4 worldPos4 = u_model * vertexPos;
v_worldPos = worldPos4.xyz / worldPos4.w;
gl_Position = u_mvp * vertexPos * degen;
}
#endif
#ifdef FRAGMENT
out vec4 o_color;
void main() {
if(u_blink!=1.0 && (int(gl_FragCoord.x)+int(gl_FragCoord.y)) % 2 ==0){
discard;
}
vec3 col = vec3(1.0,0.0,0.0)*0.9+v_color*0.1;
vec3 normal = v_normal;
float light = 0.4 + 0.6*abs(dot(v_normal, vec3(0.0,0.707,707)));
vec4 color = vec4(col * light, u_attenuate*u_blink*0.95+0.05);
o_color = color;
}
#endif