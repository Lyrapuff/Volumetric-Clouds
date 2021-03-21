using UnityEngine;

namespace VolumetricRendering.Clouds.Generators
{
    public interface ICloudGenerator
    {
        void Generate();
        void Apply(Material material);
    }
}