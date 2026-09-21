//! bundle game
precision highp float;
#ifdef VERTEX
#define varying out
#else
#define varying in
#endif
uniform mat4 u_mvp;
uniform vec4 u_index;
#ifdef VERTEX
in vec3 a_position;
void main() {
vec4 vertexPos = vec4( a_position, 1 );
gl_Position = u_mvp * vertexPos;
}
#endif
#ifdef FRAGMENT
out vec4 o_color;
void main() {
o_color = u_index;
}
#endif