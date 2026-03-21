// Copyright (c) Microsoft Corporation.
// Licensed under the MIT license.


#if OPENGL
    #define VS_SHADERMODEL vs_3_0
    #define PS_SHADERMODEL ps_3_0
#else
    #define VS_SHADERMODEL vs_4_0_level_9_1
    #define PS_SHADERMODEL ps_4_0_level_9_1
#endif

texture Mask;
float4 PosToUV;
float4 GlowColor;

sampler2D MaskSampler =
sampler_state
{
    Texture = <Mask>;
    MipFilter = Linear;
    MinFilter = Linear;
    MagFilter = Linear;

    AddressU = Clamp;
    AddressV = Clamp;
};


struct VS_INPUT
{
    float2 position : POSITION0;

};

struct PS_INPUT
{
    float4 position : POSITION0;
	float2 texcoord : TEXCOORD0;
};

PS_INPUT ColorVS(VS_INPUT input)
{
    PS_INPUT output;

    output.position.xy = input.position.xy;
    output.position.z = 0.0f;
    output.position.w = 1.0f;

	output.texcoord = input.position * PosToUV.xz + PosToUV.yw;

    return output;
}

float4 ColorPS(PS_INPUT input) : COLOR0
{
	float4 color = tex2D(MaskSampler, input.texcoord);

	color.a *= GlowColor.a;
	color.rgb *= GlowColor * color.a;
	
	return color;
}

technique Technique1
{
    pass Pass1
    {

        VertexShader = compile VS_SHADERMODEL ColorVS();
        PixelShader = compile PS_SHADERMODEL ColorPS();

        /* // Alpha test
        AlphaFunc = GreaterEqual; */

        // Alpha blending


    }
}
