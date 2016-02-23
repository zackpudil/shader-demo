#extension GL_EXT_shader_texture_lod : enable
#extension GL_OES_standard_derivatives : enable

precision highp float;

uniform float time;
uniform vec2 resolution;
uniform vec2 mouse;

uniform sampler2D noise;
uniform sampler2D terrain;

uniform sampler2D clouds;

uniform int currentDemo;

#pragma glslify: demoImage = require('./demo.frag.glsl', iGlobalTime=time, iResolution=resolution, iMouse=mouse);
#pragma glslify: seaImage = require('./sea.frag.glsl', iGlobalTime=time, iResolution=resolution, iMouse=mouse);
#pragma glslify: terrainImage = require('./terrain.frag.glsl', iGlobalTime=time, iResolution=resolution, iMouse=mouse, iChannel0=noise, iChannel2=terrain);
#pragma glslify: cloudImage = require('./clouds.frag.glsl', iGlobalTime=time, iResolution=resolution, iMouse=mouse, iChannel0=clouds);

void main() {
  if(currentDemo == 0)
    demoImage(gl_FragColor, gl_FragCoord.xy);
  else if(currentDemo == 1)
    seaImage(gl_FragColor, gl_FragCoord.xy);
  else if(currentDemo == 2)
    terrainImage(gl_FragColor, gl_FragCoord.xy);
  else
    cloudImage(gl_FragColor, gl_FragCoord.xy);
}
