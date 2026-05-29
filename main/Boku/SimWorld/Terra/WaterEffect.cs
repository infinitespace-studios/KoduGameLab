// Copyright (c) Microsoft Corporation.
// Licensed under the MIT license.


using System;
using System.Collections.Generic;
using System.Text;

using Microsoft.Xna.Framework;
using Microsoft.Xna.Framework.Graphics;

using Boku.Fx;
using Boku.Common;

namespace Boku.SimWorld.Terra
{
    /// <summary>
    /// Pull away all the dealings with the water rendering effect. This file isn't
    /// for defining a new class, just the parts of VirtualMap dealing with Water
    /// rendering state.
    /// </summary>
    public partial class VirtualMap
    {
        #region EFFECT_CACHE
        private enum EffectParams
        {
            WorldToNDC, // global
            BumpMap, // global
            WaveCycle, // global
            WaveCenter, // global
            HalfSize, // global
            InverseWaveLength, // global, 2 * PI / WaveLength
            TextureTile, // global 1.0f / texture size in world space
            NeighborCutoff, // global, 0.25 for normal, 0.75 for edit mode (glass walls at holes)
            WaveHeight, // per water
            BaseHeight, // per water
            Color, // per water
            Fresnel, // per water
            Shininess, // per water
            Emissive, // per water
            ToNeighbor, // per face
            NeighborSelect, // per face
            UVToX, // per face
            UVToY, // per face
            IsTop, // per face
            BumpToWorld, // per face
            LightDir,   // per face
        };
        private enum EffectTechs
        {
            DepthPass = InGame.RenderEffect.Normal,
            EditMode,
            ColorPass,
        };
        private EffectParameter Parameter(EffectParams param)
        {
            return effectCache.Parameter((int)param);
        }
        private EffectTechnique Technique(EffectTechs tech)
        {
            return effectCache.Technique((int)tech);
        }
        private EffectCache effectCache = new EffectCache<EffectParams, EffectTechs>();
        #endregion EFFECT_CACHE

        #region MEMBERS
        private Effect effect = null;
        public string bumpMapFilename;
        private Texture2D bumpMap = null;

        private Vector2[] toNeighbors = new Vector2[Tile.NumFaces];
        private Vector3[] uvToX = new Vector3[Tile.NumFaces];
        private Vector3[] uvToY = new Vector3[Tile.NumFaces];
        private Vector4[] neighborSelect = new Vector4[Tile.NumFaces];
        private Matrix[] bumpToWorld = new Matrix[Tile.NumFaces];
        private Vector3[] lightDir = new Vector3[Tile.NumFaces];
        #endregion MEMBERS

        #region INTERNAL
        private void LoadWaterEffect()
        {
            if (effect == null)
            {
                effect = BokuGame.Load<Effect>(BokuGame.Settings.MediaPath + @"Shaders\Water");
                ShaderGlobals.RegisterEffect("Water", effect);

                effectCache.Load(effect);
            }
            if (bumpMap == null)
            {
                if((bumpMapFilename == null)||(bumpMapFilename == ""))
                {
                    bumpMapFilename = @"Textures\Terrain\WaterNormalMap";
                }
                bumpMap = BokuGame.Load<Texture2D>(BokuGame.Settings.MediaPath + bumpMapFilename);
            }

            SetupToNeighbors();
            SetupUvToOffsets();
            SetupNeighborSelects();
            SetupBumpToWorlds();
            SetupLightDirs();
        }

        private void UnloadWaterEffect()
        {
            if (effect != null)
            {
                BokuGame.Release(ref effect);

                effectCache.UnLoad();
            }
            if (bumpMap != null)
            {
                BokuGame.Release(ref bumpMap);
            }
        }

        public void SetupWaterEffect(Camera camera, Matrix localToWorld, bool effects)
        {
            effect.CurrentTechnique = Technique(effects ? EffectTechs.DepthPass : EffectTechs.ColorPass);

            Matrix worldToCamera = camera.ViewMatrix;
            Matrix cameraToNDC = camera.ProjectionMatrix;

            Matrix worldToNDC = localToWorld * worldToCamera * cameraToNDC;
            effectCache.TrySet((int)(EffectParams.WorldToNDC), worldToNDC);
            effectCache.TrySet((int)(EffectParams.BumpMap), bumpMap);

            float waveCycle = (float)Time.GameTimeTotalSeconds;
            effectCache.TrySet((int)(EffectParams.WaveCycle), waveCycle);

            effectCache.TrySet((int)(EffectParams.WaveCenter), new Vector2(127.0f, 600.0f));

            effectCache.TrySet((int)(EffectParams.HalfSize), CubeSize * 0.5f);
            const double WaveLength = 15.0;
            effectCache.TrySet((int)(EffectParams.InverseWaveLength), (float)(2.0 * Math.PI / WaveLength));

            effectCache.TrySet((int)(EffectParams.NeighborCutoff), 
                Terrain.WaterBusy ? 0.75f : 0.25f);
        }
        public void SetupWaterEffect(Water.Definition def, float baseHeight)
        {
            /// Give the water a shot at setting up body specific parameters.
            effectCache.TrySet((int)(EffectParams.Color), def.Color);
            effectCache.TrySet((int)(EffectParams.BaseHeight), baseHeight);
            effectCache.TrySet((int)(EffectParams.WaveHeight), Terrain.WaveHeight);
            effectCache.TrySet((int)(EffectParams.Fresnel), def.Fresnel);
            effectCache.TrySet((int)(EffectParams.Shininess), def.Shininess);
            effectCache.TrySet((int)(EffectParams.Emissive), def.Emissive);
            effectCache.TrySet((int)(EffectParams.TextureTile), def.TextureTiling);

            ShaderGlobals.FixExplicitBloom(def.ExplicitBloom);
        }
        private void SetupWaterFaceEffect(int face)
        {
            float halfSize = CubeSize * 0.5f;
            effectCache.TrySet((int)(EffectParams.ToNeighbor), toNeighbors[face] * CubeSize);
            effectCache.TrySet((int)(EffectParams.IsTop), face == (int)Tile.Face.Top ? 2.0f : 0.0f);
            effectCache.TrySet((int)(EffectParams.NeighborSelect), neighborSelect[face]);

            effectCache.TrySet((int)(EffectParams.UVToX), uvToX[face] * halfSize);
            effectCache.TrySet((int)(EffectParams.UVToY), uvToY[face] * halfSize);

            effectCache.TrySet((int)(EffectParams.BumpToWorld), bumpToWorld[face]);
            effectCache.TrySet((int)(EffectParams.LightDir), lightDir[face]);
        }
        private void EndWaterEffect()
        {
            ShaderGlobals.ReleaseExplicitBloom();
        }

        private void SetupToNeighbors()
        {
            toNeighbors[(int)Tile.Face.Top] = Vector2.Zero;
            toNeighbors[(int)Tile.Face.Front] = new Vector2(0.0f, -1.0f);
            toNeighbors[(int)Tile.Face.Back] = new Vector2(0.0f, 1.0f);
            toNeighbors[(int)Tile.Face.Right] = new Vector2(1.0f, 0.0f);
            toNeighbors[(int)Tile.Face.Left] = new Vector2(-1.0f, 0.0f);
        }
        private void SetupUvToOffsets()
        {
            uvToX[(int)Tile.Face.Top] = new Vector3(1.0f, 0.0f, 0.0f);
            uvToY[(int)Tile.Face.Top] = new Vector3(0.0f, 1.0f, 0.0f);

            uvToX[(int)Tile.Face.Front] = new Vector3(-1.0f, 0.0f, 0.0f);
            uvToY[(int)Tile.Face.Front] = new Vector3(0.0f, 0.0f, -1.0f);

            uvToX[(int)Tile.Face.Back] = -uvToX[(int)Tile.Face.Front];
            uvToY[(int)Tile.Face.Back] = -uvToY[(int)Tile.Face.Front];

            uvToX[(int)Tile.Face.Right] = new Vector3(0.0f, 0.0f, 1.0f);
            uvToY[(int)Tile.Face.Right] = new Vector3(1.0f, 0.0f, 0.0f);

            uvToX[(int)Tile.Face.Left] = -uvToX[(int)Tile.Face.Right];
            uvToY[(int)Tile.Face.Left] = -uvToY[(int)Tile.Face.Right];
        }
        private void SetupNeighborSelects()
        {
            neighborSelect[(int)Tile.Face.Top] = Vector4.Zero;
            neighborSelect[(int)Tile.Face.Front] = new Vector4(0.0f, 0.0f, 1.0f, 0.0f);
            neighborSelect[(int)Tile.Face.Back] = new Vector4(1.0f, 0.0f, 0.0f, 0.0f);
            neighborSelect[(int)Tile.Face.Right] = new Vector4(0.0f, 1.0f, 0.0f, 0.0f);
            neighborSelect[(int)Tile.Face.Left] = new Vector4(0.0f, 0.0f, 0.0f, 1.0f);

        }
        private void SetupBumpToWorlds()
        {
            bumpToWorld[(int)Tile.Face.Top] = Matrix.Identity;

            bumpToWorld[(int)Tile.Face.Front] = new Matrix(
                1.0f, 0.0f, 0.0f, 0.0f,
                0.0f, 0.0f, 1.0f, 0.0f,
                0.0f, -1.0f, 0.0f, 0.0f,
                0.0f, 0.0f, 0.0f, 1.0f);
            bumpToWorld[(int)Tile.Face.Back] = new Matrix(
                -1.0f, 0.0f, 0.0f, 0.0f,
                0.0f, 0.0f, 1.0f, 0.0f,
                0.0f, 1.0f, 0.0f, 0.0f,
                0.0f, 0.0f, 0.0f, 1.0f);

            bumpToWorld[(int)Tile.Face.Left] = new Matrix(
                0.0f, 1.0f, 0.0f, 0.0f,
                0.0f, 0.0f, 1.0f, 0.0f,
                -1.0f, 0.0f, 0.0f, 0.0f,
                0.0f, 0.0f, 0.0f, 1.0f);
            bumpToWorld[(int)Tile.Face.Right] = new Matrix(
                0.0f, -1.0f, 0.0f, 0.0f,
                0.0f, 0.0f, 1.0f, 0.0f,
                1.0f, 0.0f, 0.0f, 0.0f,
                0.0f, 0.0f, 0.0f, 1.0f);
        }
        private void SetupLightDirs()
        {
            lightDir[(int)Tile.Face.Top] = new Vector3(0.0f, 0.0f, 1.0f);
            lightDir[(int)Tile.Face.Front] = new Vector3(0.0f, -1.0f, 0.0f);
            lightDir[(int)Tile.Face.Back] = new Vector3(0.0f, 1.0f, 0.0f);
            lightDir[(int)Tile.Face.Right] = new Vector3(1.0f, 0.0f, 0.0f);
            lightDir[(int)Tile.Face.Left] = new Vector3(-1.0f, 0.0f, 0.0f);
        }
        #endregion INTERNAL
    }
}
