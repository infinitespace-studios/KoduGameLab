// Copyright (c) Microsoft Corporation.
// Licensed under the MIT license.

//
//  Screen Space Quad shaders
//

//
// Variables
//

#if OPENGL
    #define VS_SHADERMODEL vs_3_0
    #define PS_SHADERMODEL ps_3_0
    #define DECLARE_TEXTURE(Name, index) \
        texture2D Name; \
        sampler Name##Sampler : register(s##index) = sampler_state { Texture = (Name); }
    #define SAMPLE_TEXTURE(Name, texCoord) tex2D(Name##Sampler, texCoord)
#else
    #define VS_SHADERMODEL vs_4_0_level_9_1
    #define PS_SHADERMODEL ps_4_0_level_9_1
    #define DECLARE_TEXTURE(Name, index) \
        texture2D Name; \
        sampler Name##Sampler : register(s##index) = sampler_state { Texture = (Name); }
    #define SAMPLE_TEXTURE(Name, texCoord) tex2D(Name##Sampler, texCoord)
#endif

float4 DiffuseColor;
float DiffuseAlpha;

// MonoGame uses SpriteTexture as the convention for binding textures
// via Effect.Parameters on DesktopGL/OpenGL.
DECLARE_TEXTURE(SpriteTexture, 0);
texture ShadowMaskTexture;
texture MaskTexture;
float4 YLimits;

// Split texture specific
texture LeftTexture;
texture RightTexture;
float T;

// Gradient colors for each tap.  The alpha channel
// contains a 0..1 value for their position in the gradient.
// These positions must be strictly ascending.
float4 Color0;
float4 Color1;
float4 Color2;
float4 Color3;
float4 Color4;

//
// Texture samplers
//
sampler2D LeftTextureSampler =
sampler_state
{
    Texture = <LeftTexture>;
    MipFilter = Linear;
    MinFilter = Linear;
    MagFilter = Linear;

    AddressU = Clamp;
    AddressV = Clamp;
};
sampler2D RightTextureSampler =
sampler_state
{
    Texture = <RightTexture>;
    MipFilter = Linear;
    MinFilter = Linear;
    MagFilter = Linear;

    AddressU = Clamp;
    AddressV = Clamp;
};
sampler2D ShadowMaskTextureSampler =
sampler_state
{
    Texture = <ShadowMaskTexture>;
    MipFilter = Linear;
    MinFilter = Linear;
    MagFilter = Linear;

    AddressU = Clamp;
    AddressV = Clamp;
};
sampler2D MaskTextureSampler =
sampler_state
{
    Texture = <MaskTexture>;
    MipFilter = Linear;
    MinFilter = Linear;
    MagFilter = Linear;

    AddressU = Clamp;
    AddressV = Clamp;
};

//
// Vertex shader output structure
//
struct VS_OUTPUT
{
    float4 position     : POSITION;     // vertex position
    float2 textureUV    : TEXCOORD0;    // vertex texture coords
};

//
// Vertex shader
//
VS_OUTPUT
VS( float2 pos : POSITION0,
    float2 tex : TEXCOORD0 )
{
    VS_OUTPUT   Output;

    Output.position = float4( pos.x, pos.y, 0.0f, 1.0f );
    Output.textureUV = tex;

    return Output;
}   // end of VS()

//
// Pixel shaders
//
float4
TexturedPS( VS_OUTPUT In ) : COLOR0
{
    float4 result = DiffuseColor * SAMPLE_TEXTURE(SpriteTexture, In.textureUV );

    return result;
}   // end of TexturedPS()

float4
TexturedAlphaPS( VS_OUTPUT In ) : COLOR0
{
    float4 result = DiffuseColor * SAMPLE_TEXTURE(SpriteTexture, In.textureUV );
    result.a *= DiffuseAlpha;

    return result;
}   // end of TexturedAlphaPS()

float4
MaskTexturedPS( VS_OUTPUT In ) : COLOR0
{
	float2 uv = In.textureUV;
	//uv.y *= 0.75f;
	float4 mask = tex2D( MaskTextureSampler, uv );
    float4 result = mask.r * DiffuseColor * SAMPLE_TEXTURE(SpriteTexture, In.textureUV );

    return result;
}   // end of MaskTexturedPS()

// Version of masking that just uses limits based of on V tex coord.
float4
YLimitTexturedPS( VS_OUTPUT In ) : COLOR0
{
    float4 result = 0;
	float2 uv = In.textureUV;
    float4 text = SAMPLE_TEXTURE(SpriteTexture, uv );

    result = DiffuseColor * text;

    float mask = smoothstep( YLimits.x, YLimits.y, uv.y ) * smoothstep( YLimits.w, YLimits.z, uv.y );

    result *= mask;

    return result;
}   // end of MaskTexturedPS()

float4
TexturedNoAlphaPS( VS_OUTPUT In ) : COLOR0
{
	float4 result = DiffuseColor;
	result.rgb *= SAMPLE_TEXTURE(SpriteTexture, In.textureUV );
	return result;
}

float4
SplitTexturedPS( VS_OUTPUT In ) : COLOR0
{
    float4 left = tex2D( LeftTextureSampler, In.textureUV );
    float4 right = tex2D( RightTextureSampler, In.textureUV );

	float4 result = T > In.textureUV.x ? left : right;
	
    return result;
}   // end of TexturedPS()

//
// Drop Shadow -- This requires a shadow mask texture.  This texture should
//                have the "shape" of the object in white in the RGB channels
//                and a blurred version of this in the alpha channel for the 
//                shadow.
//
float4
DropShadowPS( VS_OUTPUT In ) : COLOR0
{
    float4 diffuse = SAMPLE_TEXTURE(SpriteTexture, In.textureUV );
    float4 mask = tex2D( ShadowMaskTextureSampler, In.textureUV );
    
    float4 result;
    result.rgb = diffuse.rgb * mask.rgb;
    result.a = mask.a;

    return result;
}   // end of DropShadowPS()

//
// SolidColorWithDrop Shadow -- This requires a shadow mask texture.  This texture should
//                              have the "shape" of the object in white in the RGB channels
//                              and a blurred version of this in the alpha channel for the 
//                              shadow.  The RGB channels are attenuated by the DiffuseColor
//
float4
SolidColorWithDropShadowPS( VS_OUTPUT In ) : COLOR0
{
    float4 mask = tex2D( ShadowMaskTextureSampler, In.textureUV );
    
    float4 result;
    result.rgb = DiffuseColor.rgb * mask.rgb;
    result.a = max(mask.r, mask.a);

    return result;
}   // end of SolidColorWithDropShadowPS()

//
// SolidColor -- Just a solid fill in the DiffuseColor.
//
float4
SolidColorPS( VS_OUTPUT In ) : COLOR0
{
    float4 result = DiffuseColor;

    return result;
}   // end of SolidColorPS()

//
// Gradient -- Fill in the sky gradient.
//
float4
GradientPS( VS_OUTPUT In ) : COLOR0
{
    float4 result = float4(0, 0, 0, 0);
    
    // Use V value of input to determine color.

	float z = 1.0f - In.textureUV.y;
	
	if( z < Color0.a )
	{
		result = Color0;
	}
	else if( z < Color1.a )
	{
		z = (z - Color0.a) / ( Color1.a - Color0.a);
		z = smoothstep( 0.0f, 1.0f, z );
		result = lerp( Color0, Color1, z );
	}
	else if( z < Color2.a )
	{
		z = (z - Color1.a) / ( Color2.a - Color1.a);
		z = smoothstep( 0.0f, 1.0f, z );
		result = lerp( Color1, Color2, z );
	}
	else if( z < Color3.a )
	{
		z = (z - Color2.a) / ( Color3.a - Color2.a);
		z = smoothstep( 0.0f, 1.0f, z );
		result = lerp( Color2, Color3, z );
	}
	else if( z < Color4.a )
	{
		z = (z - Color3.a) / ( Color4.a - Color3.a);
		z = smoothstep( 0.0f, 1.0f, z );
		result = lerp( Color3, Color4, z );
	}
	else
	{
		result = Color4;
	}
	
    result.a = 1.0f;


    return result;
}   // end of SolidColorPS()


//
// Stencil
//
float4
StencilPS( VS_OUTPUT In ) : COLOR0
{
    float4 result;
    result.rgba = DiffuseColor.rgba;

    return result;
}   // end of StencilPS()

//
// TexturedNoAlpha
//
technique TexturedNoAlpha
{
    pass P0
    {
        VertexShader = compile VS_SHADERMODEL VS();
        PixelShader  = compile PS_SHADERMODEL TexturedNoAlphaPS();

        /* // Alpha test
        AlphaFunc = GreaterEqual; */

        // Alpha blending


    }
}

//
// TexturedRegularAlpha
//
technique TexturedRegularAlpha
{
    pass P0
    {
        VertexShader = compile VS_SHADERMODEL VS();
        PixelShader  = compile PS_SHADERMODEL TexturedPS();

        /* // Alpha test
        AlphaFunc = GreaterEqual; */

        // Alpha blending


    }
}

//
// TexturedDiffuseAlpha
//
technique TexturedDiffuseAlpha
{
    pass P0
    {
        VertexShader = compile VS_SHADERMODEL VS();
        PixelShader  = compile PS_SHADERMODEL TexturedAlphaPS();

        /* // Alpha test
        AlphaFunc = GreaterEqual; */

        // Alpha blending


    }
}

//
// TexturedRegularAlphaNoZ
//
technique TexturedRegularAlphaNoZ
{
    pass P0
    {
        VertexShader = compile VS_SHADERMODEL VS();
        PixelShader  = compile PS_SHADERMODEL TexturedPS();

        /* // Alpha test
        AlphaFunc = GreaterEqual; */

        // Alpha blending


    }
}

//
// TexturedPreMultAlpha
//
technique TexturedPreMultAlpha
{
    pass P0
    {
        VertexShader = compile VS_SHADERMODEL VS();
        PixelShader  = compile PS_SHADERMODEL TexturedPS();

        /* // Alpha test
        AlphaFunc = GreaterEqual; */

        // Alpha blending


    }
}

//
// MaskTexturedRegularAlpha
//
technique MaskTexturedRegularAlpha
{
    pass P0
    {
        VertexShader = compile VS_SHADERMODEL VS();
        PixelShader  = compile PS_SHADERMODEL MaskTexturedPS();

        /* // Alpha test
        AlphaFunc = GreaterEqual; */

        // Alpha blending


    }
}

//
// MaskTexturedPreMultAlpha
//
technique MaskTexturedPreMultAlpha
{
    pass P0
    {
        VertexShader = compile VS_SHADERMODEL VS();
        PixelShader  = compile PS_SHADERMODEL MaskTexturedPS();

        /* // Alpha test
        AlphaFunc = GreaterEqual; */

        // Alpha blending


    }
}

//
// YLimitTexturedRegularAlpha
//
technique YLimitTexturedRegularAlpha
{
    pass P0
    {
        VertexShader = compile VS_SHADERMODEL VS();
        PixelShader  = compile PS_SHADERMODEL YLimitTexturedPS();

        /* // Alpha test
        AlphaFunc = GreaterEqual; */

        // Alpha blending


    }
}

//
// YLimitTexturedPreMultAlpha
//
technique YLimitTexturedPreMultAlpha
{
    pass P0
    {
        VertexShader = compile VS_SHADERMODEL VS();
        PixelShader  = compile PS_SHADERMODEL YLimitTexturedPS();

        /* // Alpha test
        AlphaFunc = GreaterEqual; */

        // Alpha blending


    }
}



//
// AdditiveBlend
//
technique AdditiveBlend
{
    pass P0
    {
        VertexShader = compile VS_SHADERMODEL VS();
        PixelShader  = compile PS_SHADERMODEL TexturedPS();

        /* // Alpha test
        AlphaFunc = GreaterEqual; */

        // Alpha blending


    }
}

//
// AdditiveBlendWithAlpha
//
technique AdditiveBlendWithAlpha
{
    pass P0
    {
        VertexShader = compile VS_SHADERMODEL VS();
        PixelShader  = compile PS_SHADERMODEL TexturedPS();

        /* // Alpha test
        AlphaFunc = GreaterEqual; */

        // Alpha blending


    }
}


//
// DropShadow
//
technique DropShadow
{
    pass P0
    {
        VertexShader = compile VS_SHADERMODEL VS();
        PixelShader  = compile PS_SHADERMODEL DropShadowPS();

        /* // Alpha test
        AlphaFunc = GreaterEqual; */

        // Alpha blending


    }
}

//
// SolidColor
//
technique SolidColor
{
    pass P0
    {
        VertexShader = compile VS_SHADERMODEL VS();
        PixelShader  = compile PS_SHADERMODEL SolidColorPS();

        /* // Alpha test
        AlphaFunc = GreaterEqual; */

        // Alpha blending


    }
}

//
// SolidColorNoAlpha
//
technique SolidColorNoAlpha
{
    pass P0
    {
        VertexShader = compile VS_SHADERMODEL VS();
        PixelShader  = compile PS_SHADERMODEL SolidColorPS();

        /* // Alpha test
        AlphaFunc = GreaterEqual; */

        // Alpha blending


    }
}

//
// SolidColorWithDropShadow
//
technique SolidColorWithDropShadow
{
    pass P0
    {
        VertexShader = compile VS_SHADERMODEL VS();
        PixelShader  = compile PS_SHADERMODEL SolidColorWithDropShadowPS();

        /* // Alpha test
        AlphaFunc = GreaterEqual; */

        // Alpha blending


    }
}

//
// Stencil
//
technique Stencil
{
    pass P0
    {
        VertexShader = compile VS_SHADERMODEL VS();
        PixelShader  = compile PS_SHADERMODEL StencilPS();

        /* // Alpha test
        AlphaFunc = GreaterEqual; */

        // Alpha blending

        
        StencilFunc = Always;
        StencilPass = Replace;
        StencilRef = 1;


    }
}

//
// Gradient
//
technique Gradient
{
    pass P0
    {
        VertexShader = compile VS_SHADERMODEL VS();
        PixelShader  = compile PS_SHADERMODEL GradientPS();

        /* // Alpha test
        AlphaFunc = GreaterEqual; */

        // Alpha blending


    }
}

//
// SplitTexture
//
technique SplitTexturedRegularAlpha
{
    pass P0
    {
        VertexShader = compile VS_SHADERMODEL VS();
        PixelShader  = compile PS_SHADERMODEL SplitTexturedPS();

        /* // Alpha test
        AlphaFunc = GreaterEqual; */

        // Alpha blending


    }
}





