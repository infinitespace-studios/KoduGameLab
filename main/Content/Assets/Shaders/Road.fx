// Copyright (c) Microsoft Corporation.
// Licensed under the MIT license.

//
// StdMaterials -- Shaders to handle the standard materials from 3DS Max via Xbf Files
//

#if OPENGL
    #define VS_SHADERMODEL vs_3_0
    #define PS_SHADERMODEL ps_3_0
#else
    #define VS_SHADERMODEL vs_4_0_level_9_1
    #define PS_SHADERMODEL ps_4_0_level_9_1
#endif

#include "Globals.fx"

#include "Fog.fx"
#include "DOF.fx"

#include "StandardLight.fx"
#include "Luz.fx"

//
// Locals common to all variants.
//

// The world view and projection matrices
float4x4    WorldViewProjMatrix;
float4x4    WorldMatrix;

// Material info.
texture     DiffuseTexture0;
texture		DiffuseTexture1;
texture     NormalTexture0;
texture     NormalTexture1;

float4		UVXfm;


//
// Texture samplers
//
sampler2D DiffuseTexture0Sampler =
sampler_state
{
    Texture = <DiffuseTexture0>;
    MipFilter = Linear;
    MinFilter = Linear;
    MagFilter = Linear;
    
    AddressU = WRAP;
    AddressV = WRAP;
};
sampler2D DiffuseTexture1Sampler =
sampler_state
{
    Texture = <DiffuseTexture1>;
    MipFilter = Linear;
    MinFilter = Linear;
    MagFilter = Linear;
    
    AddressU = WRAP;
    AddressV = WRAP;
};

float2 HorizontalUV(float3 pos)
{
	return pos.xy;
}

/// Include the variants

#include "Road_SM3.fx"
#include "Road_SM2.fx"

/// Functions and techniques common to both variants (whether or not used by both).

//
// Vertex shader output structure
//
struct DEPTH_VS_OUTPUT
{
    float4 position         : POSITION;     // vertex position
    float4 color            : TEXCOORD0;    // depth values
};

// Transform our coordinates into world space
DEPTH_VS_OUTPUT DepthVS(
                            float3 position : POSITION,
                            float3 normal   : NORMAL,
                            float2 tex      : TEXCOORD0)
{
    DEPTH_VS_OUTPUT   Output;

    // Transform our position.
    Output.position = mul( float4(position, 1.0f), WorldViewProjMatrix );

    // Transform the position into world coordinates for calculating the eye vector.
    float4 worldPosition = mul( float4(position, 1.0f), WorldMatrix );

    // Calc the eye vector.  This is the direction from the point to the eye.
    float4 eyeDist = EyeDist(worldPosition.xyz);

    Output.color = CalcDOF( eyeDist.w );
    Output.color.b = 0.0f;

    return Output;
}

//
// Pixel shader
//
float4 DepthPS( DEPTH_VS_OUTPUT In ) : COLOR0
{
    float4 result = In.color;
    
    return result;
}

//
// Technique
//
technique Depth
{
    pass P0
    {
        VertexShader = compile VS_SHADERMODEL DepthVS();
        PixelShader  = compile PS_SHADERMODEL DepthPS();

        // Alpha blending


    }
}



#include "Distort.fx"


//
//
//  Shadows
//
//

//
// Vertex shader output structure for shadow pass
//
struct VS_OUTPUT_SHADOWPASS
{
    float4 position     : POSITION;     // vertex position
};

// Transform our coordinates into world space
VS_OUTPUT_SHADOWPASS ShadowPassVS(
                                float4 position : POSITION,
                                float3 normal   : NORMAL,       // ignored
                                float2 tex      : TEXCOORD0 )   // ignored
{
    VS_OUTPUT_SHADOWPASS Output;

    Output.position = mul( position, WorldViewProjMatrix );

    return Output;
}

//
// Pixel shader for shadow pass.
//
float4 ShadowPassPS( VS_OUTPUT_SHADOWPASS In ) : COLOR0
{
    return float4(0.0f, 1.0f, 0.0f, 1.0f);
}

technique ShadowPass
{
    pass P0
    {
        VertexShader = compile VS_SHADERMODEL ShadowPassVS();
        PixelShader  = compile PS_SHADERMODEL ShadowPassPS();

        // Alpha blending


    }
}

// Explicit bloom

//
// Vertex shader output structure for shadow pass
//
struct VS_OUTPUT_BLOOMPASS
{
    float4 position     : POSITION;     // vertex position
};


// Transform our coordinates into world space
VS_OUTPUT_BLOOMPASS BloomPassVS(
                                float4 position : POSITION,
                                float3 normal   : NORMAL,       // ignored
                                float2 tex      : TEXCOORD0 )   // ignored
{
    VS_OUTPUT_BLOOMPASS Output;

    Output.position = mul( position, mul(PreWorld, WorldViewProjMatrix) );

    return Output;
}

//
// Pixel shader for shadow pass.
//
float4 BloomPassPS( VS_OUTPUT_BLOOMPASS In ) : COLOR0
{
    return BloomColor;
}


technique BloomPass
{
    pass P0
    {
        VertexShader = compile VS_SHADERMODEL BloomPassVS();
        PixelShader  = compile PS_SHADERMODEL BloomPassPS();

        // Alpha blending


    }
}
