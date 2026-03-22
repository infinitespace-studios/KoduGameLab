// Copyright (c) Microsoft Corporation.
// Licensed under the MIT license.


#if OPENGL
    #define VS_SHADERMODEL vs_3_0
    #define PS_SHADERMODEL ps_3_0
#else
    #define VS_SHADERMODEL vs_4_0_level_9_1
    #define PS_SHADERMODEL ps_4_0_level_9_1
#endif

#include "Terrain_FA.fx"

// -----------------------------------------------------
// Color-pass techniques
// -----------------------------------------------------
technique TerrainColorPass_FA
{
    pass P0
    {
        VertexShader = compile VS_SHADERMODEL ColorVS_FA_SM3();
        PixelShader = compile PS_SHADERMODEL ColorPS_FA_SM3();

        /* // Alpha test
        AlphaFunc = GreaterEqual; */

        // Alpha blending


    }
}
//ToDo (DZ): We need to rethink the mechanisms
// that selects special effects by specifying a
// technique extension (e.g. "Masked"). It should
// be done by manipulation of the PSIndex and 
// VSIndex instead.
technique TerrainColorPass_FAMasked
{
    pass P0
    {
        VertexShader = compile VS_SHADERMODEL ColorVS_FA_SM3();
        PixelShader = compile PS_SHADERMODEL Color2PS_FA_SM3();

        /* // Alpha test
        AlphaFunc = GreaterEqual; */

        // Alpha blending


    }
}
