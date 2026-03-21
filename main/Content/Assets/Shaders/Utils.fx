// Copyright (c) Microsoft Corporation.
// Licensed under the MIT license.

//
// Utils shaders -- Simple shaders that work with the Utils functions.
//

//
// Shared Globals.
//

#if OPENGL
    #define VS_SHADERMODEL vs_3_0
    #define PS_SHADERMODEL ps_3_0
#else
    #define VS_SHADERMODEL vs_4_0_level_9_1
    #define PS_SHADERMODEL ps_4_0_level_9_1
#endif

float4   EyeLocation;
texture  EnvironmentMap;
texture	Ramps;

float4 ConeColor;

//
// Locals.
//

// The world view and projection matrices
float4x4 WorldViewProjMatrix;
float4x4 WorldMatrix;

// Textures
texture DiffuseTexture;

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

sampler2D RampTextureSampler =
sampler_state
{
    Texture = <Ramps>;
    MipFilter = Linear;
    MinFilter = Linear;
    MagFilter = Linear;

    AddressU = Clamp;
    AddressV = Clamp;
};

//
// Vertex shader output structure
//
struct VS_OUTPUT_NOTEX
{
    float4 position     : POSITION;     // vertex position
    float4 color        : COLOR0;       // vertex color
};

//
// Vertex Shader
//
VS_OUTPUT_NOTEX NoTex_VS(
            float3 position : POSITION,
            float4 color    : COLOR0 )
{
    VS_OUTPUT_NOTEX Output;

    // Transform our position.
    float4 pos = float4(position, 1.0f);
    Output.position = mul( pos, WorldViewProjMatrix );

    Output.color = color;

    return Output;
}   // end of NoTex_VS()

//
// Pixel shader
//
float4 NoTex_PS( VS_OUTPUT_NOTEX In ) : COLOR0
{
    return In.color;
}   // end of NoTex_PS()


//
//
// Screenspace shaders
//
//
//
// Vertex Shader
//
VS_OUTPUT_NOTEX ScreenspaceVS(
            float3 position : POSITION,
            float4 color    : COLOR0 )
{
    VS_OUTPUT_NOTEX Output;

    Output.position = float4( position.x, position.y, 0.0f, 1.0f );
    Output.color = color;

    return Output;
}   // end of ScreenspaceVS()




//
// Position and color.  No texture or lighting.
//
technique NoTexture
{
    pass P0
    {
        VertexShader = compile VS_SHADERMODEL NoTex_VS();
        PixelShader  = compile PS_SHADERMODEL NoTex_PS();

        /* // Alpha test
        AlphaFunc = GreaterEqual; */

        // Alpha blending


    }
}

technique Screenspace2D
{
    pass P0
    {
        VertexShader = compile VS_SHADERMODEL ScreenspaceVS();
        PixelShader  = compile PS_SHADERMODEL NoTex_PS();

        /* // Alpha test
        AlphaFunc = GreaterEqual; */

        // Alpha blending


    }
}

struct VS_OUTPUT_VTXCOLOR
{
	float4 position : POSITION;
	float4 color : COLOR0;
};

VS_OUTPUT_VTXCOLOR VtxColor_VS(float3 position : POSITION,
							float4 color : COLOR0)
{
	VS_OUTPUT_VTXCOLOR Out;
	
	Out.position = mul(float4(position.xyz, 1.0f), WorldViewProjMatrix);
	
	Out.color = color;
	
	return Out;
}

float4 VtxColor_PS(VS_OUTPUT_VTXCOLOR In) : COLOR0
{
	return In.color;
}


//
// Position and color.  Color embedded in vertex
//
technique VtxColor
{
    pass P0
    {
        VertexShader = compile VS_SHADERMODEL VtxColor_VS();
        PixelShader  = compile PS_SHADERMODEL VtxColor_PS();

        /* // Alpha test
        AlphaFunc = GreaterEqual; */

        // Alpha blending


    }
}

struct VS_OUTPUT_RUNWAY
{
	float4 position : POSITION;
	float4 toEnd : TEXCOORD0;
};

float2 RunWidth = float2(1.0f, 1.0f);
float RunPhase = 0.0f;
float RunCount = 1.0f;
float RunCutOff = 0.33f;
float4 RunEndColor = float4(0.0f, 1.0f, 1.0f, 1.0f);

float4 CodeParm(float4 parm)
{
	parm.w *= RunCount;
	
	parm.w += RunPhase;
	
	return parm;
}

float2 DeCodeParm(float w)
{
	w = frac(w);
	
	float2 uv;
	uv.x = w > RunCutOff ? 0.0f : 1.0f;
	uv.y = w > RunCutOff ? (w - RunCutOff) / (1.0f - RunCutOff) : w / RunCutOff;
	
	return uv;
}

VS_OUTPUT_RUNWAY RunwayVS(float3 position : POSITION,
							float4 other : TEXCOORD0,
							float4 toEnd : COLOR0)
{
	VS_OUTPUT_RUNWAY Out;
	
	Out.position = mul(float4(position.xyz, 1.0f), WorldViewProjMatrix);

	float4 scrOther = mul(float4(other.xyz, 1.0f), WorldViewProjMatrix);
	float2 del = scrOther.xy / scrOther.w - Out.position.xy / Out.position.w;
	del = float2(-del.y, del.x);
	del *= RunWidth;
	del = normalize(del) * other.w;
	del *= RunWidth;
	Out.position.xy += del * Out.position.w;
	
	toEnd.w *= length(position - other);
	
	Out.toEnd = CodeParm(toEnd);
//Out.toEnd = toEnd.w;
//Out.toEnd = 0.0f;
	
	return Out;
}

float4 RunwayPS(VS_OUTPUT_RUNWAY In) : COLOR0
{
//return float4(In.toEnd, In.toEnd, In.toEnd, 1.0f);

	float2 uv = DeCodeParm(In.toEnd.w);
	
	float4 startColor = float4(In.toEnd.rgb, 1.0f);
	
    float4 ramp = tex2D( RampTextureSampler, float2(uv.y, 0.5f) );
	
	float4 color = lerp(startColor, RunEndColor, uv.x);
	color.a *= ramp.z;
//color = ramp.xxxx;
//color.a = 1.0f;
	
	return color;
}

technique RunwayAlpha
{
	pass P0
	{
		VertexShader = compile VS_SHADERMODEL RunwayVS();
		PixelShader = compile PS_SHADERMODEL RunwayPS();
		
        /* // Alpha test
        AlphaFunc = Greater; */

        // Alpha blending


	}
}

technique RunwayAlphaBack
{
	pass P0
	{
		VertexShader = compile VS_SHADERMODEL RunwayVS();
		PixelShader = compile PS_SHADERMODEL RunwayPS();
		
        /* // Alpha test
        AlphaFunc = Greater; */

        // Alpha blending


	}
}

