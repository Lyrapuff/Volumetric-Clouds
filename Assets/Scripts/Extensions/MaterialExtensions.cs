using UnityEngine;

namespace Systems.Extensions
{
    public static class MaterialExtensions
    {
        public static void SetKeyword(this Material material, string keyword, bool enabled)
        {
            if (enabled)
            {
                material.EnableKeyword(keyword);
            }
            else
            {
                material.DisableKeyword(keyword);
            }
        }
    }
}