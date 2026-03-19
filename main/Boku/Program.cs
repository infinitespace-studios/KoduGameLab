// Copyright (c) Microsoft Corporation.
// Licensed under the MIT license.

//#define IMPORT_DEBUG

#if EXTERNAL || true
# define GLOBAL_CATCH    // include the global exception handler.
# define GLOBAL_CATCH_PC
#endif

#if EXTERNAL
# define UPDATE_CHECK    // check for new version at startup.
#endif

//#define DISABLE_STUDIOK 

using System;
using System.Net;
using System.Threading;
using System.Runtime.InteropServices;
using System.IO;
using System.Text;
using System.Diagnostics;
using System.Collections.Generic;
using System.Reflection;
using System.Xml.Serialization;
using BokuShared.Wire;
using System.Globalization;

using Microsoft.Xna.Framework.Graphics;

using Microsoft.Xna.Framework.Input;
using Microsoft.Xna.Framework;

using Boku.Common;
using Boku.Common.Sharing;
using Boku.Common.Xml;
using Boku.Web;
using Boku.Analyses;

using BokuShared;
using Boku.Common.Localization;

namespace Boku
{
    //Class that holds version information from service. 
    public class UpdateInfo
    {
        public string releaseNotesUrl = "";
        public string updateUrl = "";
        public Version latestVersion;

        //Construct from wire message.
        public UpdateInfo(Message_Version version)
        {
            latestVersion = new Version(version.Major,version.Minor,version.Build,version.Revision);
            releaseNotesUrl = version.ReleaseNotesUrl;
            updateUrl = version.UpdateUrl;
        }

    }
    static partial class Program2
    {
        public static Mutex InstanceMutex;
        private static string kOptInForUpdatesFilename = @"Options\1F2B5B79-6EB0-45c4-A8BD-0EBDF4EE10C3.opt";
        private static string kOptInForInstrumentationFilename = @"Options\C90D3C0E-D0B4-4aa6-B35D-0A1D9931FB38.opt";

        public static Version ThisVersion;
        public static string CurrentKCodeVersion="9";   // Version of the KCode.
                                                        // 4 -> 5 : Add local variables and Squash.
                                                        // 5 -> 6 : New movement code.  Make missiles targetable.
                                                        // 6 -> 7 : Add Settings slider tiles as well as some settings as scores.
                                                        // 7 -> 8 : Add naming of characters and the ability to sense named characters.
                                                        // 8 -> 9 : Move linked level target from XmlWorldData to ReflexData.
        
        public static string UpdateCode;

        public static UpdateInfo updateInfo=null;

        public static CmdLine CmdLine;

        public static string MicrobitCmdLine = null;

        public static SiteOptions SiteOptions;

        public static bool InstallerOptCheckForUpdates;
        public static bool InstallerOptSendInstrumentation;

        public static bool bShowVersionWarning = false;

        static bool localizedFilesUpdated = false;
        static public void langCallback()
        {
            localizedFilesUpdated = true;
        }

        /// <summary>
        /// The main entry point for the application.
        /// </summary>
        // Must specify STA threading model to be allowed clipboard access.
        [STAThread]
        static public void Main(string[] args)
        {
#if GLOBAL_CATCH
            try
            {
#endif

                ThisVersion = Assembly.GetExecutingAssembly().GetName().Version;
                Assembly asm = Assembly.GetExecutingAssembly();
                var attr = (asm.GetCustomAttributes(typeof(GuidAttribute), true));
                UpdateCode = (attr[0] as GuidAttribute).Value;

                // Fake command line args to test double-click to launch
                //args = new string[3] { args[0], @"/Import", @"C:\Users\scoy\My Documents\New World 3, by Stephen Coy.Kodu2" };

                CmdLine = new CmdLine(args);

                if (CmdLine.Exists("?") || CmdLine.Exists("HELP"))
                {
                    Console.WriteLine(
                        "  /FPS \t- display FPS\r\n" +
                        "  /F \t- full screen\r\n" +
                        "  /S \t- sync refresh\r\n" +
                        "  /W 1280 \t- width\r\n" +
                        "  /H 1024 \t- height\r\n" +
                        "  /EFFECTS \t- turn on depth of field and bloom effects\r\n" +
                        "  /NOEFFECTS \t- turn off depth of field and bloom effects\r\n" +
                        "  /NOAUDIO \t- turn off audio\r\n" +
                        "  /PATH <save folder> \t- override save folder\r\n" +
                        "  /UPDATE \t- check for updates\r\n" +
                        "  /NOUPDATE \t- do not check for updates\r\n" +
                        "  /INSTRUMENTATION \t- send usage information\r\n" +
                        "  /NOINSTRUMENTATION \t- do not send usage information\r\n" +
                        "  /IMPORT <filename> \t- unpack the kodu level package to your downloads area\r\n" +
                        "  /LOGON \t- ask player for username\r\n" +
                        "  /ANALYTICS \t- run analytics on game being loaded\r\n" +
                        "  /LOCALIZATION <language> \t- report localization information that is missing in the specified language.\r\n" +
                        "  /PIESIZE <int> \t- pie menu maximum size.\r\n" +
                        "  /NOMICROBIT \t- Do not scan for attached BBC micro:bits\r\n" +
                        "  /MICROBIT \"COM3 E:\"\t- Try to enable micro:bit with given com port and drive letter.  The quotes are required.\r\n" +
                        "");

                    return;
                }

                {
                    // Initialize level import/export facility
                    // ====================================================
                    // This is done before preventing multiple instances
                    // so that if an import was specified on the command
                    // line then it will be moved to the imports folder,
                    // allowing the already running instance of Kodu to
                    // pick it up the next time the user enters the load
                    // level menu.
                    Storage4.Init();
                    Storage4.StartupDir = AppContext.BaseDirectory;

                    // Note, we need to get the user override location before
                    // import otherwise we send the files to the wrong place.
                    BokuSettings settings = BokuSettings.Settings;
                    if (!string.IsNullOrEmpty(settings.UserFolder))
                    {
                        Storage4.UserOverrideLocation = settings.UserFolder;
                    }

                    if (!LevelPackage.Initialize(CmdLine))
                    {
                        // Must be bad folder.
                        return;
                    }

                    // Restore default state for now.
                    Storage4.ResetUserOverrideLocation();
                    // ====================================================
                }

                {
                    // Prevent multiple instances of Kodu
                    // ====================================================
                    bool instanceMutexCreated;
                    InstanceMutex = new Mutex(false, @"Local\Boku", out instanceMutexCreated);

                    // If we didn't create the shared mutex, then another
                    // instance of Boku already exists.
                    if (!instanceMutexCreated)
                        return;
                    // ====================================================
                }

                {
                    // Load Site Options
                    // ====================================================
                    SiteOptions = SiteOptions.Load(StorageSource.All);
                    // ====================================================
                }

                {
                    // Load the unique site id.
                    // ====================================================
                    SiteID.Initialize();
                    // ====================================================
                }

                {
                    // Process the Import Directive
                    // ====================================================
                    // We're importing a level from the command line. Do the
                    // import and set it as the startup world so that we can
                    // jump right into it.

                    // First, set the userOverrideLocation so we import to the correct location.
                    BokuSettings settings = BokuSettings.Settings;
                    if (!string.IsNullOrEmpty(settings.UserFolder))
                    {
                        Storage4.UserOverrideLocation = settings.UserFolder;
                    }

                    List<Guid> importedLevels = new List<Guid>();
                    bool importOk = LevelPackage.ImportAllLevels(importedLevels);

                    if (!importOk)
                    {
                        bShowVersionWarning = true;
                    }

#if IMPORT_DEBUG
                LevelPackage.DebugPrint("Done importing");
                LevelPackage.DebugPrint("Files imported");
                foreach (Guid guid in importedLevels)
                {
                    LevelPackage.DebugPrint("    " + guid.ToString());
                }
#endif

                    if (importedLevels.Count > 0)
                    {
                        MainMenu.StartupWorldFilename = BokuGame.Settings.MediaPath + BokuGame.DownloadsPath + importedLevels[0].ToString() + ".Xml";
#if IMPORT_DEBUG
                    LevelPackage.DebugPrint("StartupWorldFilename : " + MainMenu.StartupWorldFilename);
#endif
                    }
                    // check here for the Analytics flag
                    if (CmdLine.Exists("ANALYTICS"))
                    {
                        //run my code here?
                        //Console.WriteLine("Begin Analytics");
                        //ObjectAnalysis oa = new ObjectAnalysis();
                        //oa.beginAnalysis(MainMenu.StartupWorldFilename.ToString());
                    }

                }

                {
                    // DebugLog.NewRun();

                    // Initialize Localization Resources.
                    Unicode.Init(); // Needed for loading localizations.
                    LocalizationResourceManager.Init();

                    // Update to Latest resources of the Default Language
                    LocalizationResourceManager.UpdateResources(LocalizationResourceManager.DefaultLanguage);

                    // Localization options
                    // ====================================================
                    // Allow command line option to override user choice iff user choise is "".
                    // If XmlOptionsData has a valid choice, always use it.
                    string lang = XmlOptionsData.Language;
                    string commandLineLang = CmdLine.GetString("LOCALIZATION", "");

                    // If we haven't previously set a language preference, select one 
                    // from the current locale.
                    if (string.IsNullOrEmpty(lang))
                    {
                        if (string.IsNullOrEmpty(commandLineLang))
                        {
                            {
                                try
                                {
                                    // Get current language.
                                    lang = CultureInfo.CurrentUICulture.TwoLetterISOLanguageName;

                                    // Verify that it's a supported language.
                                    bool valid = false;
                                    foreach (LocalizationResourceManager.SupportedLanguage supportedLang in LocalizationResourceManager.SupportedLanguages)
                                    {
                                        if (string.Compare(lang, supportedLang.Language, StringComparison.OrdinalIgnoreCase) == 0)
                                        {
                                            valid = true;
                                            break;
                                        }
                                    }

                                    if (!valid)
                                    {
                                        lang = "EN";
                                    }
                                }
                                catch
                                {
                                    lang = "EN";
                                }
                            }
                        }
                        else
                        {
                            lang = commandLineLang;
                        }
                        // Persist language choice.
                        XmlOptionsData.Language = lang;
                    }

                    // Always create missing loc report except when English is the language.
                    if (string.Compare(lang, "EN", StringComparison.OrdinalIgnoreCase) != 0)
                    {
                        Localizer.ShouldReportMissing = true;
                    }

                    if (!String.IsNullOrEmpty(lang))
                    {
                        Localizer.LocalLanguage = lang;
                        if (lang != LocalizationResourceManager.DefaultLanguage)
                        {
                            localizedFilesUpdated = false;
                            LocalizationResourceManager.UpdateResources(lang, langCallback);

                            while (!localizedFilesUpdated)
                            {
                                Thread.Sleep(10);
                            }
                        }
                    }

                    // Record current language to instrumentation.
                    if (!String.IsNullOrEmpty(lang))
                    {
                        Instrumentation.RecordDataItem(Instrumentation.DataItemId.Language, lang);
                    }
                }

                {
                    BokuSettings settings = BokuSettings.Settings;

                    // Apply Settings from the command Line
                    // ====================================================
                    //XmlOptionsData.ShowFramerate = CmdLine.GetBool("FPS", XmlOptionsData.ShowFramerate);
                    settings.FullScreen = CmdLine.GetBool("F", settings.FullScreen);
                    BokuGame.syncRefresh = CmdLine.GetBool("S", BokuGame.syncRefresh);
                    BokuGame.Logon = CmdLine.GetBool("Logon", SiteOptions.Logon);
                    DateTime endMarsMode = new DateTime(2012, 10, 1, 0, 0, 0);
                    if (CmdLine.Exists("MARS") || DateTime.Now < endMarsMode)
                    {
                        BokuGame.bMarsMode = true;
                    }
                    if (CmdLine.Exists("W"))
                    {
                        settings.ResolutionX = CmdLine.GetInt("W", settings.ResolutionX);
                    }
                    if (CmdLine.Exists("H"))
                    {
                        settings.ResolutionY = CmdLine.GetInt("H", settings.ResolutionY);
                    }
                    settings.PostEffects = CmdLine.GetBool("Effects", settings.PostEffects);
                    settings.PostEffects = !CmdLine.GetBool("NoEffects", !settings.PostEffects);
                    settings.LowModels = CmdLine.GetBool("LowModels", settings.LowModels);
                    settings.Audio = !CmdLine.GetBool("NoAudio", !settings.Audio);

                    // Update flags for update checking and instrumentation gathering from both the command line arguments and privacy options chosen during installation.

                    // XmlOptionsData will default to these values if these options have not been overridden in the Options screen.
                    InstallerOptCheckForUpdates = File.Exists(Storage4.TitleLocation + @"\" + kOptInForUpdatesFilename);
                    InstallerOptSendInstrumentation = File.Exists(Storage4.TitleLocation + @"\" + kOptInForInstrumentationFilename);

                    // XmlOptionData.CheckForUpdates combines the installer option
                    // as well as any user override.
                    SiteOptions.CheckForUpdates = XmlOptionsData.CheckForUpdates;

#if !UPDATE_CHECK
                    // Internal builds override this.  Why?
                    SiteOptions.CheckForUpdates = false;
#endif

                    if (XmlOptionsData.SendInstrumentationWasSet)
                    {
                        // Note that this seems inverted because of the stupid naming.
                        SiteOptions.InstrumentationUnchecked = XmlOptionsData.SendInstrumentation;
                    }

                    // Allow command line arguments to override in-game settings.
                    if (CmdLine.Exists("Update"))
                    {
                        SiteOptions.CheckForUpdates = true;
                    }
                    if (CmdLine.Exists("NoUpdate"))
                    {
                        SiteOptions.CheckForUpdates = false;
                    }
                    if (CmdLine.Exists("Instrumentation"))
                    {
                        // Note that this seems inverted because of the stupid naming.
                        SiteOptions.InstrumentationUnchecked = true;
                    }
                    if (CmdLine.Exists("NoInstrumentation"))
                    {
                        // Note that this seems inverted because of the stupid naming.
                        SiteOptions.InstrumentationUnchecked = false;
                    }
                    if (CmdLine.Exists("MICROBIT"))
                    {
                        MicrobitCmdLine = CmdLine.GetString("MICROBIT", null);
                    }

                    /// This is fortuitously timed. We have already pulled the settings file
                    /// out of the real user folder (somewhere in Documents\Saved Games\...).
                    /// If we override the user path now to some central shared spot, we
                    /// get individualized settings from BokuSettings, but then shared levels
                    /// from the central source.
                    string userPath = CmdLine.GetString("PATH", "");
                    if (!string.IsNullOrEmpty(userPath))
                    {
                        settings.UserFolder = userPath;
                    }
                    if (!string.IsNullOrEmpty(settings.UserFolder))
                    {
                        Storage4.UserOverrideLocation = settings.UserFolder;
                    }

                    if (!XmlOptionsData.ShowMicrobitTiles)
                    {
                        // Scan for attached microbits (but don't connect to them yet). If any are found,
                        // RefreshDevices will modify XmlOptionsData to make the microbit programming tiles
                        // permanently visible in the tile picker.
                        Input.MicrobitManager.RefreshDevices(false);
                    }
                    // ====================================================
                }

                {
                    // Record this installation's unique ID to instrumentation.
                    Instrumentation.RecordDataItem(Instrumentation.DataItemId.InstallationUniqueId, SiteID.Instance.Value.ToString());

                    // Get the latest version number.
                    // ====================================================

                    // See if an update is available.
                    if (SiteOptions.CheckForUpdates)
                    {
                        FetchLatestVersionFromServer(SiteOptions.Product);

                        var ignoreVersion = new Version(SiteOptions.IgnoreVersion);
                        if (updateInfo != null && ThisVersion < updateInfo.latestVersion
                            && updateInfo.latestVersion != ignoreVersion
                        )
                        {
                            // Log that an update is available.
                            Console.WriteLine($"Update available: current version {ThisVersion}, latest version {updateInfo.latestVersion}");
                            Console.WriteLine($"Release notes: {updateInfo.releaseNotesUrl}");
                            Console.WriteLine($"Download: {updateInfo.updateUrl}");
                        }
                    }

                    // ====================================================

                    using var game = new BokuGame();
                    game.Run();

                    // In case the app was closed while in play mode with a microbit attached. Release microbits
                    // so that the serial port receive thread doesn't block application exit.
                    Boku.Input.MicrobitManager.ReleaseDevices();

                    FlushInstrumentation();

                    // ====================================================
                }
#if GLOBAL_CATCH
            }
            catch (Exception ex)
            {
                // Write out a file to act as the crash cookie.
                {
                    Stream stream = Storage4.OpenWrite(MainMenu.CrashCookieFilename);
                    byte[] buffer = { 42 };
                    stream.Write(buffer, 0, 1);
                    stream.Close();
                }

                // Be sure mouse cursor is on regardless of current input mode.
                BokuGame.bokuGame.IsMouseVisible = true;

                // Report the crash unless we're running the debugger.
                if (!Debugger.IsAttached)
                {
                    string gfxString;
                    try
                    {
                        gfxString = String.Format("Adapter: {0}", GraphicsAdapter.DefaultAdapter.Description);
                    }
                    catch
                    {
                        gfxString = "(Error getting graphics adapter information)";
                    }

                    string errorReport =
                        ex.Message + "\r\n" +
                        ThisVersion.ToString() + "\r\n" +
                        gfxString + "\r\n\r\n" +
                        ex.StackTrace;

                    Console.Error.WriteLine("=== KODU CRASH REPORT ===");
                    Console.Error.WriteLine(errorReport);
                    Console.Error.WriteLine("=========================");

                    string addInfo =
                        ex.GetType().Name + "\r\n" +
                        "Kodu: " + ThisVersion.ToString() + "\r\n" +
                        gfxString;
                    SendErrorReport(ex.Message, ex.StackTrace, addInfo);

                    Process.GetCurrentProcess().Kill();
                }
            }
#endif // GLOBAL_CATCH

            // Prevent the garbage collector from optimizing away our shared mutex instance.
            GC.KeepAlive(InstanceMutex);

        }   // end of Main()

        /// <summary>
        /// Copies any files that match the searchPattern string from src to dst.
        /// </summary>
        /// <param name="srcDir"></param>
        /// <param name="dstDir"></param>
        /// <param name="searchPattern"></param>
        static void CopyFiles(string srcDir, string dstDir, string searchPattern)
        {
            try
            {
                string[] filePaths = Directory.GetFiles(srcDir, searchPattern);

                foreach (string srcPath in filePaths)
                {
                    string dstPath = Path.Combine(dstDir, Path.GetFileName(srcPath));
                    File.Copy(srcPath, dstPath);
                }
            }
            catch (Exception e)
            {
                // If the file has already been copied over, this will throw.
                // No worries...
                if (e != null)
                {
                }
            }
        }   // end of CopyFiles()

    }   // end of class Program2

    /// This chunk of the Program class manages the task of fetching the latest
    /// version number from the server to determine whether an update is available.
    static partial class Program2
    {
        static bool getCurrentVersionComplete = false;
        private static void FetchLatestVersionFromServer(string productName)
        {
            try
            {
                Web.Trans.GetCurrentVersion trans = new Boku.Web.Trans.GetCurrentVersion(productName, GetCurrentVersionCallback, null);

                if (trans.Send())
                {
                    int timeSpent = 0;
                    while (!getCurrentVersionComplete && timeSpent < 30 * 1000)
                    {
                        // Pump web request callbacks.
                        Web.Trans.Request.Update();
                        System.Threading.Thread.Sleep(10);
                        timeSpent += 10;
                    }
                }
            }
            catch
            {
                updateInfo = null;
                getCurrentVersionComplete = true;
            }
        }
        static void GetCurrentVersionCallback(object param)
        {
            Web.Trans.GetCurrentVersion.Result result = (Web.Trans.GetCurrentVersion.Result)param;

            if (result.success)
            {
                updateInfo = new UpdateInfo(result.version);
            }

            getCurrentVersionComplete = true;
        }
    }



    /// This chunk of the Program class manages the task of sending crash reports and instrumentation.
    static partial class Program2
    {
        static bool instrumentationFlushed = false;
        static void InstrumentationFlushed(object param)
        {
            instrumentationFlushed = true;
        }

        static void FlushInstrumentation()
        {
            try
            {
                if (SiteOptions.Instrumentation)
                {
                    int timeSpent = 0;
                    if (Common.Instrumentation.Flush(InstrumentationFlushed))
                    {
                        // Give it 30 seconds to complete.
                        while (!instrumentationFlushed && timeSpent < 30 * 1000)
                        {
                            // Pump web request callbacks.
                            Web.Trans.Request.Update();
                            System.Threading.Thread.Sleep(10);
                            timeSpent += 10;
                        }
                    }
                }
            }
            catch { }
        }

#if GLOBAL_CATCH
        static bool errorReportSent = false;

        static void ErrorReportSent(object param)
        {
            errorReportSent = true;
        }

        static void SendErrorReport(string errorMessage, string stackTrace, string addInfo)
        {
            try
            {
                Web.Trans.ReportError trans = new Web.Trans.ReportError(
                    errorMessage,
                    stackTrace,
                    addInfo,
                    ErrorReportSent,
                    null);

                if (trans.Send())
                {
                    int timeSpent = 0;
                    while (!errorReportSent && timeSpent < 30 * 1000)
                    {
                        // Pump web request callbacks.
                        Web.Trans.Request.Update();
                        System.Threading.Thread.Sleep(10);
                        timeSpent += 10;
                    }
                }
            }
            catch { }
        }
#endif
    }

}   // end of namespace Boku
