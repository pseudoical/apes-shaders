//! bundle game
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
in uvec4 a_normal;
#endif
uniform vec3 u_cam_pos;
varying vec3 v_codes;
varying vec3 v_actual_codes;
varying vec3 v_normal;
varying float v_ao;
varying vec3 v_blend;
varying vec2 v_uv;
varying float v_tile;
varying vec3 v_barycentric;
varying vec3 v_smooth_normal;
varying vec3 v_edge;
#ifdef VERTEX
const vec3 code2normal[26] = vec3[26](vec3(0,0,1), vec3(0,1,0), vec3(0,0.70710677,0.70710677), vec3(0,-0.70710677,0.70710677), vec3(1,0,0), vec3(0.70710677,0,0.70710677), vec3(-0.70710677,0,0.70710677), vec3(0.70710677,0.70710677,0), vec3(0.57735026,0.57735026,0.57735026), vec3(-0.57735026,-0.57735026,0.57735026), vec3(-0.70710677,0.70710677,0), vec3(0.57735026,-0.57735026,0.57735026), vec3(-0.57735026,0.57735026,0.57735026), vec3(-0,-0,-1), vec3(-0,-1,-0), vec3(-0,-0.70710677,-0.70710677), vec3(-0,0.70710677,-0.70710677), vec3(-1,-0,-0), vec3(-0.70710677,-0,-0.70710677), vec3(0.70710677,-0,-0.70710677), vec3(-0.70710677,-0.70710677,-0), vec3(-0.57735026,-0.57735026,-0.57735026), vec3(0.57735026,0.57735026,-0.57735026), vec3(0.70710677,-0.70710677,-0), vec3(-0.57735026,0.57735026,-0.57735026), vec3(0.57735026,-0.57735026,-0.57735026));
const vec3 bary[3] = vec3[3](vec3(1,0,0),vec3(0,1,0),vec3(0,0,1));
void setup_varyings(float cam_dist){
int tidx = gl_VertexID%3;
uvec3 codes = a_codes.xyz&127u;
v_actual_codes = vec3(codes);
v_codes = vec3(get_code(codes.r-1u),get_code(codes.g-1u),get_code(codes.b-1u));
v_blend = vec3(a_codes.xyz>>7);
v_barycentric = bary[tidx];
int normal_code = int((a_codes.w>>2)&31u);
v_normal = code2normal[normal_code];
v_smooth_normal = vec3(a_normal.xyz)/255.0 *2.0 -1.0;
#ifdef BOAT
v_normal = normalize(mat3(u_model)*v_normal);
v_smooth_normal = normalize(mat3(u_model)*v_smooth_normal);
#endif
v_edge = vec3(a_normal.w&1u,(a_normal.w>>1)&1u,(a_normal.w>>2)&1u);
int tile = normal_code;
if(tile>=13){
tile-=13;
}
v_tile=float(tile)+0.5;
vec3 uvs = vec3(a_position.w&7u,(a_position.w>>3)&7u,(a_position.w>>6)&3u);
v_uv = get_uv(tile,uvs);
float dist_f = clamp((cam_dist-50.0)/200.0,0.0,1.0);
v_ao = float(a_codes.w&3u)/2.0*(1.0-dist_f);
}
#endif
#ifdef FRAGMENT
uniform sampler2D u_atlas;
uniform sampler2D u_atlas_data;
const vec3 Tex2World[26] = vec3[26](vec3(1,0,0),vec3(0,1,0),vec3(-1,0,0),vec3(0,-0,1),vec3(1,0,0),vec3(0,1,-1),vec3(1,0,-0),vec3(-0,1,1),vec3(0,1,0),vec3(0,0,1),vec3(0,1,0),vec3(-1,0,1),vec3(-0,1,-0),vec3(1,-0,1),vec3(0,0,1),vec3(1,-1,0),vec3(-1,1,0),vec3(-1,0,1),vec3(1,-1,0),vec3(1,0,1),vec3(0,-0,1),vec3(1,1,-0),vec3(1,1,-0),vec3(-0,1,1),vec3(-1,-1,0),vec3(0,-1,1));
mat2x3 tex2World(int tile){
return mat2x3(Tex2World[tile*2],Tex2World[tile*2+1]);
}
vec2 atlas_cell(float code){
float c = floor(code+0.5);
return TEX*vec2(mod(c,TEX_COUNT),floor(c/TEX_COUNT));
}
uint get_pixel(out vec4 color, out vec4 data){
float bend = 0.3;
vec2 uv = v_uv;
float code = v_actual_codes[0];
if(u_lod<3){
for(int i=0; i<3; i++){
if(i==0 || (v_actual_codes[i]>0.5 &&
v_blend[i]>0.0)){
vec2 tuv = atlas_cell(v_codes[i]);
tuv+=uv;
vec4 col= texture(u_atlas,tuv);
vec4 in_data = texture(u_atlas_data,tuv);
if(i>0){
float m = float(floor(clamp(v_blend[i]*16.0,0.01,15.99))>col.w*16.0);
color = mix(color,col,m);
data = mix(data,in_data,m);
code = mix(code,v_actual_codes[i],m);
}else{
color = col;
data = in_data;
}
}
}
}else{
vec2 tuv = atlas_cell(v_codes[0])+TEX*0.5;
color = textureLod(u_atlas,tuv,6.0);
data = textureLod(u_atlas_data,tuv,6.0);
}
return uint(code+0.5)-1u;
}
void output_ground(uint code, inout vec4 color, inout vec4 data, out vec3 normal){
vec3 norm_xy = vec3(0.0);
vec2 uvn = data.zw;
int tile = int(v_tile);
if(u_lod==0){
norm_xy = tex2World(tile)*(uvn*2.0-1.0);
}
data.b=0.0;
data.a = mix(1.0,0.5,v_ao);
apply_variant(code, color,data);
float max_bary = max(max(v_barycentric.x,v_barycentric.y),v_barycentric.z);
vec3 edged = mix(v_barycentric,max(v_barycentric,1.0-v_edge),1.0-max_bary);
float soft = 8.0;
if(v_blend.x>0.5){
soft = 3.0;
}
float bary = min(min(edged.x,edged.y),edged.z);
normal = mix(v_normal+norm_xy,v_smooth_normal,clamp(1.0-bary*soft,0.0,1.0));
}
#endif
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
void main() {
vec3 pos = get_position();
float cam_dist = length(u_cam_pos-pos);
setup_varyings(cam_dist);
vec4 vertexPos = vec4( pos, 1 );
gl_Position = u_mvp * vertexPos;
}
#endif
#ifdef FRAGMENT
uniform sampler2D u_dither_ref;
void main() {
ivec2 pix = ivec2(gl_FragCoord);
float ditherRef = texelFetch(u_dither_ref, ivec2(mod(gl_FragCoord.xy, 8.0)), 0).r;
if (ditherRef<0.25){
discard;
}
vec4 color;
vec4 data;
vec3 normal;
uint code = get_pixel(color,data);
output_ground(code, color,data,normal);
write_gbuffer_ground(color.rgb,normal,data, u_lod);
}
#endif