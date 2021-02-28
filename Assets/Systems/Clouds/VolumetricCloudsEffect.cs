using UnityEngine;
using VolumetricRendering.Clouds.Noise;

namespace VolumetricRendering.Clouds
{
    [ExecuteInEditMode]
    public class VolumetricCloudsEffect : MonoBehaviour
    {
        [Header("References")]
        [SerializeField] private Shader _shader;
        [SerializeField] private CloudNoise _noise;

        [Header("Settings")]
        [SerializeField] private float _noiseScale;
        [Header("Altitude settings")]
        [SerializeField] private float _minHeight;
        [SerializeField] private float _maxHeight;
        [Header("Raymarch settings")]
        [SerializeField] private int _steps;
        [SerializeField] private float _distance;
        [SerializeField] private float _extinctionFactor;
        [SerializeField] private float _scatteringFactor;
        [Header("Lightmarch settings")]
        [SerializeField] private int _lightSteps;
        [SerializeField] private float _lightAbsorbtion;
        [Header("Phase settings")]
        [Range (0, 1)]
        [SerializeField] private float _forwardScattering = .83f;
        [Range (0, 1)]
        [SerializeField] private float _backScattering = .3f;
        [Range (0, 1)]
        [SerializeField] private float _baseBrightness = .8f;
        [Range (0, 1)]
        [SerializeField] private float _phaseFactor = .15f;

        [Header("Debug")] 
        [SerializeField] private bool _drawOnScreen;

        private Material _material;
        
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

        private void OnRenderImage(RenderTexture src, RenderTexture dest)
        {
            if (_material == null)
            {
                _material = new Material(_shader);
            }

            if (_noise.NoiseTexture == null)
            {
                _noise.UpdateNoise();
            }
            
            SendSettings();

            Graphics.Blit(src, dest, _material);
        }

        private void SendSettings()
        {
            _material.SetTexture(NoiseTex, _noise.NoiseTexture);
            _material.SetFloat(NoiseScale, _noiseScale);
            _material.SetFloat(MinHeight, _minHeight);
            _material.SetFloat(MaxHeight, _maxHeight);
            _material.SetInt(Steps, _steps);
            _material.SetFloat(Distance, _distance);
            _material.SetFloat(ExtinctionFactor, _extinctionFactor);
            _material.SetFloat(ScatteringFactor, _scatteringFactor);
            _material.SetInt(LightSteps, _lightSteps);
            _material.SetFloat(LightAbsorbtion, _lightAbsorbtion);
            _material.SetVector(PhaseParams, new Vector4(_forwardScattering, _backScattering, _baseBrightness, _phaseFactor));

            _material.SetInt(DrawOnScreen, _drawOnScreen ? 1 : 0);
        }
    }
}