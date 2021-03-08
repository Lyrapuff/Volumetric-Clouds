using System.Diagnostics;
using UnityEngine;
using UnityEngine.Experimental.Rendering;
using UnityEngine.Rendering;
using Debug = UnityEngine.Debug;

namespace VolumetricRendering.Clouds.Noise
{
    public class WeatherMap : MonoBehaviour, IWeatherMap
    {
        public RenderTexture WeatherMapTexture { get; private set; }
        
        [SerializeField] private ComputeShader _computeShader;
        [SerializeField] private int _size;
        
        public void UpdateMap()
        {
            Stopwatch stopwatch = Stopwatch.StartNew();

            GenerateMap();
            
            stopwatch.Stop();
            
            Debug.Log($"Updated WeatherMap in {stopwatch.Elapsed.TotalMilliseconds}ms.");
        }

        private void GenerateMap()
        {
            int kernelIndex = _computeShader.FindKernel("CSMain");
            
            RenderTexture texture = CreateTexture();
            _computeShader.SetTexture(kernelIndex, "Result", texture);
            
            _computeShader.Dispatch(kernelIndex, _size, _size, _size);

            if (WeatherMapTexture != null)
            {
                WeatherMapTexture.Release();
            }
            
            WeatherMapTexture = texture;
        }

        private RenderTexture CreateTexture()
        {
            RenderTexture texture = new RenderTexture(_size, _size, 0);
            texture.graphicsFormat = GraphicsFormat.R16G16B16A16_UNorm;
            texture.dimension = TextureDimension.Tex3D;
            texture.volumeDepth = _size;
            texture.enableRandomWrite = true;
            texture.Create();

            texture.wrapMode = TextureWrapMode.Repeat;
            
            return texture;
        }
    }
}