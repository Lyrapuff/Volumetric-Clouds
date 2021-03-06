using UnityEngine;

namespace VolumetricRendering.Clouds.Noise
{
    public interface ICloudNoise
    {
        RenderTexture ShapeNoiseTexture { get; }
        RenderTexture DetailNoiseTexture { get; }

        void UpdateNoise();
    }
}