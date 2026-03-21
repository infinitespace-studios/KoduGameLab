// Copyright (c) Microsoft Corporation.
// Licensed under the MIT license.


#if OPENGL
    #define VS_SHADERMODEL vs_3_0
    #define PS_SHADERMODEL ps_3_0
#else
    #define VS_SHADERMODEL vs_4_0_level_9_1
    #define PS_SHADERMODEL ps_4_0_level_9_1
#endif

#include "Globals.fx"

texture Background;
texture Mask;
texture Glow;

float4 Color;
float2 Height;
float4 Transform;

float4 BorderGlowColor;

sampler2D BackgroundSampler =
sampler_state
{
    Texture = <Background>;
    MipFilter = Linear;
    MinFilter = Linear;
    MagFilter = Linear;

    AddressU = Clamp;
    AddressV = Clamp;
};

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

sampler2D GlowSampler =
sampler_state
{
    Texture = <Glow>;
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

    output.position.xy = input.position.xy * Transform.xy + Transform.zw;
    output.position.z = 0.0f;
    output.position.w = 1.0f;

	output.texcoord = input.position;

    return output;
}

float4 ColorPS(PS_INPUT input) : COLOR0
{
	float4 bkg = tex2D(BackgroundSampler, input.texcoord);

	float4 mask = tex2D(MaskSampler, input.texcoord);
	
	mask.rgb = (1.0f - input.texcoord.y < Height.y)
		? mask.rgb
		: float3(1.0f, 0.0f, mask.b);
	float4 color = Color;
	color.rgb = color.rgb * mask.rrr + mask.ggg;
	
	float select = (1.0f - input.texcoord.y < Height.x) * (1.0f - mask.b);
	color.rgb = lerp(bkg, color, select);
	
	color.a *= bkg.a;
	
	return color;
}

technique ShowBudget
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

struct PS_GLOW_INPUT
{
    float4 position : POSITION0;
	float2 texcoord	: TEXCOORD0;
};

PS_GLOW_INPUT BorderGlowVS(VS_INPUT input)
{
    PS_GLOW_INPUT output;

    output.position.xy = input.position.xy * Transform.xy + Transform.zw;
    output.position.z = 0.0f;
    output.position.w = 1.0f;

	output.texcoord = input.position;

    return output;
}


float4 BorderGlowPS(PS_GLOW_INPUT input) : COLOR0
{
	float4 glowShape = tex2D(GlowSampler, input.texcoord);

	float4 color = BorderGlowColor;
	
//	return float4(color.rgb, glowShape.b * color.w);
	return color * glowShape.bbbb;
}

technique BorderGlow
{
    pass Pass1
    {

        VertexShader = compile VS_SHADERMODEL BorderGlowVS();
        PixelShader = compile PS_SHADERMODEL BorderGlowPS();

        /* // Alpha test
        AlphaFunc = GreaterEqual; */

        // Alpha blending


    }
}
