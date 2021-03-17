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
            
            v2f vert(appdata v)
            {
                v2f o;
                
                o.vertex = UnityObjectToClipPos(v.vertex);
                o.uv = v.uv;

                float3 viewVector = mul(unity_CameraInvProjection, float4(v.uv * 2 - 1, 0, -1));
                viewVector = mul(unity_CameraToWorld, float4(viewVector, 0));

                o.viewVector = viewVector;
                
                return o;
            }
            
            sampler2D _MainTex;
            sampler2D _CameraDepthTexture;

            Texture3D<float4> ShapeNoiseTex;
            SamplerState samplerShapeNoiseTex;
            Texture3D<float4> DetailNoiseTex;
            SamplerState samplerDetailNoiseTex;
            Texture2D<float4> WeatherMapTex;
            SamplerState samplerWeatherMapTex;
            Texture2D<float4> BlueNoiseTex;
            SamplerState samplerBlueNoiseTex;
            
            float NoiseScale;
            float WeatherMapScale;
            float Density;
            float Coverage;

            float3 BoundsMin;
            float3 BoundsMax;
            
            int Steps;
            float ExtinctionFactor;
            float ScatteringFactor;

            int LightSteps;
            float LightAbsorbtionThroughCloud;
            float LightAbsorbtionTowardsSun;
            float DarknessThreshold;

            float4 PhaseParams;

            int TextureToDraw;
            int ChannelToDraw;
            float Slice;

            struct IntersectionInfo
            {
                float dstToVolume;
                float dstInside;
            };

            float remap(float v, float minNew, float maxNew, float minOld, float maxOld)
            {
                return minNew + (v-minOld) * (maxNew - minNew) / (maxOld-minOld);
            }

            float2 squareUV(float2 uv)
            {
                float width = _ScreenParams.x;
                float height =_ScreenParams.y;
                //float minDim = min(width, height);
                float scale = 1000;
                float x = uv.x * width;
                float y = uv.y * height;
                return float2 (x/scale, y/scale);
            }
            
            // Returns (dstToBox, dstInsideBox). If ray misses box, dstInsideBox will be zero
            IntersectionInfo tryIntersectVolume(float3 ro, float3 rd)
            {
                const float sr = 80000;
                const float3 sc = float3(0, -40000, 0);

                IntersectionInfo intersectionInfo;
                intersectionInfo.dstToVolume = -1;
                intersectionInfo.dstInside = -1;

                float a = dot(rd, rd);
                float b = -1 * dot(sc, rd);
                float c = dot(sc, sc)-sr*sr;

                float det = b*b-4*a*c;

                if (a < 0 || det < 0)
                {
                    return intersectionInfo;
                }

                float x1 = sqrt(det)/(2*a);
                float t1 = -b+x1;
                float t2 = -b-x1;
                
                intersectionInfo.dstToVolume = t1;
                intersectionInfo.dstInside = 650;

                return intersectionInfo;
            }

            // Henyey-Greenstein's phase function
            float hg(float dotAngle, float g)
            {
                float g2 = g * g;
                return (1 - g2) / (4 * 3.1416 * pow(1 + g2 - 2 * g * dotAngle, 1.5));
            }

            float phase (float dotAngle)
            {
                float hgBlend = hg(dotAngle, PhaseParams.x) * 0.5 + hg(dotAngle, -PhaseParams.y) * 0.5;
                return PhaseParams.z + hgBlend * PhaseParams.w;
            }
            
            float sampleDensity (float3 pos)
            {
                float3 uvw = pos / NoiseScale;
                
                float4 shape = ShapeNoiseTex.SampleLevel(samplerShapeNoiseTex, uvw / NoiseScale, 0);
                float density = remap(shape.r, shape.g * 0.625 + shape.b * 0.25 + shape.a * 0.125 - 1, 1, 0 ,1);

                float2 weatherPos = pos.xz;
                float4 weather = WeatherMapTex.SampleLevel(samplerWeatherMapTex, weatherPos / WeatherMapScale, 0);
                
                return density * Density * weather.r;
            }

            float computeSunTransmittence(float3 pos)
            {
                IntersectionInfo intersectionInfo = tryIntersectVolume(pos, _WorldSpaceLightPos0);

                float stepSize = intersectionInfo.dstInside / LightSteps;

                float totalDensity = 0;

                for (int i = 0; i < LightSteps; i++)
                {
                    pos += _WorldSpaceLightPos0 * stepSize;
                    
                    totalDensity += max(0, sampleDensity(pos) * stepSize);
                }
                
                return exp(-LightAbsorbtionTowardsSun * totalDensity);
            }
            
            float4 drawOnScreen(float2 uv)
            {
                float4 sample = 0;

                if (TextureToDraw == 0)
                {
                    sample = ShapeNoiseTex.SampleLevel(samplerShapeNoiseTex, float3(uv, Slice), 0);
                }
                if (TextureToDraw == 1)
                {
                    sample = DetailNoiseTex.SampleLevel(samplerDetailNoiseTex, float3(uv, Slice), 0);
                }
                if (TextureToDraw == 2)
                {
                    sample = WeatherMapTex.SampleLevel(samplerWeatherMapTex, float3(uv, Slice), 0);
                }

                float4 noise = 0;

                if (ChannelToDraw == 0)
                {
                    noise = sample;
                }
                if (ChannelToDraw == 1)
                {
                    noise = sample.r;
                }
                if (ChannelToDraw == 2)
                {
                    noise = sample.g;
                }
                if (ChannelToDraw == 3)
                {
                    noise = sample.b;
                }
                if (ChannelToDraw == 04)
                {
                    noise = sample.a;
                }
                
                return noise;
            }
            
            float4 frag(v2f i) : SV_Target
            {
                #ifdef DRAW_ON_SCREEN
                    return drawOnScreen(i.uv);
                #else
                    float3 rayOrigin = _WorldSpaceCameraPos.xyz;
                    float3 rayDir = normalize(i.viewVector);
                    
                    IntersectionInfo intersectionInfo = tryIntersectVolume(rayOrigin, rayDir);

                    if (intersectionInfo.dstInside == -1)
                    {
                        return tex2D(_MainTex, i.uv);
                    }
                    
                    float3 hitPos = rayOrigin + rayDir * intersectionInfo.dstToVolume;
                    //float steps = lerp(Steps, 15, clamp(intersectionInfo.dstToVolume / 3000, 0, 1));
                    float stepSize = intersectionInfo.dstInside / Steps;

                    float randomOffset = BlueNoiseTex.SampleLevel(samplerBlueNoiseTex, squareUV(i.uv * 3), 0);
                    randomOffset *= 3;
                    
                    float cosAngle = dot(rayDir, _WorldSpaceLightPos0.xyz);
                    float phaseVal = phase(cosAngle);
                    
                    float dstTraveled = randomOffset;

                    float transmittance = 1;
                    float3 lightEnergy = 0;
                    
                    while (dstTraveled < intersectionInfo.dstInside)
                    {
                        float3 currentPos = hitPos + rayDir * dstTraveled;
                        
                        float density = sampleDensity(currentPos) * stepSize;

                        if (density > 0)
                        {
                            float transmittanceAtPoint = computeSunTransmittence(currentPos);
                            
                            transmittance *= exp(-density * LightAbsorbtionThroughCloud);
                            
                            lightEnergy += density * transmittance * transmittanceAtPoint * phaseVal;

                            if (transmittance < 0.01)
                            {
                                break;
                            }
                        }
                        
                        dstTraveled += stepSize;
                    }
                    
                    float4 backGroundCol = tex2D(_MainTex, i.uv);

                    float blending = lerp(0.15, 1, saturate(1 - dot(rayDir, float3(0, 2, 0))));
                    
                    float4 cloudCol = float4(lightEnergy * _LightColor0 * backGroundCol * (1 - blending) + backGroundCol * blending * (1 - transmittance), 0);
                    float4 col = backGroundCol * transmittance + cloudCol;
                    
                    return col;
                #endif
            }
            ENDCG
        }
    }
}