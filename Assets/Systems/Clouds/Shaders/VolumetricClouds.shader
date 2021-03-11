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
            Texture3D<float4> WeatherMapTex;
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

            float remap (float v, float minOld, float maxOld, float minNew, float maxNew)
            {
                return minNew + (v-minOld) * (maxNew - minNew) / (maxOld-minOld);
            }

            float2 squareUV (float2 uv)
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
            IntersectionInfo tryIntersectVolume(float3 rayOrigin, float3 rayDir)
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

            // Henyey-Greenstein's phase function
            float hg (float dotAngle, float g)
            {
                float g2 = g * g;
                return (1 - g2) / (4 * 3.1416 * pow(1 + g2 - 2 * g * dotAngle, 1.5));
            }

            float phase (float dotAngle)
            {
                float firstHg = PhaseParams.z * pow(saturate(dotAngle), 0.1);
                float secondHg = hg(dotAngle, PhaseParams.x);

                float inScatterHg = max(firstHg, secondHg);
                float outScatterHg = hg(dotAngle, -PhaseParams.y);
                
                return lerp(inScatterHg, outScatterHg, PhaseParams.w);
            }
            
            float sampleDensity (float3 pos)
            {
                float3 size = BoundsMax - BoundsMin;
                float3 uvw = (size * .5 + pos) / NoiseScale;

                float factor = sin((pos.y - BoundsMin.y) / size.y * 3.1416);
                
                float4 shapeSample = ShapeNoiseTex.SampleLevel(samplerShapeNoiseTex, uvw / NoiseScale, 0);

                float density = shapeSample.r * 0.575 + shapeSample.g * 0.22 + shapeSample.b * 0.13 + shapeSample.a * 0.075;

                float4 weatherSample = WeatherMapTex.SampleLevel(samplerWeatherMapTex, pos / WeatherMapScale, 0);
                
                return density * Density * weatherSample * factor;
            }

            float computeSunTransmittence (float3 pos)
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
            
            float4 drawOnScreen (float2 uv)
            {
                float4 sample = 0;

                if (TextureToDraw == 0)
                {
                    sample = ShapeNoiseTex.SampleLevel(samplerShapeNoiseTex, float3(uv, Slice), 0) * Density;
                }
                if (TextureToDraw == 1)
                {
                    sample = DetailNoiseTex.SampleLevel(samplerDetailNoiseTex, float3(uv, Slice), 0) * Density;
                }
                if (TextureToDraw == 2)
                {
                    sample = WeatherMapTex.SampleLevel(samplerWeatherMapTex, float3(uv, Slice), 0) * Density;
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
            
            float4 frag (v2f i) : SV_Target
            {
                #ifdef DRAW_ON_SCREEN
                    return drawOnScreen(i.uv);
                #endif
                
                float4 col = tex2D(_MainTex, i.uv);

                float3 rayOrigin = _WorldSpaceCameraPos;
                float3 rayDir = normalize(i.viewVector);

                IntersectionInfo intersectionInfo = tryIntersectVolume(rayOrigin, rayDir);
                
                float3 hitPos = rayOrigin + rayDir * intersectionInfo.dstToVolume;
                float steps = lerp(Steps, 15, clamp(intersectionInfo.dstToVolume / 3000, 0, 1));
                float stepSize = intersectionInfo.dstInside / steps;

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

                float4 atmosphereColor = float4(0.7, 0.6, 0.3, 1);
                float atmosphereFactor = dot(rayDir, float3(0, 1, 0));
                
                float4 cloudColor = float4(lightEnergy * _LightColor0, atmosphereFactor);
                
                return col * transmittance + cloudColor * (atmosphereColor + atmosphereFactor);
            }
            ENDCG
        }
    }
}