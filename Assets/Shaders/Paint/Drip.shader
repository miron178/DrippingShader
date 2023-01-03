Shader "Unlit/Drip"
{
    Properties
    {
        _PaintTex ("Texture", 2D) = "white" {}
        _PaintMinDepth("Paint Min Depth", Range(0,1)) = 0.4
        _PaintViscosity("Paint Viscosity", Range(0,1)) = 0.99
    }

    SubShader
    {
         Lighting Off
         Blend One Zero

        Pass
        {
            name "Drip pass"
            CGPROGRAM
            #include "UnityCustomRenderTexture.cginc"
            #pragma vertex CustomRenderTextureVertexShader
            #pragma fragment frag
            #pragma target 3.0

            float4 _PaintTex_TexelSize;
            float _PaintMinDepth;
            float _PaintViscosity;

            float4 frag(v2f_customrendertexture IN) : COLOR
            {
                float texelHeight = 1 / _CustomRenderTextureHeight;
                float paintLevelHere = tex2D(_SelfTexture2D, IN.localTexcoord.xy);
                float paintLevelAbove = tex2D(_SelfTexture2D, float2(IN.localTexcoord.x, IN.localTexcoord.y + texelHeight));
                if (IN.localTexcoord.y + texelHeight >= 1)
                    paintLevelAbove = 0;
                float paintLevelBelow = tex2D(_SelfTexture2D, float2(IN.localTexcoord.x, IN.localTexcoord.y - texelHeight));
                float paintSpeed = 1 - _PaintViscosity;

                //move paint from above to here
                float availablePaint = max(paintLevelAbove - _PaintMinDepth, 0);
                float availableSpace = 1 - paintLevelHere;
                float movePaint = min(paintSpeed, min(availablePaint, availableSpace));

                //move paint from here to below
                availablePaint = max(paintLevelHere - _PaintMinDepth, 0);
                availableSpace = 1 - paintLevelBelow;
                movePaint -= min(paintSpeed, min(availablePaint, availableSpace));

                //return remaining paint here
                return paintLevelHere + movePaint;
            }
            ENDCG
        }
    }
}
