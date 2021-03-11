using System.Diagnostics;
using UnityEngine;
using UnityEngine.Experimental.Rendering;
using UnityEngine.Rendering;
using Debug = UnityEngine.Debug;

namespace VolumetricRendering.Clouds.Generators
{
    public class WeatherMap : MonoBehaviour, ICloudGenerator
    {
        [SerializeField] private ComputeShader _computeShader;
        [Range(128, 512)]
        [SerializeField] private int _size;
        [Range(1, 16)]
        [SerializeField] private int _rep;
        [Range(1, 16)]
        [SerializeField] private int _lacunarity;
        [Range(1, 6)]
        [SerializeField] private int _octaves;
        [Range(0f, 1f)]
        [SerializeField] private float _persistence;
        
        private RenderTexture _weatherMapTexture;
        
        private static readonly int WeatherMapTex = Shader.PropertyToID("WeatherMapTex");

        public void Generate()
        {
            Stopwatch stopwatch = Stopwatch.StartNew();

            GenerateMap();
            
            stopwatch.Stop();
            
            Debug.Log($"Updated WeatherMap in {stopwatch.Elapsed.TotalMilliseconds}ms.");
        }

        public void Apply(Material material)
        {
            material.SetTexture(WeatherMapTex, _weatherMapTexture);
        }

        private void GenerateMap()
        {
            int kernelIndex = _computeShader.FindKernel("CSMain");
            
            _computeShader.SetInt("Size", _size);
            _computeShader.SetInt("Octaves", _octaves);
            _computeShader.SetFloat("Persistence", _persistence);
            _computeShader.SetInt("Rep", _rep);
            _computeShader.SetInt("Lacunarity", _lacunarity);
            
            RenderTexture texture = CreateTexture();
            _computeShader.SetTexture(kernelIndex, "Result", texture);
            
            _computeShader.Dispatch(kernelIndex, _size, _size, _size);

            if (_weatherMapTexture != null)
            {
                _weatherMapTexture.Release();
            }
            
            _weatherMapTexture = texture;
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