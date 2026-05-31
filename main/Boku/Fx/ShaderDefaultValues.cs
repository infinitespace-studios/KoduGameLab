// Copyright (c) Microsoft Corporation.
// Licensed under the MIT license.

using Microsoft.Xna.Framework;
using Microsoft.Xna.Framework.Graphics;

namespace Boku.Fx
{
    internal static class ShaderDefaultValues
    {
        public static void ApplySharedDefaults(Effect effect)
        {
            if (effect == null)
            {
                return;
            }

            // MojoShader on DesktopGL doesn't preserve HLSL default initialisers.
            effect.Parameters["LightWrap"]?.SetValue(new Vector3(1.0f, 0.5f, 0.5f));
            effect.Parameters["WindStrength"]?.SetValue(1.0f);
            effect.Parameters["Aniso"]?.SetValue(new Vector2(1.0f, 1.0f));
        }

        public static void ApplyDistortDefaults(Effect effect)
        {
            ApplySharedDefaults(effect);
            effect.Parameters["BumpScroll"]?.SetValue(new Vector4(0.0f, 0.0f, 0.0f, 0.0f));
            effect.Parameters["BumpScale"]?.SetValue(new Vector4(1.0f, 1.0f, 1.0f, 1.0f));
            effect.Parameters["BumpStrength"]?.SetValue(1.0f);
            effect.Parameters["BumpTransU"]?.SetValue(new Vector4(0.0f, 0.0f, 0.0f, 0.0f));
            effect.Parameters["BumpTransV"]?.SetValue(new Vector4(0.0f, 0.0f, 0.0f, 0.0f));
            effect.Parameters["BumpTint"]?.SetValue(new Vector4(0.0f, 1.0f, 1.0f, 1.0f));
            effect.Parameters["PreWorld"]?.SetValue(Matrix.Identity);
            effect.Parameters["Opacity"]?.SetValue(new Vector4(1.0f, 1.0f, 1.0f, 1.0f));
        }

        public static void ApplyDistortFilterDefaults(Effect effect)
        {
            ApplySharedDefaults(effect);
            effect.Parameters["BumpStrength"]?.SetValue(1.0f);
            effect.Parameters["BumpScroll"]?.SetValue(new Vector4(0.0f, 0.0f, 0.0f, 0.0f));
            effect.Parameters["BumpScale"]?.SetValue(new Vector4(1.0f, 1.0f, 1.0f, 1.0f));
            effect.Parameters["WaterColor"]?.SetValue(new Vector3(0.2f, 0.5f, 0.6f));
        }

        public static void ApplyDofFilterDefaults(Effect effect)
        {
            ApplySharedDefaults(effect);
            effect.Parameters["DOF_MinBlur"]?.SetValue(new Vector2(0.0f, 1.0f));
        }

        public static void ApplyFpeDistortDefaults(Effect effect)
        {
            effect.Parameters["BumpScroll"]?.SetValue(new Vector4(0.0f, 0.0f, 0.0f, 0.0f));
            effect.Parameters["BumpScale"]?.SetValue(new Vector4(1.0f, 1.0f, 1.0f, 1.0f));
        }

        public static void ApplyNoiseParticle2DDefaults(Effect effect)
        {
            ApplySharedDefaults(effect);
            effect.Parameters["Texel"]?.SetValue(1.0f / 256.0f);
            effect.Parameters["HalfTexel"]?.SetValue(0.5f / 256.0f);
        }

        public static void ApplyParticle2DDefaults(Effect effect)
        {
            ApplySharedDefaults(effect);
            effect.Parameters["BumpStrength"]?.SetValue(1.0f);
            effect.Parameters["BlurStrength"]?.SetValue(1.0f);
            effect.Parameters["BumpScroll"]?.SetValue(new Vector4(0.0f, 0.0f, 0.0f, 0.0f));
            effect.Parameters["BumpScale"]?.SetValue(new Vector4(1.0f, 1.0f, 1.0f, 1.0f));
        }

        public static void ApplyRippleDefaults(Effect effect)
        {
            ApplySharedDefaults(effect);
            effect.Parameters["UvExpand"]?.SetValue(new Vector4(10.0f, 9.0f, 5.0f, 4.0f));
        }

        public static void ApplyUtilsDefaults(Effect effect)
        {
            effect.Parameters["RunWidth"]?.SetValue(new Vector2(1.0f, 1.0f));
            effect.Parameters["RunPhase"]?.SetValue(0.0f);
            effect.Parameters["RunCount"]?.SetValue(1.0f);
            effect.Parameters["RunCutOff"]?.SetValue(0.33f);
            effect.Parameters["RunEndColor"]?.SetValue(new Vector4(0.0f, 1.0f, 1.0f, 1.0f));
        }
    }
}
