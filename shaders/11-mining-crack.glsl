//! bundle game
//! queue debug
//! blend src_alpha one_minus_src_alpha
//! zwrite off
//! ztest on
//! cull off
precision highp float;
uniform mat4 u_mvp;
uniform vec4 u_color;
uniform float u_fade;
#ifdef VERTEX
in vec3 a_position;
void main() {
gl_Position = u_mvp * vec4(a_position, 1.0);
gl_Position.z -= 0.00002 * gl_Position.w;
}
#endif
#ifdef FRAGMENT
out vec4 o_color;
void main() {
o_color = vec4(u_color.rgb, u_color.a * u_fade);
}
#endif