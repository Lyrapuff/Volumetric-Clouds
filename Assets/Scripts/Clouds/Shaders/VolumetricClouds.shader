﻿Shader "Hidden/VolumetricClouds"
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

            float4 CloudTopColor;
            float4 CloudBottomColor;
            
            Texture3D<float4> ShapeNoiseTex;
            SamplerState samplerShapeNoiseTex;
            Texture3D<float4> DetailNoiseTex;
            SamplerState samplerDetailNoiseTex;
            Texture3D<float4> WeatherMapTex;
            SamplerState samplerWeatherMapTex;
            Texture2D<float4> BlueNoiseTex;
            SamplerState samplerBlueNoiseTex;

            // x - radius, y - y offset
            float2 VolumeParams;
            float NoiseScale;
            float WeatherMapScale;
            float Density;
            float Coverage;
            
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
                float height = _ScreenParams.y;
                //float minDim = min(width, height);
                float scale = 1000;
                float x = uv.x * width;
                float y = uv.y * height;
                return float2 (x/scale, y/scale);
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

            float beerLaw(float opticalDepth)
            {
                return exp(-LightAbsorbtionTowardsSun * opticalDepth);
            }

            float intersectSphere(float sr, float3 sc, float3 ro, float3 rd)
            {
                const float3 oc = ro - sc;
                
                const float a = dot(rd, rd);
                const float b = 2 * dot(oc, rd);
                const float c = dot(oc, oc)-sr*sr;

                const float det = b*b-4*a*c;

                if (det < 0)
                {
                    return -1;
                }
                
                const float x1 = sqrt(det)/a;
                const float t1 = -b+x1;

                return t1 < 0 ? -1 : t1;
            }
            
            IntersectionInfo tryIntersectVolume(float3 ro, float3 rd)
            {
                const float s1r = VolumeParams.x;
                const float3 s1c = float3(ro.x, VolumeParams.y, ro.z);

                const float s2r = s1r + ExtinctionFactor;
                const float3 s2c = s1c;

                IntersectionInfo intersectionInfo;
                intersectionInfo.dstToVolume = -1;
                intersectionInfo.dstInside = -1;

                const float t1 = intersectSphere(s1r, s1c, ro, rd);
                const float t2 = intersectSphere(s2r, s2c, ro, rd);

                if (t1 == -1 || t2 == -1)
                {
                    return intersectionInfo;
                }
                
                intersectionInfo.dstToVolume = t1;
                intersectionInfo.dstInside = t2 - t1;

                return intersectionInfo;
            }

            float heightFrac(float3 pos, IntersectionInfo intersectionInfo)
            {
                return (pos.y - intersectionInfo.dstToVolume) / intersectionInfo.dstInside;
            }
            
            float sampleDensity (float3 pos)
            {
                float3 densityPos = pos / NoiseScale;
                
                float4 shape = ShapeNoiseTex.SampleLevel(samplerShapeNoiseTex, densityPos, 0);
                float density = remap(shape.r, shape.g * 0.625 + shape.b * 0.25 + shape.a * 0.125 - 1, 1, 0 ,1);

                float3 weatherPos = pos.xyz / WeatherMapScale;
                float4 weatherMap = WeatherMapTex.SampleLevel(samplerWeatherMapTex, weatherPos, 0);
                
                return density * Density * weatherMap.r;
            }

            float3 calculateAmbientLighting(float heightFrac)
            {
                return lerp(CloudBottomColor.rgb, CloudTopColor.rgb, heightFrac);
            }
            
            float computeTransmittence(float3 pos)
            {
                const float LightStepScale = 1;
                
                float stepSize = ScatteringFactor * LightStepScale / LightSteps;
                float3 step = _WorldSpaceLightPos0 * stepSize;
                
                pos += 0.5 * step;

                float totalDensity = 0;

                for (int i = 0; i < LightSteps; i++)
                {
                    pos += step;
                    
                    totalDensity += max(0, sampleDensity(pos) * stepSize);
                }
                
                return beerLaw(totalDensity);
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
                #endif
                
                float3 rayOrigin = _WorldSpaceCameraPos.xyz;
                float3 rayDir = normalize(i.viewVector);
                
                IntersectionInfo intersectionInfo = tryIntersectVolume(rayOrigin, rayDir);

                float depthSample = SAMPLE_DEPTH_TEXTURE(_CameraDepthTexture, i.uv);
                float depth = LinearEyeDepth(depthSample) * intersectionInfo.dstToVolume-10000000;

                if (intersectionInfo.dstInside == -1)
                {
                     return tex2D(_MainTex, i.uv);
                }

                if (intersectionInfo.dstInside > depth)
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

                float totalTransmittance = 1;
                float3 totalLightEnergy = 0;
            
                while (dstTraveled < intersectionInfo.dstInside)
                {
                    float3 currentPos = hitPos + rayDir * dstTraveled;
                    
                    float density = sampleDensity(currentPos) * stepSize;

                    if (density > 0)
                    {
                        float transmittance = computeTransmittence(currentPos);
                        
                        totalTransmittance *= exp(-density * LightAbsorbtionThroughCloud);

                        //float3 ambientLighting = calculateAmbientLighting( heightFrac(currentPos, intersectionInfo)) / Steps;
                        float3 ambientLighting = 1;
                        
                        totalLightEnergy += density * totalTransmittance * transmittance * phaseVal * ambientLighting;

                        if (totalTransmittance < 0.01)
                        {
                            break;
                        }
                    }
                    
                    dstTraveled += stepSize;
                }
                
                float4 backgroundCol = tex2D(_MainTex, i.uv);

                float blending = lerp(0, 1, saturate(1 - dot(rayDir, float3(0, 6, 0))));
            
                float4 cloudCol = float4(totalLightEnergy * _LightColor0 * (1 - blending) + backgroundCol * blending * (1 - totalTransmittance), 0);
                float4 col = backgroundCol * totalTransmittance + cloudCol;
                
                return col;
            }
            ENDCG
        }
    }
}