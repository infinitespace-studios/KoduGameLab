// Copyright (c) Microsoft Corporation.
// Licensed under the MIT license.

//
//  Font shader
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

float4  FontColor;
texture FontTexture;

//
// Texture samplers
//
sampler2D FontTextureSampler =
sampler_state
{
    Texture = <FontTexture>;
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

    Output.position = float4( pos.x, pos.y, 0.0f, 1.0f );
    Output.textureUV = tex / 256;

    return Output;
}   // end of VS()

//
// Font pixel shader
//
float4
PS( VS_OUTPUT In ) : COLOR0
{
    float4 result = FontColor;
    
    result.a *= tex2D( FontTextureSampler, In.textureUV ).a;

    return result;
}   // end of PS()

//
// Font
//
technique Font
{
    pass P0
    {
        VertexShader = compile VS_SHADERMODEL VS();
        PixelShader  = compile PS_SHADERMODEL PS();

        // Alpha test

        // Alpha blending


    }
}


