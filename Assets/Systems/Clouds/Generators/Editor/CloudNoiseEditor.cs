using UnityEditor;
using UnityEngine;

namespace VolumetricRendering.Clouds.Generators.Editor
{
    [CustomEditor(typeof(ShapeNoiseGenerator))]
    public class CloudNoiseEdior : UnityEditor.Editor
    {
        public override void OnInspectorGUI()
        {
            base.OnInspectorGUI();

            EditorGUILayout.Space();
            
            if (GUILayout.Button("Update Noise"))
            {
                if (target is ICloudGenerator cloudNoise)
                {
                    cloudNoise.Generate();
                }
            }
        }
    }
}