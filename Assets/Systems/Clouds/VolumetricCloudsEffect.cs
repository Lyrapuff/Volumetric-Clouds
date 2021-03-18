using System;
using Systems.Extensions;
using UnityEngine;
using VolumetricRendering.Clouds.Generators;

namespace VolumetricRendering.Clouds
{
    [ExecuteInEditMode]
    public partial class VolumetricCloudsEffect : MonoBehaviour
    {
        [Header("References")]
        [SerializeField] private Shader _shader;

        [Header("Settings")]
        [SerializeField] private Texture2D _blueNoise;
        [SerializeField] private float _noiseScale;
        [SerializeField] private float _weatherMapScale;
        [Range(0f, 1f)]
        [SerializeField] private float _density;
        [Range(0f, 1f)]
        [SerializeField] private float _coverage;
        
        [Header("Volume settings")] 
        [SerializeField] private Transform _volume;
        
        [Header("Raymarch settings")]
        [SerializeField] private int _steps;
        [SerializeField] private float _extinctionFactor;
        [SerializeField] private float _scatteringFactor;
        
        [Header("Lightmarch settings")]
        [SerializeField] private int _lightSteps;
        [Range(0f, 1f)]
        [SerializeField] private float _lightAbsorbtionThroughCloud;
        [Range(0f, 1f)]
        [SerializeField] private float _lightAbsorbtionTowardsSun;
        [SerializeField] private float _darknessThreshold;
        
        [Header("Phase settings")]
        [Range (0, 1)]
        [SerializeField] private float _forwardScattering = .83f;
        [Range (0, 1)]
        [SerializeField] private float _backScattering = .3f;
        [Range (0, 1)]
        [SerializeField] private float _baseBrightness = .8f;
        [Range (0, 1)]
        [SerializeField] private float _phaseFactor = .15f;

        private enum TextureType { ShapeNoise, DetailNoise, WeatherMap }
        private enum Channel { RGBA, R, G, B, A }

        [Header("Debug")]
        [SerializeField] private bool _drawOnScreen;
        [SerializeField] private TextureType _textureToDraw;
        [SerializeField] private Channel _channelToDraw;
        [Range(0f, 1f)]
        [SerializeField] private float _slice;

        private ICloudGenerator[] _cloudGenerators;
        
        private Material _material;

        private void Awake()
        {
            _cloudGenerators ??= GetComponents<ICloudGenerator>();

            foreach (ICloudGenerator cloudGenerator in _cloudGenerators)
            {
                cloudGenerator.Generate();
            }
        }

        private void OnRenderImage(RenderTexture src, RenderTexture dest)
        {
            // Ensuring that all necessary stuff is on place
            PokeDependencies();
            
            SendSettings(_material);

            Graphics.Blit(src, dest, _material);
        }

        private void PokeDependencies()
        {
            _material ??= new Material(_shader);
            
            _cloudGenerators ??= GetComponents<ICloudGenerator>();
            
            foreach (ICloudGenerator cloudGenerator in _cloudGenerators)
            {
                cloudGenerator.Apply(_material);
            }
        }
        
        private void SendSettings(Material material)
        {
            material.SetTexture(BlueNoiseTex, _blueNoise);
            material.SetFloat(NoiseScale, _noiseScale);
            material.SetFloat(WeatherMapScale, _weatherMapScale);
            material.SetFloat(Density, _density);
            material.SetFloat(Coverage, _coverage);

            Vector3 halfScale = _volume.localScale * 0.5f;
            material.SetVector(BoundsMin, _volume.position - halfScale);
            material.SetVector(BoundsMax, _volume.position + halfScale);
            
            material.SetInt(Steps, _steps);
            material.SetFloat(ExtinctionFactor, _extinctionFactor);
            material.SetFloat(ScatteringFactor, _scatteringFactor);
            
            material.SetInt(LightSteps, _lightSteps);
            material.SetFloat(LightAbsorbtionThroughCloud, _lightAbsorbtionThroughCloud);
            material.SetFloat(LightAbsorbtionTowardsSun, _lightAbsorbtionTowardsSun);
            material.SetFloat(DarknessThreshold, _darknessThreshold);
            
            material.SetVector(PhaseParams, new Vector4(_forwardScattering, _backScattering, _baseBrightness, _phaseFactor));
            
            material.SetKeyword("DRAW_ON_SCREEN", _drawOnScreen);
            material.SetInt(TextureToDraw, (int)_textureToDraw);
            material.SetInt(ChannelToDraw, (int)_channelToDraw);
            material.SetFloat(Slice, _slice);
        }
    }
}