//! bundle game editor
precision highp float;
uniform mat4 u_mvp;
#ifdef VERTEX
#define varying out
#else
#define varying in
#endif
varying vec4 v_color;
#ifdef VERTEX
in vec3 a_position;
in vec4 a_color;
void main() {
gl_Position = u_mvp * vec4( a_position, 1 );
v_color = a_color;
}
#endif
#ifdef FRAGMENT
out vec4 o_color;
void main() {
o_color = v_color;
}
#endif