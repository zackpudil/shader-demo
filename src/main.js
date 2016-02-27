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

var shader, screenBuffer;
var camera;

var mouse = {
  lx: 0, ly: 0, d: false
};

shell.on('gl-init', () => {
  let gl = shell.gl;

  var vertSrc = glslify("../shaders/main.vert.glsl");
  var fragSrc = glslify("../shaders/main.frag.glsl");

  shader = new Shader(gl)
    .attach(vertSrc, 'vert')
    .attach(fragSrc, 'frag')
    .link();

  let twoTriangles = new Float32Array([
    1, -1, -1, -1, -1, 1,
    -1, 1, 1, 1, 1, -1
  ]);

  screenBuffer = gl.createBuffer();
  gl.bindBuffer(gl.ARRAY_BUFFER, screenBuffer);
  gl.bufferData(gl.ARRAY_BUFFER, twoTriangles, gl.STATIC_DRAW);

  let loc = gl.getAttribLocation(shader.program, "position");
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
let speed = 0.075;

shell.on('gl-render', (t) => {
  let gl = shell.gl;
  globalTime += t/10;

  if(pressed("W")) camera.move(speed);
  if(pressed("S")) camera.move(-speed);
  if(pressed("A")) camera.straff(-speed);
  if(pressed("D")) camera.straff(speed);
  if(pressed("<space>")) camera.up(speed);
  if(pressed("<shift>")) camera.up(-speed);

  shader.use()
    .bind("time", { type: 'float', val: globalTime })
    .bind("resolution", { type: 'vec2', val: [shell.width, shell.height] })
    .bind("view", { type: 'mat3', val: camera.getViewMatrix() })
    .bind("eye", { type: 'vec3', val: camera.position });

  gl.clear(gl.COLOR_BUFFER_BIT | gl.DEPTH_BUFFER_BIT);
  gl.drawArrays(gl.TRIANGLES, 0, 6);
});
