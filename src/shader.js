export default class Shader {
  constructor(gl) {
    this.gl = gl;
    this.program = this.gl.createProgram();
  }

  use() {
    this.gl.useProgram(this.program);

    return this;
  }

  attach(src, type) {
    let shader = this.gl.createShader(type == "vert" ? this.gl.VERTEX_SHADER : this.gl.FRAGMENT_SHADER);
    this.gl.shaderSource(shader, src);
    this.gl.compileShader(shader);

    let info = this.gl.getShaderInfoLog(shader);
    if(info) throw new Error(info);

    this.gl.attachShader(this.program, shader);

    return this;
  }

  link() {
    this.gl.linkProgram(this.program);
    let info = this.gl.getProgramInfoLog(this.program);
    if(info) throw new Error(info);
    return this;
  }

  bind(name, value) {
    let loc = this.gl.getUniformLocation(this.program, name);
    if(value.type === "mat4")
      this.gl.uniformMatrix4fv(loc, false, value.val);
    else if(value.type === "vec3")
      this.gl.uniform3fv(loc, value.val);
    else if(value.type === "vec2")
      this.gl.uniform2fv(loc, value.val);
    else if(value.type === "float")
      this.gl.uniform1f(loc, value.val);
    else if(value.type === "sampler2D" || value.type === "int")
      this.gl.uniform1i(loc, value.val);

    return this;
  }
}
