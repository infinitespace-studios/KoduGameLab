// Copyright (c) Microsoft Corporation.
// Licensed under the MIT license.


#ifndef GLOBALS_H
#define GLOBALS_H

//
// Shared Globals.
//

// UI lights
float3   UILightDirection0;  // Direction light is travelling.
float3   UILightColor0;
float3   UILightDirection1;  // Direction light is travelling.
float3   UILightColor1;
float3   UILightDirection2;  // Direction light is travelling.
float3   UILightColor2;

float4	FogVector;			// Scale, Offset, Max, unused
float3   FogColor;

float4   EyeLocation;		// These separate values for camera,
float4	CameraDir;			// position, direction etc., are 
float4   CameraUp;			// redundant with the WorldToCamera transform
float4x4	WorldToCamera;		// which we also need. Could replace with functions?

float    BloomThreshold;     // Limit above which blooms happens.
float    BloomStrength;      // Multiplier for amount of bloom to add.

float    DOF_NearPlane;      // Near distance at which blur is max.
float    DOF_FocalPlane;     // Distance at which everything is in focus.
float    DOF_FarPlane;       // Far distance at which blur is max.
float    DOF_MaxBlur;        // Max amount of blur, only applies to far plane.

float4	BloomColor;		// Constant color to write to bloom map.

#define NUM_LUZ (10) /// Must match kMaxLights in Luz.cs
float4	LightPosition[NUM_LUZ]; /// position.xyz, 1/radius in .w
float4	LightColor[NUM_LUZ]; /// color.rgb, wrap in .w

float3   LightWrap = float3(1.0f, 0.5f, 0.5f);	// 0 == no wrap, 1 == full, spherical lighting.
														// y is 1.0f / (1.0f + Wrap.x);
														// z is Wrap.x / (1.0f + Wrap.x);

// From Light.fx
// Light 0 is the key light, which shadows are based off of.
float4   LightDirection0;    // Direction light is travelling.
float3   LightColor0;
float4   LightDirection1;    // Direction light is travelling.
float3   LightColor1;
float4   LightDirection2;    // Direction light is travelling.
float3   LightColor2;
float4   LightDirection3;    // Direction light is travelling.
float3   LightColor3;

float4	WarpCenter;

texture ShadowTexture;
texture ShadowMask;
float4 ShadowTextureOffsetScale;    // Offset (x,y) and Scale (z,w) values used to translate 
                                    // the XY coord of the pixel into shadow UV coords.
float4 ShadowMaskOffsetScale; // same, but for the shadowmask
float    ShadowAttenuation;  // How dark should the shadows be.


#endif // GLOBALS_H
