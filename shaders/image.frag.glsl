#define pi 3.1415926535897932384626433832795

// distance fields
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

float box2(vec2 p, vec2 b) {
  vec2 h = abs(p) - b;
  return min(max(h.x, h.y), 0.0) + length(max(h, 0.0));
}

float cylinder(vec3 p, vec2 h) {
    vec2 d = abs(vec2(length(p.xz), p.y)) - h;
    return min(max(d.x, d.y), 0.0) + length(max(d, 0.0));
}

// operations on distance fields
vec4 unionRightAngle(vec4 a, vec4 b) {
  float d = min(a.x, b.x);
  return vec4(d, d == a.x ? a.yzw : b.yzw);
}

vec4 unionChamfer(vec4 a, vec4 b, float r) {
  return min(min(a, b), (a - vec4(r) + b)*sqrt(0.5));
}

vec4 compliment(vec4 a, vec4 b) {
  float d = max(-a.x, b.x);
  return vec4(d, d == a.x ? a.yzw : b.yzw);
}

// Domain operations
void rep(inout float p, float o) {
  p = mod(p + o, o*2.0) - o;
}

void rep(inout vec2 p, vec2 o) {
  p = mod(p + o, o*2.0) - o;
}

void mirrorLeft(inout float p, float o) {
  p = abs(p) - o;
}

void mirrorLeft(inout vec2 p, vec2 o) {
  p = abs(p) - o;
  if(p.y > p.x) p.xy = p.yx;
}

void mirrorRight(inout float p, float o) {
  p = -abs(p) + o;
}

void mirrorRight(inout vec2 p, vec2 o) {
  p = -abs(p) + o;
  if(p.y > p.x) p.xy = p.yx;
}

void rotateX(inout vec3 p, float a) {
  float r = a*pi/180.0;
  mat3 rx = mat3(1,   0,      0,
                 0, cos(r), sin(r),
                 0, -sin(r), cos(r));

  p = rx*p;
}

vec4 scene(vec3 p) {
  vec3 color = vec3(0.75);

  vec4 planeDI = vec4(
    plane(p, vec4(0, 1, 0, 0)),
    vec3(1.0)*mod(floor(p.z) + floor(p.x), 2.0));

  p.y -= 1.45;
  mirrorLeft(p.xz, vec2(5, 5));
  vec4 sphereDI = vec4(sphere(p + vec3(0, -1.0, 0), 0.6), vec3(1, 0, 0));
  vec3 m = p;
  mirrorRight(m.xz, vec2(0.15, 0.15));
  vec4 column = vec4(cylinder(m + vec3(0, 0.62, 0), vec2(0.2, 0.9)), color);
  m = p;
  m.y += 0.53;
  mirrorLeft(m.y, 0.82);
  vec4 platform = vec4(box(m, vec3(0.7, 0.1, 0.7)), color);

  vec4 pillar = unionChamfer(platform, column, 0.1);
  pillar = unionRightAngle(sphereDI, pillar);
  mirrorRight(p.xz, vec2(5, 5));
  mirrorRight(p.z, 1.5);
  vec4 wall = vec4(box2(p.yz, vec2(1.4, 0.05)), color);

  m = p;
  m.yz -= vec2(2.3, 1.05);
  rotateX(m, 45.0);
  vec4 roof = vec4(box2(m.yz, vec2(0.05, 1.7)), color);
  vec4 building = unionRightAngle(roof, wall);

  rep(p.x, 1.5);
  mirrorLeft(p.x, 0.55);
  mirrorLeft(p.x, -0.2);
  p.y += 0.3;
  vec4 boxDI = vec4(box(p, vec3(0.6, 0.7, 0.1)), color);
  p.y -= 0.7;
  vec4 cylinderDI = vec4(cylinder(p.xzy, vec2(0.6, 0.1)), color);

  vec4 windows = unionRightAngle(boxDI, cylinderDI);
  building = compliment(windows, building);
  building = unionRightAngle(building, pillar);

  vec4 scene = unionRightAngle(planeDI, building);

  return scene;
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
  float f = 1.0;
  float t = 10.0*0.0002;
  float tmax = length(p1 - p0);

  for(int i = 0; i < 100; i++) {
    float d = scene(p0 + rd*t).x;
    if(d < 0.0002) return 0.0;
    f = min(f, k*d/t);
    t += d;
    if(t >= tmax) break;
  }

  return f;
}

float ambientOcclusion(vec3 p, vec3 n) {
  float stepSize = 0.01;
  float t = stepSize;

  float oc = 0.0;
  for(int i = 0; i < 10; i++) {
    float d = scene(p + n*t).x;
    oc += t - d;
    t += stepSize;
  }

  return clamp(oc, 0.0, 1.0);
}

vec3 getShading(vec3 p, vec3 n, vec3 l) {
  float ints = 0.0;
  float shadow = getShadow(p, l, 15.5);
  float ao = ambientOcclusion(p, n);

  if(shadow > 0.0) {
    vec3 lightDir = normalize(l - p);
    ints = clamp(dot(n, lightDir), 0.0, 1.0)*shadow;
  }

  return vec3(1.0)*ints + vec3(0.4)*(1.0 - ints)*(1.0 - ao);
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

  if(t > 50.0) m = vec3(-1.0);
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
    vec3 shading =
      getShading(pos, normal, vec3(0, 10, 0));

    fragColor = vec4(pow(render.yzw*shading, vec3(0.474)), 1);
  } else {
    fragColor = vec4(vec3(0.25), 1.0);
  }
}

#pragma glslify: export(tryImage);
