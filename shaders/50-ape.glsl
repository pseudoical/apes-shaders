
//! bundle game
//! priority 0
precision highp float;
#ifdef VERTEX
#define varying out
#else
#define varying in
#endif
#define MAX_BONES 80

#ifdef DUAL_QUAT_SKINNING
uniform vec4 u_boneRotQuats[ MAX_BONES ];
uniform vec4 u_bonePosQuats[ MAX_BONES ];
#else
uniform mat4 u_boneMatrices[ MAX_BONES ];
#endif
#ifdef VERTEX
in vec4 a_boneWeights;
in uvec4 a_boneIndices;
#ifdef DUAL_QUAT_SKINNING
void apply_bone_transform(inout vec4 position, inout vec3 normal, inout vec3 tangent) {
vec4 rotQuat0 = u_boneRotQuats[ a_boneIndices.x ];
vec4 rotQuat1 = u_boneRotQuats[ a_boneIndices.y ];
vec4 rotQuat2 = u_boneRotQuats[ a_boneIndices.z ];
vec4 rotQuat3 = u_boneRotQuats[ a_boneIndices.w ];
vec4 posQuat0 = u_bonePosQuats[ a_boneIndices.x ];
vec4 posQuat1 = u_bonePosQuats[ a_boneIndices.y ];
vec4 posQuat2 = u_bonePosQuats[ a_boneIndices.z ];
vec4 posQuat3 = u_bonePosQuats[ a_boneIndices.w ];
if (dot(rotQuat0, rotQuat1) < 0.0) { rotQuat1 = -rotQuat1; posQuat1 = -posQuat1; }
if (dot(rotQuat0, rotQuat2) < 0.0) { rotQuat2 = -rotQuat2; posQuat2 = -posQuat2; }
if (dot(rotQuat0, rotQuat3) < 0.0) { rotQuat3 = -rotQuat3; posQuat3 = -posQuat3; }
vec4 rotQuat = rotQuat0*a_boneWeights.x + rotQuat1*a_boneWeights.y
+ rotQuat2*a_boneWeights.z + rotQuat3*a_boneWeights.w;
vec4 posQuat = posQuat0*a_boneWeights.x + posQuat1*a_boneWeights.y
+ posQuat2*a_boneWeights.z + posQuat3*a_boneWeights.w;
float len = length(rotQuat);
rotQuat /= len;
posQuat /= len;
position.xyz += 2.0 * (
cross( rotQuat.xyz, cross( rotQuat.xyz, position.xyz ) + rotQuat.w*position.xyz )
+ rotQuat.w*posQuat.xyz - posQuat.w*rotQuat.xyz + cross( rotQuat.xyz, posQuat.xyz )
);
normal += 2.0 * cross( rotQuat.xyz, cross( rotQuat.xyz, normal ) + rotQuat.w*normal );
tangent += 2.0 * cross( rotQuat.xyz, cross( rotQuat.xyz, tangent ) + rotQuat.w*tangent );
}
void apply_bone_transform_position_only(inout vec4 position) {
vec4 rotQuat0 = u_boneRotQuats[ a_boneIndices.x ];
vec4 rotQuat1 = u_boneRotQuats[ a_boneIndices.y ];
vec4 rotQuat2 = u_boneRotQuats[ a_boneIndices.z ];
vec4 rotQuat3 = u_boneRotQuats[ a_boneIndices.w ];
vec4 posQuat0 = u_bonePosQuats[ a_boneIndices.x ];
vec4 posQuat1 = u_bonePosQuats[ a_boneIndices.y ];
vec4 posQuat2 = u_bonePosQuats[ a_boneIndices.z ];
vec4 posQuat3 = u_bonePosQuats[ a_boneIndices.w ];
if (dot(rotQuat0, rotQuat1) < 0.0) { rotQuat1 = -rotQuat1; posQuat1 = -posQuat1; }
if (dot(rotQuat0, rotQuat2) < 0.0) { rotQuat2 = -rotQuat2; posQuat2 = -posQuat2; }
if (dot(rotQuat0, rotQuat3) < 0.0) { rotQuat3 = -rotQuat3; posQuat3 = -posQuat3; }
vec4 rotQuat = rotQuat0*a_boneWeights.x + rotQuat1*a_boneWeights.y
+ rotQuat2*a_boneWeights.z + rotQuat3*a_boneWeights.w;
vec4 posQuat = posQuat0*a_boneWeights.x + posQuat1*a_boneWeights.y
+ posQuat2*a_boneWeights.z + posQuat3*a_boneWeights.w;
float len = length(rotQuat);
rotQuat /= len;
posQuat /= len;
position.xyz += 2.0 * (
cross( rotQuat.xyz, cross( rotQuat.xyz, position.xyz ) + rotQuat.w*position.xyz )
+ rotQuat.w*posQuat.xyz - posQuat.w*rotQuat.xyz + cross( rotQuat.xyz, posQuat.xyz )
);
}
#else
void apply_bone_transform(inout vec4 position, inout vec3 normal, inout vec3 tangent) {
mat4 boneMatrix =
u_boneMatrices[ a_boneIndices.x ] * a_boneWeights.x +
u_boneMatrices[ a_boneIndices.y ] * a_boneWeights.y +
u_boneMatrices[ a_boneIndices.z ] * a_boneWeights.z +
u_boneMatrices[ a_boneIndices.w ] * a_boneWeights.w;
position = boneMatrix * position;
normal = (boneMatrix * vec4( normal, 0 )).xyz;
tangent = (boneMatrix * vec4( tangent, 0 )).xyz;
}
void apply_bone_transform_position_only(inout vec4 position) {
mat4 boneMatrix =
u_boneMatrices[ a_boneIndices.x ] * a_boneWeights.x +
u_boneMatrices[ a_boneIndices.y ] * a_boneWeights.y +
u_boneMatrices[ a_boneIndices.z ] * a_boneWeights.z +
u_boneMatrices[ a_boneIndices.w ] * a_boneWeights.w;
position = boneMatrix * position;
}
#endif
#endif
uniform float u_fade;
uniform float u_flash;
uniform float u_chill;
uniform vec3 u_chill_tint;
uniform mat4 u_model;
uniform mat4 u_mvp;
uniform sampler2D u_mainTex;
uniform vec3 u_cam_pos;
uniform sampler2D u_dataTex;
varying vec2 v_uv;
varying vec3 v_worldPos;
#ifdef VERTEX
in vec3 a_normal;
in vec4 a_tangent;
#endif
varying vec3 v_normal;
varying vec4 v_tangent;
uniform sampler2D u_normalTex;
vec3 get_normal(vec2 uv){
vec3 norm = texture(u_normalTex, uv).rgb*2.0-1.0;
vec3 bitangent = cross(v_normal,v_tangent.xyz)*v_tangent.w;
mat3 TBN = mat3(normalize(v_tangent.xyz),normalize(bitangent),normalize(v_normal));
return TBN*norm;
}
#ifdef FRAGMENT
layout(location = 0) out vec4 o_color;
layout(location = 1) out vec4 o_normal;
float signNotZero(in float k) {
return (k >= 0.0) ? 1.0 : -1.0;
}
vec2 signNotZero(in vec2 v) {
return vec2(signNotZero(v.x), signNotZero(v.y));
}
vec2 octEncode(in vec3 v) {
float l1norm = abs(v.x) + abs(v.y) + abs(v.z);
vec2 result = v.xy * (1.0 / l1norm);
if (v.z < 0.0) {
result = (1.0 - abs(result.yx)) * signNotZero(result.xy);
}
return result * 0.5+0.5;
}
void write_gbuffer(vec3 color, vec3 normal, vec4 data){
uvec2 data_int = uvec2((uint(data.r*15.0)&15u) | (uint(data.g*7.0)&7u)<<4, (uint(data.b *7.0)&7u) | (uint(data.a *15.0) & 15u) << 4);
vec2 pack = vec2(data_int)/255.0;
o_color = vec4(color,pack.x);
vec2 encoded_normal = octEncode(normal);
o_normal = vec4(encoded_normal,0.0,pack.y);
}
void write_gbuffer_ground(vec3 color, vec3 normal, vec4 data, int lod){
uvec2 data_int = uvec2((uint(data.r*15.0)&15u) | (uint(data.g*7.0)&7u)<<4 | 1u<<7, (uint(data.b *7.0)&7u) | (uint(data.a *15.0) & 15u) << 4);
vec2 pack = vec2(data_int)/255.0;
o_color = vec4(color,pack.x);
vec2 encoded_normal = octEncode(normal);
o_normal = vec4(encoded_normal,float(lod)/255.0,pack.y);
}
void write_gbuffer_ape(vec3 color, vec3 normal, vec4 data){
uvec2 data_int = uvec2((uint(data.r*15.0)&15u) | (uint(data.g*7.0)&7u)<<4, (uint(data.b *7.0)&7u) | 1u<<3 | (uint(data.a *15.0) & 15u) << 4);
vec2 pack = vec2(data_int)/255.0;
o_color = vec4(color,pack.x);
vec2 encoded_normal = octEncode(normal);
o_normal = vec4(encoded_normal,0.0,pack.y);
}
#endif
#ifdef VERTEX
in vec3 a_position;
in vec2 a_uv;
void main() {
v_uv = a_uv;
vec4 vertexPos = vec4( a_position, 1 );
v_normal = normalize(a_normal);
vec3 tangent = a_tangent.xyz;
apply_bone_transform(vertexPos, v_normal, tangent);
vec4 worldPos4 = u_model * vertexPos;
v_worldPos = worldPos4.xyz / worldPos4.w;
v_normal = normalize(( u_model * vec4( v_normal, 0 )).xyz);
tangent = normalize(( u_model * vec4( tangent, 0 )).xyz);
v_tangent = vec4( tangent, a_tangent.w );
gl_Position = u_mvp * vertexPos;
}
#endif
#ifdef FRAGMENT
void main() {
vec3 color = texture(u_mainTex, vec2(v_uv.x,1.-v_uv.y)).rgb;
vec4 data = texture(u_dataTex, vec2(v_uv.x,1.-v_uv.y));
color = mix(color, u_chill_tint * (0.3 + 1.4 * dot(color, vec3(0.299, 0.587, 0.114))), u_chill);
color += u_flash;
data.b += u_flash;
vec2 pack = floor(data.rb*255.0/16.0)/255.0+floor(data.ga*255.0/16.0)/255.0*16.0;
vec3 normal = get_normal(vec2(v_uv.x,1.-v_uv.y));
write_gbuffer(color,normal,data);
}
#endif