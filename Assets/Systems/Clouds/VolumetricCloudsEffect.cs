using UnityEngine;
using VolumetricRendering.Clouds.Noise;

namespace VolumetricRendering.Clouds
{
    [ExecuteInEditMode]
    [RequireComponent(typeof(ICloudNoise))]
    public partial class VolumetricCloudsEffect : MonoBehaviour
    {
        [Header("References")]
        [SerializeField] private Shader _shader;

        [Header("Settings")]
        [SerializeField] private float _noiseScale;
        [Range(0f, 1f)]
        [SerializeField] private float _density;
        [Range(0f, 1f)]
        [SerializeField] private float _coverage;
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

        private ICloudNoise _cloudNoise;
        
        private Material _material;

        private void OnRenderImage(RenderTexture src, RenderTexture dest)
        {
            _cloudNoise ??= GetComponent<ICloudNoise>();
            
            if (_cloudNoise.ShapeNoiseTexture == null)
            {
                _cloudNoise.UpdateNoise();
            }
            
            _material ??= new Material(_shader);
            
            SendSettings(_material);

            Graphics.Blit(src, dest, _material);
        }

        private void SendSettings(Material material)
        {
            material.SetTexture(NoiseTex, _cloudNoise.ShapeNoiseTexture);
            material.SetFloat(NoiseScale, _noiseScale);
            material.SetFloat(Density, _density);
            material.SetFloat(Coverage, _coverage);
            material.SetFloat(MinHeight, _minHeight);
            material.SetFloat(MaxHeight, _maxHeight);
            material.SetInt(Steps, _steps);
            material.SetFloat(Distance, _distance);
            material.SetFloat(ExtinctionFactor, _extinctionFactor);
            material.SetFloat(ScatteringFactor, _scatteringFactor);
            material.SetInt(LightSteps, _lightSteps);
            material.SetFloat(LightAbsorbtion, _lightAbsorbtion);
            material.SetVector(PhaseParams, new Vector4(_forwardScattering, _backScattering, _baseBrightness, _phaseFactor));

            material.SetInt(DrawOnScreen, _drawOnScreen ? 1 : 0);
        }
    }
}