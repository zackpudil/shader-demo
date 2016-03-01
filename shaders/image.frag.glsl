#define pi 3.1415926535897932384626433832795
mat3 m = mat3( 0.00,  0.80,  0.60,
              -0.80,  0.36, -0.48,
              -0.60, -0.48,  0.64 );

float hash( float n ) {
  return fract(sin(n)*43758.5453);
}


float noise( in vec3 x ) {
  vec3 p = floor(x);
  vec3 f = fract(x);

  f = f*f*(3.0-2.0*f);

  float n = p.x + p.y*57.0 + 113.0*p.z;

  float res = mix(mix(mix( hash(n+  0.0), hash(n+  1.0),f.x),
                      mix( hash(n+ 57.0), hash(n+ 58.0),f.x),f.y),
                  mix(mix( hash(n+113.0), hash(n+114.0),f.x),
                      mix( hash(n+170.0), hash(n+171.0),f.x),f.y),f.z);
  return res;
}

float fbm( vec3 p ) {
  float f = 0.0;

  f += 0.5000*noise( p ); p = m*p*2.02;
  f += 0.2500*noise( p ); p = m*p*2.03;
  f += 0.1250*noise( p ); p = m*p*2.01;
  f += 0.0625*noise( p );

  return f/0.9375;
}

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
vec2 unionRightAngle(vec2 a, vec2 b) {
  float d = min(a.x, b.x);
  return vec2(d, d == a.x ? a.y : b.y);
}

vec2 unionChamfer(vec2 a, vec2 b, float r) {
  return min(min(a, b), (a - vec2(r) + b)*sqrt(0.5));
}

vec2 compliment(vec2 a, vec2 b) {
  float d = max(-a.x, b.x);
  return vec2(d, d == a.x ? a.y : b.y);
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

vec3 sphereMaterial(vec3 p) {
  vec3 sphereColor = vec3(1.0,0.0,0.0);
  float a = atan(p.x,p.z);
  float r = length(p.xz);
  float f = smoothstep( 0.1, 1.0, fbm(p) );
  sphereColor = mix( sphereColor, vec3(0.0,0.0,1.0), f );
  f = smoothstep( 0.0, 1.0, fbm(p*4.0) );
  sphereColor *= 0.8+0.2*f;

  f = fbm( vec3(a*7.0 + p.z,3.0*p.y,p.x)*2.0);
  f = smoothstep( 0.2,1.0,f);
  f *= smoothstep(0.4,1.2,p.y + 0.75*(noise(4.0*p.zyx)-0.5) );
  sphereColor = mix( sphereColor, vec3(0.4,0.2,0.0), 0.5*f );

  return sphereColor;
}

vec3 buildingMaterial(vec3 p) {
  vec3 wallColor = vec3(0.25);
  float f = fbm( 4.0*p*vec3(1.0,9.0,0.5) );
  wallColor = mix( wallColor, vec3(0.2,0.2,0.2)*1.7, f );
  f = fbm( 2.0*p);
  wallColor *= 0.7+0.3*f;

  f = smoothstep(0.0, 1.0, fbm(p*48.0));
  f = smoothstep(0.7, 0.9, f);
  wallColor = mix(wallColor, vec3(0.2), f*0.75);

  return wallColor;
}

vec3 floorMaterial(vec3 p) {
  vec3 planeColor = vec3(1.0)*mod(floor(p.z) + floor(p.x), 2.0);
  return planeColor;
}

vec2 scene(vec3 p) {
  vec2 planeDI = vec2(plane(p, vec4(0, 1, 0, 0)),0.0);
  p.y -= 1.45;

  rep(p.xz, vec2(13, 13));
  mirrorLeft(p.xz, vec2(5, 5));
  vec2 sphereDI = vec2(sphere(p + vec3(0, -1.0, 0), 0.6), 1.0);

  vec3 m = p;
  mirrorRight(m.xz, vec2(0.15, 0.15));
  vec2 column = vec2(cylinder(m + vec3(0, 0.62, 0), vec2(0.2, 0.9)), 2.0);
  m = p;
  m.y += 0.53;
  mirrorLeft(m.y, 0.82);
  vec2 platform = vec2(box(m, vec3(0.7, 0.1, 0.7)), 2.0);

  vec2 pillar = unionChamfer(platform, column, 0.1);
  pillar = unionRightAngle(sphereDI, pillar);
  mirrorRight(p.xz, vec2(5, 5));
  mirrorRight(p.z, 1.5);
  vec2 wall = vec2(box2(p.yz, vec2(1.4, 0.05)), 2.0);

  m = p;
  m.yz -= vec2(2.3, 1.05);
  rotateX(m, 45.0);
  vec2 roof = vec2(box2(m.yz, vec2(0.05, 1.7)), 2.0);
  vec2 building = unionRightAngle(roof, wall);

  rep(p.x, 1.5);
  mirrorLeft(p.x, 0.55);
  mirrorLeft(p.x, -0.2);
  p.y += 0.3;
  vec2 boxDI = vec2(box(p, vec3(0.6, 0.7, 0.1)), 0.0);
  p.y -= 0.7;
  vec2 cylinderDI = vec2(cylinder(p.xzy, vec2(0.6, 0.1)), 0.0);

  vec2 windows = unionRightAngle(boxDI, cylinderDI);
  building = compliment(windows, building);
  building = unionRightAngle(building, pillar);

  vec2 scene = unionRightAngle(planeDI, building);

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

vec2 raymarch(vec3 rayOrigin, vec3 rayDirection) {
  float t = 0.0;
  float m = -1.0;

  for(int i = 0; i < 64; i++) {
    vec3 p = rayOrigin + rayDirection*t;
    vec2 s = scene(p);
    if(s.x < 0.0002) break;
    t += s.x;
    m = s.y;
  }

  if(t > 50.0) m = -1.0;
  return vec2(t, m);
}

void tryImage(out vec4 fragColor, in vec2 fragCoord) {
  vec2 uv = -1.0+2.0*fragCoord/res;
  uv.x *= res.x/res.y;

  vec3 ro = eye;
  vec3 rd = view*normalize(vec3(uv, 1.97));
  int i;
  float t;

  vec2 render = raymarch(ro, rd);

  if(render.y > -1.0) {
    vec3 pos = ro + render.x*rd;
    vec3 normal = getNormal(pos);
    vec3 shading = getShading(pos, normal, vec3(0, 10, 0));

    vec3 col;
    if(render.y == 0.0)
      col = floorMaterial(pos);
    else if(render.y == 1.0)
      col = sphereMaterial(pos);
    else if(render.y == 2.0)
      col = buildingMaterial(pos);

    fragColor = vec4(pow(col*shading, vec3(0.474)), 1);
  } else {
    fragColor = vec4(vec3(0.25), 1.0);
  }
}

#pragma glslify: export(tryImage);
