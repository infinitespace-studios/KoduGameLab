// Copyright (c) Microsoft Corporation.
// Licensed under the MIT license.

using System;
using System.IO;
using System.Text;
using System.Diagnostics;
using System.Collections.Generic;
using System.Runtime.InteropServices;

    using Windows.Storage;
#endif

namespace Cab
{
    /// <summary>
    /// Creates a CAB archive.
    /// 
    /// Usage:
    /// 
    ///     Compressor comp = new Compressor();
    ///     comp.Create(@"C:\MyCabFiles", @"MyArchive.cab");
    ///     comp.AddFile(null, "personal.xml");
    ///     comp.AddFile(null, "virus.exe");
    ///     comp.Destroy();
    ///     
    ///  Limitations:
    ///     The underlying system component "cabinet.dll" does not support
    ///     multithreaded usage. We do nothing to improve on this.
    ///     
    /// </summary>
    public partial class Compressor
    {
        public Compressor(ICompressorHelper compressorHelper)
        {
            this.compressorHelper = compressorHelper;

            // Store a null file stream at index zero, since cabinet.dll doesn't like
            // file handles with a value of zero.
            streams.Add(Stream.Null);
            filenames.Add("null");

            InitDelegates();
        }

        /// <summary>
        /// Override to receive progress callbacks during compression.
        /// </summary>
        public virtual void Progress()
        {
        }

    }   // end of partial class Compressor


    partial class Compressor
    {
        static ushort seq;

        int handle;

        Cabinet.ERF erf;

        Cabinet.CCAB ccab;

        List<Stream> streams = new List<Stream>();

        List<string> filenames = new List<string>();

        byte[] scratchBuffer = new byte[0];

        ICompressorHelper compressorHelper;

        void ResizeScratchBuffer(int size)
        {
            if (scratchBuffer.Length < size)
            {
                scratchBuffer = new byte[size];
            }
        }

        Cabinet.FciAllocFn FciAllocDelegate;
        Cabinet.FciFreeFn FciFreeDelegate;
        Cabinet.FciFilePlacedFn FciFilePlacedDelegate;
        Cabinet.FciOpenFn FciOpenDelegate;
        Cabinet.FciReadFn FciReadDelegate;
        Cabinet.FciWriteFn FciWriteDelegate;
        Cabinet.FciCloseFn FciCloseDelegate;
        Cabinet.FciSeekFn FciSeekDelegate;
        Cabinet.FciDeleteFn FciDeleteDelegate;
        Cabinet.FciGetTempFileFn FciGetTempFileDelegate;
        Cabinet.FciGetNextCabinetFn FciGetNextCabinetDelegate;
        Cabinet.FciStatusFn FciStatusDelegate;
        Cabinet.FciGetOpenInfoFn FciGetOpenInfoDelegate;

        void InitDelegates()
        {
            FciAllocDelegate = new Cabinet.FciAllocFn(FciAlloc);
            FciFreeDelegate = new Cabinet.FciFreeFn(FciFree);
            FciFilePlacedDelegate = new Cabinet.FciFilePlacedFn(FciFilePlaced);
            FciOpenDelegate = new Cabinet.FciOpenFn(FciOpen);
            FciReadDelegate = new Cabinet.FciReadFn(FciRead);
            FciWriteDelegate = new Cabinet.FciWriteFn(FciWrite);
            FciCloseDelegate = new Cabinet.FciCloseFn(FciClose);
            FciSeekDelegate = new Cabinet.FciSeekFn(FciSeek);
            FciDeleteDelegate = new Cabinet.FciDeleteFn(FciDelete);
            FciGetTempFileDelegate = new Cabinet.FciGetTempFileFn(FciGetTempFile);
            FciGetNextCabinetDelegate = new Cabinet.FciGetNextCabinetFn(FciGetNextCabinet);
            FciStatusDelegate = new Cabinet.FciStatusFn(FciStatus);
            FciGetOpenInfoDelegate = new Cabinet.FciGetOpenInfoFn(FciGetOpenInfo);
        }

        IntPtr FciAlloc(uint cb)
        {
            return Marshal.AllocHGlobal((int)cb);
        }

        void FciFree(IntPtr memory)
        {
            Marshal.FreeHGlobal(memory);
        }

        int FciFilePlaced(
            ref Cabinet.CCAB pccab,
            IntPtr pszFile,
            int cbFile,
            int fContinuation,
            IntPtr pv)
        {
            string filename = Util.StringFromPtr(pszFile);

            return 0;
        }

        int FciOpen(
            IntPtr pszFile,
            Rtl.OFLAG oflag,
            Rtl.PMODE pmode,
            ref int err,
            IntPtr pv)
        {
            string filename = Util.StringFromPtr(pszFile);

            FileMode fileMode = Util.FileModeFromDos(oflag);

            FileAccess fileAccess = Util.FileAccessFromDos(oflag, pmode);

            int hf = -1;

            for (int i = 0; i < streams.Count; ++i)
            {
                if (streams[i] == null)
                {
                    hf = i;
                    break;
                }
            }

            if (hf == -1)
            {
                hf = streams.Count;
                streams.Add(null);
                filenames.Add(null);
            }

            streams[hf] = compressorHelper.Open(filename, fileMode, fileAccess, FileShare.ReadWrite); //File.Open(filename, fileMode, fileAccess, FileShare.ReadWrite);
            filenames[hf] = filename;

            err = 0;

            return hf;
        }

        uint FciRead(
            int hf,
            IntPtr memory,
            uint cb,
            ref int err,
            IntPtr pv)
        {
            Stream stream = streams[hf];

            ResizeScratchBuffer((int)cb);

            int n = stream.Read(scratchBuffer, 0, (int)cb);

            Marshal.Copy(scratchBuffer, 0, memory, n);

            err = 0;

            return (uint)n;
        }

        uint FciWrite(
            int hf,
            IntPtr memory,
            uint cb,
            ref int err,
            IntPtr pv)
        {
            Stream stream = streams[hf];

            ResizeScratchBuffer((int)cb);

            Marshal.Copy(memory, scratchBuffer, 0, (int)cb);

            stream.Write(scratchBuffer, 0, (int)cb);

            err = 0;

            return cb;
        }

        int FciClose(
            int hf,
            ref int err,
            IntPtr pv)
        {
            Stream stream = streams[hf];

#if NETFX_CORE
            stream.Flush();
            stream.Dispose();
            stream = null;

            streams[hf] = null;
            filenames[hf] = null;

            err = 0;

            return 0;
        }

        int FciSeek(
            int hf,
            int dist,
            int seektype,
            ref int err,
            IntPtr pv)
        {
            Stream stream = streams[hf];

            SeekOrigin seekOrigin = Util.SeekOriginFromDos(seektype);

            long result = stream.Seek(dist, seekOrigin);

            err = 0;

            return (int)result;
        }

        int FciDelete(
            IntPtr pszFile,
            ref int err,
            IntPtr pv)
        {
            string filename = Util.StringFromPtr(pszFile);

            compressorHelper.Delete(filename);//File.Delete(filename);

            err = 0;

            return 0;
        }

        int FciGetTempFile(
            IntPtr pszTempName,
            int cbTempName,
            IntPtr pv)
        {
            string filename = compressorHelper.GetTempFileName();//Path.GetTempFileName();
            char[] chars = new char[filename.Length + 1];
            Array.Copy(filename.ToCharArray(), chars, filename.Length);
            Marshal.Copy(chars, 0, pszTempName, chars.Length);

            return 1;
        }

        int FciGetNextCabinet(
            ref Cabinet.CCAB pccab,
            uint cbPrevCab,
            IntPtr pv)
        {
            throw new Exception("Multi-part cabinets not supported in this wrapper at the moment.");
        }

        int FciStatus(
            uint typeStatus,
            uint cb1,
            uint cb2,
            IntPtr pv)
        {
            Progress();
            return typeStatus == 2 ? (int)cb2 : 0;
        }

        int FciGetOpenInfo(
            IntPtr pszName,
            ref ushort pdate,
            ref ushort ptime,
            ref ushort pattribs,
            ref int err,
            IntPtr pv)
        {
            string filename = Util.StringFromPtr(pszName);

            int fh = FciOpen(pszName, Rtl.OFLAG._O_RDONLY | Rtl.OFLAG._O_BINARY, Rtl.PMODE._S_IREAD, ref err, pv);

            FileAttributes fa = compressorHelper.GetAttributes(filename);//File.GetAttributes(filename);
            pattribs = Util.FileAttributesToDos(fa);

            DateTime ct = compressorHelper.GetLastWriteTimeUtc(filename);//File.GetLastWriteTimeUtc(filename);
            err = 0;

            return fh;
        }
    }
}
