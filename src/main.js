import createShell from 'gl-now';
import touches from 'touches';
import { vec2 } from 'gl-matrix';
var glslify = require("glslify");

import Shader from './shader';
import Texture from './texture';

let shell = createShell();

var w, h, m = vec2.fromValues(0, 0), down = false, pause = false;
var distanceFieldShader, triangleBuffer, noiseTex, terrainTex, cloudTex;

var currentDemo = 0;

shell.on('gl-init', () => {
  let gl = shell.gl;

  w = shell.width;
  h = shell.height;

  gl.enable(gl.DEPTH_TEST);
  gl.viewport(0, 0, w, h);

  var triangleSrc = glslify("../shaders/main.vert.glsl");
  var distanceFieldShaderSrc = glslify("../shaders/main.frag.glsl");

  distanceFieldShader = new Shader(gl)
    .attach(triangleSrc, 'vert')
    .attach(distanceFieldShaderSrc, 'frag')
    .link();

  noiseTex = new Texture(gl, document.getElementById("noise"));
  terrainTex = new Texture(gl, document.getElementById("terrain"));
  cloudTex = new Texture(gl, document.getElementById("clouds"));

  let triangleData = new Float32Array([
    1, -1, -1, -1, -1, 1,
    -1, 1, 1, 1, 1, -1
  ]);

  triangleBuffer = gl.createBuffer();
  gl.bindBuffer(gl.ARRAY_BUFFER, triangleBuffer);
  gl.bufferData(gl.ARRAY_BUFFER, triangleData, gl.STATIC_DRAW);

  let loc = gl.getAttribLocation(distanceFieldShader.program, "position");
  gl.enableVertexAttribArray(loc);
  gl.vertexAttribPointer(loc, 2, gl.FLOAT, false, 0, 0);

  touches()
    .on('start', () => down = true)
    .on('move', (ev, position) => down ? m = vec2.fromValues(...position) : null)
    .on('end', () => down = false);

  document.addEventListener('keyup', ev => {
    if(ev.keyCode == 32) {
      currentDemo += 1;
      if(currentDemo > 3) currentDemo = 0;
    } else if(ev.keyCode == 80) pause = !pause;
  });
});

let globalTime = 0;

shell.on('gl-render', (t) => {
  if(pause) return;

  let gl = shell.gl;
  let resolution = [w, h];

  globalTime += t/10;

  distanceFieldShader.use()
    .bind("time", { type: 'float', val: globalTime })
    .bind("resolution", { type: 'vec2', val: resolution })
    .bind("mouse", { type: 'vec2', val: m })
    .bind("noise", { type: 'sampler2D', val: noiseTex.bind() })
    .bind("terrain", { type: 'sampler2D', val: terrainTex.bind() })
    .bind("clouds", { type: 'sampler2D', val: cloudTex.bind() })
    .bind("currentDemo", { type: 'int', val: currentDemo });

  gl.clear(gl.COLOR_BUFFER_BIT | gl.DEPTH_BUFFER_BIT);
  gl.drawArrays(gl.TRIANGLES, 0, 6);
});
