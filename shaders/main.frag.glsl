#extension GL_EXT_shader_texture_lod : enable
#extension GL_OES_standard_derivatives : enable
precision highp float;

uniform float time;
uniform vec2 resolution;

uniform vec3 eye;
uniform mat3 view;

#pragma glslify: tryImage = require('./image.frag.glsl', res=resolution, time=time, view=view, eye=eye);

void main() {
  tryImage(gl_FragColor, gl_FragCoord.xy);
}
