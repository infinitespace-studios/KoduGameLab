// Copyright (c) Microsoft Corporation.
// Licensed under the MIT license.

//
//  Gaussian -- Gaussian blur, 7 pixels wide
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

texture SourceTexture;
float2  PixelSize;      // Since XNA doesn't support a pretransformed position vertex decl we
                        // have to scale all out offsets by the pixel size.
float   Weights[ 4 ];
float   Offsets[ 4 ];

//
// Texture samplers
//
sampler2D SourceTextureSampler =
sampler_state
{
    Texture = <SourceTexture>;
    MipFilter = NONE;
    MinFilter = LINEAR;
    MagFilter = LINEAR;
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

#include "QuadUvToPos.fx"

//
// Vertex shader
//
VS_OUTPUT
VS( float2 tex : TEXCOORD0 )
{
    VS_OUTPUT   Output;

    Output.position = QuadUvToPos(tex, 0.0f);
    Output.textureUV = tex;
    
    return Output;
}   // end of VS()

//
// Pixel shaders
//
float4 
Horizontal4PS( VS_OUTPUT In ) : COLOR0
{
    float4 Color = 0;

    for( int i = 0; i < 4; i++ ) 
    {
        float2 tex = In.textureUV + float2( Offsets[ i ], 0.0f ) * PixelSize;
        Color += Weights[ i ] * tex2D( SourceTextureSampler, tex );
    }

    return Color;
}

float4 
Vertical4PS( VS_OUTPUT In ) : COLOR0
{
    float4 Color = 0;

    for( int i = 0; i < 4; i++ ) 
    {
        float2 tex = In.textureUV + float2( 0.0f, Offsets[ i ] ) * PixelSize;
        Color += Weights[ i ] * tex2D( SourceTextureSampler, tex );
    }

    return Color;
}

//
// Filter
//
technique GaussianHorizontal
{
    pass P0
    {
        VertexShader = compile VS_SHADERMODEL VS();
        PixelShader  = compile PS_SHADERMODEL Horizontal4PS();

        /* // Alpha test
        AlphaFunc = GreaterEqual; */

        // Alpha blending


    }
}

technique GaussianVertical
{
    pass P0
    {
        VertexShader = compile VS_SHADERMODEL VS();
        PixelShader  = compile PS_SHADERMODEL Vertical4PS();

        /* // Alpha test
        AlphaFunc = GreaterEqual; */

        // Alpha blending


    }
}



