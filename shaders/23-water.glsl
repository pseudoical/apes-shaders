//! bundle game
//! cull off
precision highp float;
precision highp int;
#ifdef VERTEX
#define varying out
#else
#define varying in
#endif
uniform mat4 u_mvp;
uniform sampler2D u_flow_tex;
uniform float u_world_size;
uniform highp usampler2D u_water_map;
uniform ivec2 u_water_map_origin;
uniform int u_water_map_size;
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
varying vec3 v_face_normal;
varying vec2 v_flow;
varying vec3 v_world;
varying float v_lava;
#ifdef VERTEX
const uint NO_WATER = 0xFFFFFFFFu;
const float UNKNOWN_LEVEL = 1.0e30;
float map_level(ivec2 c){
if(any(lessThan(c, ivec2(0))) || any(greaterThanEqual(c, ivec2(u_water_map_size)))){
return UNKNOWN_LEVEL;
}
uint bits = texelFetch(u_water_map, c, 0).r;
return bits == NO_WATER ? UNKNOWN_LEVEL : uintBitsToFloat(bits & 0xFFFFFFF0u);
}
void main() {
vec3 pos = get_position();
uint material = a_codes.x&127u;
if(material!=40u && material!=35u){
pos = vec3(0.0);
}
v_lava = material==35u ? 1.0 : 0.0;
uint water_bits = a_normal.w;
uint level = (water_bits>>4u)&15u;
if(level>0u && ((water_bits>>3u)&1u)==1u){
pos.z -= float(level)/16.0*float(1<<u_lod);
}
int normal_code = int((a_codes.w>>2)&31u);
v_face_normal = code2normal[normal_code];
v_flow = texture(u_flow_tex, pos.xy / u_world_size).rg * 2.0 - 1.0;
if(length(v_flow) <= 0.2 && u_water_map_size > 0){
vec2 f = pos.xy - 0.5;
ivec2 b = ivec2(floor(f)) - u_water_map_origin;
float h00 = map_level(b);
float h10 = map_level(b + ivec2(1, 0));
float h01 = map_level(b + ivec2(0, 1));
float h11 = map_level(b + ivec2(1, 1));
if(level > 0u){
if(max(max(h00, h10), max(h01, h11)) < UNKNOWN_LEVEL * 0.5){
vec2 g = vec2(h10 - h00 + h11 - h01, h01 - h00 + h11 - h10) * 0.5;
if(length(g) > 0.02){
v_flow = -normalize(g);
}
}
}else{
float level = min(min(h00, h10), min(h01, h11));
if(level < UNKNOWN_LEVEL * 0.5){
bool top = ((water_bits>>3u)&1u)==1u;
pos.z = top ? level : min(pos.z, level);
if(v_face_normal.z > 0.3){
v_face_normal = vec3(0.0, 0.0, 1.0);
}
}
}
}
v_world = pos;
gl_Position = u_mvp * vec4(pos, 1.0);
}
#endif
#ifdef FRAGMENT
out vec4 o_color;
void main() {
vec3 n = v_face_normal;
vec2 flow = v_flow;
float len = length(flow);
flow = len > 0.2 ? flow / len : vec2(0.0);
int a = (gl_FrontFacing ? 128 : 0)
| (n.z < 0.0 ? 64 : 0)
| (v_lava > 0.5 ? 32 : 0)
| int(round((flow.y*0.5+0.5)*31.0));
o_color = vec4(n.xy*0.5+0.5, flow.x*0.5+0.5, float(a)/255.0);
}
#endif