using System.Diagnostics;
using UnityEngine;
using UnityEngine.Experimental.Rendering;
using UnityEngine.Rendering;
using Debug = UnityEngine.Debug;

namespace VolumetricRendering.Clouds.Noise
{
    [ExecuteInEditMode]
    public class CloudNoise : MonoBehaviour, INoise
    {
        public RenderTexture NoiseTexture => _noiseTexture;
        
        [Header("Settings")] 
        [Range(0, 2048)]
        [SerializeField] private int _size;
        [SerializeField] private WorleyNoiseSettings _worleySettings;

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
            ComputeShader computeShader = _worleySettings.ComputeShader;
            int kernelIndex = computeShader.FindKernel("CSMain");
            
            // Sending buffers
            Vector3[] points = GetRandomPoints(_worleySettings.PointCount, _size);
            
            ComputeBuffer pointsBuffer = new ComputeBuffer(points.Length, sizeof(float) * 3);
            pointsBuffer.SetData(points);
            computeShader.SetBuffer(kernelIndex, "Points", pointsBuffer);
            
            // Sending settings
            computeShader.SetInt("PointCount", _worleySettings.PointCount);
            computeShader.SetInt("Size", _size);
            
            // Creating the result texture
            RenderTexture texture = CreateTexture();
            computeShader.SetTexture(kernelIndex, "Result", texture);
            
            // Running the compute shader
            computeShader.Dispatch(kernelIndex, _size, _size, 1);

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
        
        private static Vector3[] GetRandomPoints(int count, int size)
        {
            Vector3[] points = new Vector3[count];

            for (int i = 0; i < count; i++)
            {
                points[i] = new Vector3(Random.Range(0, size), Random.Range(0, size), Random.Range(0, size));
            }
            
            return points;
        }
    }
}