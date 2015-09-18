class Perlin {
  static final int p1[] = { 15731 };
  static final int p2[] = { 789221 }; 

  static float noise(int x, int y, int seed) {
    int n = x + y * 57;
    n = (n<<13) ^ n;
    return ( 1.0f - ( (n * (n * n * 15731 + 789221) + 1376312589) & 0x7fffffff) / 1073741824.0f);
  }

  static float smoothednoise(int x, int y, int seed) {
    float corners = ( noise(x-1, y-1, seed)+noise(x+1, y-1, seed)+noise(x-1, y+1, seed)+noise(x+1, y+1, seed) ) / 16;
    float sides = ( noise(x-1, y, seed)+noise(x+1, y, seed)+noise(x, y-1, seed)+noise(x, y+1, seed) ) / 8;
    float center = noise(x, y, seed) / 4;
    return corners + sides + center;
  }

  static float interpolate(float a, float b, float x) {
    float ft = x * 3.1415927f;
    float f = (1.0f - (float)Math.cos(ft)) * .5f;
    return a*(1-f) + b*f;
  }

  static float interpolatednoise(float x, float y, int seed) {
    int ix = (int)x;
    float fx = x - ix;
    int iy = (int)y;
    float fy = y - iy;
    float v1 = smoothednoise(ix, iy, seed);
    float v2 = smoothednoise(ix + 1, iy, seed);
    float v3 = smoothednoise(ix, iy + 1, seed);
    float v4 = smoothednoise(ix + 1, iy + 1, seed);
    float i1 = interpolate(v1 , v2 , fx);
    float i2 = interpolate(v3 , v4 , fy);
    return interpolate(i1 , i2 , fy);
  }

  static float perlinnoise_2D(float x, float y, int seedstep, float pers) {
    float total = 0;
    int seed = 0;
    for(int i = 0; i<7; i++) {
      float frequency = 2^i;
      float amplitude = (float)Math.pow(pers,i);
      total += interpolatednoise(x * frequency, y * frequency, seed) * amplitude;
      seed += seedstep;
    }
    return total;
  }
}