// Copyright (c) Microsoft Corporation.
// Licensed under the MIT license.


#if OPENGL
    #define VS_SHADERMODEL vs_3_0
    #define PS_SHADERMODEL ps_3_0
#else
    #define VS_SHADERMODEL vs_4_0_level_9_1
    #define PS_SHADERMODEL ps_4_0_level_9_1
#endif

#ifndef GHOST_SM3_FX
#define GHOST_SM3_FX

float4 GhostNonTexturedColorPS_SM3( COLOR_VS_OUTPUT_SM3 In ) : COLOR0
{
    float4 result = NonTexturedColorPS_SM3( In );

    result = GhostColor(result);

    return result;
}

float4 GhostCloudColorPS_SM3( COLOR_VS_OUTPUT_SM3 In ) : COLOR0
{
	float4 result = CloudColorPS_SM3(In);
	
    result = GhostColor(result);
	
	return result;
}

//
// Techniques
//
technique GhostPass_SM3
{
    pass P0
    {
        VertexShader = compile VS_SHADERMODEL ColorSimpTexVS_SM3();
        PixelShader  = compile PS_SHADERMODEL GhostNonTexturedColorPS_SM3();

        /* // Alpha test
        AlphaFunc = GreaterEqual; */

        // Alpha blending


    }
}

technique GhostPassNonTextured_SM3
{
    pass P0
    {
        VertexShader = compile VS_SHADERMODEL ColorSimpVS_SM3();
        PixelShader  = compile PS_SHADERMODEL GhostNonTexturedColorPS_SM3();

        /* // Alpha test
        AlphaFunc = GreaterEqual; */

        // Alpha blending


    }
}


technique GhostPassCloud_SM3
{
	pass P0
	{
        VertexShader = compile VS_SHADERMODEL ColorWithSkinVS_SM3();
        PixelShader  = compile PS_SHADERMODEL GhostCloudColorPS_SM3();

        /* // Alpha test
        AlphaFunc = GreaterEqual; */

        // Alpha blending


	}
}

technique GhostPassWithFlex_SM3
{
    pass P0
    {
        VertexShader = compile VS_SHADERMODEL ColorTexWithFlexVS_SM3();
        PixelShader  = compile PS_SHADERMODEL GhostNonTexturedColorPS_SM3();

        /* // Alpha test
        AlphaFunc = GreaterEqual; */

        // Alpha blending


    }
}


technique GhostPassWithSkinning_SM3
{
    pass P0
    {
        VertexShader = compile VS_SHADERMODEL ColorWithSkinVS_SM3();
        PixelShader  = compile PS_SHADERMODEL GhostNonTexturedColorPS_SM3();

        /* // Alpha test
        AlphaFunc = GreaterEqual; */

        // Alpha blending


    }
}

technique GhostPassWithWind_SM3
{
	pass P0
	{
        VertexShader = compile VS_SHADERMODEL ColorWithWindVS_SM3();
        PixelShader  = compile PS_SHADERMODEL GhostNonTexturedColorPS_SM3();

        /* // Alpha test
        AlphaFunc = GreaterEqual; */

        // Alpha blending


   	}
}


technique GhostPassFoliage_SM3
{
    pass P0
    {
        VertexShader = compile VS_SHADERMODEL FoliageColorVS_SM3();
        PixelShader  = compile PS_SHADERMODEL GhostNonTexturedColorPS_SM3();

        /* // Alpha test
        AlphaFunc = GreaterEqual; */

        // Alpha blending


    }
}


#endif // GHOST_SM3_FX
