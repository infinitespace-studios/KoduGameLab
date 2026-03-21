// Copyright (c) Microsoft Corporation.
// Licensed under the MIT license.


#if OPENGL
    #define VS_SHADERMODEL vs_3_0
    #define PS_SHADERMODEL ps_3_0
#else
    #define VS_SHADERMODEL vs_4_0_level_9_1
    #define PS_SHADERMODEL ps_4_0_level_9_1
#endif

#ifndef GHOST_SURF_SM3_FX
#define GHOST_SURF_SM3_FX

float4 GhostNonTexturedColorPS_SURF_SM3( COLOR_VS_OUTPUT_SURF_SM3 In ) : COLOR0
{
    float4 result = NonTexturedColorPS_SURF_SM3( In );

    result = GhostColor(result);

    return result;
}

float4 GhostCloudColorPS_SURF_SM3( COLOR_VS_OUTPUT_SURF_SM3 In ) : COLOR0
{
	float4 result = CloudColorPS_SURF_SM3(In);
	
    result = GhostColor(result);
	
	return result;
}

float4 GhostNonTexturedColorPSBokuFace_SURF_SM3( COLOR_VS_OUTPUT_SURF_SM3 In ) : COLOR0
{
	float4 result = NonTexturedColorPSBokuFace_SURF_SM3(In);
	
    result = GhostColor(result);
	
	return result;
}

float4 GhostNonTexturedColorPSWideFace_SURF_SM3( COLOR_VS_OUTPUT_SURF_SM3 In ) : COLOR0
{
	float4 result = NonTexturedColorPSWideFace_SURF_SM3(In);
	
    result = GhostColor(result);
	
	return result;
}

float4 GhostNonTexturedColorPSTwoFace_SURF_SM3( COLOR_VS_OUTPUT_SURF_SM3 In ) : COLOR0
{
	float4 result = NonTexturedColorPSTwoFace_SURF_SM3(In);
	
    result = GhostColor(result);
	
	return result;
}

//
// Techniques
//
technique GhostPass_SURF_SM3
{
    pass P0
    {
        VertexShader = compile VS_SHADERMODEL ColorSimpTexVS_SURF_SM3();
        PixelShader  = compile PS_SHADERMODEL GhostNonTexturedColorPS_SURF_SM3();

        /* // Alpha test
        AlphaFunc = GreaterEqual; */

        // Alpha blending


    }
}


technique GhostPassCloud_SURF_SM3
{
	pass P0
	{
        VertexShader = compile VS_SHADERMODEL ColorWithSkinVS_SURF_SM3();
        PixelShader  = compile PS_SHADERMODEL GhostCloudColorPS_SURF_SM3();

        /* // Alpha test
        AlphaFunc = GreaterEqual; */

        // Alpha blending


	}
}

technique GhostPassWithFlex_SURF_SM3
{
    pass P0
    {
        VertexShader = compile VS_SHADERMODEL ColorTexWithFlexVS_SURF_SM3();
        PixelShader  = compile PS_SHADERMODEL GhostNonTexturedColorPS_SURF_SM3();

        /* // Alpha test
        AlphaFunc = GreaterEqual; */

        // Alpha blending


    }
}


technique GhostPassWithSkinning_SURF_SM3
{
    pass P0
    {
        VertexShader = compile VS_SHADERMODEL ColorTexWithSkinVS_SURF_SM3();
        PixelShader  = compile PS_SHADERMODEL GhostNonTexturedColorPS_SURF_SM3();

        /* // Alpha test
        AlphaFunc = GreaterEqual; */

        // Alpha blending


    }
}

technique GhostPassBokuFaceWithSkinning_SURF_SM3
{
	pass P0
	{
        VertexShader = compile VS_SHADERMODEL ColorTexWithSkinVS_SURF_SM3();
        PixelShader  = compile PS_SHADERMODEL GhostNonTexturedColorPSBokuFace_SURF_SM3();

        /* // Alpha test
        AlphaFunc = GreaterEqual; */

        // Alpha blending


   	}
}

technique GhostPassWideFaceWithSkinning_SURF_SM3
{
	pass P0
	{
        VertexShader = compile VS_SHADERMODEL ColorTexWithSkinVS_SURF_SM3();
        PixelShader  = compile PS_SHADERMODEL GhostNonTexturedColorPSWideFace_SURF_SM3();

        /* // Alpha test
        AlphaFunc = GreaterEqual; */

        // Alpha blending


   	}
}

technique GhostPassTwoFaceWithSkinning_SURF_SM3
{
	pass P0
	{
        VertexShader = compile VS_SHADERMODEL ColorTexWithSkinVS_SURF_SM3();
        PixelShader  = compile PS_SHADERMODEL GhostNonTexturedColorPSTwoFace_SURF_SM3();

        /* // Alpha test
        AlphaFunc = GreaterEqual; */

        // Alpha blending


   	}
}

technique GhostPassWithWind_SURF_SM3
{
	pass P0
	{
        VertexShader = compile VS_SHADERMODEL ColorWithWindVS_SURF_SM3();
        PixelShader  = compile PS_SHADERMODEL GhostNonTexturedColorPS_SURF_SM3();

        /* // Alpha test
        AlphaFunc = GreaterEqual; */

        // Alpha blending


   	}
}


technique GhostPassFoliage_SURF_SM3
{
    pass P0
    {
        VertexShader = compile VS_SHADERMODEL FoliageColorVS_SURF_SM3();
        PixelShader  = compile PS_SHADERMODEL GhostNonTexturedColorPS_SURF_SM3();

        /* // Alpha test
        AlphaFunc = GreaterEqual; */

        // Alpha blending


    }
}


#endif // GHOST_SURF_SM3_FX
