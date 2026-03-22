// Copyright (c) Microsoft Corporation.
// Licensed under the MIT license.


//
// Particle2D -- A collection of shaders for textured, 2D particles cotrolled by Perlin noise.
//

//
// Global variables
//

#if OPENGL
    #define VS_SHADERMODEL vs_3_0
    #define PS_SHADERMODEL ps_3_0
#else
    #define VS_SHADERMODEL vs_4_0_level_9_1
    #define PS_SHADERMODEL ps_4_0_level_9_1
#endif

float3 EyeLocation;
float3 CameraUp;

//
// Locals.
//

// The world view and projection matrices
float4x4 WorldViewProjMatrix;
float4x4 WorldMatrix;

float4  WaterColor;     // RGB value to tint underwater terrain.  Alpha value is depth where
                        // maximum attenuation happens.

float4 DiffuseColor;    // Base color for tinting sprites.
float2 BaseUV;          // Base used for sampling noise.
float Amplitude;        // How much noise to add;
float Sync;             // How much to scale the value that goes into the UV coord.  Making this smaller
                        // causes neighboring particles to be more in sync.

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

// Math-based noise (replaces vertex texture fetch which is unsupported in vs_3_0 on OpenGL)
float3 HashNoise3(float2 p)
{
    float3 q = float3(dot(p, float2(127.1, 311.7)),
                      dot(p, float2(269.5, 183.3)),
                      dot(p, float2(419.2, 371.9)));
    return frac(sin(q) * 43758.5453);
}

//
// Vertex shader output structure
//
struct VS_OUTPUT
{
    float4 position     : POSITION;     // Vertex position
    float2 textureUV    : TEXCOORD0;    // Vertex texture coords
    float4 color        : COLOR;        // Particle color.
};

// forward decl
VS_OUTPUT ColorVS(
            float3 position : POSITION,
            float2 tex      : TEXCOORD0, 
            float3 params   : TEXCOORD1 );  // rotation, radius, alpha


//
// MultiSample -- bilinear filtering
//

float Texel = 1.0f / 256.0f;
float HalfTexel = 0.5f / 256.0f;

VS_OUTPUT MultiSampleVS(
            float3 position : POSITION,
            float2 tex      : TEXCOORD0, 
            float3 params   : TEXCOORD1 )   // rotation, radius, alpha
{
    VS_OUTPUT   Output;
    
    // Add noise to position using math-based noise (bilinear-style interpolation).
    float2 uv = BaseUV + position.xy * Sync;
    float2 uvScaled = uv * 256.0f;
    float2 uvFloor = floor(uvScaled) / 256.0f;
    float2 fraction = frac(uvScaled);

    float3 noise00 = HashNoise3(uvFloor);
    float3 noise10 = HashNoise3(uvFloor + float2(Texel, 0));
    float3 noise01 = HashNoise3(uvFloor + float2(0, Texel));
    float3 noise11 = HashNoise3(uvFloor + float2(Texel, Texel));
    
    float3 noise = lerp(lerp(noise00, noise01, fraction.y), lerp(noise10, noise11, fraction.y), fraction.x);
    
    position.xyz += 0.5f * Amplitude - Amplitude * noise;
    
    Output = ColorVS( position, tex, params );
    
    return Output;
}

//
// SingleSample
//
VS_OUTPUT SingleSampleVS(
            float3 position : POSITION,
            float2 tex      : TEXCOORD0, 
            float3 params   : TEXCOORD1 )   // rotation, radius, alpha
{
    VS_OUTPUT   Output;
    
    // Add noise to position using math-based noise.
    float2 uv = BaseUV + position.xy * 0.1f;
    float3 noise = HashNoise3(uv);
    position.xyz += 10.0f * noise;

    Output = ColorVS( position, tex, params );
    
    return Output;
}

//
// Color Pass Vertex Shader
//
VS_OUTPUT ColorVS(
            float3 position : POSITION,
            float2 tex      : TEXCOORD0, 
            float3 params   : TEXCOORD1 )   // rotation, radius, alpha
{
    VS_OUTPUT   Output;
    
    // Copy texture over, untouched.    
    Output.textureUV = tex;
    
    float rotation = params.x;
    float radius = params.y;
    
    // Transform position in world coords.
    //float4 worldPosition = mul( position, WorldMatrix );
    //worldPosition /= worldPosition.w;
    
    // Calc the eye vector.  This is the direction from the point to the eye.
    float3 eyeDir = EyeLocation - position;
    eyeDir = normalize( eyeDir );
    
    // Calc right vector.
    float3 right = cross( CameraUp, eyeDir );
    right = normalize( right );
    
    // Calc screen space up vector.
    float3 up = cross( eyeDir, right );
    up = normalize( up );
    
    // Offset world position based on UV coords.
    float sine;
    float cosine;
    sincos( rotation, sine, cosine );
    
    // Move texture coords into -1, 1 range.
    tex = 2.0f * ( tex - 0.5f );
    
    /*
    // Rotate.
    float2 coords = float2( tex.x*cosine - tex.y*sine, tex.x*sine + tex.y*cosine );
    position += right * coords.x * radius;
    position -= up * coords.y * radius;
    */
    position += right * tex.x * radius;
    position -= up * tex.y * radius;
    
        
    // Transform our position.
    float4 pos;
    pos.xyz = position;
    pos.w = 1.0f;
    Output.position = mul( pos, WorldViewProjMatrix );

    // Add underwater tint.
    float amount = saturate( -position.z / WaterColor.a );
    Output.color.rgb = lerp(DiffuseColor.rgb, WaterColor.rgb, amount);
    Output.color.a = DiffuseColor.a * params.z;
    
    // Attenuate alpha by depth based on near clip plane.
    float alpha = 1.0f - Output.position.z / Output.position.w;
    // Fade at near clip rather than pop.
    if(alpha > 0.9)
    {
        alpha = ( 1.0f - alpha ) * 10.0f; 
        Output.color.a *= alpha;
    }
    
    return Output;
}


//
// Color Pass Pixel Shader
//
float4 ColorPS( VS_OUTPUT In ) : COLOR0
{
    // Sample the texture.
    float4 diffuseColor = In.color * tex2D( DiffuseTextureSampler, In.textureUV );
    
    return diffuseColor;

}   // end of PS()


//
// NormalAlphaColorPass technique
//
technique TexturedColorPassNormalAlpha
{
    pass P0
    {
        VertexShader = compile VS_SHADERMODEL MultiSampleVS();
        PixelShader  = compile PS_SHADERMODEL ColorPS();

        // Alpha blending


    }
}

