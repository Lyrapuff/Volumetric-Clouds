using UnityEngine;

namespace VolumetricRendering.Clouds
{
    public partial class VolumetricCloudsEffect
    {
        private static readonly int ShapeNoiseTex = Shader.PropertyToID("ShapeNoiseTex");
        private static readonly int DetailNoiseTex = Shader.PropertyToID("DetailNoiseTex");
        private static readonly int WeatherMapTex = Shader.PropertyToID("WeatherMapTex");
        private static readonly int BlueNoiseTex = Shader.PropertyToID("BlueNoiseTex");
        private static readonly int NoiseScale = Shader.PropertyToID("NoiseScale");
        private static readonly int WeatherMapScale = Shader.PropertyToID("WeatherMapScale");
        private static readonly int BoundsMin = Shader.PropertyToID("BoundsMin");
        private static readonly int BoundsMax = Shader.PropertyToID("BoundsMax");
        private static readonly int Density = Shader.PropertyToID("Density");
        private static readonly int Coverage = Shader.PropertyToID("Coverage");
        
        private static readonly int Steps = Shader.PropertyToID("Steps");
        private static readonly int ExtinctionFactor = Shader.PropertyToID("ExtinctionFactor");
        private static readonly int ScatteringFactor = Shader.PropertyToID("ScatteringFactor");
        
        private static readonly int LightSteps = Shader.PropertyToID("LightSteps");
        private static readonly int LightAbsorbtionThroughCloud = Shader.PropertyToID("LightAbsorbtionThroughCloud");
        private static readonly int LightAbsorbtionTowardsSun = Shader.PropertyToID("LightAbsorbtionTowardsSun");
        private static readonly int DarknessThreshold = Shader.PropertyToID("DarknessThreshold");
        
        private static readonly int PhaseParams = Shader.PropertyToID("PhaseParams");
        
        private static readonly int Slice = Shader.PropertyToID("Slice");
        private static readonly int TextureToDraw = Shader.PropertyToID("TextureToDraw");
        private static readonly int ChannelToDraw = Shader.PropertyToID("ChannelToDraw");
    }
}