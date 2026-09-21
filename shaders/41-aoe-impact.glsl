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
uniform vec3 u_cam_pos;
uniform sampler2D u_mainTex;
uniform float u_ditherAlpha;
uniform sampler2D u_ditherTex;
varying vec3 v_worldNormal;
varying vec3 v_worldPos;
#ifdef VERTEX
in vec3 a_position;
in vec3 a_normal;
in vec2 a_uv;
void main() {
vec4 vertexPos = vec4( a_position, 1 );
v_worldNormal = normalize((u_model * vec4( a_normal, 0 )).xyz);
v_worldPos = (u_model * vertexPos).xyz;
gl_Position = u_mvp * vertexPos;
}
#endif
#ifdef FRAGMENT
out vec4 o_color;
void main() {
float ditherRef = texelFetch(u_ditherTex, ivec2(mod(gl_FragCoord.xy, 8.0)), 0).r;
float x = -dot(normalize(v_worldPos - u_cam_pos), v_worldNormal);
float ditherAlpha = u_ditherAlpha * (1.0 - x) * step(0.0, x);
if (ditherAlpha < ditherRef) {
discard;
}
float gb = 0.5 * ditherAlpha;
o_color = vec4(vec3(1.0,gb,gb),ditherAlpha);
}
#endif