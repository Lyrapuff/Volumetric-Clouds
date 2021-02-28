using UnityEngine;

namespace VolumetricRendering.Clouds.Noise
{
    [CreateAssetMenu(menuName = "Clouds/Noise/Worley Noise settings", fileName = "New WorleyNoiseSettings")]
    public class WorleyNoiseSettings : ScriptableObject
    {
        public ComputeShader ComputeShader => _computeShader;
        public int PointCount => _pointCount;

        [Header("References")] 
        [SerializeField] private ComputeShader _computeShader;
        [Header("Settings")]
        [SerializeField] private int _pointCount;
    }
}