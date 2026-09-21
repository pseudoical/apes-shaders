//! bundle game
precision highp float;
#ifdef VERTEX
#define varying out
#else
#define varying in
#endif
#define MAX_BONES 64
uniform float u_fade;
uniform mat4 u_model;
uniform mat4 u_mvp;
uniform vec3 u_cam_pos;
uniform sampler2D u_mainTex;
uniform vec4 u_uv_scale_offset;
varying vec3 v_normal;
varying vec2 v_uv;
varying vec3 v_worldPos;
#ifdef FRAGMENT
layout(location = 0) out vec4 o_color;
layout(location = 1) out vec4 o_normal;
float signNotZero(in float k) {
return (k >= 0.0) ? 1.0 : -1.0;
}
vec2 signNotZero(in vec2 v) {
return vec2(signNotZero(v.x), signNotZero(v.y));
}
vec2 octEncode(in vec3 v) {
float l1norm = abs(v.x) + abs(v.y) + abs(v.z);
vec2 result = v.xy * (1.0 / l1norm);
if (v.z < 0.0) {
result = (1.0 - abs(result.yx)) * signNotZero(result.xy);
}
return result * 0.5+0.5;
}
void write_gbuffer(vec3 color, vec3 normal, vec4 data){
uvec2 data_int = uvec2((uint(data.r*15.0)&15u) | (uint(data.g*7.0)&7u)<<4, (uint(data.b *7.0)&7u) | (uint(data.a *15.0) & 15u) << 4);
vec2 pack = vec2(data_int)/255.0;
o_color = vec4(color,pack.x);
vec2 encoded_normal = octEncode(normal);
o_normal = vec4(encoded_normal,0.0,pack.y);
}
void write_gbuffer_ground(vec3 color, vec3 normal, vec4 data, int lod){
uvec2 data_int = uvec2((uint(data.r*15.0)&15u) | (uint(data.g*7.0)&7u)<<4 | 1u<<7, (uint(data.b *7.0)&7u) | (uint(data.a *15.0) & 15u) << 4);
vec2 pack = vec2(data_int)/255.0;
o_color = vec4(color,pack.x);
vec2 encoded_normal = octEncode(normal);
o_normal = vec4(encoded_normal,float(lod)/255.0,pack.y);
}
void write_gbuffer_ape(vec3 color, vec3 normal, vec4 data){
uvec2 data_int = uvec2((uint(data.r*15.0)&15u) | (uint(data.g*7.0)&7u)<<4, (uint(data.b *7.0)&7u) | 1u<<3 | (uint(data.a *15.0) & 15u) << 4);
vec2 pack = vec2(data_int)/255.0;
o_color = vec4(color,pack.x);
vec2 encoded_normal = octEncode(normal);
o_normal = vec4(encoded_normal,0.0,pack.y);
}
#endif
#ifdef VERTEX
in vec3 a_position;
in vec3 a_normal;
in vec2 a_uv;
void main() {
vec4 vertexPos = vec4( a_position, 1 );
v_normal = a_normal;
v_normal = ( u_model * vec4( v_normal, 0 )).xyz;
vec4 worldPos4 = u_model * vertexPos;
v_worldPos = worldPos4.xyz / worldPos4.w;
v_uv = a_uv*u_uv_scale_offset.xy + u_uv_scale_offset.zw;
gl_Position = u_mvp * vertexPos;
}
#endif
#ifdef FRAGMENT
void main() {
vec3 color = texture(u_mainTex, v_uv).rgb;
vec4 data = vec4(1.0-color.g,color.r,0.2,1.0);
write_gbuffer(color,v_normal,data);
}
#endif