//! bundle game
//! queue particle
//! cull off
precision highp float;
#ifdef VERTEX
#define varying out
#else
#define varying in
#endif
uniform mat4 u_model;
uniform mat4 u_mvp;
uniform sampler2D u_mainTex;
uniform float u_ditherAlpha;
uniform sampler2D u_ditherTex;
varying vec2 v_uv;
#ifdef VERTEX
in vec3 a_position;
in vec3 a_normal;
in vec2 a_uv;
void main() {
vec4 vertexPos = vec4( a_position, 1 );
v_uv = a_uv;
gl_Position = u_mvp * vertexPos;
}
#endif
#ifdef FRAGMENT
uniform vec4 u_color;
out vec4 o_color;
void main() {
float ditherRef = texelFetch(u_ditherTex, ivec2(mod(gl_FragCoord.xy, 8.0)), 0).r;
if (u_ditherAlpha*(1.0-abs(v_uv.y-0.5)*2.0) < ditherRef) {
discard;
}
o_color = vec4(u_color.xyz,u_color.w*u_ditherAlpha);
}
#endif