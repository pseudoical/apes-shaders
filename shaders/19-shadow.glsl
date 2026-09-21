//! bundle game
//! queue shadow
//! cull off
precision highp float;
#ifdef VERTEX
#define varying out
#else
#define varying in
#endif
uniform mat4 u_model;
uniform mat4 u_mvp;
uniform mat4 u_vp;
#ifdef VERTEX
in vec3 a_position;
void main() {
vec4 vertexPos = vec4( a_position, 1 );
gl_Position = u_mvp * vertexPos;
}
#endif
#ifdef FRAGMENT
void main() {
}
#endif