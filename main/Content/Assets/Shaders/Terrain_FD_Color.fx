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
#include "Terrain_FA_Color.fx"

#ifndef XBOX
VertexShader ColorVS[] =
{
	compile VS_SHADERMODEL ColorL0VS_SM2(),
	compile VS_SHADERMODEL ColorL2VS_SM2(),
	compile VS_SHADERMODEL ColorL4VS_SM2(),
	compile VS_SHADERMODEL ColorL6VS_SM2(),
	compile VS_SHADERMODEL ColorL10VS_SM2(),
	compile VS_SHADERMODEL ColorVS_SM3(),
};
#endif

#ifndef XBOX
PixelShader ColorPS[] =
{
	compile PS_SHADERMODEL ColorPS_SM2(),
	compile PS_SHADERMODEL Color2PS_SM2(),
	compile PS_SHADERMODEL ColorPS_SM3(),
	compile PS_SHADERMODEL Color2PS_SM3(),
};
#endif

// -----------------------------------------------------
// Color-pass techniques
// -----------------------------------------------------
technique TerrainColorPass
{
    pass P0
    {
#ifndef XBOX
        VertexShader = (ColorVS[VSIndex]);
        PixelShader  = (ColorPS[PSIndex]);
#else
        VertexShader = compile VS_SHADERMODEL ColorVS_SM3();
        PixelShader  = compile PS_SHADERMODEL ColorPS_SM3();
#endif

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
technique TerrainColorPassMasked
{
    pass P0
    {
#ifndef XBOX
        VertexShader = (ColorVS[VSIndex]);
        PixelShader  = (ColorPS[PSIndex + 1]);
#else
        VertexShader = compile VS_SHADERMODEL ColorVS_SM3();
        PixelShader  = compile PS_SHADERMODEL Color2PS_SM3();
#endif

        /* // Alpha test
        AlphaFunc = GreaterEqual; */

        // Alpha blending


    }
}

