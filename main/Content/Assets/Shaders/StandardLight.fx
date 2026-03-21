// Copyright (c) Microsoft Corporation.
// Licensed under the MIT license.


#ifndef STANDARD_LIGHT_FX
#define STANDARD_LIGHT_FX

float4      DiffuseColor;
float4      EmissiveColor;
float4      SpecularColor;
float       SpecularPower;
float       Shininess;
float2      Aniso = float2(1.0f, 1.0f);

#include "Light.fx"

#endif // STANDARD_LIGHT_FX
