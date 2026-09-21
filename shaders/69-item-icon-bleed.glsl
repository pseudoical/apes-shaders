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
uniform int u_radius;
out vec4 o_color;
void main() {
ivec2 at=ivec2(gl_FragCoord.xy);
ivec2 size=textureSize(u_tex,0);
vec4 here=texelFetch(u_tex,at,0);
if(here.a>0.5){
o_color=here;
return;
}
int radius=clamp(u_radius,0,8);
int nearest=9;
for(int dy=-8;dy<=8;dy++){
for(int dx=-8;dx<=8;dx++){
int d=max(abs(dx),abs(dy));
if(d==0 || d>radius || d>=nearest) continue;
ivec2 p=at+ivec2(dx,dy);
if(p.x<0 || p.y<0 || p.x>=size.x || p.y>=size.y) continue;
if(texelFetch(u_tex,p,0).a>0.5) nearest=d;
}
}
if(nearest>radius){
o_color=vec4(0.0);
return;
}
vec3 sum=vec3(0.0);
float count=0.0;
for(int dy=-8;dy<=8;dy++){
for(int dx=-8;dx<=8;dx++){
if(max(abs(dx),abs(dy))!=nearest) continue;
ivec2 p=at+ivec2(dx,dy);
if(p.x<0 || p.y<0 || p.x>=size.x || p.y>=size.y) continue;
vec4 c=texelFetch(u_tex,p,0);
if(c.a<0.5) continue;
sum+=c.rgb;
count+=1.0;
}
}
o_color=vec4(sum/max(count,1.0),0.0);
}
#endif