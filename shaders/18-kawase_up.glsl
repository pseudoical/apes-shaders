//! bundle game
precision highp float;
#ifdef VERTEX
#define varying out
#else
#define varying in
#endif
uniform sampler2D u_maintex;
uniform sampler2D u_curtex;
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
vec4 sum = texture(u_maintex,uv + vec2(-hp.x*2.,0.));
sum += texture(u_maintex, uv + vec2(-hp.x,hp.y))*2.;
sum += texture(u_maintex, uv + vec2(0.0,hp.y*2.0));
sum += texture(u_maintex, uv + hp)*2.;
sum += texture(u_maintex, uv + vec2(hp.x*2.0, 0.0));
sum += texture(u_maintex, uv + vec2(hp.x, -hp.y))*2.;
sum += texture(u_maintex, uv + vec2(0.0,-hp.y*2.0));
sum += texture(u_maintex, uv - hp)*2.;
o_color = mix(sum/12.0,texture(u_curtex,v_uv),0.25);
}
#endif