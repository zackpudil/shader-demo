import createTexture from 'gl-texture2d';

let unit = -1;
export default class Texture {
  constructor(gl, image) {

    this.texture = createTexture(gl, image);
    
    gl.pixelStorei(gl.UNPACK_FLIP_Y_WEBGL, false);
    this.texture.generateMipmap();
    this.texture.wrap = [gl.REPEAT, gl.REPEAT];
    this.texture.magFilter = gl.LINEAR;
    this.texture.minFilter = gl.LINEAR_MIPMAP_LINEAR;

    this.unit = ++unit;
  }

  bind() {
    return this.texture.bind(this.unit);
  }
}
