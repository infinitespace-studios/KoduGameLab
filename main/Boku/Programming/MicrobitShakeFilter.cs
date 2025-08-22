// Copyright (c) Microsoft Corporation.
// Licensed under the MIT license.

using System;
using System.Collections.Generic;
using System.Diagnostics;

using System.Xml;
using System.Xml.Serialization;

using Microsoft.Xna.Framework;
using Microsoft.Xna.Framework.Audio;
using Microsoft.Xna.Framework.Content;
using Microsoft.Xna.Framework.Graphics;
using Microsoft.Xna.Framework.Input;
using Microsoft.Xna.Framework.Storage;

using Boku.Base;
using Boku.Common;
using Boku.Input;

namespace Boku.Programming
{
    public class MicrobitShakeFilter : Filter, IMicrobitTile
    {
        GamePadSensor.PlayerId playerId = GamePadSensor.PlayerId.Dynamic;

        int prevGeneration = 0;
        Vector3 prevAccel = Vector3.Zero;

        public override bool MatchTarget(Reflex reflex, SensorTarget sensorTarget)
        {
            return false;
        }

        public override bool MatchAction(Reflex reflex, out object param)
        {
            // See if there's a filter defining which player we should be.  If not, use bit0.
            if (playerId == GamePadSensor.PlayerId.Dynamic)
            {
                playerId = GamePadSensor.PlayerId.All;

                ReflexData data = reflex.Data;
                for (int i = 0; i < data.Filters.Count; i++)
                {
                    if (data.Filters[i] is PlayerFilter)
                    {
                        playerId = ((PlayerFilter)data.Filters[i]).playerIndex;
                    }
                }
            }

            bool shaken = false;

            param = shaken;

            return shaken;

        }

        public override ProgrammingElement Clone()
        {
            MicrobitShakeFilter clone = new MicrobitShakeFilter();
            CopyTo(clone);
            return clone;
        }
        protected void CopyTo(MicrobitButtonFilter clone)
        {
            base.CopyTo(clone);
        }
    }
}
