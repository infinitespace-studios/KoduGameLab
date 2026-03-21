// Copyright (c) Microsoft Corporation.
// Licensed under the MIT license.

using Boku.Base;
using Boku.Common;

namespace Boku.SimWorld
{
    /// <summary>
    /// Inner child rendering object for Rock.
    /// </summary>
    public class RockSRO : FBXModel
    {
        private static RockSRO sroInstance = null;

        private RockSRO()
            : base(@"Models\rock_low_b")
        {
        }

        /// <summary>
        /// Returns a static, shareable instance of a Rock sro.
        /// </summary>
        public static RockSRO GetInstance()
        {
            if (sroInstance == null)
            {
                sroInstance = new RockSRO();
                sroInstance.XmlActor = Rock.XmlActor;
            }
            return sroInstance;
        }
    }
}
