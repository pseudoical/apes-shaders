//! bundle game
precision highp float;
precision highp int;
#ifdef VERTEX
#define varying out
#else
#define varying in
#endif
uniform float u_fade;
uniform mat4 u_mvp;
uniform mat4 u_view;
uniform int u_lod;
const float TEX_COUNT=16.0;
const float PERIOD = 4.0;
const float TEX_ROWS = 4.0;
const vec2 DIVIDER = vec2(1.0/(PERIOD*PERIOD*TEX_COUNT),1.0/(13.0*PERIOD*TEX_ROWS));
const vec2 TD = 1.0/vec2(PERIOD*TEX_COUNT,13.0*TEX_ROWS);
const vec2 TEX = vec2(1.0/TEX_COUNT,1.0/TEX_ROWS);
#ifdef VERTEX
uniform sampler2D u_variant_codes;
uniform vec3 u_coord;
in uvec4 a_position;
vec3 get_position(){
return vec3(a_position.xyz<<u_lod)+u_coord;
}
float get_code(uint code){
return floor(texelFetch(u_variant_codes,ivec2(code>>2,0),0)[code&3u]*255.0+0.5);
}
vec2 get_uv(int tile,vec3 uvs){
vec2 uvzw = vec2(uvs.z,tile);
return uvs.xy*DIVIDER  +uvzw*TD;
}
#endif
#ifdef FRAGMENT
uniform sampler2D u_variants;
void apply_variant(uint code, inout vec4 color,inout vec4 data){
color *= texelFetch(u_variants,ivec2(0,code),0);
color += texelFetch(u_variants,ivec2(1,code),0);
data *= texelFetch(u_variants,ivec2(2,code),0);
data += texelFetch(u_variants,ivec2(3,code),0);
}
#endif
#ifdef VERTEX
in uvec4 a_codes;
#endif
uniform vec3 u_cam_pos;
uniform float u_dither_dist_inv;
varying vec3 v_normal;
varying vec2 v_uv;
varying vec3 v_view_pos;
varying vec2 v_base_uv;
varying float v_vanish;
varying float v_code;
uniform sampler2D u_tex;
const int ATLAS_COUNT = 2;
const float ATLAS_SIZES[ATLAS_COUNT] = float[ATLAS_COUNT](0.5,1.0);
ivec3 dir_vec(uint i){
int neg = -(int(i & 1u) * 2 - 1);
uint rest = i >> 1;
return ivec3(
neg * int(rest == 0u),
neg * int(rest == 1u),
neg * int(rest == 2u)
);
}
#ifdef VERTEX
void main() {
uint code = a_position.w-1u;
v_code = float(code);
uint type = uint(get_code(code));
float shrink_factor = 0.0;
if(type==0u){
shrink_factor = 0.5;
}
float offset = 1.0-shrink_factor;
vec3 normal = -vec3(dir_vec((a_codes.z>>4) & 7u));
vec3 shrink_dir = -normal*(float((a_codes.z>>2)&1u));
vec2 base_uv = vec2(a_codes.z&1u,(a_codes.z>>1)&1u);
vec3 pos = get_position()+shrink_dir*shrink_factor;
uint tile = (a_codes.y>>4)&15u;
vec3 uvs = vec3(a_codes.w&7u,(a_codes.w>>3)&7u,(a_codes.w>>6)&3u);
v_uv = get_uv(int(tile),uvs)+TEX*vec2(type%16u,type/16u);
vec3 adjust =  (vec3(a_codes.x&15u,(a_codes.x>>4)&15u,a_codes.y&15u)/15.0-0.5)*0.4;
pos+=adjust;
v_normal = normalize(normal);
v_vanish = max(abs(dot(normalize(pos-u_cam_pos),v_normal))-0.66,0.0)*3.0;
vec4 vertexPos = vec4( pos, 1 );
gl_Position = u_mvp * vertexPos;
v_view_pos = (u_view*vertexPos).xyz*vec3(3.0,3.0,1.0);
v_base_uv = vec2(base_uv.x*0.5+0.5,base_uv.y*0.5+0.5);
}
#endif
#ifdef FRAGMENT
precision highp sampler3D;
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
uniform sampler2D u_atlas;
uniform sampler2D u_atlas_data;
uniform sampler2D u_dither_ref;
void main() {
vec2 uv = v_uv;
vec4 col = texture(u_tex,v_base_uv);
float dist = clamp(dot(abs(v_view_pos),vec3(u_dither_dist_inv)),0.0,1.0)-v_vanish;
float ditherRef = texelFetch(u_dither_ref, ivec2(mod(gl_FragCoord.xy, 8.0)), 0).r;
if(0.1>col.a || dist<ditherRef){
discard;
}
vec4 color = texture(u_atlas,uv);
vec4 data = texture(u_atlas_data,uv);
data.b=0.0;
data.a=1.0;
apply_variant(uint(v_code+0.5),color,data);
data.r = mix(data.r,1.0,1.0-v_base_uv.y);
write_gbuffer_ground(color.rgb,v_normal,data,u_lod);
}
#endif