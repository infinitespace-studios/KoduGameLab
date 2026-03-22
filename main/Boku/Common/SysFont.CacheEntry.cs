// Copyright (c) Microsoft Corporation.
// Licensed under the MIT license.

namespace Boku.Common
{
    public static partial class SysFont
    {
        /// <summary>
        /// Stub retained for compatibility. FontStashSharp manages its own glyph caching
        /// via internal texture atlases, so explicit cache entries are no longer needed.
        /// </summary>
        public class CacheEntry
        {
        }   // end of class CacheEntry

    }   // end of class SysFont
}   // end of namespace Boku.Common
