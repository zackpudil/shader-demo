import { mat3, vec3, vec2 } from 'gl-matrix';
import { radians, mod } from './util';

export default class Camera {
  constructor(position, angles) {
    this.position = position;
    this.angles = angles;

    this.forward = vec3.create();
    this.right = vec3.create();
  }

  move(speed) {
    vec3.add(this.position, this.position, vec3.scale([], this.forward, speed));
  }

  straff(speed) {
    vec3.add(this.position, this.position, vec3.scale([], this.right, speed));
  }

  up(speed) {
    let up = vec3.normalize([], vec3.cross([], this.forward, this.right));
    vec3.add(this.position, this.position, vec3.scale([], up, speed));
  }

  look(offset, sens) {
    vec3.add(this.angles, this.angles, vec3.scale([], offset, sens));
  }

  getViewMatrix() {
    let rads = mod(radians(this.angles), 2*Math.PI);

    let sintheta = Math.sin(rads[0]);
    let costheta = Math.cos(rads[0]);

    let sinphi = Math.sin(rads[1]);
    let cosphi = Math.cos(rads[1]);

    this.forward = [cosphi * sintheta, -sinphi, cosphi*costheta];
    this.right = [costheta, 0, -sintheta];
    let up = vec3.normalize([], vec3.cross([], this.forward, this.right));

    localStorage.cx = this.position[0];
    localStorage.cy = this.position[1];
    localStorage.cz = this.position[2];
    localStorage.ax = this.angles[0];
    localStorage.ay = this.angles[1];

    return [
      ...this.right,
      ...up,
      ...this.forward
    ];
  }
}
