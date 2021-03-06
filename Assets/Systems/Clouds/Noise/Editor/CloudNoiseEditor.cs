using UnityEditor;
using UnityEngine;

namespace VolumetricRendering.Clouds.Noise.Editor
{
    [CustomEditor(typeof(CloudNoise))]
    public class CloudNoiseEdior : UnityEditor.Editor
    {
        public override void OnInspectorGUI()
        {
            base.OnInspectorGUI();

            EditorGUILayout.Space();
            
            if (GUILayout.Button("Update Noise"))
            {
                if (target is ICloudNoise cloudNoise)
                {
                    cloudNoise.UpdateNoise();
                }
            }
        }
    }
}