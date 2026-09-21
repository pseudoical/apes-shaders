
//! bundle game editor
//! priority 2
precision highp float;
#ifdef VERTEX
#define varying out
#else
#define varying in
#endif

uniform float u_fade;
uniform mat4 u_projection;
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
const bool OPAQUE_VOXEL_WATER_DEBUG = false;
varying vec3 v_worldPos;
varying float v_depth;
varying vec4 v_worldRay;
uniform mat4 u_vp_inv;
uniform mat4 u_p_inv;
uniform vec3 u_cam_pos;
uniform sampler2D u_maintex;
uniform sampler2D u_normaltex;
uniform sampler2D u_depthtex;
uniform sampler2D u_particles_tex;
uniform sampler2D u_bloom_tex;
uniform sampler2D u_particles_depth_tex;
uniform highp sampler2DArray u_light_list;
uniform int u_light_list_layers;
uniform int u_light_tile;
uniform highp sampler3D u_turbulence;
uniform highp sampler3D u_lut;
uniform highp sampler2D u_shadowtex;
uniform mat4 u_shadow_vp;
uniform float u_shadow_range;
uniform highp sampler2DShadow u_object_shadow;
uniform ivec2 u_shadow_pos;
uniform vec3 u_focus_pos;
uniform float u_ape_light_radius;
const int MAX_LIGHTS = 256;
uniform vec4 u_light_positions[ MAX_LIGHTS ];
uniform vec4 u_light_colors[MAX_LIGHTS];
uniform int u_circle_closed;
uniform highp sampler3D u_world_ao_tex;
uniform sampler2D u_water_depth;
uniform sampler2D u_water_data;
uniform int u_cam_in_water;
uniform sampler2D u_sky_tex;
uniform float u_sky_half_res;
uniform float u_sky_pixel_block;
uniform vec2 u_clip;
varying vec3 v_eye_direction;
uniform vec3 u_circle;
uniform vec2 u_halfSizeNearPlane;
varying vec4 eye_ray;
#ifdef VERTEX
in vec3 a_position;
void main() {
vec4 vertexPos = vec4( a_position.xy,0, 1 );
vec2 uv = vertexPos.xy*0.5+0.5;
v_eye_direction = vec3((2.0 * u_halfSizeNearPlane * uv) - u_halfSizeNearPlane , -1.0);
v_worldRay = u_vp_inv*vertexPos;
v_worldRay/=v_worldRay.w;
gl_Position = vertexPos;
}
#endif
#ifdef FRAGMENT
out vec4 o_color;
uniform bool u_hitEnabled;
uniform vec3 u_hitColor;
uniform float u_hitIntensity;
uniform float u_hitYaw01;
uniform vec2 u_screenDims;
uniform int u_particle_downscale_shift;
uniform vec3 u_tint;
uniform float u_ape_fade;
uniform float u_brightness;
uniform float u_saturation;
float signNotZero(in float k) {
return (k >= 0.0) ? 1.0 : -1.0;
}
vec2 signNotZero(in vec2 v) {
return vec2(signNotZero(v.x), signNotZero(v.y));
}
vec3 octDecode(vec2 o) {
o = o*2.0-1.0;
vec3 v = vec3(o.x, o.y, 1.0 - abs(o.x) - abs(o.y));
if (v.z < 0.0) {
v.xy = (1.0 - abs(v.yx)) * signNotZero(v.xy);
}
return normalize(v);
}
const vec4 dielectric_spec  = vec4(0.220916301, 0.220916301, 0.220916301, 1.0 - 0.220916301);
float OneMinusReflectivityFromMetallic(float metallic)
{
float oneMinusDielectricSpec = dielectric_spec.a;
return oneMinusDielectricSpec - metallic * oneMinusDielectricSpec;
}
vec3 DiffuseAndSpecularFromMetallic (vec3 albedo, float metallic, out vec3 specColor, out float oneMinusReflectivity)
{
specColor = mix (dielectric_spec.rgb, albedo, metallic);
oneMinusReflectivity = OneMinusReflectivityFromMetallic(metallic);
return albedo * oneMinusReflectivity;
}
float saturate(float val){
return clamp(val,0.0,1.0);
}
vec3 saturate_color(vec3 c, float s){
float lum = dot(c, vec3(0.299, 0.587, 0.114));
return clamp(mix(vec3(lum), c, s), 0.0, 1.0);
}
float Pow4 (float x)
{
return x*x*x*x;
}
vec3 FresnelLerpFast (vec3 F0, vec3 F90, float cosA)
{
float t = Pow4 (1.0 - cosA);
return mix (F0, F90, t);
}
vec3 brdf(vec3 diffColor, vec3 specColor, float oneMinusReflectivity, float perceptualRoughness, vec3 normal, vec3 viewDir, vec3 ambient, vec3 spec, vec3 lightcol, vec3 lightdir){
vec3 halfDir = normalize(vec3(lightdir) + viewDir);
float nl = saturate(dot(normal, lightdir)+0.1);
float nh = saturate(dot(normal, halfDir));
float nv = abs(dot(normal, viewDir));
float lh = saturate(dot(lightdir, halfDir));
float smoothness = 1.0-perceptualRoughness;
float roughness = perceptualRoughness;
float a = roughness;
float a2 = a*a;
float d = nh * nh * (a2 - 1.0) + 1.00001;
float specularTerm = a2 / (max(0.1f, lh*lh) * (roughness + 0.5f) * (d * d) * 4.0);
float surfaceReduction = (0.6-0.08*perceptualRoughness);
surfaceReduction = 1.0 - roughness*perceptualRoughness*surfaceReduction;
float grazingTerm = saturate(smoothness + (1.0-oneMinusReflectivity));
vec3 color =   (diffColor + specularTerm * specColor) * lightcol * nl
+diffColor*ambient
+surfaceReduction * spec * FresnelLerpFast (specColor, vec3(grazingTerm), nv);
return color;
}
vec3 brdf_light(vec3 diffColor, vec3 specColor, float oneMinusReflectivity, float perceptualRoughness, vec3 normal, vec3 viewDir, vec3 lightcol, vec3 lightdir){
vec3 halfDir = normalize(vec3(lightdir) + viewDir);
float nl = saturate(dot(normal, lightdir));
float nh = saturate(dot(normal, halfDir));
float lh = saturate(dot(lightdir, halfDir));
float smoothness = 1.0-perceptualRoughness;
float roughness = perceptualRoughness;
float a = roughness;
float a2 = a*a;
float d = nh * nh * (a2 - 1.0) + 1.00001;
float specularTerm = a2 / (max(0.1f, lh*lh) * (roughness + 0.5f) * (d * d) * 4.0);
vec3 color =   (diffColor + specularTerm * specColor) * lightcol * nl;
return color;
}
vec3 point_light_color(uint idx, vec3 wp){
vec4 light_color = u_light_colors[idx];
vec4 light_position = u_light_positions[idx];
vec3 ld = light_position.xyz-wp;
float d2 = dot(ld,ld);
float r2 = light_position.w;
float window = r2 > 0.0 ? clamp(1.0-(d2*d2)/(r2*r2), 0.0, 1.0) : 1.0;
float core2 = max(light_color.w, 0.0625);
return light_color.xyz*(window*window*core2/max(core2,d2));
}
vec4 CalcEyeFromWindow(in float windowZ, in vec3 eyeDirection)
{
float ndcZ = (2.0 * windowZ - 1.0);
float eyeZ = u_projection[3][2] / ((u_projection[2][3] * ndcZ) - u_projection[2][2]);
return vec4(eyeDirection * eyeZ, 1);
}
uint pcg3d16(uvec3 p)
{
uvec3 v = p * 1664525u + 1013904223u;
v.x += v.y*v.z; v.y += v.z*v.x; v.z += v.x*v.y;
v.x += v.y*v.z;
return v.x;
}
vec3 ACESFilm(vec3 x)
{
float a = 2.51;
float b = 0.03;
float c = 2.43;
float d = 0.59;
float e = 0.14;
return clamp((x*(a*x+b))/(x*(c*x+d)+e),0.0,1.0);
}
vec3 Tonemap_Aces(vec3 color) {
const float slope = 12.0f;
vec4 x = vec4(
color.r, color.g, color.b,
(color.r * 0.299) + (color.g * 0.587) + (color.b * 0.114)
);
const float a = 2.51f;
const float b = 0.03f;
const float c = 2.43f;
const float d = 0.59f;
const float e = 0.14f;
vec4 tonemap = clamp((x * (a * x + b)) / (x * (c * x + d) + e), 0.0, 1.0);
float t = x.a;
t = t * t / (slope + t);
return mix(tonemap.rgb, tonemap.aaa, t);
}
void main() {
float depth = texelFetch(u_depthtex, ivec2(gl_FragCoord.xy),0).r;
float noise = float(pcg3d16(uvec3(gl_FragCoord.xy,u_time*1000.0))>>16)/65535.0/255.0;
vec3 dir = normalize(v_worldRay.xyz);
vec4 eye_pos = CalcEyeFromWindow(depth,v_eye_direction);
float dist = length(eye_pos.xyz);
vec3 world_pos = dist*dir+u_cam_pos;
float wdist = 1e9;
vec4 wdata = vec4(0.0);
bool water_seen = false;
bool cam_in_water = false;
#ifdef WORLD
{
cam_in_water = u_cam_in_water!=0;
float wdepth = texelFetch(u_water_depth, ivec2(gl_FragCoord.xy),0).r;
if(wdepth<1.0){
float d = length(CalcEyeFromWindow(wdepth,v_eye_direction).xyz);
vec4 data = texelFetch(u_water_data, ivec2(gl_FragCoord.xy),0);
if(d<dist-(0.005+dist*0.0002) && (cam_in_water || data.a>0.5)){
wdist = d;
wdata = data;
}
}
water_seen = cam_in_water || wdist<dist;
if(u_cam_in_water == 2){
wdata.a = float(int(wdata.a*255.0 + 0.5) | 32)/255.0;
}
if(OPAQUE_VOXEL_WATER_DEBUG){
cam_in_water = false;
water_seen = false;
}
}
#endif
vec4 base_color = vec4(0,0,0,1);
bool ape = false;
if(depth!=1.0){
#ifdef WORLD
float world_ao = texture(u_world_ao_tex,world_pos.zyx/1536.0).r*36.0;
#else
float world_ao = 1.0;
#endif
vec4 cbuf = texelFetch(u_maintex, ivec2(gl_FragCoord.xy),0);
vec4 nbuf = texelFetch(u_normaltex, ivec2(gl_FragCoord.xy),0);
uvec2 unpack = uvec2(vec2(cbuf.a,nbuf.a)*255.0);
vec4 data = vec4(float(unpack.x&15u)/15.0,float((unpack.x>>4)&7u)/7.0,float(unpack.y&7u)/7.0,float((unpack.y>>4)&15u)/15.0);
bool ground = ((unpack.x>>7)&1u)==1u;
ape = ((unpack.y>>3)&1u)==1u;
data.a*=world_ao*0.85+0.15;
base_color = vec4(cbuf.xyz,1.0);
int lod = int(nbuf.z*255.0);
vec3 normal = octDecode(nbuf.xy);
vec3 wp = world_pos;
vec3 lightdir = u_light_dir;
if(ground){
wp = world_pos+normal*(0.1+0.5*float(dist>100.0));
}
float sun_atten = 1.0-fog(2000.0,wp,lightdir);
vec3 lightcol = u_light_color*sun_atten;
float ground_shadowed = 1.0;
#ifdef WORLD
{
float facing = clamp(dot(normal,lightdir),0.0,1.0);
vec4 sc = u_shadow_vp*vec4(wp+lightdir*(1.0-facing),1.0);
float stored = texture(u_shadowtex,sc.xy*0.5+0.5).r;
float bias = (2.0+float(1<<lod))*0.7/max(u_shadow_range,1.0);
if(sc.z*0.5+0.5<stored-bias){
lightcol = vec3(0.0);
}
}
if(ground){
vec2 shadow_off = world_pos.xy-vec2(u_shadow_pos);
float shadowed = 0.0;
shadowed+=texture(u_object_shadow,vec3(((shadow_off*16.0)+512.0)/1024.0,1.0-wp.z/1536.0));
vec2 a = abs(shadow_off);
shadowed = max(shadowed,clamp(max(a.x,a.y)/(1024.0/16.0/2.0),0.0,1.0));
ground_shadowed = shadowed;
lightcol*=shadowed;
data.a*=shadowed*0.1+0.9;
}
#endif
if(world_pos.z<sea_surface(world_pos.xy) || water_seen){
data.r=1.0;
}
vec3 specular;
float oneMinusReflectivity;
vec3 diffuse = DiffuseAndSpecularFromMetallic(base_color.rgb, data.g, specular,  oneMinusReflectivity);
vec3 view_dir = -normalize(v_worldRay.xyz);
vec3 refl = 2.0*dot(view_dir,normal)*normal-view_dir;
vec3 ambient = mix(u_away_sun,u_to_sun,mix(0.5,dot(lightdir,normal)*0.5+0.5,u_light_aniso))*2.0
+ u_flash*vec3(0.8,0.85,1.0)*(normal.z*0.5+0.5)*1.2;
vec3 spec = mix(u_away_sun,u_to_sun,mix(0.5,dot(lightdir,refl)*0.5+0.5,u_light_aniso));
base_color.rgb = brdf(diffuse,specular,oneMinusReflectivity, data.r, normal,view_dir,
ambient*data.a,
spec*data.a
, lightcol, lightdir
)+cbuf.rgb*data.b;
#ifdef WORLD
if(u_light_tile > 0){
ivec2 tile = ivec2(gl_FragCoord.xy) / u_light_tile;
for(int t=0; t<4; t++){
uvec4 list = uvec4(texelFetch(u_light_list,ivec3(tile.x*4+t,tile.y,0),0)*255.0);
for(int i=0; i<4; i++){
if(list[i]!=255u){
uint idx = list[i];
vec3 light_dir = normalize(u_light_positions[idx].xyz-wp);
base_color.rgb +=brdf_light(diffuse,specular,oneMinusReflectivity, data.r, normal,view_dir, point_light_color(idx, wp), light_dir);
}
}
}
} else {
for(int layer=0; layer<u_light_list_layers; layer++){
uvec4 list = uvec4(texelFetch(u_light_list,ivec3(gl_FragCoord.xy,layer),0)*255.0);
for(int i=0; i<4; i++){
if(list[i]!=255u){
uint idx = list[i];
vec3 light_dir = normalize(u_light_positions[idx].xyz-wp);
base_color.rgb +=brdf_light(diffuse,specular,oneMinusReflectivity, data.r, normal,view_dir, point_light_color(idx, wp), light_dir);
}
}
}
}
float ape_light_brightness_limit = 0.1;
float ape_light_center_brightness = 2.0;
float ape_light_saturation = 0.2;
vec3 ape_light_color = vec3(0.8,0.9,1.0);
vec3 ld = u_focus_pos - wp;
float atten = min(ape_light_brightness_limit,1.0/max(1.0,dot(ld,ld))*max(0.0,0.8-world_ao));
float nl = saturate(dot(normal, normalize(ld)));
base_color.rgb+=  (diffuse*ape_light_saturation+(1.0-ape_light_saturation)) * nl * atten *ape_light_color*ape_light_center_brightness*u_ape_light_radius;
#endif
}
vec4 particle_color = texelFetch(u_particles_tex,ivec2(gl_FragCoord.xy)>>u_particle_downscale_shift,0);
vec4 bloom_color = texelFetch(u_bloom_tex,ivec2(gl_FragCoord.xy)>>u_particle_downscale_shift,0);
float particle_depth = texelFetch(u_particles_depth_tex, ivec2(gl_FragCoord.xy)>>u_particle_downscale_shift,0).r;
#ifdef WORLD
if(particle_color.a!=0.0 && particle_depth<min(depth+(0.1*(1.0-depth)),1.0)){
vec3 col = pow(particle_color.rgb,vec3(0.7))+bloom_color.xyz*2.0*bloom_color.a;
float over = dot(clamp(col-1.0,0.0,1.0),vec3(1));
bool sky = depth==1.0;
float scene_dist = sky ? 1.0e5 : dist;
depth = particle_depth;
vec4 eye_pos = CalcEyeFromWindow(depth,v_eye_direction);
dist = length(eye_pos.xyz);
if(water_seen && dist<wdist){
base_color.rgb = apply_voxel_water_at(base_color.rgb,scene_dist,dir,u_cam_pos,wdist,wdata,cam_in_water,vec2(0.0));
water_seen = false;
}
base_color.rgb = mix(base_color.rgb,clamp(col+over,vec3(0.0),vec3(1.0)),max(float(sky),mix(0.1,0.3,clamp(dist*0.1,0.0,1.0))));
}
#endif
#ifdef WORLD
vec2 dir_xy = dir.xy;
float hmul = 1.0;
bool intersect = false;
vec3 add_cyl = vec3(0.0);
bool circle_closed = u_circle_closed!=0;
vec2 circle = world_pos.xy-u_circle.xy;
float circle_dist = length(circle.xy);
if (dot(dir_xy,dir_xy)>0.0001){
vec2 d = dir_xy;
vec2 f = u_cam_pos.xy-u_circle.xy;
float r = u_circle.z;
float a = dot(d,d);
float b = 2.0*dot(f,d);
float c = dot(f,f)-r*r;
float discr = b*b-4.0*a*c;
if(discr>0.0){
discr = sqrt(discr);
float t1 = (-b - discr)/(2.0*a);
float t2 = (-b + discr)/(2.0*a);
float ta = max(t1,t2);
float tb = min(t1,t2);
if(tb<0.0){
tb=ta;
}
float t = min(ta,tb);
if(t>0.0){
float mag = t;
vec3 pnt = mag*dir+u_cam_pos;
if(mag<dist){
vec3 turb = texture(u_turbulence, (floor(pnt*2.0)*0.5+vec3(0.0,0.0,-u_time*20.0))/64.0).xyz;
float rim = max(0.0,min(1.0,dot(dir,vec3((u_circle.xy-pnt.xy)/u_circle.z,0.0))));
rim = (1.0 - rim) * step(0.0, rim);
rim = rim*rim*rim;
add_cyl = (1.0-max(0.0,min(1.0,(pnt.z-1000.0)/500.0)))*(vec3(mod(turb,0.5)*2.0)*0.5+0.5)*mix(vec3(0.3,0.00,0.07),vec3(0.8,0.2,0.1),rim);
if(circle_closed){
add_cyl = vec3(dot(add_cyl,vec3(0.30, 0.59, 0.11)));
}
add_cyl = add_cyl*(1.0-fog(mag,u_cam_pos,dir));
}
}
}
}
#endif
if(depth==1.0){
if(u_sky_half_res > 0.5){
vec3 sky = texture(u_sky_tex, gl_FragCoord.xy/u_screenDims).rgb;
base_color.rgb = sky*sky*4.0;
}else{
float block = max(u_sky_pixel_block, 1.0);
vec2 block_ndc = ((floor(gl_FragCoord.xy/block)+0.5)*block/u_screenDims)*2.0-1.0;
vec4 block_ray = u_vp_inv*vec4(block_ndc,0.0,1.0);
vec3 dir_disc = normalize(block_ray.xyz/block_ray.w);
base_color.rgb = skybox_fog(dir,dir_disc,u_cam_pos);
}
if(water_seen){
base_color.rgb = apply_voxel_water_at(base_color.rgb,1.0e5,dir,u_cam_pos,wdist,wdata,cam_in_water,vec2(0.0));
}
}else if(water_seen){
base_color.rgb = apply_voxel_water_at(base_color.rgb,dist,dir,u_cam_pos,wdist,wdata,cam_in_water,vec2(0.0));
}else{
#ifdef WORLD
if(u_circle.z > 0.0) {
if(circle_dist<u_circle.z){
if(circle_closed){
base_color.rgb*=0.1;
}
}else{
if(!circle_closed){
base_color.rgb*=vec3(1.0,0.5,0.5);
}
}
float rim_burn = (1.0-clamp(abs(circle_dist-u_circle.z)/20.0, 0.0, 1.0));
rim_burn = rim_burn*rim_burn*0.5;
vec3 burn = vec3(1.0,0.1,0.0);
if(circle_closed){
burn = vec3(0.5,0.5,0.5);
}
base_color.rgb = mix(base_color.rgb,burn,rim_burn);
}
#endif
base_color.rgb = apply_fog_post(base_color.rgb,dist,dir,u_cam_pos);
}
#ifdef WORLD
base_color.rgb+=add_cyl;
#endif
#ifdef WORLD
base_color.rgb+=bloom_color.xyz*2.0*base_color.a;
#endif
base_color.rgb = Tonemap_Aces(base_color.rgb * max(u_brightness, 0.0));
#ifdef WORLD
vec3 flashes = vec3(0);
vec4 overlay = vec4(0);
if (u_hitEnabled) {
vec2 coord = 2.*gl_FragCoord.xy/u_screenDims.yy - vec2(u_screenDims.x/u_screenDims.y, 1.);
float r = length(coord);
float getShot = 2.*max(0., .5*u_hitIntensity*r);
flashes = u_hitColor*getShot;
if (u_hitYaw01 >= 0.0) {
float angle = (atan(coord.y, coord.x==0.0?0.00001:coord.x) + 3.14159) / 6.28319;
float moddelta = fract(u_hitYaw01 - angle);
float a = 30.0 * (moddelta-0.5);
float b = max(0.0, 5.0-a*a);
float c = max(0.0, 1.0 - 20.*abs(r-0.5));
overlay = vec4(u_hitColor * b * c, min(1.0,b * c * u_hitIntensity));
}
}
base_color.rgb = mix((base_color.rgb + flashes), overlay.rgb, overlay.a);
#endif
base_color.rgb = texture(u_lut,mix(vec3(0.5/32.0), vec3(31.5/32.0), clamp(base_color.rgb,0.0,1.0))).rgb;
base_color.rgb = saturate_color(base_color.rgb, u_saturation);
o_color = vec4(mix(u_fade * u_tint,vec3(1.0),float(ape)*u_ape_fade) * base_color.rgb,1.0)+noise;
}
#endif