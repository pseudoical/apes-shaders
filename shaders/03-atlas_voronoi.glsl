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
float hash1( float n ) { return fract(sin(n)*43758.5453); }
vec3 hash(vec3 p) {
return fract(
sin(vec3(dot(p, vec3(1.0, 57.0, 113.0)), dot(p, vec3(57.0, 113.0, 1.0)),
dot(p, vec3(113.0, 1.0, 57.0)))) *
43758.5453);
}
uniform sampler2D u_x_tex;
uniform int u_x_channel;
uniform int u_x_type;
uniform sampler2D u_y_tex;
uniform int u_y_channel;
uniform int u_y_type;
uniform sampler2D u_z_tex;
uniform int u_z_channel;
uniform int u_z_type;
uniform sampler2D u_gx_tex;
uniform int u_gx_channel;
uniform int u_gx_type;
uniform sampler2D u_gy_tex;
uniform int u_gy_channel;
uniform int u_gy_type;
uniform sampler2D u_gz_tex;
uniform int u_gz_channel;
uniform int u_gz_type;
vec3 voronoi(vec3 x) {
vec4 in_x = texture(u_x_tex,v_uv);
in_x = unpack_type(in_x,u_x_type,u_x_channel);
vec4 in_y = texture(u_y_tex,v_uv);
in_y = unpack_type(in_y,u_y_type,u_y_channel);
vec4 in_z = texture(u_z_tex,v_uv);
in_z = unpack_type(in_z,u_z_type,u_z_channel);
vec4 in_gx = texture(u_gx_tex,v_uv);
in_gx = unpack_type(in_gx,u_gx_type,u_gx_channel);
vec4 in_gy = texture(u_gy_tex,v_uv);
in_gy = unpack_type(in_gy,u_gy_type,u_gy_channel);
vec4 in_gz = texture(u_gz_tex,v_uv);
in_gz = unpack_type(in_gz,u_gz_type,u_gz_channel);
vec3 size = vec3(in_gx.x,in_gy.y,in_gz.z);
x=fract(x+vec3(in_x.x,in_y.x,in_z.x));
x*=size;
vec3 p = floor(x);
vec3 f = fract(x);
float id = 0.0;
vec2 dist = vec2(1.0);
vec3 offset = vec3(0.0);
for (int k = -1; k <= 1; k++) {
for (int j = -1; j <= 1; j++) {
for (int i = -1; i <= 1; i++) {
vec3 b = vec3(float(i), float(j), float(k));
vec3 off = mod(p + b,size);
vec3 r = vec3(b) - f + hash(off);
float d = dot(r, r);
dist.y = max(dist.x,min(dist.y,d));
if( d<dist.x )
{
dist.x = d;
offset = b;
}
}
}
}
return vec3(sqrt(dist.x),hash1( dot(mod(p+offset,size),vec3(7.0,113.0,41.0) ) ),dist.y-dist.x);
}
const vec3 Tex2World[39] = vec3[39](vec3(1,0,0),vec3(0,1,0),vec3(0,0,1),vec3(-1,0,0),vec3(0,-0,1),vec3(0,1,0),vec3(1,0,0),vec3(0,1,-1),vec3(0,0,1),vec3(1,0,-0),vec3(-0,1,1),vec3(0,0,1),vec3(0,1,0),vec3(0,0,1),vec3(1,0,0),vec3(0,1,0),vec3(-1,0,1),vec3(1,0,0),vec3(-0,1,-0),vec3(1,-0,1),vec3(-1,-0,-0),vec3(0,0,1),vec3(1,-1,0),vec3(0,1,0),vec3(-1,1,0),vec3(-1,0,1),vec3(1,0,0),vec3(1,-1,0),vec3(1,0,1),vec3(-1,0,0),vec3(0,-0,1),vec3(1,1,-0),vec3(0,1,0),vec3(1,1,-0),vec3(-0,1,1),vec3(0,-1,0),vec3(-1,-1,0),vec3(0,-1,1),vec3(0,1,-0));
mat3 tex2World(int tile){
return mat3(Tex2World[tile*3],Tex2World[tile*3+1],Tex2World[tile*3+2]);
}
layout(location = 0) out vec4 o_color;
uniform vec3 u_granularity;
void main(){
ivec2 pix = ivec2(gl_FragCoord.xy);
const int ATLAS_PERIOD = 4;
int tile_width = 16*ATLAS_PERIOD;
int tile = pix.y/tile_width;
vec3 uvloc = vec3((float(pix.x%tile_width)+0.5)/float(16),(float(pix.y%tile_width)+0.5)/float(16),float(pix.x/tile_width%ATLAS_PERIOD));
vec3 loc = tex2World(tile)*uvloc;
loc = mod(loc,vec3(ATLAS_PERIOD))/vec3(ATLAS_PERIOD);
vec3 vor1 =voronoi(loc);
o_color = vec4(vor1,1.0);
}
#endif