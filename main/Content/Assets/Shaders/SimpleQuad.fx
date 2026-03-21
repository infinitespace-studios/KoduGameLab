// Copyright (c) Microsoft Corporation.
// Licensed under the MIT license.

//
//  SimpleQuad shaders
//

//
// Variables
//

#if OPENGL
    #define VS_SHADERMODEL vs_3_0
    #define PS_SHADERMODEL ps_3_0
#else
    #define VS_SHADERMODEL vs_4_0_level_9_1
    #define PS_SHADERMODEL ps_4_0_level_9_1
#endif

float4x4 WorldViewProjMatrix;
float4x4 WorldMatrix;

float4	Tint;
float   Alpha;
texture Texture;
texture AlphaMap;

//
// Texture samplers
//
sampler2D TextureSampler =
sampler_state
{
    Texture = <Texture>;
    MipFilter = Linear;
    MinFilter = Linear;
    MagFilter = Linear;

    AddressU = Clamp;
    AddressV = Clamp;
};

sampler2D AlphaSampler =
sampler_state
{
    Texture = <AlphaMap>;
    MipFilter = Linear;
    MinFilter = Linear;
    MagFilter = Linear;

    AddressU = Clamp;
    AddressV = Clamp;
};

//
// Vertex shader output structure
//
struct VS_OUTPUT
{
    float4 position     : POSITION;     // vertex position
    float2 textureUV    : TEXCOORD0;    // vertex texture coords
};

//
// Vertex shader
//
VS_OUTPUT
VS( float2 pos : POSITION0,
    float2 tex : TEXCOORD0 )
{
    VS_OUTPUT   Output;

    float4 position = float4( pos.x, pos.y, 0.0f, 1.0f );
    Output.position = mul( position, WorldViewProjMatrix );
    Output.textureUV = tex;

    return Output;
}   // end of VS()

//
// Pixel shader: TexturedPS
//
float4
TexturedPS( VS_OUTPUT In ) : COLOR0
{
    float4 result = Tint * tex2D( TextureSampler, In.textureUV );
    result.a *= Alpha;

    return result;
}   // end of TexturedPS()

//
// Pixel shader: TexturedWithAlphaMapPS
//
float4
TexturedWithAlphaMapPS( VS_OUTPUT In ) : COLOR0
{
    float4 result = Tint * tex2D( TextureSampler, In.textureUV );
    result.a = tex2D( AlphaSampler, In.textureUV ).r * Alpha;

    return result;
}   // end of TexturedWithAlphaMapPS()

//
// TexturedNormalAlpha
//
technique TexturedNormalAlpha
{
    pass P0
    {
        VertexShader = compile VS_SHADERMODEL VS();
        PixelShader  = compile PS_SHADERMODEL TexturedPS();

        /* // Alpha test
        AlphaFunc = GreaterEqual; */

        // Alpha blending


    }
}

//
// TexturedWithAlphaMap
//
technique TexturedWithAlphaMap
{
    pass P0
    {
        VertexShader = compile VS_SHADERMODEL VS();
        PixelShader  = compile PS_SHADERMODEL TexturedWithAlphaMapPS();

        /* // Alpha test
        AlphaFunc = GreaterEqual; */

        // Alpha blending


    }
}
