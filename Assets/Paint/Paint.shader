Shader "Custom/Paint"
{
    Properties
    {
        _Color ("Color", Color) = (1,1,1,1)
        _MainTex ("Albedo (RGB)", 2D) = "white" {}
        [Normal]_NormalTex("Normal map", 2D) = "white" {}
        _OcclusionTex("Occlusion map", 2D) = "white" {}
        _MetallicTex("Metallic map", 2D) = "black" {}
        _Metallic("Metallic", Range(0,1)) = 0.0
        _Glossiness("Glossiness", Range(0,1)) = 0.5

        _PaintGlossiness("Paint Glossiness", Range(0,1)) = 0.5
        _PaintSmooth("Paint Smoothness", Range(0,1)) = 0.1
        _PaintIntensity("Paint Intensity", Range(0,1)) = 1
        _PaintColor("Paint Color", Color) = (1,0,0,0.5)
        _PaintTex("Paint", 2D) = "white" {}
        _PaintMetallic("Paint Metallic", Range(0,1)) = 0.0
        _PaintBlur("Paint Blur", Range(0,5)) = 1.0
        _PaintDisplacement("Paint Displacement", Range(-0.1,0.1)) = 0
        _PaintBumpStrength("Paint Bump Strength", Range(0,1)) = 0.1
        _PaintBumpSmooth("Paint Bump Smoothing", Range(1,100)) = 10
        _PaintMinDepth("Paint Min Depth", Range(0,1)) = 0
        _PaintViscosity("Paint Viscosity", Range(0,1)) = 1
    }
    SubShader
    {
        Tags { "RenderType" = "Opaque" }
        LOD 300

        //Pass
        //{
        //    Name "Paint Pass"
        //    CGPROGRAM
        //    #include "UnityCustomRenderTexture.cginc" m
        //    #pragma vertex CustomRenderTextureVertexShader
        //    #pragma fragment frag
        //    #pragma target 3.0

        //    float4      _PaintColor;
        //    sampler2D   _Paint;

        //    float4 frag(v2f_customrendertexture IN) : COLOR
        //    {
        //        fixed4 col = 0;
        //        col.rg = IN.localTexcoord.xy;
        //        col.a = 0.5 ;
        //        return col;
        //        //return _PaintColor * tex2D(_Paint, IN.localTexcoord.xy);
        //    }
        //    ENDCG
        //}

        CGPROGRAM
        // Physically based Standard lighting model, and enable shadows on all light types
        #pragma surface surf Standard fullforwardshadows

        // Use shader model 3.0 target, to get nicer looking lighting
        #pragma target 3.0

        sampler2D _MainTex, _NormalTex, _OcclusionTex, _MetallicTex, _PaintTex;

        struct Input
        {
            float2 uv_MainTex;
            float2 uv_NormalTex;
            float2 uv_MetallicTex;
            float2 uv_OcclusionTex;
            float2 uv_PaintTex;
        };

        half _Glossiness;
        fixed4 _Color;
        half _Metallic;

        half _PaintGlossiness;
        float _PaintSmooth;
        float _PaintIntensity;
        float4 _PaintColor;
        half _PaintMetallic;
        float _PaintBlur;
        float _PaintDisplacement;
        float _PaintBumpStrength;
        float _PaintBumpSmooth;
        float4 _PaintTex_TexelSize;
        float _PaintMinDepth;
        float _PaintViscosity;

        // Add instancing support for this shader. You need to check 'Enable Instancing' on materials that use the shader.
        // See https://docs.unity3d.com/Manual/GPUInstancing.html for more information about instancing.
        // #pragma instancing_options assumeuniformscaling
        UNITY_INSTANCING_BUFFER_START(Props)
            // put more per-instance properties here
        UNITY_INSTANCING_BUFFER_END(Props)

        void surf (Input IN, inout SurfaceOutputStandard o)
        {
            //paint
            float paint = tex2D(_PaintTex, IN.uv_PaintTex);
            float paintMask = smoothstep(0, _PaintSmooth, paint) * _PaintIntensity;
            float mainMask = 1 - paintMask;


            //paint normal vector from bump map
            float2 dist = _PaintTex_TexelSize * _PaintBumpSmooth;
            float u1 = tex2D(_PaintTex, float2(IN.uv_PaintTex.x - dist.x, IN.uv_PaintTex.y));
            float u2 = tex2D(_PaintTex, float2(IN.uv_PaintTex.x + dist.x, IN.uv_PaintTex.y));
            float v1 = tex2D(_PaintTex, float2(IN.uv_PaintTex.x, IN.uv_PaintTex.y - dist.y));
            float v2 = tex2D(_PaintTex, float2(IN.uv_PaintTex.x, IN.uv_PaintTex.y + dist.y));
            float3 uGradient = float3(2 * dist.x, 0, (u2 - u1) * _PaintBumpStrength);
            float3 vGradient = float3(0, 2 * dist.y, (v2 - v1) * _PaintBumpStrength);
            float3 paintNormal = normalize(cross(uGradient, vGradient));

            //thicker paint == more blur
            float paintBlur = _PaintBlur * paint;
            float paintDisplacement = _PaintDisplacement * (paint - 0.5);

            //main material
            float2 mainUV = IN.uv_MainTex + paintDisplacement * paintMask;
            fixed4 c = tex2Dlod(_MainTex, float4(mainUV, 0, paintBlur)) * _Color;
            float3 mainNormal = UnpackNormal(tex2D(_NormalTex, IN.uv_MainTex));

            //seethrogh paint
            o.Albedo.rgb = (_PaintColor.rgb * _PaintColor.a + c.rgb * (1 - _PaintColor.a))* paintMask;

            //main mat under paint
            o.Albedo.rgb += c.rgb * mainMask;

            

            //Metallic and smoothness come from slider variables
            //o.Metallic = _Metallic;
            
            float metallic = tex2D(_MetallicTex, IN.uv_MetallicTex).a;
            o.Smoothness = _Glossiness * mainMask + _PaintGlossiness * paintMask;
            o.Alpha = c.a;
            o.Normal = normalize(mainNormal * mainMask + paintNormal * paintMask);
            o.Occlusion = tex2D(_OcclusionTex, IN.uv_MainTex) * mainMask + paintMask;
            o.Metallic = metallic * _Metallic * mainMask + _PaintMetallic * paintMask;
        }
        ENDCG
    }
    FallBack "Diffuse"
}
