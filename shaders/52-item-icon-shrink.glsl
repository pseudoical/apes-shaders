//! bundle game
//! queue ui
//! blend one zero
//! ztest off
//! zwrite off
//! cull off
precision highp float;
#ifdef VERTEX
uniform mat4 u_model;
in vec3 a_position;
void main() {
gl_Position=vec4((u_model*vec4(a_position.xy,1.0,0.0)).xy,0.0,1.0);
}
#endif
#ifdef FRAGMENT
uniform sampler2D u_tex;
uniform int u_factor;
uniform float u_coverage;
out vec4 o_color;
void main() {
int f=clamp(u_factor,1,8);
ivec2 origin=ivec2(gl_FragCoord.xy)*f;
int count=0;
vec3 sum=vec3(0.0);
for(int y=0;y<8;y++){
if(y>=f) break;
for(int x=0;x<8;x++){
if(x>=f) break;
vec4 sample_color=texelFetch(u_tex,origin+ivec2(x,y),0);
if(sample_color.a<0.5) continue;
count++;
sum+=sample_color.rgb;
}
}
float need=max(1.0,float(f*f)*u_coverage);
if(count==0 || float(count)<need){
o_color=vec4(0.0);
} else {
o_color=vec4(sum/float(count),1.0);
}
}
#endif