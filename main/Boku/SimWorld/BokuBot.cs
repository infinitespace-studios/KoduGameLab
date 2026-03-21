// Copyright (c) Microsoft Corporation.
// Licensed under the MIT license.

using Boku.Base;
using Boku.Common.Xml;

namespace Boku
{
    /// <summary>
    /// Stub for the BokuBot actor class required by BokuBotSRO/BokuBotLRO.
    /// </summary>
    public class BokuBot : GameActor
    {
        private static XmlGameActor xmlGameActor = null;
        public static XmlGameActor XmlActor
        {
            get
            {
                if (xmlGameActor == null)
                    xmlGameActor = XmlGameActor.Deserialize("BokuBot");
                return xmlGameActor;
            }
        }
    }
}
