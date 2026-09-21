//! bundle game editor
precision highp float;
precision highp int;
#ifdef VERTEX
out vec2 v_uv;
in vec3 a_position;
void main(){
gl_Position.xyz = a_position;
gl_Position.w = 1.0;
v_uv = (a_position.xy*0.5+0.5);
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
uniform sampler2D u_diff_tex;
uniform int u_diff_channel;
uniform int u_diff_type;
uniform sampler2D u_blend_tex;
uniform int u_blend_channel;
uniform int u_blend_type;
layout(location = 0) out vec4 data;
void main(){
vec4 diff = texture(u_diff_tex,v_uv);
diff = unpack_type(diff,u_diff_type,u_diff_channel);
vec4 blend = texture(u_blend_tex,v_uv);
blend = unpack_type(blend,u_blend_type,u_blend_channel);
data = vec4(diff.rgb,dot(blend.rgb,vec3(0.3333,0.3333,0.3334)));
}
#endif