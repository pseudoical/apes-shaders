//! bundle game editor
precision highp float;
precision highp int;
#ifdef VERTEX
layout(location = 0) in vec3 vpos;
out vec2 v_uv;
uniform vec4 u_uv_scale_offset;
void main(){
gl_Position.xyz = vpos;
gl_Position.w = 1.0;
v_uv = (vpos.xy*0.5+0.5)*u_uv_scale_offset.xy+u_uv_scale_offset.zw;
}
#endif
#ifdef FRAGMENT
layout(location = 0) out vec4 o_color;
in vec2 v_uv;
uniform sampler2D u_Tex;
void main(){
o_color = texture(u_Tex,v_uv);
}
#endif