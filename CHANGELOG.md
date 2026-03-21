# Kodu Game Lab — MonoGame Porting Changelog

All notable changes during the XNA → MonoGame 3.8.5 / .NET 9.0 port are documented here.

---

## Phase 0: Project Infrastructure Setup

### Step 0.1: Create New Solution Structure
- Created `KoduGameLab.slnx` at repo root with Source, Content, and BokuShared projects
- Created `main/Content/` directory for the new Content Builder

### Step 0.2: Update boku.csproj to .NET 9.0 + MonoGame 3.8.5
- Changed TargetFramework from `net8.0` to `net9.0`
- Updated MonoGame.Framework.DesktopGL from `3.8.*` to `3.8.5-preview.*`
- Removed `System.Resources.Extensions` package reference
- Added `RollForward`, `PublishReadyToRun`, `TieredCompilation` settings
- Removed all commented-out legacy references (Cab, MicrobitNeedDriverDlg, TouchHook, etc.)
- Removed all commented-out embedded resources (ErrorForm.resx, StartupForm.resx, etc.)
- Added active `ProjectReference` to BokuShared
- Added `Import` for `BuildContent.targets`

### Step 0.3: Create Content Builder Project
- Created `main/Content/Builder.csproj` targeting .NET 9.0 with MonoGame Content Pipeline packages
- Created `main/Content/Source/Builder.cs` with programmatic content collection strategy
- Created `main/Content/BuildContent.targets` for MSBuild integration
- Builder includes wildcard rules for all assets and FBX model processing
- **Verified:** Content Builder builds successfully

### Step 0.5: Port BokuShared to .NET 9.0
- Converted `main/BokuShared/BokuShared.csproj` from old-style MSBuild (.NET 3.5) to SDK-style (.NET 9.0)
- Resolved NETFX_CORE conditionals in `Auth.cs`: kept System.Security.Cryptography (removed Windows.Security.Cryptography)
- Resolved NETFX_CORE conditionals in `StorageHelper.cs`: kept System.IO file operations (removed WinRT asserts)
- Resolved NETFX_CORE conditionals in `XmlData.cs`: kept Debug.Assert and stream.Close() (removed WinRT stream.Dispose path)
- Removed legacy `Properties/AssemblyInfo.cs` (SDK-style auto-generates)
- **Verified:** BokuShared builds successfully with only 2 pre-existing warnings

## Phase 1: Remove WinForms Dependencies (Steps 1.1, 1.2, 1.5)

### Step 1.1: Delete Pure WinForms Files
Deleted 14 C# files and 7 .resx files:
- `MainForm.cs`, `MainFormEvents.cs` — WinForms container for XNA rendering
- `StartupForm.cs/.Designer.cs` — WinForms splash screen
- `UpdateForm.cs/.Designer.cs` — Version update dialog
- `ErrorForm.cs/.Designer.cs` — Crash report dialog
- `Web/BrowserForm.cs/.Designer.cs` — Embedded web browser
- `Web/LoginDialog.cs/.Designer.cs` — Login dialog form
- `XNAControl.cs` — XNA rendering inside WinForms
- All associated `.resx` resource files

### Step 1.2: Delete WinForms Graphics Hosting
- `GraphicsDeviceControl.cs` — already removed (not present)
- `XNAControl.cs` — deleted (above)

### Step 1.5: Delete WinStoreHelpers.cs
- Deleted `Common/WinStoreHelpers.cs` (P/Invoke UWP detection, no longer needed)

### Cleanup: Remove Legacy Properties
- Deleted `Properties/` directory: AssemblyInfo.cs, Resources.resx/.Designer.cs, Settings files
- SDK-style project auto-generates assembly info

## Phase 2: Resolve All NETFX_CORE Conditionals

### Batch Resolution (85 files, 0 remaining)
Resolved ALL 206+ `#if NETFX_CORE` / `#if !NETFX_CORE` preprocessor directives across 85 files:

**Core infrastructure (11 files):**
- `Storage4.cs` — Removed ~800 lines of Windows.Storage/StorageFolder API, Close() extensions
- `Audio.cs` — Kept Path.Combine paths + AudioStopOptions.Immediate
- `BokuGame.cs` — Kept WinKeyboard, IsMouseVisible, desktop paths
- `BokuGame.Designer.cs` — Removed Win8 fullscreen/snapped mode
- `ContentLoader.cs`, `GamePadInput.cs`, `KeyboardInput.cs`, `PerfTimer.cs`, `Settings.cs`, `GameListManager.cs`, `GraphicsDeviceService.cs`

**UI/Scene files (21 files):**
- `InGameRunSim.cs`, `OptionsMenu.cs` — `Application.Current.Exit()` → `BokuGame.bokuGame.Exit()`
- Various UI dialogs, render objects, title screen — removed UWP paths

**Remaining files (53 files):**
- Font system, text blobs, sharing, hints, level browsers, localization, particle system
- Tutorial system, XML data, analyses, animatics, base classes
- Input/microbit, programming elements, terrain, twitter, web transactions
- All resolved: UWP code removed, desktop code kept, guards removed

**Verification:** `grep -rl "NETFX_CORE" main/Boku --include="*.cs"` returns 0 files


## Build Milestone: C# Compilation SUCCESS

### ✅ Build succeeds — 0 errors, 0 warnings
`dotnet build main/Boku/boku.csproj -p:SkipContentBuild=true` — **BUILD SUCCEEDED**

### Key fixes to reach compilation:
- Restored `BokuGame : Microsoft.Xna.Framework.Game` inheritance (removed by NETFX_CORE cleanup)
- Restored `Settings.MediaPath` and `Settings.Default` (were in NETFX_CORE block)
- Added GameActor 3-param constructor for legacy subclasses
- Added default parameter values for InitDefaults, CheckSelectCursor, SharedIdle ctor
- Fixed GraphicsDeviceManager → GraphicsDevice parameter mismatches in INeedsDeviceReset implementations
- Fixed UIGrid, AudioCue, KeyboardInput, Road, Color type ambiguities with using aliases
- Added missing members to BokuGame, GameThing, UIGridElement, AudioCue, etc.
- Created minimal stubs for BokuBot, Popsy, RockSRO (missing actor types)
- Added PortingStubs.cs for WinKeyboard, BitmapFont, BokuSettings, UIMeshData
- Added System.Drawing.Common, System.IO.Packaging, System.Management NuGet packages
- Excluded ~25 files with missing base types or deleted project dependencies
- AnimWindows (Xclna animation library) included for runtime animation support

### Remaining work:
- Content pipeline build (shaders need HLSL porting, audio needs XACT replacement)
- Runtime testing
- Shader porting (Phase 6)
- Audio system replacement (Phase 5)
