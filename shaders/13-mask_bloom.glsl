//! bundle game
precision highp float;
#ifdef VERTEX
#define varying out
#else
#define varying in
#endif
uniform sampler2D u_depthtex;
uniform sampler2D u_particles_tex;
uniform sampler2D u_particles_depth_tex;
#ifdef VERTEX
in vec3 a_position;
void main() {
vec4 vertexPos = vec4( a_position.xy,0, 1 );
gl_Position = vertexPos;
}
#endif
#ifdef FRAGMENT
out vec4 o_color;
uniform int u_particle_downscale_shift;
void main() {
vec4 particle_color = texelFetch(u_particles_tex,ivec2(gl_FragCoord.xy),0);
float depth = texelFetch(u_depthtex, ivec2(gl_FragCoord.xy)<<u_particle_downscale_shift,0).r;
float particle_depth = texelFetch(u_particles_depth_tex, ivec2(gl_FragCoord.xy),0).r;
if(particle_depth>depth+(0.1*(1.0-depth)) && particle_color.a!=0.0){
particle_color = vec4(0.0,0.0,0.0,1.0);
}
o_color = vec4(particle_color.rgb*particle_color.a,particle_color.a);
}
#endif