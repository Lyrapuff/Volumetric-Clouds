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
            
            #include "UnityCG.cginc"
            #include "UnityLightingCommon.cginc"
            #include "Assets/Lib/Shaders/Snoise.cginc"

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

                float3 viewVector = mul(unity_CameraInvProjection, float4(v.uv * 2 - 1, 0, -1));
                o.viewVector = mul(unity_CameraToWorld, float4(viewVector, 0));
                
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

            // x is the nearRadius
            // y is the farRadius
            float2 VolumeSettings;
            
            int Steps;
            float Distance;
            float ExtinctionFactor;
            float ScatteringFactor;

            int LightSteps;
            float LightAbsorbtion;

            float4 PhaseParams;

            struct HitInfo
            {
                float dstToVolume;
                float dstInside;
            };

            HitInfo tryHitVolume(float3 rayOrigin, float3 rayDir)
            {
                HitInfo hitInfo;
                
                hitInfo.dstToVolume = distance(rayOrigin, float3(0,0,0));
                hitInfo.dstInside = 1;
                
                return hitInfo;
            }
            
            float sampleDensity (float3 pos)
            {
                float3 samplePos = pos;
                
                //float density = ShapeNoiseTex.SampleLevel(samplerShapeNoiseTex, samplePos, 0);
                
                return 0;
            }

            float4 frag (v2f i) : SV_Target
            {
                float4 col = tex2D(_MainTex, i.uv);

                float3 rayOrigin = _WorldSpaceCameraPos;
                float3 rayDir = normalize(i.viewVector);
                
                return col;
            }
            ENDCG
        }
    }
}