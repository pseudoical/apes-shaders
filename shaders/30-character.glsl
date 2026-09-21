
//! bundle game
//! queue character-overlay
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
uniform mat4 u_model;
uniform mat4 u_mvp;
uniform sampler2D u_mainTex;
uniform sampler2D u_dataTex;
uniform float u_ditherAlpha;
uniform sampler2D u_ditherTex;
varying vec2 v_uv;
varying vec3 v_worldPos;
uniform samplerCube u_hdr_light;
uniform vec3 u_cam_pos;
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
layout(location = 0) out vec4 o_color;
uniform highp sampler3D u_lut;
float signNotZero(in float k) {
return (k >= 0.0) ? 1.0 : -1.0;
}
vec2 signNotZero(in vec2 v) {
return vec2(signNotZero(v.x), signNotZero(v.y));
}
vec3 octDecode(vec2 o) {
o = o*2.0-1.0;
vec3 v = vec3(o.x, o.y, 1.0 - abs(o.x) - abs(o.y));
if (v.z < 0.0) {
v.xy = (1.0 - abs(v.yx)) * signNotZero(v.xy);
}
return normalize(v);
}
const vec4 dielectric_spec  = vec4(0.220916301, 0.220916301, 0.220916301, 1.0 - 0.220916301);
float OneMinusReflectivityFromMetallic(float metallic)
{
float oneMinusDielectricSpec = dielectric_spec.a;
return oneMinusDielectricSpec - metallic * oneMinusDielectricSpec;
}
vec3 DiffuseAndSpecularFromMetallic (vec3 albedo, float metallic, out vec3 specColor, out float oneMinusReflectivity)
{
specColor = mix (dielectric_spec.rgb, albedo, metallic);
oneMinusReflectivity = OneMinusReflectivityFromMetallic(metallic);
return albedo * oneMinusReflectivity;
}
float saturate(float val){
return clamp(val,0.0,1.0);
}
float Pow4 (float x)
{
return x*x*x*x;
}
vec3 FresnelLerpFast (vec3 F0, vec3 F90, float cosA)
{
float t = Pow4 (1.0 - cosA);
return mix (F0, F90, t);
}
vec3 brdf(vec3 diffColor, vec3 specColor, float oneMinusReflectivity, float perceptualRoughness, vec3 normal, vec3 viewDir, vec3 ambient, vec3 spec, vec3 lightcol, vec3 lightdir){
vec3 halfDir = normalize(vec3(lightdir) + viewDir);
float nl = saturate(dot(normal, lightdir)+0.1);
float nh = saturate(dot(normal, halfDir));
float nv = abs(dot(normal, viewDir));
float lh = saturate(dot(lightdir, halfDir));
float smoothness = 1.0-perceptualRoughness;
float roughness = perceptualRoughness;
float a = roughness;
float a2 = a*a;
float d = nh * nh * (a2 - 1.0) + 1.00001;
float specularTerm = a2 / (max(0.1f, lh*lh) * (roughness + 0.5f) * (d * d) * 4.0);
float surfaceReduction = (0.6-0.08*perceptualRoughness);
surfaceReduction = 1.0 - roughness*perceptualRoughness*surfaceReduction;
float grazingTerm = saturate(smoothness + (1.0-oneMinusReflectivity));
vec3 color =   (diffColor + specularTerm * specColor) * lightcol * nl
+diffColor*ambient
+surfaceReduction * spec * FresnelLerpFast (specColor, vec3(grazingTerm), nv);
return color;
}
vec3 Tonemap_Aces(vec3 color) {
const float slope = 12.0f;
vec4 x = vec4(
color.r, color.g, color.b,
(color.r * 0.299) + (color.g * 0.587) + (color.b * 0.114)
);
const float a = 2.51f;
const float b = 0.03f;
const float c = 2.43f;
const float d = 0.59f;
const float e = 0.14f;
vec4 tonemap = clamp((x * (a * x + b)) / (x * (c * x + d) + e), 0.0, 1.0);
float t = x.a;
t = t * t / (slope + t);
return mix(tonemap.rgb, tonemap.aaa, t);
}
void main() {
float ditherRef = texelFetch(u_ditherTex, ivec2(mod(gl_FragCoord.xy, 8.0)), 0).r;
vec4 color = texture(u_mainTex, vec2(v_uv.x,1.-v_uv.y)).rgba;
float alpha = u_ditherAlpha * color.a;
if (alpha < ditherRef) {
discard;
}
vec4 data = texture(u_dataTex, vec2(v_uv.x,1.-v_uv.y));
vec3 normal = -normalize(get_normal(vec2(v_uv.x,1.-v_uv.y)));
vec3 specular;
float oneMinusReflectivity;
vec3 diffuse = DiffuseAndSpecularFromMetallic(color.rgb, data.g, specular,  oneMinusReflectivity);
vec3 view_dir = normalize(v_worldPos.xyz-u_cam_pos);
vec3 refl = 2.0*dot(view_dir,normal)*normal-view_dir;
vec3 lightcol = vec3(255,255,255)*1.0/255.0;
vec3 lightdir = -normalize(vec3(0,1,1));
const vec3 to_sun = vec3(255,180,255)*1.0/255.0;
const vec3 away_sun = vec3(0,0,0)*1.0/255.0;
vec3 ambient = mix(away_sun,to_sun,dot(normalize(vec3(0,1,1)),normal)*0.1+0.5);
vec3 spec = mix(away_sun,to_sun,dot(normalize(vec3(0,1,1)),refl)*0.1+0.5);
vec3 col = brdf(diffuse,specular,oneMinusReflectivity, data.r, normal,view_dir,
ambient*data.a,
spec*data.a
, lightcol, lightdir
)+color.rgb*data.b;
o_color = vec4(texture(u_lut,mix(vec3(0.5/32.0), vec3(31.5/32.0), clamp(Tonemap_Aces(col.rgb),0.0,1.0))).rgb,1.0);
}
#endif