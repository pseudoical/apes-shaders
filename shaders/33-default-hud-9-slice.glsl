//! bundle game
//! queue ui
//! zwrite off
//! ztest off
precision highp float;
uniform float u_fade;
uniform vec4 u_color;
uniform vec4 u_slice;
uniform vec2 u_pixel_size_inv;
#ifdef VERTEX
out vec2 v_uv;
uniform mat4 u_mvp;
in vec2 a_uv;
in vec3 a_position;
void main() {
v_uv = a_uv;
gl_Position = u_mvp * vec4( a_position, 1 );
}
#endif
#ifdef FRAGMENT
uniform sampler2D u_tex;
out vec4 o_color;
in vec2 v_uv;
void main() {
vec2 slice = u_slice.xy;
vec2 stretch = vec2(1)-u_slice.xy;
vec2 edge = u_slice.zw*u_pixel_size_inv;
vec2 base = vec2(1)-edge;
vec2 coord = v_uv*2.0-1.0;
vec2 s = sign(coord);
vec2 q = abs(coord);
vec2 e = clamp(q-base,vec2(0.0),edge);
vec2 b = clamp(q, vec2(0.0),base);
vec2 base_term = mix(vec2(1), b/base, greaterThan(base, vec2(.0001)));
vec2 uv_quad = base_term*stretch+e/edge*slice;
vec2 uv = uv_quad*s*0.5+0.5;
o_color = texture(u_tex, uv)*u_color;
o_color.rgb *= u_fade;
}
#endif