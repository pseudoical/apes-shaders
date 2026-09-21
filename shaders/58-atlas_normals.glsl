//! bundle game editor
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
uniform sampler2D u_rough_tex;
uniform int u_rough_channel;
uniform int u_rough_type;
uniform sampler2D u_metal_tex;
uniform int u_metal_channel;
uniform int u_metal_type;
uniform sampler2D u_height_tex;
uniform int u_height_channel;
uniform int u_height_type;
in vec2 v_uv;
layout(location = 0) out vec4 data;
void main(){
int tile_width = 16*4;
vec2 total = vec2(16*4*4,16*4*13);
ivec2 pix = ivec2(v_uv*total);
mat3 dx = mat3(1,2,1,0,0,0,-1,-2,-1);
mat3 dy = transpose(dx);
vec2 grad = vec2(0.0);
vec4 rough = texture(u_rough_tex,v_uv);
rough = unpack_type(rough, u_rough_type,u_rough_channel);
data.x = dot(rough.rgb,vec3(0.3333,0.3333,0.3334));
vec4 mtl = texture(u_metal_tex,v_uv);
mtl = unpack_type(mtl,u_metal_type,u_metal_channel);
data.y = dot(mtl.rgb,vec3(0.3333,0.3333,0.3334));
for(int x=-1; x<2; x++){
for(int y=-1; y<2; y++){
ivec2 offset = ivec2(x,y);
ivec2 tile_loc = pix / tile_width * tile_width;
ivec2 sub_tile = (pix - tile_loc + offset+ tile_width)%tile_width;
vec2 sloc = (vec2(tile_loc+sub_tile)+0.5)/total;
vec4 h = texture(u_height_tex,sloc);
h = unpack_type(h,u_height_type,u_height_channel);
float height = dot(h.rgb,vec3(0.3333,0.3333,0.3334));
if(!(x==0 && y==0)){
grad += vec2(dx[x+1][y+1],dy[x+1][y+1])*height;
}
}
}
data.zw = clamp(grad,-vec2(1),vec2(1.0))*0.5+0.5;
}
#endif