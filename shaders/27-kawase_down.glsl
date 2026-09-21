//! bundle game
precision highp float;
#ifdef VERTEX
#define varying out
#else
#define varying in
#endif
uniform sampler2D u_maintex;
uniform vec2 u_texelsize;
varying vec2 v_uv;
#ifdef VERTEX
in vec3 a_position;
void main() {
vec4 vertexPos = vec4( a_position.xy,0, 1 );
v_uv = vertexPos.xy*0.5+0.5;
gl_Position = vertexPos;
}
#endif
#ifdef FRAGMENT
out vec4 o_color;
void main() {
vec2 hp = u_texelsize*0.5;
vec2 uv = v_uv;
vec4 sum = texture(u_maintex,uv)*4.0;
sum += texture(u_maintex, uv - hp);
sum += texture(u_maintex, uv + hp);
sum += texture(u_maintex, uv + vec2(hp.x, -hp.y));
sum += texture(u_maintex, uv - vec2(hp.x, -hp.y));
o_color = sum/8.0;
}
#endif