using UnityEngine;

namespace VolumetricRendering.Clouds
{
    public partial class VolumetricCloudsEffect
    {
        private static readonly int ShapeNoiseTex = Shader.PropertyToID("ShapeNoiseTex");
        private static readonly int NoiseScale = Shader.PropertyToID("NoiseScale");
        private static readonly int VolumeSettings = Shader.PropertyToID("VolumeSettings");
        private static readonly int Density = Shader.PropertyToID("Density");
        private static readonly int Coverage = Shader.PropertyToID("Coverage");
        
        private static readonly int Steps = Shader.PropertyToID("Steps");
        private static readonly int Distance = Shader.PropertyToID("Distance");
        private static readonly int ExtinctionFactor = Shader.PropertyToID("ExtinctionFactor");
        private static readonly int ScatteringFactor = Shader.PropertyToID("ScatteringFactor");
        
        private static readonly int LightSteps = Shader.PropertyToID("LightSteps");
        private static readonly int LightAbsorbtion = Shader.PropertyToID("LightAbsorbtion");
        
        private static readonly int PhaseParams = Shader.PropertyToID("PhaseParams");
    }
}