// Copyright (c) Microsoft Corporation.
// Licensed under the MIT license.

using System;
using System.Collections.Generic;
using System.Collections.Concurrent;
using System.Linq;
using System.Text;
using System.IO;
using System.Runtime.InteropServices;
using System.Diagnostics;

using Boku.Common;
using Boku.Common.Xml;
using Boku.Programming;

            List<MicrobitDesc> microbitDescs = new List<MicrobitDesc>();

            // Detect microbits.
            microbitDescs = GetDeviceDesc();

            // Open interfaces to devices.
            if (createDevices)
            {
                if (DriverInstalled)
                {
                    if (microbitDescs != null && microbitDescs.Count > 0)
                    {
                        int microbitIndex = (int)GamePadSensor.PlayerId.One;
                        foreach (MicrobitDesc desc in microbitDescs)
                        {
                            Microbit microbit = Microbit.Create(desc);
                            if (microbit != null)
                            {
                                Microbits.TryAdd(microbitIndex++, microbit);
                            }
                        }
                    }
                }
                else
                {
                    // Do nothing here.  The main thread loop will notice that DirverInstalled is false
                    // and should put up the needed dialog there.  We can't do it here since the dialog
                    // can't be shown on a background thread.
                }
            }

            // If none were found, check if user tried the command line.
            if (microbitDescs.Count == 0 && Program2.MicrobitCmdLine != null)
            {
                if (Program2.MicrobitCmdLine.Length == 7)
                {
                    MicrobitDesc desc = new MicrobitDesc();
                    desc.COM = Program2.MicrobitCmdLine.Substring(0, 4);
                    desc.Drive = Program2.MicrobitCmdLine.Substring(5);
                    microbitDescs.Add(desc);
                }
            }

            int deviceCount = createDevices ? Microbits.Count : microbitDescs.Count;

            // If any microbits were detected, then permanently enable visibility of the microbit programming tiles.
            if (!XmlOptionsData.ShowMicrobitTiles && deviceCount > 0)
            {
                XmlOptionsData.ShowMicrobitTiles = true;
                Instrumentation.RecordEvent(Instrumentation.EventId.MicrobitTilesEnabled, "");
            }

            // Track the number of microbits attached at one time.
            if (prevDeviceCount < deviceCount)
            {
                Instrumentation.SetCounter(Instrumentation.CounterId.MicrobitCount, deviceCount);
            }

            return deviceCount;
        }

        /// <summary>
        /// A wrapper around RefreshDevices to allow it to be pushed off on a background thread.
        /// </summary>
        public static void RefreshWorker()
        {
            RefreshDevices();
        }

        public static void ShowDriverDialog()
        {
            DriverInstalled = true;

            var form = new MicrobitNeedDriverDlgForm();
            form.StartPosition = System.Windows.Forms.FormStartPosition.CenterParent;
            System.Windows.Forms.DialogResult dr = form.ShowModal(
                Strings.Localize("microbitNeedsDriverDlg.title"),
                Strings.Localize("microbitNeedsDriverDlg.message"),
                Strings.Localize("microbitNeedsDriverDlg.linkLabel"),
                Strings.Localize("microbitNeedsDriverDlg.cancelLabel"),
                Strings.Localize("microbitNeedsDriverDlg.installLabel"),
                MainForm.Instance);
            if (dr == System.Windows.Forms.DialogResult.OK)
            {
                string filename = Path.Combine(Storage4.TitleLocation, @"Content", @"Microbit", @"mbedWinSerial_16466.exe");
                Process proc = Process.Start(filename);

                // Busy loop while driver is loading.
                while (!proc.HasExited)
                {
                    System.Threading.Thread.Sleep(10);
                }

                // Refresh the list of attached microbits.
                {
                    System.Threading.Thread t = new System.Threading.Thread(new System.Threading.ThreadStart(MicrobitManager.RefreshWorker));
                    t.Start();
                }
            }
        }   // end of ShowDriverDialog()

        /// <summary>
        /// Update each attached microbit.
        /// </summary>
        public static void Update()
        {
            foreach (var bit in Microbits.Values)
            {
                try
                {
                    bit.Update();
                }
                catch
                {
                    // Don't crash if a microbit experiences an exception while updating.
                }
            }
        }
    }
}
