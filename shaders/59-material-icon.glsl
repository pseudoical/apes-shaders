//! bundle game
//! queue ui
//! zwrite off
//! ztest off
#ifdef VERTEX
#define varying out
#else
#define varying in
#endif
precision highp float;
varying vec2 v_uv;
#ifdef VERTEX
uniform mat4 u_mvp;
in vec3 a_position;
in vec2 a_uv;
void main() {
v_uv = a_uv;
gl_Position = u_mvp * vec4(a_position, 1.0);
}
#endif
#ifdef FRAGMENT
out vec4 o_color;
uniform mat4 u_color;
uniform int u_material_code;
uniform sampler2D u_atlas;
uniform sampler2D u_variant_codes;
uniform sampler2D u_variants;
const float ISO = 0.8660254;
uint baseMaterialCode(uint code) {
vec4 codes = texelFetch(u_variant_codes, ivec2(int(code >> 2u), 0), 0);
return uint(floor(codes[int(code & 3u)] * 255.0 + 0.5));
}
void applyMaterialVariant(uint code, inout vec4 color) {
color *= texelFetch(u_variants, ivec2(0, int(code)), 0);
color += texelFetch(u_variants, ivec2(1, int(code)), 0);
}
vec4 faceColor(int tile, vec2 st) {
uint code = uint(max(u_material_code, 0));
uint base_code = baseMaterialCode(code);
ivec2 atlas_size = textureSize(u_atlas, 0);
ivec2 material_size = atlas_size / ivec2(16, 4);
ivec2 material_origin = ivec2(int(base_code % 16u), int(base_code / 16u)) * material_size;
vec2 texel = vec2(material_origin)
+ vec2(0.5 + st.x * 63.0, float(tile) * 64.0 + 0.5 + st.y * 63.0);
vec4 color = texture(u_atlas, texel / vec2(atlas_size));
applyMaterialVariant(code, color);
return color;
}
void main() {
vec2 p = vec2(v_uv.x - 0.5, 0.5 - v_uv.y) * 2.12;
float sum = 2.0 * (1.0 - p.y);
float diff = p.x / ISO;
vec2 top = vec2((sum - diff) * 0.5, (sum + diff) * 0.5);
float sl = -p.x / ISO;
float tl = 0.5 * sl - p.y;
float sr = p.x / ISO;
float tr = 0.5 * sr - p.y;
vec4 color;
float shade;
if (top.x >= 0.0 && top.x <= 1.0 && top.y >= 0.0 && top.y <= 1.0) {
color = faceColor(0, top);
shade = 1.0;
} else if (sl >= 0.0 && sl <= 1.0 && tl >= 0.0 && tl <= 1.0) {
color = faceColor(1, vec2(sl, tl));
shade = 0.78;
} else if (sr >= 0.0 && sr <= 1.0 && tr >= 0.0 && tr <= 1.0) {
color = faceColor(4, vec2(sr, tr));
shade = 0.6;
} else {
discard;
}
o_color = u_color * vec4(color.rgb * shade * 1.12, 1.0);
}
#endif