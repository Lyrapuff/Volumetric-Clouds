using System.Diagnostics;
using UnityEngine;
using UnityEngine.Experimental.Rendering;
using UnityEngine.Rendering;
using Debug = UnityEngine.Debug;

namespace VolumetricRendering.Clouds.Generators
{
    [ExecuteInEditMode]
    public class ShapeNoiseGenerator : MonoBehaviour, ICloudGenerator
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

        private RenderTexture _shapeNoiseTexture;
        
        private static readonly int ShapeNoiseTex = Shader.PropertyToID("ShapeNoiseTex");

        public void Generate()
        {
            Stopwatch stopwatch = Stopwatch.StartNew();

            UpdateShapeTexture();
            
            stopwatch.Stop();
            
            Debug.Log($"Updated Shape Noise in {stopwatch.Elapsed.TotalMilliseconds}ms.");
        }

        public void Apply(Material material)
        {
            material.SetTexture(ShapeNoiseTex, _shapeNoiseTexture);
        }

        private void UpdateShapeTexture()
        {
            RenderTexture shapeTexture = GetShapeTexture();

            if (_shapeNoiseTexture != null)
            {
                _shapeNoiseTexture.Release();
            }
            
            _shapeNoiseTexture = shapeTexture;
        }
        
        private RenderTexture GetShapeTexture()
        {
            int kernelIndex = _computeShader.FindKernel("CSMain");

            // Sending settings
            _computeShader.SetInt("Size", _size);
            _computeShader.SetInt("Octaves", _octaves);
            _computeShader.SetFloat("Persistence", _persistence);
            _computeShader.SetInt("Rep", _rep);
            _computeShader.SetInt("Lacunarity", _lacunarity);
            
            // Creating result texture
            RenderTexture texture = CreateTexture();
            _computeShader.SetTexture(kernelIndex, "Result", texture);

            // Running the compute shader
            _computeShader.Dispatch(kernelIndex, _size, _size, _size);

            return texture;
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