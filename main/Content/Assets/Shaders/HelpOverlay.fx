// Copyright (c) Microsoft Corporation.
// Licensed under the MIT license.


//
//  Help Overlay shader
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

float   Alpha;      // Used to fade overlays.
texture Texture;

//
// Texture sampler
//
sampler2D TextureSampler =
sampler_state
{
    Texture = <Texture>;
    MipFilter = None;       // Help overlay textures should be 1-to-1 with pixels on the
    MinFilter = Point;      // screen so no filtering should be needed.
    MagFilter = Point;

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
    Output.textureUV = tex;

    return Output;
}   // end of VS()

//
// Pixel shader
//
float4
PS( VS_OUTPUT In ) : COLOR0
{
    float4 result = tex2D( TextureSampler, In.textureUV );
    result.a *= Alpha;

    return result;
}   // end of PS()

//
// Technique
//
technique Overlay
{
    pass P0
    {
        VertexShader = compile VS_SHADERMODEL VS();
        PixelShader  = compile PS_SHADERMODEL PS();

        /* // Alpha test
        AlphaFunc = GreaterEqual; */

        // Alpha blending


    }
}


