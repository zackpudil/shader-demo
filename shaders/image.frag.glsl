float mapTo(float x, float minx, float maxx, float miny, float maxy) {
  float a = (maxy - miny)/(maxx-minx);
  float b = miny - a*minx;
  return a * x + b;
}

float plane(vec3 p, vec4 n) {
  return dot(p, n.xyz) + n.w;
}

float sphere(vec3 p, float radius) {
  return length(p) - radius;
}

float box(vec3 p, vec3 b) {
  vec3 d = abs(p) - b;
  return min(max(d.x, max(d.y, d.z)), 0.0) + length(max(d, 0.0));
}

float cylinder(vec3 p, vec2 h) {
    vec2 d = abs(vec2(length(p.xz), p.y)) - h;
    return min(max(d.x, d.y), 0.0) + length(max(d, 0.0));
}

vec4 opU(vec4 a, vec4 b) {
  return a.x < b.x ? a : b;
}

vec4 scene(vec3 p) {

  vec4 planeDI = vec4(plane(p, vec4(0, 1, 0, 0)), vec3(0));

  p.y -= 0.2;
  vec4 boxDI = vec4(box(p, vec3(0.1)), vec3(0.1, 0.8, 0.6));
  p.x -= 0.35;
  vec4 sphereDI = vec4(sphere(p, 0.2), vec3(0.56, 0.12, 0.01));
  p.x -= 0.35;
  vec4 cylinderDI = vec4(cylinder(p.xzy, vec2(0.1, 0.3)), vec3(0.11, 0.2, 0.43));

  return opU(planeDI, opU(sphereDI, opU(boxDI, cylinderDI)));
}

vec3 getNormal(vec3 p) {
  float h = 0.0001;

  vec3 x = vec3(h, 0, 0);
  vec3 y = vec3(0, h, 0);
  vec3 z = vec3(0, 0, h);

  return normalize(vec3(
    scene(p + x).x - scene(p - x).x,
    scene(p + y).x - scene(p - y).x,
    scene(p + z).x - scene(p - z).x));
}

float getShadow(vec3 p0, vec3 p1, float k) {
  vec3 rd = normalize(p1 - p0);
  float t = 10.0 * 0.0002;
  float maxt = length(p1 - p0);
  float f = 1.0;

  for(int i = 0; i < 64; i++) {
    float d = scene(p0 + rd*t).x;

    if(d < 0.0002) return 0.0;

    f = min(f, k*d/t);
    t += d;

    if(t >= maxt) break;
  }

  return f;
}

vec4 getShading(vec3 p, vec3 n, vec3 l) {
  float ints = 0.0;
  float shadow = getShadow(p, l, 16.0);

  if(shadow > 0.0) {
    vec3 lightDir = normalize(l - p);
    ints = clamp(dot(n, lightDir), 0.0, 1.0);
  }

  return vec4(1.0)*ints + vec4(vec3(0.4), 1.0)*(1.0 - ints);
}

vec4 raymarch(vec3 rayOrigin, vec3 rayDirection) {
  float t = 0.0;
  vec3 m = vec3(-1.0);

  for(int i = 0; i < 64; i++) {
    vec3 p = rayOrigin + rayDirection*t;
    vec4 s = scene(p);
    if(s.x < 0.0002) break;
    t += s.x;
    m = s.yzw;
  }

  if(t > 10.0) m = vec3(-1.0);
  return vec4(t, m);
}

void tryImage(out vec4 fragColor, in vec2 fragCoord) {
  vec2 uv = -1.0+2.0*fragCoord/res;
  uv.x *= res.x/res.y;

  vec3 ro = eye;
  vec3 rd = view*normalize(vec3(uv, 1.97));
  int i;
  float t;

  vec4 render = raymarch(ro, rd);

  if(render.y > -1.0) {
    vec3 pos = ro + render.x*rd;
    vec3 normal = getNormal(pos);
    vec4 shading = getShading(pos, normal,
      vec3(sin(time/6.0), 1.0, cos(time/6.0)));

    if(render.yzw == vec3(0)) {
      float f = mod(floor(5.0*pos.z) + floor(5.0*pos.x), 2.0);
      fragColor = vec4(pow(vec3(0.8)*f, vec3(0.343)), 1)*shading;
    } else {
      fragColor = vec4(pow(render.yzw, vec3(0.474)), 1)*shading;
    }
  } else {
    fragColor = vec4(pow(vec3(0.0, fragCoord.x/res.x, fragCoord.y/res.y), vec3(0.34343)), 1);
  }
}

#pragma glslify: export(tryImage);
