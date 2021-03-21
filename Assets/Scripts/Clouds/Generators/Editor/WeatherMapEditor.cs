using UnityEditor;
using UnityEngine;

namespace VolumetricRendering.Clouds.Generators.Editor
{
    [CustomEditor(typeof(WeatherMap))]
    public class WeatherMapEditor : UnityEditor.Editor
    {
        public override void OnInspectorGUI()
        {
            base.OnInspectorGUI();

            EditorGUILayout.Space();
            
            if (GUILayout.Button("Update Weather Map"))
            {
                if (target is ICloudGenerator weatherMap)
                {
                    weatherMap.Generate();
                }
            }
        }
    }
}