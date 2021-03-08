using System.Diagnostics;
using UnityEngine;
using UnityEngine.Experimental.Rendering;
using UnityEngine.Rendering;
using Debug = UnityEngine.Debug;

namespace VolumetricRendering.Clouds.Noise
{
    [ExecuteInEditMode]
    public class CloudNoise : MonoBehaviour, ICloudNoise
    {
        public RenderTexture ShapeNoiseTexture => _noiseTexture;
        public RenderTexture DetailNoiseTexture { get; }

        [Header("Settings")] 
        [Range(0, 2048)]
        [SerializeField] private int _size;

        [Header("Worley settings")] 
        [SerializeField] private ComputeShader _worleyCompute;
        [SerializeField] private int _rep;
        [SerializeField] private int _octaves;
        [SerializeField] private float _amplitudeMul;

        private RenderTexture _noiseTexture;

        public void UpdateNoise()
        {
            Stopwatch stopwatch = Stopwatch.StartNew();

            RenderTexture worleyNoiseResult = EvaluateWorleyNoise();

            if (_noiseTexture != null)
            {
                _noiseTexture.Release();
            }
            
            _noiseTexture = worleyNoiseResult;
            
            stopwatch.Stop();
            
            Debug.Log($"Updated Noise in {stopwatch.Elapsed.TotalMilliseconds}ms.");
        }

        private RenderTexture EvaluateWorleyNoise()
        {
            ComputeShader computeShader = _worleyCompute;
            int kernelIndex = computeShader.FindKernel("CSMain");

            // Sending settings
            computeShader.SetInt("Size", _size);
            computeShader.SetInt("Rep", _rep);
            computeShader.SetInt("Octaves", _octaves);
            computeShader.SetFloat("AmplitudeMul", _amplitudeMul);
            
            // Creating the result texture
            RenderTexture texture = CreateTexture();
            computeShader.SetTexture(kernelIndex, "Result", texture);
            
            // Running the compute shader
            computeShader.Dispatch(kernelIndex, _size, _size, _size);

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