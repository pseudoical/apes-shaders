//! bundle game
//! queue late
//! blend src_alpha one_minus_src_alpha
//! zwrite off
//! ztest off
precision highp float;
uniform vec4 u_color;
uniform mat4 u_mvp;
uniform float u_fade;
#ifdef VERTEX
in vec3 a_position;
void main() {
gl_Position = u_mvp * vec4( a_position, 1 );
}
#endif
#ifdef FRAGMENT
out vec4 o_color;
void main() {
vec4 color = u_color;
color.rgb *= u_fade;
o_color = color;
}
#endif