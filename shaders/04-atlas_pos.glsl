//! bundle game editor
//! priority 3
precision highp float;
precision highp int;
#ifdef VERTEX
in vec3 a_position;
void main(){
gl_Position.xyz = a_position;
gl_Position.w = 1.0;
}
#endif
#ifdef FRAGMENT
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
o_color = vec4(mod(loc,float(tile_width))/float(tile_width),1.0);
}
#endif