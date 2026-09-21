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
uniform sampler2D u_a_tex;
uniform int u_a_channel;
uniform int u_a_type;
uniform sampler2D u_b_tex;
uniform int u_b_channel;
uniform int u_b_type;
uniform sampler2D u_mix_tex;
uniform int u_mix_channel;
uniform int u_mix_type;
uniform int u_output_type;
uniform float u_bias;
void main(){
vec4 in_1 = texture(u_a_tex,v_uv);
in_1 = unpack_type(in_1,u_a_type,u_a_channel);
vec4 in_2 = texture(u_b_tex,v_uv);
in_2 = unpack_type(in_2,u_b_type,u_b_channel);
vec4 t = texture(u_mix_tex,v_uv);
t = unpack_type(t,u_mix_type,u_mix_channel);
vec4 ret = mix(in_1,in_2,pow(t,vec4(u_bias)));
o_color = pack_type(ret,u_output_type);
}
#endif