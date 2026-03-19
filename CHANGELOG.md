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

