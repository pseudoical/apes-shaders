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
vec4 permute(vec4 i) {
vec4 im = mod(i, 289.0);
return mod(((im*34.0)+10.0)*im, 289.0);
}
float psrdnoise(vec3 x, vec3 period, out vec3 gradient)
{
const mat3 M = mat3(0.0,1.0,1.0, 1.0,0.0,1.0, 1.0,1.0,0.0);
const mat3 Mi = mat3(-0.5,0.5,0.5, 0.5,-0.5,0.5, 0.5,0.5,-0.5);
vec3 uvw = M*x;
vec3 i0 = floor(uvw); vec3 f0 = fract(uvw);
vec3 g_ = step(f0.xyx, f0.yzz); vec3 l_ = 1.0 - g_;
vec3 g = vec3(l_.z, g_.xy); vec3 l = vec3(l_.xy, g_.z);
vec3 o1 = min(g, l); vec3 o2 = max(g, l);
vec3 i1 = i0 + o1, i2 = i0 + o2, i3 = i0 + 1.0;
vec3 v0 = Mi*i0, v1 = Mi*i1, v2 = Mi*i2, v3 = Mi*i3;
vec3 x0 = x - v0, x1 = x - v1, x2 = x - v2, x3 = x - v3;
if(any(greaterThan(period, vec3(0.0)))) {
vec4 vx = vec4(v0.x, v1.x, v2.x, v3.x);
vec4 vy = vec4(v0.y, v1.y, v2.y, v3.y);
vec4 vz = vec4(v0.z, v1.z, v2.z, v3.z);
if(period.x > 0.0) vx = mod(vx, period.x);
if(period.y > 0.0) vy = mod(vy, period.y);
if(period.z > 0.0) vz = mod(vz, period.z);
i0 = floor(M * vec3(vx.x, vy.x, vz.x) + 0.5);
i1 = floor(M * vec3(vx.y, vy.y, vz.y) + 0.5);
i2 = floor(M * vec3(vx.z, vy.z, vz.z) + 0.5);
i3 = floor(M * vec3(vx.w, vy.w, vz.w) + 0.5);
}
vec4 hash = permute( permute( permute(
vec4(i0.z, i1.z, i2.z, i3.z ))
+ vec4(i0.y, i1.y, i2.y, i3.y ))
+ vec4(i0.x, i1.x, i2.x, i3.x ));
vec4 theta = hash*3.883222077;
vec4 sz = 0.996539792 - 0.006920415*hash;
vec4 psi = hash*0.108705628;
vec4 Ct = cos(theta); vec4 St = sin(theta);
vec4 sz_prime = sqrt(1.0 - sz*sz);
vec4 gx, gy, gz;
gx = Ct * sz_prime; gy = St * sz_prime; gz = sz;
vec3 g0 = vec3(gx.x, gy.x, gz.x), g1 = vec3(gx.y, gy.y, gz.y);
vec3 g2 = vec3(gx.z, gy.z, gz.z), g3 = vec3(gx.w, gy.w, gz.w);
vec4 w = 0.5-vec4(dot(x0,x0), dot(x1,x1), dot(x2,x2), dot(x3,x3));
w = max(w, 0.0); vec4 w2 = w*w; vec4 w3 = w2*w;
vec4 gdotx = vec4(dot(g0,x0), dot(g1,x1), dot(g2,x2), dot(g3,x3));
float n = dot(w3, gdotx);
vec4 dw = -6.0*w2*gdotx;
vec3 dn0 = w3.x*g0 + dw.x*x0; vec3 dn1 = w3.y*g1 + dw.y*x1;
vec3 dn2 = w3.z*g2 + dw.z*x2; vec3 dn3 = w3.w*g3 + dw.w*x3;
gradient = 39.5 * (dn0 + dn1 + dn2 + dn3);
return 39.5*n;
}
const vec3 Tex2World[39] = vec3[39](vec3(1,0,0),vec3(0,1,0),vec3(0,0,1),vec3(-1,0,0),vec3(0,-0,1),vec3(0,1,0),vec3(1,0,0),vec3(0,1,-1),vec3(0,0,1),vec3(1,0,-0),vec3(-0,1,1),vec3(0,0,1),vec3(0,1,0),vec3(0,0,1),vec3(1,0,0),vec3(0,1,0),vec3(-1,0,1),vec3(1,0,0),vec3(-0,1,-0),vec3(1,-0,1),vec3(-1,-0,-0),vec3(0,0,1),vec3(1,-1,0),vec3(0,1,0),vec3(-1,1,0),vec3(-1,0,1),vec3(1,0,0),vec3(1,-1,0),vec3(1,0,1),vec3(-1,0,0),vec3(0,-0,1),vec3(1,1,-0),vec3(0,1,0),vec3(1,1,-0),vec3(-0,1,1),vec3(0,-1,0),vec3(-1,-1,0),vec3(0,-1,1),vec3(0,1,-0));
mat3 tex2World(int tile){
return mat3(Tex2World[tile*3],Tex2World[tile*3+1],Tex2World[tile*3+2]);
}
layout(location = 0) out vec4 o_color;
void main(){
ivec2 pix = ivec2(gl_FragCoord.xy);
const int ATLAS_PERIOD = 4;
int tile_width = 16*ATLAS_PERIOD;
int tile = pix.y/tile_width;
vec3 uvloc = vec3(float(pix.x%tile_width),float(pix.y%tile_width),float(pix.x/tile_width%ATLAS_PERIOD)*16.0)+0.5;
vec3 loc = tex2World(tile)*uvloc;
vec3 pos = mod(loc,float(tile_width))/float(tile_width);
vec3 grad;
vec4 in_x = texture(u_x_tex,v_uv);
in_x = unpack_type(in_x,u_x_type,u_x_channel);
vec4 in_y = texture(u_y_tex,v_uv);
in_y = unpack_type(in_y,u_y_type,u_y_channel);
vec4 in_z = texture(u_z_tex,v_uv);
in_z = unpack_type(in_z,u_z_type,u_z_channel);
pos=fract(pos+vec3(in_x.x,in_y.x,in_z.x));
vec4 in_gx = texture(u_gx_tex,v_uv);
in_gx = unpack_type(in_gx,u_gx_type,u_gx_channel);
vec4 in_gy = texture(u_gy_tex,v_uv);
in_gy = unpack_type(in_gy,u_gy_type,u_gy_channel);
vec4 in_gz = texture(u_gz_tex,v_uv);
in_gz = unpack_type(in_gz,u_gz_type,u_gz_channel);
vec3 size = vec3(in_gx.x,in_gy.y,in_gz.z);
float n =psrdnoise(pos*size,size,grad);
uint f = uint(fract(n)*65536.0);
uint i = uint(int(floor(n))+32767);
o_color = vec4(uvec4(f,f>>8,i,i>>8)&255u)/255.0;
}
#endif