// Copyright (c) Microsoft Corporation.
// Licensed under the MIT license.

using System;
using System.Collections.Generic;

using Microsoft.Xna.Framework;

namespace Boku.Common
{
    using Color = Microsoft.Xna.Framework.Color;

    public static partial class SysFont
    {
        /// <summary>
        /// Encapsulates one DrawString call queued in a batch.
        /// Simplified for FontStashSharp — no bitmap/GDI state needed.
        /// </summary>
        public class BatchEntry
        {
            public SystemFont font;
            public string text;
            public Color textColor;
            public Vector2 position;
            public float cameraZoom;

            public Color outlineColor;
            public float outlineWidth;

            public Vector2 scaling = Vector2.One;
            public RectangleF clipRect;

            /// <summary>
            /// private c'tor.
            /// </summary>
            BatchEntry()
            {
            }

            /// <summary>
            /// Create or recycle a BatchEntry from the free list.
            /// </summary>
            public static BatchEntry CreateEntry(string text, Vector2 position, float cameraZoom, SystemFont font, Color textColor, Color outlineColor = default(Color), float outlineWidth = 0, RectangleF clipRect = default(RectangleF), Vector2 scaling = default(Vector2))
            {
                BatchEntry entry = null;
                if (freeEntries.Count > 0)
                {
                    entry = freeEntries[freeEntries.Count - 1];
                    freeEntries.RemoveAt(freeEntries.Count - 1);
                }
                else
                {
                    entry = new BatchEntry();
                }

                if (scaling == default(Vector2))
                {
                    scaling = Vector2.One;
                }

                entry.cameraZoom = cameraZoom;
                entry.scaling = scaling;
                entry.text = text;

                // Adjust position for cameraZoom.
                entry.position = cameraZoom * position;

                entry.font = font;
                entry.textColor = textColor;

                entry.outlineColor = outlineColor;
                entry.outlineWidth = outlineWidth;
                entry.clipRect = clipRect;

                return entry;
            }   // end of CreateEntry()

        }   // end of class BatchEntry

    }   // end of class SysFont
}   // end of namespace Boku.Common
