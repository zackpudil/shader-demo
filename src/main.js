import createShell from 'gl-now';
import { vec2, mat4 } from 'gl-matrix';
import pressed from 'key-pressed';
import touches from 'touches';
import mouseWheel from 'mouse-wheel';
var glslify = require("glslify");

import Shader from './shader';
import Texture from './texture';
import Camera from './camera';
import { radians } from './util';

let shell = createShell();

var w, h;
var distanceFieldShader, triangleBuffer;
var camera;

var mouse = {
  lx: 0, ly: 0, d: false
};

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

  camera = new Camera(
    [
      parseFloat(localStorage.cx) || 0,
      parseFloat(localStorage.cy) || 1,
      parseFloat(localStorage.cz) || 2],
    [
      parseFloat(localStorage.ax) || 0,
      parseFloat(localStorage.ay) || 0
    ]);

  touches()
    .on('start', (ev, pos) => {
      mouse.lx = pos[0];
      mouse.ly = pos[1];
      mouse.d = true;
    })
    .on('move', (ev, pos) => {
      if(!mouse.d) return;

      let offset =  vec2.subtract([], pos, [mouse.lx, mouse.ly]);
      camera.look(offset, 0.1);
      mouse.lx = pos[0]; mouse.ly = pos[1];
    })
    .on('end', () => mouse.d = false)

  mouseWheel((dx, dy) => camera.look([-dx, -dy], 0.3));
});

let globalTime = 0;
let speed = 0.025;

shell.on('gl-render', (t) => {
  let gl = shell.gl;
  globalTime += t/10;

  if(pressed("W")) camera.move(speed);
  if(pressed("S")) camera.move(-speed);
  if(pressed("A")) camera.straff(-speed);
  if(pressed("D")) camera.straff(speed);
  if(pressed("<space>")) camera.up(speed);
  if(pressed("<shift>")) camera.up(-speed);

  distanceFieldShader.use()
    .bind("time", { type: 'float', val: globalTime })
    .bind("resolution", { type: 'vec2', val: [w, h] })
    .bind("view", { type: 'mat3', val: camera.getViewMatrix() })
    .bind("eye", { type: 'vec3', val: camera.position });

  gl.clear(gl.COLOR_BUFFER_BIT | gl.DEPTH_BUFFER_BIT);
  gl.drawArrays(gl.TRIANGLES, 0, 6);
});
