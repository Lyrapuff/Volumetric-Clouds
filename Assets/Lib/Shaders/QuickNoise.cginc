#include "Assets/Lib/Shaders/NoiseLib.cginc"

float getWorley (float3 pos, int octaves, int rep, float persistence)
{
    float amplitude = 0.5;
    float noise = 0;

    for (int i = 0; i < octaves; i++)
    {
        noise += amplitude * (1 - worley(pos, 1, false, rep).x);
        rep	*= 2;
        amplitude *= persistence;
    }

    return noise;
}

float getPerlin (float3 pos, float persistence, int lacunarity, int octaves, int rep)
{
    float amplitude = 1;
    float noise = 0;

    for (int i = 0; i < octaves; i++)
    {
        noise += pnoise(pos, rep) * amplitude;

        amplitude *= persistence;
        rep *= lacunarity;
    }

    return noise;
}