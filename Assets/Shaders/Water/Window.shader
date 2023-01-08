Shader "Unlit/Window"
{
    Properties
    {
        _MainTex("Texture", 2D) = "white" {}
        _SkyTex("Sky", CUBE) = "white" {}
        _Size("Size", float) = 1
        _T("Time", float) = 1
        _Distortion("Distortion", range(-5,5)) = 1
        _Blur("Blur", range(0,1)) = 1
        _Samples("Samples", int) = 4
    }
    SubShader
    {
        Tags { "RenderType"="Opaque" "Queue" = "Transparent"}
        LOD 100

        GrabPass {"_GrabTexture"}

        Pass
        {
            Cull Off
            CGPROGRAM
            #pragma vertex vert
            #pragma fragment frag
            // make fog work
            #pragma multi_compile_fog
            #define S(a,b,t) smoothstep(a,b,t)
            #include "UnityCG.cginc"

            struct appdata
            {
                float4 vertex : POSITION;
                float2 uv : TEXCOORD0;
            };

            struct v2f
            {
                float2 uv : TEXCOORD0;
                float4 grabUv : TEXCOORD1;
                UNITY_FOG_COORDS(1)
                float4 vertex : SV_POSITION;
            };

            sampler2D _MainTex, _GrabTexture;
            float4 _MainTex_ST;
            float _Size, _T, _Distortion, _Blur;
            int _Samples;

            v2f vert (appdata v)
            {
                v2f o;
                o.vertex = UnityObjectToClipPos(v.vertex);
                o.uv = TRANSFORM_TEX(v.uv, _MainTex);
                o.grabUv = UNITY_PROJ_COORD(ComputeGrabScreenPos(o.vertex));

                UNITY_TRANSFER_FOG(o,o.vertex);
                return o;
            }

            float N21(float2 p)
            {
                p = frac(p * float2(123.34, 345.45));
                p += dot(p, p + 34.345);
                return frac(p.x * p.y);
            }

            float3 Layer(float2 UV, float t)
            {
                float2 aspect = float2(2, 1);
                float2 uv = UV * _Size*aspect;
                uv.y += t * .25;
                float2 gv = frac(uv)-.5;

                float2 id = floor(uv);

                float n = N21(id);
                t += n*6.3;

                float w = UV.y * 10;
                float y = sin(t+ sin(t + sin(t) * 0.5)) * -0.45;
                float x = (n - .5) * .8;
                x += (.4 - abs(x)) * sin(3 * w) * pow(sin(w), 6) * .45;
                y -= (gv.x-x) * (gv.x-x); //drop shape sag
                
                float2 dropPos = (gv - float2(x, y)) / aspect;
                float drop = S(.05, .03, length(dropPos));

                float2 trailPos = (gv - float2(x, t * .25)) / aspect;
                trailPos.y = (frac(trailPos.y * 8) - .5 )/8;
                float trail = S(.03, .01, length(trailPos));

                float fogTrail = S(-.05, .05, dropPos.y);
                fogTrail *= S(.5, y, gv.y); //trail fade
                trail *= fogTrail;
                fogTrail *= S(.05, .04, abs(dropPos.x));

                float2 offset = drop*dropPos + trail*trailPos;

                return float3 (offset, fogTrail);
            }

            fixed4 frag(v2f i) : SV_Target
            {
                float t = fmod(_Time.y + _T, 7200);

                float4 col = 0;

                float3 drops = Layer(i.uv, t);
                drops += Layer(i.uv*1.2+7, t); //repeat line + change magic nums for more layers
                
                float fade = 1-saturate(fwidth(i.uv)*50);
                
                float blur = _Blur * 7 * (1 - drops.z * fade);
                
                //col = tex2Dlod(_MainTex, float4(i.uv + drops.xy * _Distortion, 0, blur));

                float2 projUv = i.grabUv.xy / i.grabUv.w;
                projUv += drops.xy * _Distortion * fade;
                blur *= .01;

                //const float numSamples = 30;
                float a = N21(i.uv)*6.28;
                float step = 6.28 / _Samples;
                for (float i = 0; i < _Samples; i++)
                {
                    float2 offs = float2(sin(a), cos(a)) * blur;
                    float d = frac(sin((i + 1) * 546) * 5424);
                    d = sqrt(d);
                    offs *= d;
                    col += tex2D(_GrabTexture, projUv + offs);
                    a += step;
                }
                col /= _Samples;

                //col = tex2D(_GrabTexture, projUv);
                //col *= 0; col += fade;

                return col;
            }
            ENDCG
        }
    }
}
