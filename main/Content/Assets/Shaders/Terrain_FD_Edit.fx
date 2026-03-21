// Copyright (c) Microsoft Corporation.
// Licensed under the MIT license.


#if OPENGL
    #define VS_SHADERMODEL vs_3_0
    #define PS_SHADERMODEL ps_3_0
#else
    #define VS_SHADERMODEL vs_4_0_level_9_1
    #define PS_SHADERMODEL ps_4_0_level_9_1
#endif

#include "Terrain_FD.fx"
#include "Terrain_FA_Edit.fx"

// =====================================================
// Edit mode
// =====================================================

// -----------------------------------------------------
// Edit mode vertex shader output
// -----------------------------------------------------
struct COLOR_VS_EDIT_OUTPUT_SM2
{
    COLOR_VS_OUTPUT_SM2 base;

    float2 worldPos     : TEXCOORD4;    // pos in world coords
};

struct COLOR_VS_EDIT_OUTPUT_SM3
{
    COLOR_VS_OUTPUT_SM3 base;
};

// -----------------------------------------------------
// Edit mode vertex shaders
// -----------------------------------------------------
COLOR_VS_EDIT_OUTPUT_SM2 EditColorL10VS_SM2(
                    float4 positionAndZDiff : POSITION,
                    float4 face : TEXCOORD1
                    )
{
    COLOR_VS_EDIT_OUTPUT_SM2 Output;
    
    float3 position = positionAndZDiff.xyz;
    
    Output.base = ColorL10VS_SM2(positionAndZDiff, face.x);
	Output.worldPos.xy = position.xy;

    return Output;
}
COLOR_VS_EDIT_OUTPUT_SM2 EditColorL6VS_SM2(
                    float4 positionAndZDiff : POSITION,
                    float4 face : TEXCOORD1
                    )
{
    COLOR_VS_EDIT_OUTPUT_SM2 Output;
    
    float3 position = positionAndZDiff.xyz;
    
    Output.base = ColorL6VS_SM2(positionAndZDiff, face.x);
   	Output.worldPos.xy = position.xy;

    return Output;
}
COLOR_VS_EDIT_OUTPUT_SM2 EditColorL4VS_SM2(
                    float4 positionAndZDiff : POSITION,
                    float4 face : TEXCOORD1
                    )
{
    COLOR_VS_EDIT_OUTPUT_SM2 Output;
    
    float3 position = positionAndZDiff.xyz;
    
    Output.base = ColorL4VS_SM2(positionAndZDiff, face.x);
	Output.worldPos.xy = position.xy;

    return Output;
}
COLOR_VS_EDIT_OUTPUT_SM2 EditColorL2VS_SM2(
                    float4 positionAndZDiff : POSITION,
                    float4 face : TEXCOORD1
                    )
{
    COLOR_VS_EDIT_OUTPUT_SM2 Output;
    
    float3 position = positionAndZDiff.xyz;
    
    Output.base = ColorL2VS_SM2(positionAndZDiff, face.x);
	Output.worldPos.xy = position.xy;

    return Output;
}
COLOR_VS_EDIT_OUTPUT_SM2 EditColorL0VS_SM2(
                    float4 positionAndZDiff : POSITION,
                    float4 face : TEXCOORD1
                    )
{
    COLOR_VS_EDIT_OUTPUT_SM2 Output;
    
    float3 position = positionAndZDiff.xyz;
    
    Output.base = ColorL0VS_SM2(positionAndZDiff, face.x);
	Output.worldPos.xy = position.xy;

    return Output;
}

COLOR_VS_EDIT_OUTPUT_SM3 EditColorVS_SM3(
                    float4 positionAndZDiff : POSITION,
                    float4 face : TEXCOORD1
                    )
{
	COLOR_VS_EDIT_OUTPUT_SM3 Output;
	
	float3 position = positionAndZDiff.xyz;
	
    Output.base = ColorVS_SM3(positionAndZDiff, face.x);
    
    return Output;
}

#ifndef XBOX
VertexShader EditColorVS[] =
{
	compile VS_SHADERMODEL EditColorL0VS_SM2(),
	compile VS_SHADERMODEL EditColorL2VS_SM2(),
	compile VS_SHADERMODEL EditColorL4VS_SM2(),
	compile VS_SHADERMODEL EditColorL6VS_SM2(),
	compile VS_SHADERMODEL EditColorL10VS_SM2(),
	compile VS_SHADERMODEL EditColorVS_SM3(),
};
#endif

// -----------------------------------------------------
// Edit mode pixel shaders
// -----------------------------------------------------
float4 EditColorPS_SM2( COLOR_VS_EDIT_OUTPUT_SM2 In ) : COLOR0
{
    float4 result = ColorPS_SM2(In.base);
    
    float2 center = CubeCenter(In.worldPos.xy);
    result.rgb = EditInvert(center, result.rgb, In.base.face);
    
    return result;

}   // end of EditColorPS_SM2()
float4 EditColor2PS_SM2( COLOR_VS_EDIT_OUTPUT_SM2 In ) : COLOR0
{
    float4 result = Color2PS_SM2(In.base);
    
    float2 center = CubeCenter(In.worldPos.xy);
    result.rgb = EditInvert(center, result.rgb, In.base.face);
    
    return result;

}   // end of EditColor2PS_SM2()
float4 EditColorPS_SM3( COLOR_VS_EDIT_OUTPUT_SM3 In ) : COLOR0
{
    float4 result = ColorPS_SM3(In.base);
    
    float2 center = CubeCenter(In.base.worldPos.xy);
    result.rgb = EditInvert(center, result.rgb, In.base.face);
    
    return result;

}   // end of EditColorPS_SM3()
float4 EditColor2PS_SM3( COLOR_VS_EDIT_OUTPUT_SM3 In ) : COLOR0
{
    float4 result = Color2PS_SM3(In.base);
    
    float2 center = CubeCenter(In.base.worldPos.xy);
    result.rgb = EditInvert(center, result.rgb, In.base.face);
    
    return result;

}   // end of EditColor2PS_SM3()

#ifndef XBOX
PixelShader EditColorPS[] = 
{
	compile PS_SHADERMODEL EditColorPS_SM2(),
	compile PS_SHADERMODEL EditColor2PS_SM2(),
	compile PS_SHADERMODEL EditColorPS_SM3(),
	compile PS_SHADERMODEL EditColor2PS_SM3(),	
};
#endif

// -----------------------------------------------------
// Edit mode techniques
// -----------------------------------------------------
technique TerrainEditMode
{
    pass P0
    {
#ifndef XBOX
        VertexShader = (EditColorVS[VSIndex]);
        PixelShader  = (EditColorPS[PSIndex]);
#else
		VertexShader = compile VS_SHADERMODEL EditColorVS_SM3();
		PixelShader = compile PS_SHADERMODEL EditColorPS_SM3();
#endif

        /* // Alpha test
        AlphaFunc = GreaterEqual; */

        // Alpha blending


    }
}
//ToDo (DZ): We need to rethink the mechanisms
// that select special effects by specifying a
// technique extension (e.g. "Masked"). It should
// be done by manipulation of the PSIndex and 
// VSIndex instead.
technique TerrainEditModeMasked
{
    pass P0
    {
#ifndef XBOX
        VertexShader = (EditColorVS[VSIndex]);
        PixelShader  = (EditColorPS[PSIndex + 1]);
#else
		VertexShader = compile VS_SHADERMODEL EditColorVS_SM3();
		PixelShader = compile PS_SHADERMODEL EditColor2PS_SM3();
#endif

        /* // Alpha test
        AlphaFunc = GreaterEqual; */

        // Alpha blending


    }
}
