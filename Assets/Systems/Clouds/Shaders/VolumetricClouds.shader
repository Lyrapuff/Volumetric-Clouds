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
            #include "Assets/Shaders/Snoise.cginc"

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

            sampler2D NoiseTex;
            
            float NoiseScale;
            float Density;
            float Coverage;
            float MinHeight;
            float MaxHeight;
            
            int Steps;
            float Distance;
            float ExtinctionFactor;
            float ScatteringFactor;

            int LightSteps;
            float LightAbsorbtion;

            float4 PhaseParams;

            int DrawOnScreen;

            float sampleDensity (float3 pos)
            {
                float factor = saturate(exp(pos.y - MinHeight));

                if (pos.y > MaxHeight)
                {
                    factor = saturate(exp(-pos.y + MaxHeight));
                }
                
                return min(saturate(snoise(pos / NoiseScale )), Coverage) * factor * Density;
            }

            float3 computeSunColor (float3 pos)
            {
                float3 rayOrigin = _WorldSpaceLightPos0;
                float3 dir = pos - rayOrigin;
                float dst = length(dir);
                float3 rayDir = normalize(dir);

                float stepSize = dst / LightSteps;
                float dstTraveled = 0;

                float totalDensity = 0;
                
                while (dstTraveled < dst)
                {
                    float3 marchPos = rayOrigin + rayDir * dstTraveled;
                    
                    float densityAtPoint = sampleDensity(marchPos);
                    totalDensity += densityAtPoint * stepSize; 
                    
                    dstTraveled += stepSize;
                }

                return exp(-totalDensity * LightAbsorbtion) * _LightColor0;
            }

            // Henyey-Greenstein
            float hg (float a, float g)
            {
                float g2 = g * g;
                return (1 - g2) / (4 * UNITY_PI * pow(1 + g2 - 2 * g * a, 1.53));
            }
            
            float phase (float a)
            {
                float blend = 0.5;
                float hgBlend = hg(a, PhaseParams.x) * (1 - blend) + hg(a, -PhaseParams.y) * blend;
                return PhaseParams.z + hgBlend * PhaseParams.w;
            }

            float4 drawOnScreen(float2 uv)
            {
                float4 noiseCol = tex2D(NoiseTex, uv);
                
                return noiseCol;
            }
            
            float4 frag (v2f i) : SV_Target
            {
                float4 col = tex2D(_MainTex, i.uv);
                
                if (DrawOnScreen == 1)
                {
                    // TODO
                    //col = drawOnScreen(i.uv);
                }
                
                float3 rayOrigin = _WorldSpaceCameraPos;
                
                float3 rayDir = normalize(i.viewVector);

                float viewLength = length(i.viewVector);

                float depth = SAMPLE_DEPTH_TEXTURE(_CameraDepthTexture, i.uv);
                float linearDepth = LinearEyeDepth(depth) * viewLength;

                const float stepSize = Distance / Steps;
                float dstTraveled = 0;

                float cosAngle = dot(rayDir, _WorldSpaceLightPos0.xyz);
                float phaseVal = phase(cosAngle);
                
                float extinction = 1;
                float3 scattering = 0;
                
                while (dstTraveled < min(linearDepth, Distance))
                {
                    float3 pos = rayOrigin + rayDir * dstTraveled;
                    
                    float densityAtPoint = sampleDensity(pos);
                    float extinctionCoef = ExtinctionFactor * densityAtPoint;
                    float scatteringCoef = ScatteringFactor * densityAtPoint;

                    extinction *= exp(-extinctionCoef * stepSize);

                    float3 sunColor = computeSunColor(pos);
                    float3 stepScattering = scatteringCoef * stepSize * (phaseVal * sunColor);

                    scattering += extinction * stepScattering;
                    
                    dstTraveled += stepSize;
                }
                
                return col * extinction + float4(scattering, 0);
            }
            ENDCG
        }
    }
}