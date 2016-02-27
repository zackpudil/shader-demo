export function radians(degrees) {
  if(!degrees.length) degrees = [degrees];
  let result = [];

  for(let i = 0; i < degrees.length; i++) {
    result.push(degrees[i]*Math.PI / 180);
  }

  return result.length == 1 ? result[0] : result;
};

export function clamp(out, min, max) {
  if(!out.length) out = [out];
  let result = [];
  
  for(let i = 0; i < out.length; i++)
    result.push(Math.max(Math.min(out[i], max[i]), min[i]));

  return result.length == 1 ? result[0] : result;
}

export function mod(out, modolus) {
  if(!out.length) out = [out];
  let result = [];

  for(let i = 0; i < out.length; i++)
      result.push(out[i] % modolus);

  return result.length == 1 ? result[0] : result;
}
