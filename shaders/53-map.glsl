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
uniform float u_world_size;
varying vec3 v_worldPos;
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
precision highp float;
precision highp int;
uniform int u_world_center;
uniform float u_time;
uniform float u_fog_density;
const float sea_density = 0.05;
uniform vec3 u_sun_dir;
uniform vec3 u_moon_dir;
uniform vec3 u_light_dir;
uniform vec3 u_light_color;
uniform float u_light_aniso;
uniform vec3 u_to_sun;
uniform vec3 u_away_sun;
uniform float u_sky_midday;
uniform vec3 u_sky_midday_zenith;
uniform vec3 u_sky_midday_haze_to;
uniform vec3 u_sky_midday_haze_away;
uniform vec3 u_sky_sunset_haze;
uniform float u_sky_saturation;
uniform float u_daylight;
uniform float u_moon_phase;
uniform float u_moon_size;
uniform float u_star_density;
uniform float u_star_brightness;
uniform float u_star_twinkle;
uniform mat3 u_star_mat;
uniform float u_rain;
uniform float u_flash;
uniform float u_fog_scale;
uniform float u_fog_desaturation;
uniform vec3 u_fog_desat_tint;
uniform float u_night_haze_brightness;
uniform float u_night_haze_desat;
uniform float u_sky_sunset;
uniform float u_sky_clear_day;
uniform float u_sky_clear_night;
uniform vec3 u_moon_color;
uniform float u_sky_pixel_art;
uniform float u_sky_legacy;
uniform float u_sky_first;
uniform samplerCube u_skybox;
uniform float u_moon_pixels;
uniform float u_moon_glow;
uniform float u_moon_enabled;
uniform float u_moon_glow_size;
uniform float u_moon_style;
uniform float u_sun_brightness;
uniform vec2 u_sun_boil;
uniform vec2 u_sun_flames;
uniform vec3 u_sun_core_color;
uniform vec3 u_sun_edge_color;
uniform float u_sun_glow;
uniform vec3 u_moon_flicker;
uniform float u_moon_brightness;
uniform float u_moon_sphere;
uniform float u_moon_sheen;
uniform float u_moon_edge;
uniform vec3 u_moon_blotch;
uniform float u_sun_size;
uniform float u_cloud_pixel_size;
uniform float u_clouds;
vec2 hash2( vec2  p ) {
p = vec2( dot(p,vec2(127.1,311.7)), dot(p,vec2(269.5,183.3)));
return fract(sin(p)*43758.5453);
}
uint ihash(uint x){
x ^= x >> 16u;
x *= 0x7feb352du;
x ^= x >> 15u;
x *= 0x846ca68bu;
x ^= x >> 16u;
return x;
}
float ihash21(vec2 cell){
uvec2 c = uvec2(ivec2(floor(cell)) + 1048576);
uint n = ihash(c.x * 0x9e3779b9u ^ ihash(c.y * 0x85ebca6bu));
return float(n & 0xffffffu) / 16777216.0;
}
vec3 ihash33(vec3 cell){
uvec3 c = uvec3(ivec3(floor(cell)) + 1048576);
uint n = ihash(c.x * 0x9e3779b9u ^ ihash(c.y * 0x85ebca6bu ^ ihash(c.z * 0xc2b2ae35u)));
uint m = ihash(n + 0x68e31da4u);
uint k = ihash(m + 0xb5297a4du);
return vec3(float(n & 0xffffffu), float(m & 0xffffffu), float(k & 0xffffffu)) / 16777216.0;
}
vec2 grad2(vec2 i){
float h = ihash21(i) * 6.2831853;
return vec2(cos(h), sin(h));
}
float gnoise(vec2 p){
vec2 i = floor(p);
vec2 f = fract(p);
vec2 u = f*f*f*(f*(f*6.0-15.0)+10.0);
float a = dot(grad2(i), f);
float b = dot(grad2(i+vec2(1.0,0.0)), f-vec2(1.0,0.0));
float c = dot(grad2(i+vec2(0.0,1.0)), f-vec2(0.0,1.0));
float d = dot(grad2(i+vec2(1.0,1.0)), f-vec2(1.0,1.0));
return mix(mix(a,b,u.x), mix(c,d,u.x), u.y);
}
float fbm(vec2 p, int octaves){
float v = 0.0;
float a = 0.5;
const mat2 rot = mat2(0.8, 0.6, -0.6, 0.8);
for(int i=0;i<octaves;i++){
v += a*gnoise(p);
p = rot*p*2.1 + vec2(13.7, 7.1);
a *= 0.5;
}
return clamp(v*0.75 + 0.5, 0.0, 1.0);
}
vec3 hash33_v1(vec3 p){
p = vec3(dot(p,vec3(127.1,311.7,74.7)), dot(p,vec3(269.5,183.3,246.1)), dot(p,vec3(113.5,271.9,124.6)));
return fract(sin(p)*43758.5453);
}
float vnoise_v1(vec2 p){
vec2 i = floor(p);
vec2 f = fract(p);
f = f*f*(3.0-2.0*f);
float a = hash2(i).x;
float b = hash2(i+vec2(1.0,0.0)).x;
float c = hash2(i+vec2(0.0,1.0)).x;
float d = hash2(i+vec2(1.0,1.0)).x;
return mix(mix(a,b,f.x),mix(c,d,f.x),f.y);
}
float fbm_v1(vec2 p){
float v = 0.0;
float a = 0.5;
for(int i=0;i<4;i++){
v += a*vnoise_v1(p);
p = p*2.03 + vec2(17.0,31.0);
a *= 0.5;
}
return v;
}
float fog(float dist, vec3 pos, vec3 dir){
float height = max(0.0,pos.z-float(u_world_center));
dir = normalize(dir);
float a = 0.0031*max(u_fog_scale,0.05)*max(u_fog_density,0.0);
float b = 0.005;
float dz = dir.z;
if(abs(dz)<1e-4){
dz = 1e-4;
}
return clamp((a/b) * exp(-height*b) * (1.0-exp( -dist*dz*b ))/dz,0.0,1.0);
}
vec3 fog_color(vec3 dir, bool skybox){
vec3 col = mix(u_away_sun,u_to_sun,mix(0.5, dot(u_light_dir,dir)*0.5+0.5, u_light_aniso));
float night = 1.0 - u_daylight;
float lum = dot(col, vec3(0.299,0.587,0.114));
col = mix(col, lum * u_fog_desat_tint, night * clamp(u_night_haze_desat, 0.0, 1.0));
col *= mix(1.0, max(u_night_haze_brightness, 0.0), night);
return col + u_flash*vec3(0.45,0.5,0.65);
}
vec3 sky_saturate(vec3 c){
float lum = dot(c, vec3(0.299, 0.587, 0.114));
return max(mix(vec3(lum), c, u_sky_saturation), vec3(0.0));
}
vec3 day_sky_v1(vec3 dir, vec3 sun, float low){
vec2 dh = normalize(dir.xy + vec2(1e-4, 0.0));
vec2 sh = normalize(sun.xy + vec2(1e-4, 0.0));
float toward = dot(dh, sh)*0.5+0.5;
toward *= toward;
vec3 zenith = vec3(63.0, 88.0, 165.0)/255.0;
vec3 haze_away = vec3(129.0,113.0,146.0)/255.0;
vec3 haze_to = mix(vec3(244.0,169.0,87.0)/255.0, vec3(240.0,105.0,45.0)/255.0, low);
vec3 haze = mix(haze_away, haze_to, toward);
vec3 below_away = vec3(60.0,60.0,135.0)/255.0;
vec3 below_to = mix(vec3(135.0,92.0,108.0)/255.0, vec3(110.0,66.0,78.0)/255.0, low);
vec3 below = mix(below_away, below_to, toward);
float h = dir.z;
vec3 col;
if(h > 0.0){
col = mix(haze, zenith, pow(clamp(h,0.0,1.0), 0.6));
}else{
col = mix(haze, below, clamp(-h*2.5, 0.0, 1.0));
}
float cs = max(dot(dir, sun), 0.0);
vec3 glow = mix(vec3(1.0,0.85,0.55), vec3(1.0,0.5,0.25), low);
col += glow * (0.18*pow(cs, 6.0) + 0.45*pow(cs, 48.0)) * u_sun_glow;
return col;
}
vec3 day_sky(vec3 dir, vec3 sun, float low){
vec2 dh = normalize(dir.xy + vec2(1e-4, 0.0));
vec2 sh = normalize(sun.xy + vec2(1e-4, 0.0));
float toward = dot(dh, sh)*0.5+0.5;
toward *= toward;
vec3 zenith = mix(vec3(63.0, 88.0, 165.0)/255.0, u_sky_midday_zenith, u_sky_midday);
vec3 day_away = mix(vec3(0.60,0.63,0.72), u_sky_midday_haze_away, u_sky_midday);
vec3 haze_away = mix(day_away, vec3(129.0,113.0,146.0)/255.0, low);
vec3 dusk_to = mix(vec3(244.0,169.0,87.0)/255.0, u_sky_sunset_haze, low);
vec3 day_to = mix(vec3(0.78,0.80,0.86), u_sky_midday_haze_to, u_sky_midday);
vec3 haze_to = mix(day_to, dusk_to, low);
vec3 haze = mix(haze_away, haze_to, toward);
vec3 below_away = mix(vec3(0.30,0.32,0.48), vec3(60.0,60.0,135.0)/255.0, low);
vec3 dusk_below = mix(vec3(135.0,92.0,108.0)/255.0, vec3(110.0,66.0,78.0)/255.0, low);
vec3 below_to = mix(vec3(0.40,0.40,0.52), dusk_below, low);
vec3 below = mix(below_away, below_to, toward);
float h = dir.z;
vec3 col;
if(h > 0.0){
col = mix(haze, zenith, pow(clamp(h,0.0,1.0), 0.6));
}else{
col = mix(haze, below, clamp(-h*2.5, 0.0, 1.0));
}
float cs = max(dot(dir, sun), 0.0);
vec3 glow = mix(vec3(1.0,0.85,0.55), vec3(1.0,0.5,0.25), low);
col += glow * (0.18*pow(cs, 6.0) + 0.45*pow(cs, 48.0)) * u_sun_glow;
return col;
}
float moon_brightness(){
float lit = 0.5 + 0.5*cos(u_moon_phase*6.2831853);
return 0.15 + 0.85*lit;
}
vec3 night_sky(vec3 dir, vec3 mdir){
float h = dir.z;
vec3 zenith = vec3(4.0, 6.0, 16.0)/255.0;
vec3 horizon = vec3(20.0, 24.0, 48.0)/255.0;
vec3 col;
if(h > 0.0){
col = mix(horizon, zenith, pow(clamp(h,0.0,1.0), 0.7));
}else{
col = mix(horizon, vec3(8.0,8.0,20.0)/255.0, clamp(-h*2.0,0.0,1.0));
}
float cm = max(dot(dir, mdir), 0.0);
float r = max(u_moon_size, 0.002);
float ang = acos(clamp(cm, -1.0, 1.0));
float halo = exp(-max(ang - r, 0.0) / (r * max(u_moon_glow_size, 0.1)));
vec3 tint = int(u_moon_style + 0.5) == 3 ? vec3(1.5, 1.2, 0.75) : vec3(1.0);
col += u_moon_color * tint * u_moon_glow * halo * moon_brightness() * u_moon_flicker * u_moon_enabled;
return col;
}
vec3 stars(vec3 dir){
vec3 d = u_star_mat * dir;
vec3 q = d * 42.0;
vec3 c = floor(q);
vec3 h = ihash33(c);
float density = 0.09 * u_star_density;
if(h.x > density){
return vec3(0.0);
}
vec3 sp = c + 0.5 + (ihash33(c + 17.0) - 0.5)*0.8;
float dist = length(q - sp);
float size = 0.05 + 0.03*h.z;
float star = 1.0 - smoothstep(size*0.3, size, dist);
float tw_amp = 0.15 * clamp(u_star_twinkle, 0.0, 1.0);
float twinkle = (1.0 - tw_amp) + tw_amp*sin(u_time*(2.0+4.0*h.y) + h.z*40.0);
vec3 tint = mix(vec3(0.8,0.85,1.0), vec3(1.0,0.9,0.75), h.z);
return tint * star * (0.55+0.45*h.y) * twinkle * u_star_brightness;
}
float disc_coverage(vec3 dir, vec3 center, float radius, float pixels, float edge, out vec2 p){
p = vec2(0.0);
float cm = dot(dir, center);
if(cm < cos(radius*1.25)){
return 0.0;
}
vec3 up = abs(center.z) < 0.9 ? vec3(0.0,0.0,1.0) : vec3(1.0,0.0,0.0);
vec3 mu = normalize(cross(up, center));
vec3 mv = cross(center, mu);
p = vec2(dot(dir, mu), dot(dir, mv)) / sin(radius);
if(u_sky_pixel_art > 0.5){
float half_px = max(pixels, 2.0) * 0.5;
p = (floor(p * half_px) + 0.5) / half_px;
return dot(p, p) < 1.0 ? 1.0 : 0.0;
}
return 1.0 - smoothstep(1.0 - clamp(edge, 0.005, 1.0), 1.0, dot(p, p));
}
vec3 sun_ball(vec3 dir, vec3 sun, out float coverage){
coverage = 0.0;
float r = max(u_sun_size, 0.002);
float cm = dot(dir, sun);
if(cm < cos(r*2.2)){
return vec3(0.0);
}
vec3 up = abs(sun.z) < 0.9 ? vec3(0.0,0.0,1.0) : vec3(1.0,0.0,0.0);
vec3 mu = normalize(cross(up, sun));
vec3 mv = cross(sun, mu);
vec2 p = vec2(dot(dir, mu), dot(dir, mv)) / sin(r);
if(u_sky_pixel_art > 0.5){
float half_px = max(u_moon_pixels, 2.0) * 0.5;
p = (floor(p * half_px) + 0.5) / half_px;
}
float d = length(p);
float tb = u_time * u_sun_boil.y;
float boil = fbm(p*2.5 + vec2(tb*0.35, -tb*0.2), 3)*0.6 + fbm(p*5.0 - vec2(tb*0.5, tb*0.3), 2)*0.4;
float tf = u_time * u_sun_flames.y;
float lick = fbm(p*2.0 + vec2(tf*0.6, tf*0.9), 3);
float flame_r = 1.0 + u_sun_flames.x*(0.4*(lick - 0.5) + 0.35*(boil - 0.5) + 0.2);
float k = d / max(flame_r, 0.5);
vec3 core = u_sun_core_color;
vec3 edge = u_sun_edge_color;
vec3 mid = mix(core, edge, 0.5);
vec3 col = mix(core, mid, smoothstep(0.0, 0.6, k));
col = mix(col, edge, smoothstep(0.6, 1.0, k));
col *= 1.0 + u_sun_boil.x*0.4*(boil - 0.5);
float body = 1.0 - smoothstep(0.75, 1.0, k);
coverage = body;
return col * (2.2 + 2.3*body) * u_sun_brightness;
}
vec3 moon_disc(vec3 dir, vec3 moon_dir, out float coverage){
vec2 p;
int style = int(u_moon_style + 0.5);
coverage = disc_coverage(dir, moon_dir, max(u_moon_size, 0.002), u_moon_pixels, u_moon_edge, p);
if(coverage <= 0.0){
return vec3(0.0);
}
if(style == 6){
float half_px = max(u_moon_pixels, 2.0) * 0.5;
p = (floor(p * half_px) + 0.5) / half_px;
coverage = dot(p, p) < 1.0 ? 1.0 : 0.0;
if(coverage <= 0.0){
return vec3(0.0);
}
}
float rr = dot(p, p);
vec3 n = vec3(p, sqrt(max(1.0 - rr, 0.0)));
float a = u_moon_phase * 6.2831853;
vec3 l = vec3(sin(a), 0.0, cos(a));
bool hard = u_sky_pixel_art > 0.5 || style == 6;
float lit = hard ? step(0.0, dot(n, l)) : smoothstep(-0.05, 0.12, dot(n, l));
coverage *= lit;
if(style == 4){
vec2 bite = p - vec2(0.42, 0.12);
coverage *= hard ? step(1.0, dot(bite, bite)) : smoothstep(0.85, 1.05, dot(bite, bite));
}
vec3 base = u_moon_color * u_moon_brightness;
vec3 col;
if(style == 1){
float sphere = 0.5 + 0.5*pow(max(n.z, 0.0), 0.6);
float sheen = 0.25*pow(max(dot(n, normalize(vec3(-0.35, 0.3, 0.9))), 0.0), 4.0);
col = base * (sphere + sheen) * (0.92 + 0.08*gnoise(p*4.0 + 2.0));
}else if(style == 2){
float alb = 0.85 - 0.22*smoothstep(0.45, 0.75, vnoise_v1(p*2.2 + 3.1));
for(int i=0;i<7;i++){
vec3 hc = hash33_v1(vec3(float(i)*3.7, 1.3, 9.1));
vec2 c = (hc.xy*2.0-1.0)*0.75;
float cr = 0.07 + 0.12*hc.z;
float d = length(p - c);
float crater = 1.0 - smoothstep(cr*0.7, cr, d);
float rim = smoothstep(cr*0.8, cr, d) - smoothstep(cr, cr*1.2, d);
alb *= 1.0 - 0.35*crater + 0.2*rim;
}
col = base * alb * (0.85 + 0.15*n.z);
}else if(style == 3){
vec3 rim = u_moon_color * vec3(1.0, 0.75, 0.45);
col = mix(vec3(1.0, 0.97, 0.88), rim, smoothstep(0.0, 1.0, rr)) * u_moon_brightness * 1.4;
}else if(style == 5){
float maria = smoothstep(0.4, 0.7, fbm(p*1.4 + 5.0, 3));
col = base * (1.0 - 0.28*maria) * (0.88 + 0.12*n.z) * (0.96 + 0.04*gnoise(p*6.0));
}else{
float sphere = mix(1.0, 0.5 + 0.5*pow(max(n.z, 0.0), 0.6), clamp(u_moon_sphere, 0.0, 1.0));
float sheen = u_moon_sheen * 0.25 * pow(max(dot(n, normalize(vec3(-0.35, 0.3, 0.9))), 0.0), 4.0);
float noise = gnoise(p*max(u_moon_blotch.z, 0.1) + 7.0);
float threshold = mix(0.7, -0.7, clamp(u_moon_blotch.y, 0.0, 1.0));
float blotch = 1.0 - u_moon_blotch.x * smoothstep(threshold - 0.05, threshold + 0.05, noise);
col = base * (sphere + sheen) * blotch;
}
return col * u_moon_flicker;
}
float clouds(vec3 dir, out float thick){
thick = 0.0;
if(dir.z < 0.01){
return 0.0;
}
const float scale = 1.6;
vec2 uv = dir.xy / (dir.z + 0.18) * scale;
uv += mod(u_time * vec2(0.016, 0.008), 1024.0);
bool pixel_art = u_sky_pixel_art > 0.5;
if(pixel_art){
float px = (67.6 / scale) / max(u_cloud_pixel_size, 0.05);
uv = (floor(uv * px) + 0.5) / px;
}
vec2 warp = vec2(fbm(uv*0.7 + 3.1, 3), fbm(uv*0.7 - 5.7, 3)) - 0.5;
float n = fbm(uv + warp*0.6, 5);
float cover = mix(0.78, 0.30, max(u_clouds, u_rain));
float c;
if(pixel_art){
c = step(cover, n);
thick = step(cover + 0.2, n);
}else{
c = smoothstep(cover, cover + 0.2, n);
thick = smoothstep(cover + 0.1, cover + 0.45, n);
}
return c * smoothstep(0.01, 0.16, dir.z);
}
vec3 stars_v1(vec3 dir){
vec3 d = u_star_mat * dir;
vec3 q = d * 42.0;
vec3 c = floor(q);
vec3 h = hash33_v1(c);
float density = 0.09 * u_star_density;
if(h.x > density){
return vec3(0.0);
}
vec3 sp = c + 0.5 + (hash33_v1(c + 17.0) - 0.5)*0.8;
float dist = length(q - sp);
float size = 0.04 + 0.06*h.z;
float star = 1.0 - smoothstep(size*0.3, size*2.0, dist);
float twinkle = 0.75 + 0.25*sin(u_time*(2.0+4.0*h.y) + h.z*40.0);
vec3 tint = mix(vec3(0.8,0.85,1.0), vec3(1.0,0.9,0.75), h.z);
return tint * star * (0.4+0.6*h.y) * twinkle * 1.6;
}
vec3 moon_disc_v1(vec3 dir, vec3 moon_dir, out float coverage){
coverage = 0.0;
float r = 0.0419;
float cm = dot(dir, moon_dir);
if(cm < cos(r*1.1)){
return vec3(0.0);
}
vec3 up = abs(moon_dir.z) < 0.9 ? vec3(0.0,0.0,1.0) : vec3(1.0,0.0,0.0);
vec3 mu = normalize(cross(up, moon_dir));
vec3 mv = cross(moon_dir, mu);
vec2 p = vec2(dot(dir, mu), dot(dir, mv)) / sin(r);
float rr = dot(p, p);
coverage = 1.0 - smoothstep(0.92, 1.0, rr);
if(coverage <= 0.0){
return vec3(0.0);
}
vec3 n = vec3(p, sqrt(max(1.0 - rr, 0.0)));
float a = u_moon_phase * 6.2831853;
vec3 l = vec3(sin(a), 0.0, cos(a));
float lit = smoothstep(-0.08, 0.25, dot(n, l));
float alb = 0.85 - 0.22*smoothstep(0.45, 0.75, vnoise_v1(p*2.2 + 3.1));
for(int i=0;i<7;i++){
vec3 hc = hash33_v1(vec3(float(i)*3.7, 1.3, 9.1));
vec2 c = (hc.xy*2.0-1.0)*0.75;
float cr = 0.07 + 0.12*hc.z;
float d = length(p - c);
float crater = 1.0 - smoothstep(cr*0.7, cr, d);
float rim = smoothstep(cr*0.8, cr, d) - smoothstep(cr, cr*1.2, d);
alb *= 1.0 - 0.35*crater + 0.2*rim;
}
return vec3(0.98,0.97,0.9) * alb * (lit*1.7 + 0.02);
}
float clouds_v1(vec3 dir, out float shade){
shade = 1.0;
if(dir.z < 0.01){
return 0.0;
}
vec2 uv = dir.xy / (dir.z + 0.18) * 1.1;
uv += u_time * vec2(0.010, 0.005);
float n = fbm_v1(uv);
float cover = mix(0.62, 0.36, u_rain);
float c = smoothstep(cover, cover + 0.2, n);
shade = 1.0 - 0.45*smoothstep(cover + 0.05, cover + 0.4, n);
return c * smoothstep(0.01, 0.16, dir.z);
}
vec3 sky_color(vec3 pos, vec3 dir, vec3 dir_disc, bool skybox){
if(u_sky_legacy > 0.5){
return mix(texture(u_skybox,dir.xzy).rgb,fog_color(dir,false),fog(1000.0,pos,dir));
}
bool v1 = u_sky_first > 0.5;
vec3 sun = u_sun_dir;
vec3 moon_dir = u_moon_dir;
float low = v1 ? 1.0 - smoothstep(0.02, 0.4, sun.z) : u_sky_sunset;
float night = 1.0 - u_daylight;
vec3 col = mix(night_sky(dir, moon_dir), v1 ? day_sky_v1(dir, sun, low) : day_sky(dir, sun, low), u_daylight);
col = mix(dot(col, vec3(0.299,0.587,0.114)) * u_fog_desat_tint, col, 1.0 - clamp(u_fog_desaturation, 0.0, 1.0));
col += stars(dir) * night*night * (1.0 - u_rain);
float mcov;
vec3 mcol = moon_disc(dir_disc, moon_dir, mcov);
float mvis = mcov * smoothstep(-0.02, 0.05, moon_dir.z) * mix(0.35, 1.0, night) * u_moon_enabled;
col = mix(col, mcol, mvis);
float sun_cov;
vec3 sun_col = sun_ball(dir_disc, sun, sun_cov);
float disc = sun_cov * smoothstep(-0.03, 0.02, sun.z);
vec3 disc_col = sun_col * mix(vec3(1.0), vec3(1.0,0.7,0.5), low);
float cc;
vec3 cloud_col;
if(v1){
float shade;
cc = clouds_v1(dir, shade);
vec3 cloud_day = mix(vec3(0.97,0.94,0.9), vec3(1.0,0.72,0.5), low*0.7);
vec3 cloud_night = vec3(0.02,0.024,0.04)
+ vec3(0.12,0.14,0.2)*moon_brightness()*smoothstep(-0.1,0.3,moon_dir.z);
cloud_col = mix(cloud_night, cloud_day, u_daylight) * shade * (1.0 - 0.55*u_rain);
}else{
float thick;
cc = clouds(dir, thick);
float sun_side = pow(max(dot(dir, sun), 0.0), 6.0) * smoothstep(-0.05, 0.1, sun.z);
vec3 cloud_day = mix(vec3(0.98,0.97,0.95), vec3(1.0,0.78,0.6), low*0.6) * mix(1.0, 0.8, thick)
+ mix(vec3(0.5,0.42,0.25), vec3(0.9,0.42,0.15), low) * sun_side * (1.0 - 0.6*thick);
vec3 cloud_night = vec3(0.02,0.024,0.04)
+ vec3(0.12,0.14,0.2)*moon_brightness()*smoothstep(-0.1,0.3,moon_dir.z)*mix(1.0,0.6,thick);
cloud_col = mix(cloud_night, cloud_day, u_daylight) * (1.0 - 0.5*u_rain);
}
vec3 overcast = mix(vec3(0.018,0.02,0.03), vec3(0.40,0.42,0.46), u_daylight)
* (0.85 + 0.15*smoothstep(0.0,0.5,dir.z));
col = mix(col, overcast, u_rain*0.9);
col += disc_col * disc * (1.0 - cc) * (1.0 - u_rain);
col = mix(col, cloud_col, cc);
col += u_flash * vec3(0.7, 0.75, 0.9) * (0.5 + 0.5*cc);
float clear_amount = clamp(mix(v1 ? 0.0 : u_sky_clear_day, u_sky_clear_night, night), 0.0, 1.0);
float haze = fog(1000.0,pos,dir) * mix(1.0, 1.0 - clear_amount, smoothstep(0.02, 0.45, dir.z));
return mix(col,fog_color(dir,false),haze);
}
vec3 sea_color(){
return vec3(78,98,108)/255.0 * mix(0.1, 1.0, u_daylight) * (1.0 - 0.3*u_rain)
+ u_flash*vec3(0.2,0.22,0.3);
}
highp float sea_level(){
return float(u_world_center)-0.5;
}
uniform vec4 u_waves[4];
uniform vec4 u_wave_phase;
uniform float u_wave_time;
highp float sea_height(vec2 xy){
highp float h = 0.0;
for(int i=0;i<4;i++){
vec4 w = u_waves[i];
h += w.z * sin(dot(w.xy, xy) - w.w*u_wave_time + u_wave_phase[i]);
}
return h;
}
highp float sea_surface(vec2 xy){
return sea_level() + sea_height(xy);
}
vec3 sea_normal(vec2 xy){
highp float dx = 0.0;
highp float dy = 0.0;
for(int i=0;i<4;i++){
vec4 w = u_waves[i];
float c = w.z * cos(dot(w.xy, xy) - w.w*u_wave_time + u_wave_phase[i]);
dx += c*w.x;
dy += c*w.y;
}
return normalize(vec3(-dx,-dy,1.0));
}
highp float sea_hit(vec3 cpos, vec3 dir){
if(abs(dir.z) < 0.003){
return -1.0;
}
highp float t = (sea_level()-cpos.z)/dir.z;
if(t < 0.0){
t = 0.0;
}
for(int i=0;i<5;i++){
vec2 xy = (cpos+dir*t).xy;
highp float tn = (sea_surface(xy)-cpos.z)/dir.z;
t = mix(t, tn, 0.7);
}
return t;
}
vec3 sea_shade(vec3 color, vec2 xy, vec3 dir){
vec3 n = sea_normal(xy);
float lit = dot(n, u_light_dir)*0.5+0.5;
float glint = pow(max(dot(reflect(dir, n), u_light_dir), 0.0), 48.0);
return color * mix(0.78, 1.18, lit) + u_light_color * glint * 0.35;
}
vec2 displace(vec2 pos){
vec2 pos_i = floor(pos);
vec2 pos_f = fract(pos);
pos+=mix(hash2(pos_i),hash2(pos_i-1.0),pos_f.x);
return pos;
}
float waves(vec2 pos, float time){
vec4 x = vec4(-2.3, 0.5, -3.7,-1.0)*pos.x;
vec4 y = vec4(3.2, 2.0, 0.3, -3.0)*pos.y;
vec4 t = vec4(0.3, 0.2, 0.4, 0.1)*time;
vec4 val = x+y+t;
return dot(abs(fract(val)-0.5)*4.0-1.0,vec4(1.0));
}
uniform float u_water_pixel_size_near;
uniform float u_water_pixel_size_far;
uniform float u_water_pixel_size_dist;
uniform float u_water_ripple_strength_near;
uniform float u_water_ripple_strength_far;
uniform float u_water_ripple_strength_dist;
const float WATER_PIXEL_BASE_SIZE = 0.5;
vec3 water_texture(vec2 pos, vec3 color, vec3 dir,float plane_dist){
float pixel_size = max(u_water_pixel_size_near,0.001);
pos = floor(pos/pixel_size)*WATER_PIXEL_BASE_SIZE;
pos = displace(pos);
color *=vec3(0.8,0.8,1.0);
float strength = ((1.0-abs(dir.z))*0.1+0.1)
*u_water_ripple_strength_near
*mix(0.15,1.0,u_daylight);
return color+strength*(clamp(waves(pos,u_time),0.5,1.0)-0.5);
}
uniform vec3 u_water_flow;
uniform float u_water_flow_ripple_scroll;
void unpack_water_data(vec4 data, out vec3 n, out vec2 flow, out bool front, out bool lava){
int a = int(data.a*255.0 + 0.5);
front = a >= 128;
lava = (a & 32) != 0;
vec2 nxy = data.rg*2.0-1.0;
float nz = sqrt(max(0.0, 1.0 - dot(nxy,nxy)));
n = vec3(nxy, (a & 64) != 0 ? -nz : nz);
flow = vec2(data.b*2.0-1.0, float(a & 31)/31.0*2.0-1.0);
float len = length(flow);
flow = len > 0.2 ? flow/len : vec2(0.0);
}
const float VOXEL_WATER_RIPPLE_SCALE = 2.5;
vec3 voxel_ripples(vec2 uv, vec2 move, float scroll, vec3 color, vec3 dir, float plane_dist){
return water_texture((uv - move*scroll)*VOXEL_WATER_RIPPLE_SCALE,color,dir,0.0);
}
void water_frame(vec3 p, vec3 n, vec2 flow, out vec2 uv, out vec2 move){
if(n.z>0.95){
if(dot(flow,flow) > 0.0){
vec2 perp = vec2(-flow.y, flow.x);
uv = vec2(dot(p.xy, flow), dot(p.xy, perp));
move = vec2(u_water_flow_ripple_scroll, 0.0);
}else{
uv = p.xy;
move = vec2(0.0);
}
}else{
vec3 down = normalize(vec3(0.0,0.0,-1.0)+n*n.z);
vec3 across = normalize(cross(n,down));
uv = vec2(dot(p,across),dot(p,down));
move = dot(flow,flow) > 0.0 ? vec2(0.0, mix(1.0,2.5,1.0-abs(n.z))) : vec2(0.0);
}
}
vec3 voxel_water_texture(vec3 p, vec3 n, vec2 flow, vec3 color, vec3 dir, float plane_dist){
vec2 uv;
vec2 move;
water_frame(p, n, flow, uv, move);
float s = u_water_flow.x;
vec3 c = voxel_ripples(uv,move,s,color,dir,plane_dist);
float w = smoothstep(u_water_flow.y-u_water_flow.z, u_water_flow.y, s);
if(w>0.0 && dot(move,move)>0.0){
c = mix(c, voxel_ripples(uv,move,s-u_water_flow.y,color,dir,plane_dist), w);
}
return c;
}
uniform float u_lava_speed_ratio;
vec3 lava_color(){
return vec3(1.7, 0.45, 0.06) * (1.0 - 0.15*u_rain) + u_flash*vec3(0.1,0.05,0.0);
}
const float lava_density = 1.2;
vec3 lava_ripples(vec2 uv, vec2 move, float scroll, vec3 color, vec3 dir){
vec2 pos = (uv - move*scroll)*VOXEL_WATER_RIPPLE_SCALE;
float pixel_size = max(u_water_pixel_size_near,0.001);
pos = floor(pos/pixel_size)*WATER_PIXEL_BASE_SIZE;
pos = displace(pos);
float strength = ((1.0-abs(dir.z))*0.3+0.3)*u_water_ripple_strength_near;
float w = clamp(waves(pos,u_time*0.5),0.5,1.0)-0.5;
return color + strength*w*vec3(1.6, 0.5, 0.05);
}
vec3 lava_texture(vec3 p, vec3 n, vec2 flow, vec3 color, vec3 dir){
vec2 uv;
vec2 move;
water_frame(p, n, flow, uv, move);
float s = u_water_flow.x * u_lava_speed_ratio;
vec3 c = lava_ripples(uv,move,s,color,dir);
float w = smoothstep(u_water_flow.y-u_water_flow.z, u_water_flow.y, s);
if(w>0.0 && dot(move,move)>0.0){
c = mix(c, lava_ripples(uv,move,s-u_water_flow.y*u_lava_speed_ratio,color,dir), w);
}
return c;
}
vec3 apply_voxel_water_at(vec3 color, float total_dist, vec3 dir, vec3 cpos, float wdist, vec4 wdata, bool inside, vec2 ripple_shift){
vec3 n;
vec2 flow;
bool front;
bool lava;
unpack_water_data(wdata, n, flow, front, lava);
vec3 p = cpos+dir*wdist-vec3(ripple_shift,0.0);
if(lava){
if(!inside){
color = mix(lava_color(),color,exp(-lava_density*max(total_dist-wdist,0.0)));
color = lava_texture(p,n,flow,color,dir);
return mix(color,fog_color(dir,false),fog(wdist,cpos,dir));
}
if(total_dist>wdist){
color = mix(color,fog_color(dir,false),fog(total_dist-wdist,cpos+dir*wdist,dir));
color = lava_texture(p,n,flow,color,dir);
}
return mix(lava_color(),color,exp(-lava_density*min(wdist,total_dist)));
}
if(!inside){
color = mix(sea_color(),color,exp(-sea_density*max(total_dist-wdist,0.0)));
color = voxel_water_texture(p,n,flow,color,dir,wdist);
return mix(color,fog_color(dir,false),fog(wdist,cpos,dir));
}else{
if(total_dist>wdist){
color = mix(color,fog_color(dir,false),fog(total_dist-wdist,cpos+dir*wdist,dir));
color = voxel_water_texture(p,n,flow,color,dir,wdist);
}
return mix(sea_color(),color,exp(-sea_density*min(wdist,total_dist)));
}
}
vec3 apply_voxel_water(vec3 color, float total_dist, vec3 dir, vec3 cpos, float wdist, vec4 wdata, bool inside){
return apply_voxel_water_at(color, total_dist, dir, cpos, wdist, wdata, inside, vec2(0.0));
}
vec3 apply_fog_post(vec3 color, float total_dist, vec3 dir, vec3 cpos){
float air_density = u_fog_density;
bool above = cpos.z > sea_surface(cpos.xy);
float plane_dist = sea_hit(cpos, dir);
float air_dist = total_dist;
if(plane_dist>0.0 && plane_dist<total_dist){
vec2 plane_point = (cpos+dir*plane_dist).xy;
if(above){
color = mix(sea_color(),color,exp(-sea_density*(total_dist-plane_dist)));
color = water_texture(plane_point,color,dir, plane_dist);
color = sea_shade(color, plane_point, dir);
return mix(color,fog_color(dir,false),fog(plane_dist,cpos,dir));
}else{
color = mix(color,fog_color(dir,false),fog(total_dist-plane_dist,cpos,dir));
color = water_texture(plane_point,color,dir, plane_dist);
return mix(sea_color(),color,exp(-sea_density*plane_dist));
}
}else{
if(above){
return mix(color,fog_color(dir,false),fog(total_dist,cpos,dir));
}else{
return mix(sea_color(),color,exp(-0.02*total_dist));
}
}
}
vec3 skybox_fog(vec3 dir, vec3 dir_disc, vec3 cpos){
float air_density = u_fog_density;
bool above = cpos.z > sea_surface(cpos.xy);
float plane_dist = sea_hit(cpos, dir);
vec3 ret = vec3(0);
if(plane_dist>0.0){
vec2 plane_point = (cpos+dir*plane_dist).xy;
if(above){
vec3 color =  water_texture(plane_point,sea_color(),dir, plane_dist);
color = sea_shade(color, plane_point, dir);
ret = mix(color,sky_color(cpos,dir,dir_disc,true),fog(plane_dist,cpos,dir));
}else{
vec3 color = water_texture(plane_point,sky_color(cpos,dir,dir_disc,true),dir, plane_dist);
ret = mix(sea_color(),color,exp(-sea_density*plane_dist));
}
}else{
if(above){
ret = sky_color(cpos,dir,dir_disc,true);
}else{
ret=sea_color();
}
}
return sky_saturate(ret);
}
vec3 skybox_fog(vec3 dir, vec3 cpos){
return skybox_fog(dir, dir, cpos);
}
#ifdef VERTEX
void main() {
vec3 pos = get_position();
float cam_dist = length(u_cam_pos-pos);
setup_varyings(cam_dist);
v_worldPos = pos;
vec3 norm_pos = pos/u_world_size*2.0-1.0;
norm_pos.z=-norm_pos.z;
gl_Position = vec4(norm_pos,1);
}
#endif
#ifdef FRAGMENT
out vec4 o_color;
void main() {
vec4 color;
vec4 data;
vec3 normal;
uint code = get_pixel(color,data);
output_ground(code, color,data,normal);
float dott = 0.5+max(0.0,dot(normal, normalize(vec3(1,1,1))))*0.5;
color *= dott;
if(v_worldPos.z<sea_level()){
color=vec4(0.5,0.7,0.8,1.0);
}
o_color = vec4(color.rgb,1.0);
}
#endif