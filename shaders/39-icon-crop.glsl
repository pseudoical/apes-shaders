//! bundle game
//! queue ui
//! zwrite off
//! ztest off
#ifdef VERTEX
#define varying out
#else
#define varying in
#endif
precision highp float;
varying vec2 v_uv;
#ifdef VERTEX
uniform mat4 u_mvp;
in vec3 a_position;
in vec2 a_uv;
void main() {
v_uv = a_uv;
gl_Position = u_mvp * vec4(a_position, 1.0);
}
#endif
#ifdef FRAGMENT
out vec4 o_color;
uniform sampler2D u_tex;
uniform vec4 u_uv_rect;
uniform mat4 u_color;
void main() {
vec4 c = texture(u_tex, mix(u_uv_rect.xy, u_uv_rect.zw, v_uv));
o_color = u_color * c;
}
#endif