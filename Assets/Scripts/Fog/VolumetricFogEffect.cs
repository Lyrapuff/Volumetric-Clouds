using UnityEngine;

namespace VolumetricFog.Fog
{
    [ExecuteInEditMode]
    public class VolumetricFogEffect : MonoBehaviour
    {
        [SerializeField] private Shader _shader;

        private Material _material;

        private void OnRenderImage(RenderTexture src, RenderTexture dest)
        {
            if (_material == null)
            {
                _material = new Material(_shader);
            }

            Graphics.Blit(src, dest, _material);
        }
    }
}