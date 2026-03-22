// Copyright (c) Microsoft Corporation.
// Licensed under the MIT license.

using FontStashSharp;
using Microsoft.Xna.Framework;

namespace Boku.Common
{
    /// <summary>
    /// Wrapper for a FontStashSharp DynamicSpriteFont that provides
    /// the same API surface as the old System.Drawing.Font-based wrapper.
    /// </summary>
    public class SystemFont
    {
        private DynamicSpriteFont _font;

        public float Padding { get; private set; }
        public string FamilyName { get; private set; }
        public float Size { get; private set; }
        public FontStyle Style { get; private set; }

        public SystemFont(DynamicSpriteFont font, string familyName, float size, FontStyle style, float padding = 0f)
        {
            _font = font;
            FamilyName = familyName;
            Size = size;
            Style = style;
            Padding = padding;
        }

        public int LineSpacing => _font.LineHeight;

        /// <summary>
        /// Returns the size of the rendered string in pixels.
        /// </summary>
        public Vector2 MeasureString(string text)
        {
            if (string.IsNullOrEmpty(text)) return Vector2.Zero;
            return _font.MeasureString(text);
        }

        /// <summary>
        /// The underlying FontStashSharp font used for rendering.
        /// </summary>
        public DynamicSpriteFont Font => _font;

    }   // end of class SystemFont

}   // end of namespace Boku.Common
