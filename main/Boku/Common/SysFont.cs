// Copyright (c) Microsoft Corporation.
// Licensed under the MIT license.

using System;
using System.Collections.Generic;
using System.Diagnostics;
using System.IO;
using System.Text;

using FontStashSharp;
using Microsoft.Xna.Framework;
using Microsoft.Xna.Framework.Graphics;

namespace Boku.Common
{
    using Color = Microsoft.Xna.Framework.Color;

    /// <summary>
    /// Static class providing font rendering via FontStashSharp.
    /// Replaces the old GDI+/System.Drawing based rendering pipeline.
    /// Text is rendered directly to SpriteBatch — no Bitmap/Texture transfer needed.
    /// </summary>
    public static partial class SysFont
    {
        #region Members

        // Kept for callers that reference MaxWidth (e.g. TextBlob).
        static public int MaxWidth = 2048;
        static public int MaxHeight = 1024;

        static GraphicsDevice graphicsDevice;

        // Font data loaded from TTF files, kept in memory for creating FontSystem instances.
        static byte[] regularFontData;
        static byte[] boldFontData;

        // A single FontSystem per style (regular/bold). Effects are per-draw-call in FontStashSharp 1.5.4.
        static FontSystem regularFontSystem;
        static FontSystem boldFontSystem;

        static SpriteCamera camera;
        static bool inBatch = false;
        static List<BatchEntry> entries;
        static List<BatchEntry> freeEntries;
        static Dictionary<string, SystemFont> systemFonts;

        static string fontsBasePath;

        #endregion

        #region Public

        /// <summary>
        /// Initialize the font system. Loads TTF font data from disk.
        /// </summary>
        public static void Init(GraphicsDevice device)
        {
            graphicsDevice = device;

            systemFonts = new Dictionary<string, SystemFont>();
            entries = new List<BatchEntry>();
            freeEntries = new List<BatchEntry>();

            // Resolve font file paths relative to executable.
            string baseDir = AppContext.BaseDirectory;
            fontsBasePath = Path.Combine(baseDir, "Content", "Fonts");

            // Fallback to Content/Assets/Fonts if fonts aren't in the output dir
            if (!Directory.Exists(fontsBasePath))
                fontsBasePath = Path.Combine(baseDir, "Content", "Assets", "Fonts");

            // Pre-load font data into memory and create font systems.
            string regularPath = Path.Combine(fontsBasePath, "Calibri.ttf");
            if (File.Exists(regularPath))
                regularFontData = File.ReadAllBytes(regularPath);

            string boldPath = Path.Combine(fontsBasePath, "Calibri Bold.ttf");
            if (File.Exists(boldPath))
                boldFontData = File.ReadAllBytes(boldPath);

            regularFontSystem = new FontSystem();
            if (regularFontData != null)
                regularFontSystem.AddFont(regularFontData);

            boldFontSystem = new FontSystem();
            if (boldFontData != null)
                boldFontSystem.AddFont(boldFontData);
        }   // end of Init()

        /// <summary>
        /// Overload for backward compatibility with callers that pass no arguments.
        /// </summary>
        public static void Init()
        {
            Init(BokuGame.bokuGame.GraphicsDevice);
        }

        public static void CleanUp()
        {
            systemFonts?.Clear();

            regularFontSystem?.Dispose();
            regularFontSystem = null;
            boldFontSystem?.Dispose();
            boldFontSystem = null;

            regularFontData = null;
            boldFontData = null;
        }   // end of CleanUp()

        /// <summary>
        /// Start a new batch of SysFont text rendering.
        /// Batches may freely mix fonts, styles, sizes and colors.
        /// </summary>
        public static void StartBatch(SpriteCamera camera)
        {
            SysFont.camera = camera;
            inBatch = true;
        }   // end of StartBatch()

        /// <summary>
        /// Queue text for rendering in the current batch.
        /// </summary>
        /// <param name="text">Text to draw.</param>
        /// <param name="position">Position for rendering.</param>
        /// <param name="clipRect">Rect to clip text to.</param>
        /// <param name="font">SystemFont to use.</param>
        /// <param name="textColor">Color for text.</param>
        /// <param name="scaling">Only applied to text, not rect.</param>
        /// <param name="outlineColor">Outline color (if outlineWidth > 0).</param>
        /// <param name="outlineWidth">Outline width in pixels. 0 = no outline.</param>
        /// <returns>Size of the rendered text area.</returns>
        public static Vector2 DrawString(string text, Vector2 position, RectangleF clipRect, SystemFont font, Color textColor, Vector2 scaling = default(Vector2), Color outlineColor = default(Color), float outlineWidth = 0)
        {
            Debug.Assert(inBatch, "You must call StartBatch() before this and EndBatch() when done.");

            if (string.IsNullOrEmpty(text))
                return Vector2.Zero;

            if (scaling == default(Vector2))
            {
                scaling = Vector2.One;
            }

            float zoom = camera != null ? camera.Zoom : 1.0f;

            if (zoom != 1.0f)
            {
                // Create a font at the zoomed size for crisp rendering at any zoom level.
                font = GetSystemFont(font.FamilyName, font.Size * zoom, font.Style);
            }

            BatchEntry entry = BatchEntry.CreateEntry(text, position, zoom, font, textColor, outlineColor, outlineWidth, clipRect, scaling);
            entries.Add(entry);

            Vector2 textSize = font.MeasureString(text);
            return new Vector2(textSize.X + 2.0f * zoom * outlineWidth, textSize.Y);
        }   // end of DrawString()

        /// <summary>
        /// Ends the current batch and renders all queued text to the backbuffer/rendertarget.
        /// FontStashSharp renders directly via SpriteBatch — no bitmap transfer needed.
        /// </summary>
        public static void EndBatch()
        {
            if (entries.Count == 0)
            {
                inBatch = false;
                return;
            }

            SpriteBatch batch = UI2D.Shared.SpriteBatch;
            Matrix? transform = null;

            if (camera != null)
            {
                Matrix mat = Matrix.CreateScale(1.0f / camera.Zoom);
                mat *= camera.ViewMatrix;
                transform = mat;
            }

            batch.Begin(SpriteSortMode.Deferred, BlendState.AlphaBlend,
                samplerState: null, depthStencilState: null, rasterizerState: null,
                effect: null, transformMatrix: transform);

            foreach (BatchEntry entry in entries)
            {
                Vector2 pos = entry.position;

                if (entry.outlineWidth > 0)
                {
                    int effectAmount = (int)Math.Max(1, Math.Ceiling(entry.outlineWidth * entry.cameraZoom));

                    // Pass 1: Draw stroked version in outline color (outline + fill area).
                    batch.DrawString(entry.font.Font, entry.text, pos, entry.outlineColor,
                        scale: entry.scaling,
                        effect: FontSystemEffect.Stroked, effectAmount: effectAmount);

                    // Pass 2: Draw normal text on top in text color.
                    batch.DrawString(entry.font.Font, entry.text, pos, entry.textColor,
                        scale: entry.scaling);
                }
                else
                {
                    batch.DrawString(entry.font.Font, entry.text, pos, entry.textColor,
                        scale: entry.scaling);
                }
            }

            batch.End();

            inBatch = false;

            // Move all batch entries to free list.
            foreach (BatchEntry entry in entries)
            {
                freeEntries.Add(entry);
            }
            entries.Clear();

        }   // end of EndBatch()

        #endregion

        #region Internal

        static string SystemFontKey(string familyName, float emSize, FontStyle style)
        {
            string fontKey = familyName + " " + emSize.ToString() + style.ToString();
            return fontKey;
        }

        public static SystemFont GetSystemFont(string familyName, float emSize, FontStyle style)
        {
            // Force font sizes to be increments of 0.1.
            emSize = (float)Math.Round(emSize, 1);
            emSize = Math.Max(emSize, 0.1f);

            string systemFontKey = SystemFontKey(familyName, emSize, style);

            SystemFont systemFont = null;
            if (!systemFonts.TryGetValue(systemFontKey, out systemFont))
            {
                bool bold = (style == FontStyle.Bold || style == FontStyle.BoldItalic);
                FontSystem fs = bold ? boldFontSystem : regularFontSystem;
                DynamicSpriteFont dynamicFont = fs.GetFont(emSize);
                systemFont = new SystemFont(dynamicFont, familyName, emSize, style);
                systemFonts[systemFontKey] = systemFont;
            }

            return systemFont;
        }

        #endregion
    }   // end of class SysFont
}   // end of namespace Boku.Common
