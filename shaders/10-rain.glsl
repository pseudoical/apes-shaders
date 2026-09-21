//! bundle game
//! priority 2
precision highp float;
precision highp int;
#ifdef VERTEX
#define varying out
#else
#define varying in
#endif
uniform mat4 u_vp;
uniform vec3 u_cam_pos;
uniform float u_time;
uniform float u_rain;
uniform vec2 u_wind;
uniform float u_fall_speed;
uniform vec3 u_tint;
uniform mat4 u_occluder_mat;
uniform sampler2D u_occluder;
uniform sampler2D u_depthtex;
varying vec3 v_world;
varying vec2 v_uv;
varying float v_alpha;
const float BOX = 44.0;
const float HEIGHT = 30.0;
#ifdef VERTEX
in float a_position;
vec3 hash3(float n){
return fract(sin(vec3(n, n + 1.7, n + 3.1)) * vec3(43758.5453, 22578.1459, 19642.3490));
}
void main(){
int vid = int(a_position + 0.5);
int streak = vid / 6;
int corner = vid - streak * 6;
vec3 h = hash3(float(streak) * 0.7311 + 0.13);
float h4 = fract(h.x * 17.31 + h.y * 7.77);
float speed = u_fall_speed * (0.8 + 0.4 * h4);
vec2 base = h.xy * BOX + u_wind * u_time;
vec2 xy = u_cam_pos.xy + (mod(base - u_cam_pos.xy, BOX) - BOX * 0.5);
float zbase = h.z * HEIGHT - speed * u_time;
float z = u_cam_pos.z + (mod(zbase - u_cam_pos.z, HEIGHT) - HEIGHT * 0.4);
vec3 p = vec3(xy, z);
vec3 fall = normalize(vec3(u_wind, -speed));
float len = 0.3 + 0.3 * h4 + speed * 0.015;
vec3 to_cam = u_cam_pos - p;
float dist = length(to_cam);
vec3 across = normalize(cross(fall, to_cam / max(dist, 0.001)));
float width = max(0.018, dist * 0.0022);
vec2 uv;
if(corner == 0) uv = vec2(-1.0, 0.0);
else if(corner == 1) uv = vec2(1.0, 0.0);
else if(corner == 2) uv = vec2(1.0, 1.0);
else if(corner == 3) uv = vec2(-1.0, 0.0);
else if(corner == 4) uv = vec2(1.0, 1.0);
else uv = vec2(-1.0, 1.0);
vec3 wp = p - fall * (len * uv.y) + across * (width * uv.x);
v_world = wp;
v_uv = uv;
v_alpha = smoothstep(0.25, 1.2, dist) * (1.0 - smoothstep(BOX * 0.32, BOX * 0.5, dist));
gl_Position = u_vp * vec4(wp, 1.0);
}
#endif
#ifdef FRAGMENT
out vec4 o_color;
void main(){
float scene_depth = texelFetch(u_depthtex, ivec2(gl_FragCoord.xy), 0).r;
if(gl_FragCoord.z > scene_depth){
discard;
}
vec4 oc = u_occluder_mat * vec4(v_world, 1.0);
float roof = texture(u_occluder, oc.xy * 0.5 + 0.5).r;
float mine = oc.z * 0.5 + 0.5;
if(mine < roof){
discard;
}
float edge = 1.0 - abs(v_uv.x);
float a = v_alpha * edge * (0.28 + 0.3 * u_rain);
o_color = vec4(u_tint, a);
}
#endif