//! bundle game
precision highp float;
precision highp int;
#ifdef VERTEX
#define varying out
#else
#define varying in
#endif
#ifdef VERTEX
in uvec4 a_position;
in uvec4 a_codes;
in uvec4 a_normal;
#endif
uniform int u_lod;
uniform vec3 u_coord;
uniform mat4 u_shadow_vp;
uniform vec3 u_cam_pos;
#ifdef VERTEX
void main() {
vec3 pos = vec3(a_position.xyz<<u_lod)+u_coord;
if((a_codes.x&127u)==40u){
gl_Position = vec4(0.0, 0.0, -3.0, 1.0);
return;
}
gl_Position = u_shadow_vp * vec4(pos, 1.0);
}
#endif
#ifdef FRAGMENT
void main() {
}
#endif