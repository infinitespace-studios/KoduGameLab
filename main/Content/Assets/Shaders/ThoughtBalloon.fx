// Copyright (c) Microsoft Corporation.
// Licensed under the MIT license.

//
// ThoughtBalloon shader
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

//
// Variables
//

// The world view and projection matrices
float4x4    WorldViewProjMatrix;
float4x4    WorldMatrix;

float2      Size;
float       Alpha;
float4      BorderColor;

texture     ContentTexture;

//
// Texture samplers
//
sampler2D ContentTextureSampler =
sampler_state
{
    Texture = <ContentTexture>;
    MipFilter = Linear;
    MinFilter = Linear;
    MagFilter = Linear;

    AddressU = Clamp;
    AddressV = Clamp;
};

//
//
//  Color Pass
//
//

//
// Vertex shader output structure
//
struct COLOR_VS_OUTPUT
{
    float4 position     : POSITION;     // vertex position
    float2 textureUV    : TEXCOORD0;    // vertex texture coords
};

//
// Vertex shader
//
COLOR_VS_OUTPUT
ColorVS( float3 pos : POSITION,
         float2 tex : TEXCOORD0 )
{
    COLOR_VS_OUTPUT   Output;

    Output.position = mul( float4( pos.x, pos.y, pos.z, 1.0f ), WorldViewProjMatrix );
    Output.textureUV = tex;

    return Output;
}   // end of ColorVS()

//
// Pixel shader
//
float4
ColorPS( COLOR_VS_OUTPUT In ) : COLOR0
{
    float4 result = tex2D( ContentTextureSampler, In.textureUV );
    
    // We need to know whether this pixel is on the border or not.  The border
    // is full red while the rest of the balloon is white so we can compare
    // the red and green channels to get a border percentage.
    float border = result.r - result.g;
    float weight = border * result.r;
    result.rgb = weight * BorderColor.rgb + ( 1 - weight ) * result.rgb;
    
    result.a *= Alpha;

	// Ignore pixel if fully transparent.
	clip(result.a - 0.001);

    return result;
}   // end of ColorPS()

//
//  ColorPass
//
technique ColorPass
{
    pass P0
    {
        VertexShader = compile VS_SHADERMODEL ColorVS();
        PixelShader  = compile PS_SHADERMODEL ColorPS();

        /* // Alpha test
        AlphaFunc = GreaterEqual; */

        // Alpha blending


    }
}

//
//
//  Depth Pass
//
//
//  This is extremely simplified since we don't want DOF blurring on the thought balloons.
//

//
// Vertex shader output structure
//
struct DEPTH_VS_OUTPUT
{
    float4 position     : POSITION;     // vertex position
    float2 tex          : TEXCOORD0;    // texture coords
};

//
// Vertex shader
//
DEPTH_VS_OUTPUT
DepthVS( float3 pos : POSITION,
           float2 tex : TEXCOORD0 )
{
    DEPTH_VS_OUTPUT   Output;

    Output.position = mul( float4( pos.x, pos.y, pos.z, 1.0f ), WorldViewProjMatrix );
    Output.tex = tex;

    return Output;
}   // end of DepthVS()

//
// Pixel shader
//
float4
DepthPS( DEPTH_VS_OUTPUT In ) : COLOR0
{
    float4 result = tex2D( ContentTextureSampler, In.tex );
    
    result.rgb = 0;

	// Having the clip here eliminates the "box" around the thought balloon
	// where it interacts with the actor's glow.  But having it here also
	// causes the tip to be rendered brightly where it should be hidden 
	// within the actor's geometry.  IMO this looks worse so we'll have
	// to live with the box/glow interaction for now.
	//clip( result.a < 0.01f ? -1 : 1 );

    return result;
}   // end of DepthPS()

//
//  DepthPass
//
technique DepthPass
{
    pass P0
    {
        VertexShader = compile VS_SHADERMODEL DepthVS();
        PixelShader  = compile PS_SHADERMODEL DepthPS();

        /* // Alpha test
        AlphaFunc = GreaterEqual; */

        // Alpha blending


    }
}

