
//! bundle game
//! queue shadow
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
uniform mat4 u_model;
uniform mat4 u_mvp;
uniform mat4 u_vp;
#ifdef VERTEX
in vec3 a_position;
void main() {
vec4 vertexPos = vec4( a_position, 1 );
apply_bone_transform_position_only( vertexPos );
gl_Position = u_mvp * vertexPos;
}
#endif
#ifdef FRAGMENT
void main() {}
#endif