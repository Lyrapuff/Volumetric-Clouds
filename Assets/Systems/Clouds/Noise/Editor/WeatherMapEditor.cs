using UnityEditor;
using UnityEngine;

namespace VolumetricRendering.Clouds.Noise.Editor
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
                if (target is IWeatherMap weatherMap)
                {
                    weatherMap.UpdateMap();
                }
            }
        }
    }
}