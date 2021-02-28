using UnityEngine;

namespace VolumetricRendering.Clouds.Noise
{
    public interface INoise
    {
        RenderTexture NoiseTexture { get; }

        void UpdateNoise();
    }
}