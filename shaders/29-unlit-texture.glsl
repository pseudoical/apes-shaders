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
uniform vec4 u_uv_scale_offset;
varying vec2 v_uv;
#ifdef VERTEX
uniform mat4 u_mvp;
in vec3 a_position;
in vec2 a_uv;
void main() {
v_uv = a_uv;
v_uv = v_uv*u_uv_scale_offset.xy+u_uv_scale_offset.zw;
gl_Position = u_mvp * vec4( a_position, 1 );
}
#endif
#ifdef FRAGMENT
out vec4 o_color;
uniform sampler2D u_tex;
uniform mat4 u_color;
void main() {
vec4 samp = texture(u_tex, v_uv);
o_color = u_color*samp.rgba;
o_color.w*=samp.w;
}
#endif