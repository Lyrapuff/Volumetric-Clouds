Shader "Hidden/VolumetricClouds"
{
    Properties
    {
        _MainTex ("Texture", 2D) = "white" {}
    }
    SubShader
    {
        Cull Off ZWrite Off ZTest Always

        Pass
        {
            CGPROGRAM
            #pragma vertex vert
            #pragma fragment frag
            #pragma shader_feature DRAW_ON_SCREEN
            
            #include "UnityCG.cginc"
            #include "UnityLightingCommon.cginc"

            struct appdata
            {
                float4 vertex : POSITION;
                float2 uv : TEXCOORD0;
            };

            struct v2f
            {
                float2 uv : TEXCOORD0;
                float4 vertex : SV_POSITION;
                float3 viewVector : TEXCOORD1;
            };
            
            v2f vert (appdata v)
            {
                v2f o;
                
                o.vertex = UnityObjectToClipPos(v.vertex);
                o.uv = v.uv;

                float3 viewVector = mul(unity_CameraInvProjection, float4(v.uv * 2.0 - 1.0, 0.0, -1.0));
                o.viewVector = mul(unity_CameraToWorld, float4(viewVector, 0.0));
                
                return o;
            }
            
            sampler2D _MainTex;
            sampler2D _CameraDepthTexture;

            Texture3D<float4> ShapeNoiseTex;
            SamplerState samplerShapeNoiseTex;
            Texture3D<float4> DetailNoiseTex;
            SamplerState samplerDetailNoiseTex;
            
            float NoiseScale;
            float Density;
            float Coverage;

            float3 BoundsMin;
            float3 BoundsMax;
            
            int Steps;
            float ExtinctionFactor;
            float ScatteringFactor;

            int LightSteps;
            float LightAbsorbtion;

            float4 PhaseParams;

            float Slice;

            struct IntersectionInfo
            {
                float dstToVolume;
                float dstInside;
            };

            // Returns (dstToBox, dstInsideBox). If ray misses box, dstInsideBox will be zero
            IntersectionInfo intersectVolume(float3 rayOrigin, float3 rayDir)
            {
                // Adapted from: http://jcgt.org/published/0007/03/04/
                float3 invRayDir = 1 / rayDir;
                float3 t0 = (BoundsMin - rayOrigin) * invRayDir;
                float3 t1 = (BoundsMax - rayOrigin) * invRayDir;
                float3 tmin = min(t0, t1);
                float3 tmax = max(t0, t1);
                
                float dstA = max(max(tmin.x, tmin.y), tmin.z);
                float dstB = min(tmax.x, min(tmax.y, tmax.z));

                // CASE 1: ray intersects box from outside (0 <= dstA <= dstB)
                // dstA is dst to nearest intersection, dstB dst to far intersection

                // CASE 2: ray intersects box from inside (dstA < 0 < dstB)
                // dstA is the dst to intersection behind the ray, dstB is dst to forward intersection

                // CASE 3: ray misses box (dstA > dstB)

                IntersectionInfo hitInfo;
                
                hitInfo.dstToVolume = max(0, dstA);
                hitInfo.dstInside = max(0, dstB - hitInfo.dstToVolume);
                
                return hitInfo;
            }
            
            float sampleDensity (float3 pos)
            {
                float3 size = BoundsMax - BoundsMin;
                float3 uvw = (size * .5 + pos) / NoiseScale;
                
                float4 density = ShapeNoiseTex.SampleLevel(samplerShapeNoiseTex, uvw, 0);
                
                return density;
            }

            float4 drawOnScreen (float2 uv)
            {
                float4 density = ShapeNoiseTex.SampleLevel(samplerShapeNoiseTex, float3(uv, Slice), 0) * Density;
                
                return density;
            }
            
            float4 frag (v2f i) : SV_Target
            {
                #ifdef DRAW_ON_SCREEN
                    return drawOnScreen(i.uv);
                #endif
                
                float4 col = tex2D(_MainTex, i.uv);

                float3 rayOrigin = _WorldSpaceCameraPos;
                float3 rayDir = normalize(i.viewVector);

                IntersectionInfo intersectionInfo = intersectVolume(rayOrigin, rayDir);
                
                float3 hitPos = rayOrigin + rayDir * intersectionInfo.dstToVolume;
                float stepSize = intersectionInfo.dstInside / Steps;
                
                float dstTraveled = 0.0;
                float totalDensity = 0.0;

                while (dstTraveled < intersectionInfo.dstInside)
                {
                    float3 currentPos = hitPos + rayDir * dstTraveled;
                    
                    float density = sampleDensity(currentPos);
                    totalDensity += density * stepSize;
                    
                    dstTraveled += stepSize;
                }
                
                return col * exp(-totalDensity);
            }
            ENDCG
        }
    }
}