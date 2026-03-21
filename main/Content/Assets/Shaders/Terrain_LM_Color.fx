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
#include "Terrain_FA_Color.fx"

// -----------------------------------------------------
// Color-pass techniques
// -----------------------------------------------------
technique TerrainColorPass
{
    pass P0
    {
        VertexShader = compile VS_SHADERMODEL ColorVS_SM3();
        PixelShader  = compile PS_SHADERMODEL ColorPS_SM3();

        // Alpha test

        // Alpha blending


    }
}
//ToDo (DZ): We need to rethink the mechanisms
// that selects special effects by specifying a
// technique extension (e.g. "Masked"). It should
// be done by manipulation of the PSIndex and 
// VSIndex instead.
technique TerrainColorPassMasked
{
    pass P0
    {
        VertexShader = compile VS_SHADERMODEL ColorVS_SM3();
        PixelShader  = compile PS_SHADERMODEL Color2PS_SM3();

        // Alpha test

        // Alpha blending


    }
}

