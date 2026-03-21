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

// The world view and projection matrices
float4x4    WorldViewProjMatrix;
float4x4    WorldMatrix;
float4x4    WorldMatrixInverseTranspose;

#include "Fog.fx"
#include "DOF.fx"
#include "Flex.fx"
#include "Skin.fx"
#include "StandardLight.fx"
#include "SurfaceLight.fx"
#include "Luz.fx"
#include "PrepXform.fx"

//
// Locals.
//
texture     DiffuseTexture;


//
// Texture samplers
//
sampler2D DiffuseTextureSampler =
sampler_state
{
    Texture = <DiffuseTexture>;
    MipFilter = Linear;
    MinFilter = Linear;
    MagFilter = Linear;
    
    AddressU = Clamp;
    AddressV = Clamp;
};

#include "Face.fx"

float4 GhostColor(float4 color)
{
	color.xyz *= 0.25f;
	color.xyz += 0.75f.xxx;
	color.xyz *= BloomColor;
	
	return color;
}

#include "Standard_SM3.fx"
#include "Standard_SM2.fx"

#include "Surface_SM3.fx"
#include "Surface_SM2.fx"

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

    position = PrepPosition(position);
    Output.position = mul( float4(position, 1.0f), WorldViewProjMatrix );
    
    // Transform the position into world coordinates for calculating the eye vector.
    float4 worldPosition = mul( float4(position, 1.0f), WorldMatrix );

    // Calc the eye vector.  This is the direction from the point to the eye.
    float4 eyeDist = EyeDist(worldPosition.xyz);

    Output.color = CalcDOF( eyeDist.w );

    return Output;
}

DEPTH_VS_OUTPUT DepthWithFlexVS(
                            float3 position : POSITION,
                            float3 normal   : NORMAL,
                            float2 tex      : TEXCOORD0)
{
    DEPTH_VS_OUTPUT   Output;

    position = PrepPosition(position);
	float3 pos = ApplyFlex(position, normal);

    // Transform our position.
    Output.position = mul( float4(pos, 1.0f), WorldViewProjMatrix );

    // Transform the position into world coordinates for calculating the eye vector.
    float4 worldPosition = mul( float4(pos, 1.0f), WorldMatrix );

    // Calc the eye vector.  This is the direction from the point to the eye.
    float4 eyeDist = EyeDist(worldPosition.xyz);

    Output.color = CalcDOF( eyeDist.w );

    return Output;
}

DEPTH_VS_OUTPUT DepthWithSkinningVS(in SKIN_VS_INPUT input)
{
    DEPTH_VS_OUTPUT   Output;
    
    input.position = PrepPosition(input.position);
    input.normal = PrepNormal(input.normal);
    SKIN_OUTPUT skin = Skin4(input);    
    float3 pos = skin.position;
    
    Output.position = mul( float4(pos, 1.0f), WorldViewProjMatrix );

    // Transform the position into world coordinates for calculating the eye vector.
    float4 worldPosition = mul( float4(pos, 1.0f), WorldMatrix );

    // Calc the eye vector.  This is the direction from the point to the eye.
    float4 eyeDist = EyeDist(worldPosition.xyz);

    Output.color = CalcDOF( eyeDist.w );

    return Output;
}

DEPTH_VS_OUTPUT DepthWithWindVS(in SKIN_VS_INPUT input)
{
    DEPTH_VS_OUTPUT   Output;
    
    SKIN_OUTPUT skin = Skin8(input);    
    float3 pos = skin.position;
    
    Output.position = mul( float4(pos, 1.0f), WorldViewProjMatrix );

    // Transform the position into world coordinates for calculating the eye vector.
    float4 worldPosition = mul( float4(pos, 1.0f), WorldMatrix );

    // Calc the eye vector.  This is the direction from the point to the eye.
    float4 eyeDist = EyeDist(worldPosition.xyz);

    Output.color = CalcDOF( eyeDist.w );

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
technique DepthPass
{
    pass P0
    {
        VertexShader = compile VS_SHADERMODEL DepthVS();
        PixelShader  = compile PS_SHADERMODEL DepthPS();

        // Alpha blending


    }
}

technique DepthPassWithFlex
{
    pass P0
    {
        VertexShader = compile VS_SHADERMODEL DepthWithFlexVS();
        PixelShader  = compile PS_SHADERMODEL DepthPS();

        // Alpha blending


    }
}

technique DepthPassCloud
{
    pass P0
    {
        VertexShader = compile VS_SHADERMODEL DepthWithSkinningVS();
        PixelShader  = compile PS_SHADERMODEL DepthPS();

        // Alpha blending


    }
}


technique DepthPassWithSkinning
{
    pass P0
    {
        VertexShader = compile VS_SHADERMODEL DepthWithSkinningVS();
        PixelShader  = compile PS_SHADERMODEL DepthPS();

        // Alpha blending


    }
}

technique DepthPassBokuFaceWithSkinning
{
    pass P0
    {
        VertexShader = compile VS_SHADERMODEL DepthWithSkinningVS();
        PixelShader  = compile PS_SHADERMODEL DepthPS();

        // Alpha blending


    }
}

technique DepthPassWideFaceWithSkinning
{
    pass P0
    {
        VertexShader = compile VS_SHADERMODEL DepthWithSkinningVS();
        PixelShader  = compile PS_SHADERMODEL DepthPS();

        // Alpha blending


    }
}

technique DepthPassTwoFaceWithSkinning
{
    pass P0
    {
        VertexShader = compile VS_SHADERMODEL DepthWithSkinningVS();
        PixelShader  = compile PS_SHADERMODEL DepthPS();

        // Alpha blending


    }
}

technique DepthPassWithWind
{
    pass P0
    {
        VertexShader = compile VS_SHADERMODEL DepthWithWindVS();
        PixelShader  = compile PS_SHADERMODEL DepthPS();

        // Alpha blending


    }
}


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

    position = PrepPosition(position);
    Output.position = mul( position, WorldViewProjMatrix );

    return Output;
}

VS_OUTPUT_SHADOWPASS ShadowPassWithFlexVS(
                                float4 position : POSITION,
                                float3 normal   : NORMAL,       // ignored
                                float2 tex      : TEXCOORD0 )   // ignored
{
    VS_OUTPUT_SHADOWPASS Output;

    // First, transform the fishbones.  Assumes transform is affine.
    position = PrepPosition(position);
    float3 pos = ApplyFlex(position, normal);

    Output.position = mul( float4(pos, 1.0f), WorldViewProjMatrix );

    return Output;
}

VS_OUTPUT_SHADOWPASS ShadowPassWithSkinningVS(in SKIN_VS_INPUT input)
{
    input.position = PrepPosition(input.position);
    SKIN_OUTPUT skin = Skin4(input);
    VS_OUTPUT_SHADOWPASS Output;
    
    float3 pos = skin.position;
    Output.position = mul( float4(pos, 1.0f), WorldViewProjMatrix );

    return Output;
}

VS_OUTPUT_SHADOWPASS ShadowPassWithWindVS(in SKIN_VS_INPUT input)
{
    input.position = PrepPosition(input.position);
    SKIN_OUTPUT skin = Skin8(input);
    VS_OUTPUT_SHADOWPASS Output;
    
    float3 pos = skin.position;
    Output.position = mul( float4(pos, 1.0f), WorldViewProjMatrix );

    return Output;
}


//
// Pixel shader for shadow pass.
//
float4 ShadowPassPS( VS_OUTPUT_SHADOWPASS In ) : COLOR0
{
    return float4(1.0f, 1.0f, 0.0f, 1.0f);
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

technique ShadowPassWithFlex
{
    pass P0
    {
        VertexShader = compile VS_SHADERMODEL ShadowPassWithFlexVS();
        PixelShader  = compile PS_SHADERMODEL ShadowPassPS();

        // Alpha blending


    }
}

technique ShadowPassCloud
{
    pass P0
    {
        VertexShader = compile VS_SHADERMODEL ShadowPassWithSkinningVS();
        PixelShader  = compile PS_SHADERMODEL ShadowPassPS();

        // Alpha blending


    }
}

technique ShadowPassWithSkinning
{
    pass P0
    {
        VertexShader = compile VS_SHADERMODEL ShadowPassWithSkinningVS();
        PixelShader  = compile PS_SHADERMODEL ShadowPassPS();

        // Alpha blending


    }
}

technique ShadowPassBokuFaceWithSkinning
{
    pass P0
    {
        VertexShader = compile VS_SHADERMODEL ShadowPassWithSkinningVS();
        PixelShader  = compile PS_SHADERMODEL ShadowPassPS();

        // Alpha blending


    }
}

technique ShadowPassWideFaceWithSkinning
{
    pass P0
    {
        VertexShader = compile VS_SHADERMODEL ShadowPassWithSkinningVS();
        PixelShader  = compile PS_SHADERMODEL ShadowPassPS();

        // Alpha blending


    }
}

technique ShadowPassTwoFaceWithSkinning
{
    pass P0
    {
        VertexShader = compile VS_SHADERMODEL ShadowPassWithSkinningVS();
        PixelShader  = compile PS_SHADERMODEL ShadowPassPS();

        // Alpha blending


    }
}

technique ShadowPassWithWind
{
    pass P0
    {
        VertexShader = compile VS_SHADERMODEL ShadowPassWithWindVS();
        PixelShader  = compile PS_SHADERMODEL ShadowPassPS();

        // Alpha blending


    }
}

#include "Distort.fx"

////////////////////////////////////////////////////////////////////
// Bloom pass
////////////////////////////////////////////////////////////////////

//
// Vertex shader output structure for bloom pass
//
struct VS_OUTPUT_BLOOMPASS
{
    float4 position     : POSITION;     // vertex position
    float4 screenPos	: TEXCOORD0;
};

float4 GetScreenPos(float4 ndcPos)
{
    float4 screenPos = ndcPos;
    screenPos.xy /= ndcPos.w;
    screenPos = screenPos * float4(0.5f, -0.5f, 1.f, 1.f / DOF_FarPlane) 
										+ float4(0.5f, 0.5f, 0.f, 0.f);
										
	return screenPos;
}

// Transform our coordinates into world space
VS_OUTPUT_BLOOMPASS BloomPassVS(
                                float4 position : POSITION,
                                float3 normal   : NORMAL,       // ignored
                                float2 tex      : TEXCOORD0 )   // ignored
{
    VS_OUTPUT_BLOOMPASS Output;

    position = PrepPosition(position);
    Output.position = mul( position, mul(PreWorld, WorldViewProjMatrix) );

	Output.screenPos = GetScreenPos(Output.position);

    return Output;
}

VS_OUTPUT_BLOOMPASS BloomPassWithFlexVS(
                                float4 position : POSITION,
                                float3 normal   : NORMAL,       // ignored
                                float2 tex      : TEXCOORD0 )   // ignored
{
    VS_OUTPUT_BLOOMPASS Output;

    position = PrepPosition(position);
	float3 pos = ApplyFlex(position, normal);

    Output.position = mul( float4(pos, 1.0f), mul(PreWorld, WorldViewProjMatrix) );

	Output.screenPos = GetScreenPos(Output.position);

    return Output;
}

VS_OUTPUT_BLOOMPASS BloomPassWithSkinningVS(in SKIN_VS_INPUT input)
{
    VS_OUTPUT_BLOOMPASS Output;
    
    input.position = PrepPosition(input.position);
    SKIN_OUTPUT skin = Skin4(input);
    
    float3 pos = skin.position;
    
    Output.position = mul( float4(pos, 1.0f), mul(PreWorld, WorldViewProjMatrix) );
	Output.screenPos = GetScreenPos(Output.position);

    return Output;
}

VS_OUTPUT_BLOOMPASS BloomPassWithWindVS(in SKIN_VS_INPUT input)
{
    VS_OUTPUT_BLOOMPASS Output;
    
    input.position = PrepPosition(input.position);
    SKIN_OUTPUT skin = Skin8(input);
    
    float3 pos = skin.position;
    
    Output.position = mul( float4(pos, 1.0f), mul(PreWorld, WorldViewProjMatrix) );
	Output.screenPos = GetScreenPos(Output.position);

    return Output;
}

//
// Pixel shader for bloom pass.
//
float4 BloomPassPS( VS_OUTPUT_BLOOMPASS In ) : COLOR0
{
    float4 depthTex = tex2D( DepthTextureSampler, In.screenPos.xy );
    float depth = depthTex.g - In.screenPos.w;

    return depth > 0 ? BloomColor : float4(0.f, 0.f, 0.f, 0.f);
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

technique BloomPassWithFlex
{
    pass P0
    {
        VertexShader = compile VS_SHADERMODEL BloomPassWithFlexVS();
        PixelShader  = compile PS_SHADERMODEL BloomPassPS();

        // Alpha blending


    }
}

technique BloomPassCloud
{
    pass P0
    {
        VertexShader = compile VS_SHADERMODEL BloomPassWithSkinningVS();
        PixelShader  = compile PS_SHADERMODEL BloomPassPS();

        // Alpha blending


    }
}

technique BloomPassWithSkinning
{
    pass P0
    {
        VertexShader = compile VS_SHADERMODEL BloomPassWithSkinningVS();
        PixelShader  = compile PS_SHADERMODEL BloomPassPS();

        // Alpha blending


    }
}

technique BloomPassBokuFaceWithSkinning
{
    pass P0
    {
        VertexShader = compile VS_SHADERMODEL BloomPassWithSkinningVS();
        PixelShader  = compile PS_SHADERMODEL BloomPassPS();

        // Alpha blending


    }
}

technique BloomPassWideFaceWithSkinning
{
    pass P0
    {
        VertexShader = compile VS_SHADERMODEL BloomPassWithSkinningVS();
        PixelShader  = compile PS_SHADERMODEL BloomPassPS();

        // Alpha blending


    }
}

technique BloomPassTwoFaceWithSkinning
{
    pass P0
    {
        VertexShader = compile VS_SHADERMODEL BloomPassWithSkinningVS();
        PixelShader  = compile PS_SHADERMODEL BloomPassPS();

        // Alpha blending


    }
}

technique BloomPassWithWind
{
    pass P0
    {
        VertexShader = compile VS_SHADERMODEL BloomPassWithWindVS();
        PixelShader  = compile PS_SHADERMODEL BloomPassPS();

        // Alpha blending


    }
}

#include "Aura.fx"
