//! bundle game
//! queue ui
//! zwrite off
//! ztest off
precision highp float;
#ifdef VERTEX
#define varying out
#else
#define varying in
#endif
uniform float u_fade;
uniform float u_ppp;
varying vec2 v_uv;
#ifdef VERTEX
uniform mat4 u_mvp;
in vec3 a_position;
in vec2 a_uv;
uniform vec4 u_uv_scale_offset;
void main() {
v_uv = a_uv;
if(u_uv_scale_offset.x>0.001){
v_uv = v_uv*u_uv_scale_offset.xy+u_uv_scale_offset.zw;
}
gl_Position = u_mvp * vec4( a_position, 1 );
}
#endif
#ifdef FRAGMENT
uniform sampler2D u_tex;
uniform vec2 u_player_pos;
uniform vec4 u_circle_line;
uniform vec3 u_cur_circle;
uniform vec3 u_closed_circle;
uniform int u_circle_closed;
out vec4 o_color;
void main() {
vec2 uv = v_uv;
uv.y = 1.0-uv.y;
o_color = texture(u_tex, uv);
if(u_cur_circle.z > 0.0) {
vec2 c = uv-u_cur_circle.xy;
if(u_circle_closed==0){
o_color = mix(o_color,vec4(1,0,0,1.0),float(length(c)>u_cur_circle.z)*0.25);
vec2 to_circle_center = uv-u_closed_circle.xy;
if(dot(to_circle_center,to_circle_center)>u_closed_circle.z*u_closed_circle.z){
vec2 pa = uv-u_player_pos;
vec2 ba = u_circle_line.xy;
float t = dot(pa,ba)/(u_circle_line.z*u_circle_line.z);
float len = u_circle_line.z;
t = clamp(t,0.0,1.0);
float tm = (1.0-t)*len*50.0;
float ti = floor(tm);
float tf = clamp(fract(tm),0.35,0.65);
t = 1.0-(tf+ti)*u_circle_line.w*0.02;
float ln = length(pa-t*ba);
float f = fwidth(length(uv));
if(ln<f*u_ppp*0.5){
o_color = vec4(1);
}
}
}else{
o_color *= vec4(vec3(mix(1.0,0.2,float(length(c)<u_cur_circle.z))),1.0);
}
vec2 cn = uv-u_closed_circle.xy;
float ln = length(cn)-u_closed_circle.z;
if(abs(ln)<fwidth(ln)*u_ppp*0.5){
o_color = vec4(1);
}
}
o_color.rgb *= u_fade;
}
#endif