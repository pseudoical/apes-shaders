//! bundle game editor
//! priority 3
precision highp float;
precision highp int;
#ifdef VERTEX
in vec3 a_position;
out vec2 v_uv;
void main(){
gl_Position.xyz = a_position;
v_uv = (a_position.xy*0.5+0.5);
gl_Position.w = 1.0;
}
#endif
#ifdef FRAGMENT
vec4 unpack_type(vec4 value, int vtype, int channel){
switch(vtype){
case 1:
return vec4(value[channel]);
case 2:
uvec4 bytes = uvec4(value*255.0);
float i = float(int(bytes.b | bytes.a<<8) - 32767);
float f = float(bytes.r | bytes.g<<8)/65536.0;
return vec4(i+f);
}
return value;
}
vec4 pack_type(vec4 value, int vtype){
switch(vtype){
case 2:
uint f = uint(fract(value.r)*65536.0);
uint i = uint(int(floor(value.r))+32767);
return vec4(uvec4(f,f>>8,i,i>>8)&255u)/255.0;
}
return value;
}
in vec2 v_uv;
layout(location = 0) out vec4 o_color;
uniform sampler2D u_t_tex;
uniform int u_t_channel;
uniform int u_t_type;
uniform sampler2D u_grad_tex;
uniform vec4 u_domain_range;
uniform int u_output_type;
void main(){
vec4 t = texture(u_t_tex,v_uv);
t = unpack_type(t,u_t_type,u_t_channel);
t = (t-u_domain_range.y)*u_domain_range.x;
vec4 col = vec4(texture(u_grad_tex,vec2(t.r,0.5)).r,texture(u_grad_tex,vec2(t.g,0.5)).g,texture(u_grad_tex,vec2(t.b,0.5)).b,texture(u_grad_tex,vec2(t.a,0.5)).a);
vec2 range = u_domain_range.zw;
col = col*range.x+range.y;
o_color = pack_type(col, u_output_type);
}
#endif