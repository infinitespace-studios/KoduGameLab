// Copyright (c) Microsoft Corporation.
// Licensed under the MIT license.

using Boku.Base;
using Boku.Common.Xml;

namespace Boku
{
    /// <summary>
    /// Stub for the Popsy actor class required by PopsySRO.
    /// </summary>
    public class Popsy : GameActor
    {
        private static XmlGameActor xmlGameActor = null;
        public static XmlGameActor XmlActor
        {
            get
            {
                if (xmlGameActor == null)
                    xmlGameActor = XmlGameActor.Deserialize("Popsy");
                return xmlGameActor;
            }
        }
    }
}
