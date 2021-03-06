using UnityEngine;

namespace VolumetricRendering.Clouds.Noise
{
    public interface IWeatherMap
    {
        RenderTexture WeatherMapTexture { get; }
        
        void UpdateMap();
    }
}