using UnityEngine;

namespace VolumetricRendering.Clouds
{
    public partial class VolumetricCloudsEffect
    {
        private static readonly int NoiseTex = Shader.PropertyToID("NoiseTex");
        private static readonly int NoiseScale = Shader.PropertyToID("NoiseScale");
        private static readonly int MinHeight = Shader.PropertyToID("MinHeight");
        private static readonly int MaxHeight = Shader.PropertyToID("MaxHeight");
        private static readonly int Steps = Shader.PropertyToID("Steps");
        private static readonly int Distance = Shader.PropertyToID("Distance");
        private static readonly int ExtinctionFactor = Shader.PropertyToID("ExtinctionFactor");
        private static readonly int ScatteringFactor = Shader.PropertyToID("ScatteringFactor");
        private static readonly int LightSteps = Shader.PropertyToID("LightSteps");
        private static readonly int LightAbsorbtion = Shader.PropertyToID("LightAbsorbtion");
        private static readonly int PhaseParams = Shader.PropertyToID("PhaseParams");
        private static readonly int DrawOnScreen = Shader.PropertyToID("DrawOnScreen");
        private static readonly int Density = Shader.PropertyToID("Density");
        private static readonly int Coverage = Shader.PropertyToID("Coverage");
    }
}