// Copyright (c) Microsoft Corporation.
// Licensed under the MIT license.


#if OPENGL
    #define VS_SHADERMODEL vs_3_0
    #define PS_SHADERMODEL ps_3_0
#else
    #define VS_SHADERMODEL vs_4_0_level_9_1
    #define PS_SHADERMODEL ps_4_0_level_9_1
#endif

#include "Terrain_LM.fx"
#include "Terrain_FA_Edit.fx"

// -----------------------------------------------------
// Edit mode pixel shaders
// -----------------------------------------------------
float4 EditColorPS_SM2( COLOR_VS_EDIT_OUTPUT_SM2 In ) : COLOR0
{
    float4 result = ColorPS_SM2(In.base);
    
    result.rgb = EditInvert(In.center, result.rgb);
    
    return result;

}   // end of EditColorPS_SM2()
float4 EditColor2PS_SM2( COLOR_VS_EDIT_OUTPUT_SM2 In ) : COLOR0
{
    float4 result = Color2PS_SM2(In.base);
    
    result.rgb = EditInvert(In.center, result.rgb);
    
    return result;

}   // end of EditColor2PS_SM2()
float4 EditColorPS_SM3( COLOR_VS_OUTPUT_SM3 In ) : COLOR0
{
    float4 result = ColorPS_SM3(In);
    
    result.rgb = EditInvert(In.center, result.rgb);
    
    return result;

}   // end of EditColorPS_SM3()
// Edit-mode pixel shader (PS)
float4 EditColor2PS_SM3( COLOR_VS_OUTPUT_SM3 In ) : COLOR0
{
    float4 result = Color2PS_SM3(In);
    
    result.rgb = EditInvert(In.center, result.rgb);
    
    return result;

}   // end of EditColor2PS_SM3()

// -----------------------------------------------------
// Edit mode techniques
// -----------------------------------------------------
technique TerrainEditMode
{
    pass P0
    {
        VertexShader = compile VS_SHADERMODEL EditColorVS_SM3();
        PixelShader  = compile PS_SHADERMODEL EditColorPS_SM3();

        // Alpha test

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
        VertexShader = compile VS_SHADERMODEL EditColorVS_SM3();
        PixelShader  = compile PS_SHADERMODEL EditColor2PS_SM3();

        // Alpha test

        // Alpha blending


    }
}

