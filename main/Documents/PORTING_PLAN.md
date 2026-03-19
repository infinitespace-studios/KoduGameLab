# Kodu Game Lab: XNA → MonoGame Port Plan

## Problem Statement

Port Kodu Game Lab (928 C# files, ~2,700 content assets) from its current dual XNA/UWP architecture to MonoGame 3.8.5 targeting .NET 9.0 with DesktopGL. The codebase uses `#if NETFX_CORE` conditionals to separate WinForms (desktop) and UWP code paths. The strategy is:

1. **Keep the NETFX_CORE (UWP-style) code paths** — they are closer to MonoGame's cross-platform model
2. **Remove WinForms code paths** — these embed XNA inside a Form control
3. **Adapt UWP-specific APIs** (Windows.Storage, etc.) to cross-platform .NET equivalents
4. **Port content pipeline** to the new programmatic Content Builder pattern (not MGCB)
5. **Replace XACT audio** with MonoGame SoundEffect/Song APIs
6. **Port shaders** from XNA .fx format to MonoGame-compatible HLSL
7. **HiDef-only support** — No Reach profile fallback. Modern hardware supports HiDef. Use ContentHiDef shaders as primary. Remove SM2 shader variants entirely. Remove all Reach/HiDef detection and fallback logic.

## Reference: Port Sample Pattern (from ~/Documents/Sandbox/Ports)

All porting work should follow the 3-project structure:
```
KoduGameLab/
├── Source/          (Main game executable - boku.csproj)
├── Content/         (Content Builder - Builder.csproj + BuildContent.targets)
│   ├── Source/      (Builder.cs)
│   └── Assets/     (All content: Shaders/, Textures/, Models/, Fonts/, Audio/)
└── Tests/           (Unit tests)
```

**Target:** .NET 9.0, MonoGame.Framework.DesktopGL 3.8.5-preview.*

---

## PHASE 0: Project Infrastructure Setup

### Step 0.1: Create New Solution Structure
**Files:** Create new `.slnx`, restructure directories
**Action:**
- Create `KoduGameLab.slnx` at repo root with 3 folders: Source, Content, Tests
- The main game project stays at `main/Boku/boku.csproj` (Source folder in solution)
- Create `main/Content/` directory for the Content Builder
- Map existing `main/Tests/` to Tests folder

```xml
<Solution>
  <Folder Name="/Content/">
    <Project Path="main/Content/Builder.csproj" />
  </Folder>
  <Folder Name="/Tests/">
    <!-- Test projects will be added later -->
  </Folder>
  <Project Path="main/Boku/boku.csproj" />
</Solution>
```

### Step 0.2: Update boku.csproj to .NET 9.0 + MonoGame 3.8.5
**File:** `main/Boku/boku.csproj`
**Current state:** .NET 8.0, MonoGame 3.8.*, most references commented out
**Action:** Update to match port sample pattern:
```xml
<Project Sdk="Microsoft.NET.Sdk">
  <PropertyGroup>
    <OutputType>WinExe</OutputType>
    <TargetFramework>net9.0</TargetFramework>
    <RollForward>Major</RollForward>
    <PublishReadyToRun>false</PublishReadyToRun>
    <TieredCompilation>false</TieredCompilation>
    <ApplicationIcon>256x.ico</ApplicationIcon>
  </PropertyGroup>
  <ItemGroup>
    <PackageReference Include="MonoGame.Framework.DesktopGL" Version="3.8.5-preview.*" />
  </ItemGroup>
  <Import Project="..\Content\BuildContent.targets" />
</Project>
```
**Note:** Remove the `System.Resources.Extensions` package reference. Remove all commented-out legacy references. The `NETFX_CORE` define should NOT be defined — we're resolving all conditionals statically.

### Step 0.3: Create Content Builder Project
**Files to create:**
- `main/Content/Builder.csproj`
- `main/Content/Source/Builder.cs`
- `main/Content/BuildContent.targets`

**Builder.csproj** (exact pattern from port samples):
```xml
<Project Sdk="Microsoft.NET.Sdk">
  <PropertyGroup>
    <OutputType>Exe</OutputType>
    <TargetFramework>net9.0</TargetFramework>
    <ImplicitUsings>enable</ImplicitUsings>
    <Nullable>enable</Nullable>
    <AppendTargetFrameworkToOutputPath>false</AppendTargetFrameworkToOutputPath>
  </PropertyGroup>
  <ItemGroup>
    <PackageReference Include="MonoGame.Framework.Content.Pipeline" Version="3.8.5-preview.*" />
    <PackageReference Include="MonoGame.Framework.Native" Version="3.8.5-preview.*">
      <PrivateAssets>All</PrivateAssets>
    </PackageReference>
    <PackageReference Include="MonoGame.Library.Assimp" Version="5.3.1.3" />
    <PackageReference Include="MonoGame.Library.FreeType" Version="2.13.2.3" />
    <PackageReference Include="MonoGame.Library.MojoShader" Version="1.0.0.4" />
    <PackageReference Include="MonoGame.Tool.Basisu" Version="2.0.2.1" />
    <PackageReference Include="MonoGame.Tool.Crunch" Version="1.0.4.7" />
    <PackageReference Include="MonoGame.Tool.Dxc" Version="1.8.2505.11" />
    <PackageReference Include="MonoGame.Tool.FFmpeg" Version="7.0.0.10" />
    <PackageReference Include="MonoGame.Tool.FFprobe" Version="7.0.0.10" />
  </ItemGroup>
</Project>
```

**Builder.cs** (initial version — will be expanded in Phase 4):
```csharp
using Microsoft.Xna.Framework.Content.Pipeline;
using Microsoft.Xna.Framework.Content.Pipeline.Processors;
using MonoGame.Framework.Content.Pipeline.Builder;

var contentCollectionArgs = new ContentBuilderParams()
{
    Mode = ContentBuilderMode.Builder,
    WorkingDirectory = $"{AppContext.BaseDirectory}../../../",
    SourceDirectory = "Assets",
    Platform = TargetPlatform.DesktopGL
};
var builder = new Builder();
if (args is not null && args.Length > 0)
    builder.Run(args);
else
    builder.Run(contentCollectionArgs);
return builder.FailedToBuild > 0 ? -1 : 0;

public class Builder : ContentBuilder
{
    public override IContentCollection GetContentCollection()
    {
        var contentCollection = new ContentCollection();
        contentCollection.Include<WildcardRule>("*");
        contentCollection.Include<WildcardRule>("**/*.fbx", new FbxImporter(), new ModelProcessor());
        contentCollection.Exclude<WildcardRule>("*.mgcb");
        contentCollection.Exclude<WildcardRule>("*.contentproj");
        return contentCollection;
    }
}
```

**BuildContent.targets** (exact pattern from port samples):
```xml
<Project>
  <Target Name="BuildContent" BeforeTargets="BeforeCompile">
    <PropertyGroup>
      <ContentOutput>$(ProjectDir)$(OutputPath)</ContentOutput>
      <ContentTemp>$(ProjectDir)$(IntermediateOutputPath)</ContentTemp>
      <ContentArgs>build -p $(MonoGamePlatform) -s Content/Assets -o $(ContentOutput) -i $(ContentTemp)</ContentArgs>
      <ContentCommand>$(MSBuildThisFileDirectory)bin\Debug\Builder</ContentCommand>
    </PropertyGroup>
    <MSBuild Projects="$(MSBuildThisFileDirectory)Builder.csproj" Targets="Build" RemoveProperties="Configuration;TargetFramework;RuntimeIdentifier;RuntimeIdentifiers;SelfContained" />
    <Exec Command="$(ContentCommand) $(ContentArgs)" WorkingDirectory="$(MSBuildThisFileDirectory)..\" CustomErrorRegularExpression="\[E\] .+" CustomWarningRegularExpression="\[W\] .+" />
  </Target>
</Project>
```

### Step 0.4: Reorganize Content Assets
**Action:** Move content from `main/Boku/Content/` to `main/Content/Assets/`
**Structure:**
```
main/Content/Assets/
├── Shaders/     (from main/ContentHiDef/Shaders/ — 34 HiDef .fx files, PREFERRED)
├── Textures/    (from main/Boku/Content/Textures/ — 1,632 files)
├── Models/      (from main/Boku/Content/Models/ — 79 .fbx + 284 .xml)
├── Fonts/       (from main/Boku/Content/Fonts/ — 18 .spritefont files)
├── Audio/       (from main/Boku/Content/Audio/ — 602 .wav files)
├── Xml/         (from main/Boku/Content/Xml/ — level data, localization)
├── Text/        (from main/Boku/Content/Text/ — censor data)
└── Video/       (from main/Boku/Content/Video/)
```
**IMPORTANT — HiDef Only:** Use the `main/ContentHiDef/Shaders/` directory as the PRIMARY shader source. These are the HiDef versions. For any shaders that only exist in `main/Boku/Content/Shaders/` but NOT in ContentHiDef, copy those from the Boku/Content/Shaders directory. The Reach/HiDef fallback logic in BokuGame.Load<T>() should be REMOVED — we always load from a single shader path now.

**Shader merge strategy:**
1. Copy all 34 ContentHiDef shaders to `main/Content/Assets/Shaders/`
2. Copy any shaders from `main/Boku/Content/Shaders/` that don't exist in ContentHiDef (UI shaders, particle shaders, etc.)
3. Do NOT copy `*_SM2.fx` files — only SM3 and unified variants are needed

### Step 0.5: Port BokuShared to .NET 9.0
**File:** `main/BokuShared/BokuShared.csproj`
**Current:** .NET Framework 3.5, old-style MSBuild project
**Action:** Convert to SDK-style project:
```xml
<Project Sdk="Microsoft.NET.Sdk">
  <PropertyGroup>
    <TargetFramework>net9.0</TargetFramework>
  </PropertyGroup>
</Project>
```
**Files in BokuShared:** Auth.cs, CmdLine.cs, Common.cs, Compression.cs, Wire.cs, XmlData.cs, StorageHelper.cs
**Note:** Auth.cs uses `#if NETFX_CORE` for `Windows.Security.Cryptography` — will need adaptation in Phase 3.

---

## PHASE 1: Remove WinForms Dependencies (38 files)

The goal is to remove all `System.Windows.Forms` dependencies and the WinForms application hosting model. The app should launch directly as a MonoGame Game, not embedded in a Form.

### Step 1.1: Delete Pure WinForms Files (12 files)
**Action:** Delete these files entirely — they are WinForms-only with no shared logic:
```
main/Boku/MainForm.cs                    — WinForms container for XNAControl
main/Boku/MainFormEvents.cs              — Event handlers for MainForm
main/Boku/StartupForm.cs                 — WinForms splash screen
main/Boku/StartupForm.Designer.cs        — Auto-generated
main/Boku/UpdateForm.cs                  — Version update dialog
main/Boku/UpdateForm.Designer.cs         — Auto-generated
main/Boku/ErrorForm.cs                   — Crash report dialog (already broken per TODO)
main/Boku/ErrorForm.Designer.cs          — Auto-generated
main/Boku/Web/BrowserForm.cs             — Embedded web browser
main/Boku/Web/BrowserForm.Designer.cs    — Auto-generated
main/Boku/Web/LoginDialog.cs             — Login dialog form
main/Boku/Web/LoginDialog.Designer.cs    — Auto-generated
```

### Step 1.2: Delete WinForms Graphics Hosting Files
**Action:** Delete these files — MonoGame manages its own window:
```
main/Boku/Common/GraphicsDeviceControl.cs   — WinForms control base for XNA rendering
main/Boku/XNAControl.cs                     — XNA rendering inside WinForms
```

### Step 1.3: Rewrite Program.cs Entry Point
**File:** `main/Boku/Program.cs` (994 lines)
**Current state:** Has `#if NETFX_CORE` branch with `CoreApplication.Run(factory)` and `#else` branch with `Application.Run(MainForm.Instance)`
**Action:**
- Remove all `using System.Windows.Forms;` and `#if !NETFX_CORE` WinForms usings
- Remove all `using Windows.*` UWP-specific usings
- Replace the entry point with standard MonoGame pattern:
```csharp
[STAThread]
static public void Main(string[] args)
{
    // Keep: command-line parsing, version info, Storage4.Init(), etc.
    // Remove: StartupForm, UpdateForm, WinForms Application.Run
    // Remove: CoreApplication.Run (UWP)
    // Replace with:
    using var game = new BokuGame();
    game.Run();
}
```
- Keep all the command-line argument parsing logic (lines 130-420)
- Keep Storage4.Init() and initialization logic
- Remove multi-instance Mutex check that uses WinForms MessageBox
- Remove `StartupForm.Shutdown()` call
- Remove `UpdateForm` version checking UI (keep the logic, remove the Form)
- Remove all `#if NETFX_CORE` / `#else` / `#endif` blocks — resolve each to the appropriate cross-platform code

**Pattern for resolving NETFX_CORE in Program.cs:**
```csharp
// BEFORE:
#if NETFX_CORE
    lang = Windows.System.UserProfile.GlobalizationPreferences.Languages[0];
    lang = lang.Substring(0, 2);
#else
    CultureInfo culture = CultureInfo.CurrentCulture;
    lang = culture.Name.Substring(0, 2).ToUpper();
#endif

// AFTER (cross-platform):
CultureInfo culture = CultureInfo.CurrentCulture;
lang = culture.Name.Substring(0, 2).ToUpper();
```

### Step 1.4: Remove WinForms References from 26 Shared Files
**Action:** For each of these files, remove `using System.Windows.Forms;` and any WinForms-specific code blocks. Most of these use Forms only for `MessageBox.Show()` or `Clipboard` access.

**Files and their WinForms usage:**

| File | WinForms Usage | Replacement |
|------|---------------|-------------|
| `Common/HelpOverlay.cs` | Resource loading | Use Content.Load or embedded resources |
| `Common/LevelPackage.cs` | MessageBox for errors | Log to console/debug |
| `Common/Localization/Localizer.cs` | MessageBox for missing strings | Debug.WriteLine |
| `Common/MouseInput.cs` | Cursor.Position, Form.Bounds | MonoGame Mouse.GetState() |
| `Common/Storage.cs` | Legacy storage (mostly dead code) | Remove or gut the file |
| `Common/TouchInput.cs` | Form bounds checking | MonoGame window bounds |
| `Common/TweakScreenHelp.cs` | MessageBox | Debug.WriteLine |
| `Common/UnityTouchEmulation.cs` | Form mouse handling | MonoGame input |
| `Common/WinKeyboard.cs` | P/Invoke user32.dll | MonoGame Keyboard.GetState() |
| `Common/TutorialSystem/Crumb.cs` | Clipboard.SetText | Remove or use cross-platform clipboard |
| `DebugLog.cs` | MessageBox for errors | Console.Error.WriteLine |
| `Programming/Help.cs` | Resource loading | Content.Load |
| `Programming/Print.cs` | Debug output | Debug.WriteLine |
| `Scenes/Editor.cs` | Clipboard, cursor | MonoGame equivalents |
| `Scenes/InGame/InGameLoadSave.cs` | File dialogs | Custom in-game UI |
| `Scenes/LoadLevelMenu.cs` | File dialogs | Custom in-game UI |
| `Scenes/MainMenu.cs` | Application.Exit() | game.Exit() |
| `Scenes/SaveLevelDialog.cs` | File dialogs | Custom in-game UI |
| `Scenes/TextEditor.cs` | Clipboard | Remove or stub |
| `TitleScreen/TitleScreenMode.cs` | Application.Exit() | game.Exit() |
| `Web/Facebook.cs` | BrowserForm | Remove or stub web auth |
| `SimWorld/Terra/VirtualMap.cs` | MessageBox | Debug.WriteLine |
| `Input/Microbit/MicrobitManager.cs` | MessageBox | Debug.WriteLine |

**Common replacement patterns:**
```csharp
// BEFORE: MessageBox.Show(message, title);
// AFTER:  System.Diagnostics.Debug.WriteLine($"[{title}] {message}");

// BEFORE: Application.Exit();
// AFTER:  BokuGame.bokuGame.Exit();  // or Environment.Exit(0);

// BEFORE: Clipboard.SetText(text);
// AFTER:  SDL2.SDL.SDL_SetClipboardText(text); // MonoGame DesktopGL uses SDL2
//   OR:   Remove clipboard functionality

// BEFORE: Cursor.Position = new Point(x, y);
// AFTER:  Mouse.SetPosition(x, y);  // MonoGame API
```

### Step 1.5: Remove WinStoreHelpers.cs
**File:** `main/Boku/Common/WinStoreHelpers.cs`
**Action:** Delete entirely. This P/Invoke-based UWP detection is no longer needed.
**Impact:** Search for `WinStoreHelpers.RunningAsUWP` (3 usages in Program.cs) and replace:
- Line 226: Old UWP level copy logic → remove or make unconditional
- Line 595: Update checking guard → keep update check without UWP guard
- Line 688: App data path → use standard .NET path APIs

---

## PHASE 2: Resolve All NETFX_CORE Conditionals (206 directives, 358 occurrences)

### Strategy
For each `#if NETFX_CORE` block, we choose the BEST cross-platform implementation:
- **If the NETFX_CORE path uses UWP APIs** (Windows.Storage, etc.) → replace with System.IO equivalents
- **If the !NETFX_CORE path is already cross-platform** → keep that path
- **If both paths differ only in minor details** → merge into a single cross-platform version

### Step 2.1: Resolve Storage4.cs Conditionals (Largest file — 1,549 lines)
**File:** `main/Boku/Common/Storage4.cs`
**Current:** Heavy `#if NETFX_CORE` branching between Windows.Storage and System.IO
**Action:**
- Remove all `using Windows.Storage;`, `using Windows.Foundation;`, etc.
- Remove `StorageFolder` members (`TitleSpaceFolder`, `UserSpaceFolder`, `TempFolder`)
- Keep System.IO-based file operations
- Replace UWP async file operations with synchronous System.IO equivalents
- Keep the existing path structure: `TitleLocation`, `UserLocation`
- For stream `.Close()` extension methods (lines 49-78): Remove them — .NET has `.Close()` natively
- The Storage4 class should use `Environment.GetFolderPath(SpecialFolder.ApplicationData)` for user data

**Pattern:**
```csharp
// BEFORE:
#if NETFX_CORE
    static StorageFolder TitleSpaceFolder;
    static public StorageFolder UserSpaceFolder;
    static StorageFolder TempFolder;
#endif

// AFTER:
static string titleSpacePath;
static string userSpacePath;
static string tempPath;

// Initialize with:
userSpacePath = Path.Combine(Environment.GetFolderPath(
    Environment.SpecialFolder.ApplicationData), "KoduGameLab");
tempPath = Path.GetTempPath();
```

### Step 2.2: Resolve Audio.cs Conditionals
**File:** `main/Boku/Audio/Audio.cs` (487 lines)
**Current:** `#if NETFX_CORE` for file paths and AudioStopOptions
**Action:** (Preliminary — full XACT replacement is Phase 5)
- Remove the conditional path logic — use a single content-relative path
- Keep the `engine.GetCategory("Music").Stop()` form (without AudioStopOptions parameter, which is the NETFX_CORE form)

### Step 2.3: Batch-Resolve Simple NETFX_CORE Patterns
**Files:** All files with simple conditional patterns
**Action:** For each file, apply the appropriate resolution:

**Pattern A — Application Exit (5+ files):**
```csharp
// BEFORE:
#if NETFX_CORE
    Windows.UI.Xaml.Application.Current.Exit();
#else
    // Some WinForms exit
#endif

// AFTER:
BokuGame.bokuGame?.Exit();
// or for fatal: Environment.Exit(0);
```
**Files:** MainMenu.cs, OptionsMenu.cs, InGameRunSim.cs, TitleScreenMode.cs, Program.cs

**Pattern B — Language/Culture Detection:**
```csharp
// BEFORE:
#if NETFX_CORE
    lang = Windows.System.UserProfile.GlobalizationPreferences.Languages[0];
#else
    lang = CultureInfo.CurrentCulture.Name.Substring(0, 2).ToUpper();
#endif

// AFTER:
lang = CultureInfo.CurrentCulture.TwoLetterISOLanguageName.ToUpper();
```

**Pattern C — Stream.Close() Extension (Storage4.cs, others):**
```csharp
// BEFORE:
#if NETFX_CORE
    // Extension method because WinRT streams don't have Close()
    public static void Close(this Stream stream) { stream.Dispose(); }
#endif

// AFTER:
// Delete entirely — .NET has Close() on all streams
```

**Pattern D — RegexOptions.Compiled (PutWorldData.cs, others):**
```csharp
// BEFORE:
#if NETFX_CORE
    Regex r = new Regex(pattern);  // No Compiled option
#else
    Regex r = new Regex(pattern, RegexOptions.Compiled);
#endif

// AFTER:
Regex r = new Regex(pattern, RegexOptions.Compiled);  // .NET 9 supports this
```

**Pattern E — Encoding (Request.cs, others):**
```csharp
// BEFORE:
#if NETFX_CORE
    byte[] bytes = Encoding.UTF8.GetBytes(data);
#else
    byte[] bytes = Encoding.ASCII.GetBytes(data);
#endif

// AFTER:
byte[] bytes = Encoding.UTF8.GetBytes(data);  // UTF8 is correct for modern apps
```

### Step 2.4: Create a Tracking Spreadsheet of All NETFX_CORE Locations
**Action:** Run `grep -rn "#if.*NETFX_CORE\|#else\|#endif" main/Boku --include="*.cs"` and create a checklist of every file that needs resolution. Group by pattern type (A-E above, plus custom patterns).

**Known files with NETFX_CORE (from exploration):**
- Audio/Audio.cs
- Common/Storage4.cs, Storage.cs
- Common/LevelPackage.cs
- Common/Localization/Localizer.cs
- Common/KeyboardInput.cs, WinKeyboard.cs
- Common/WinStoreHelpers.cs (DELETE)
- Common/GamePadInput.cs
- Common/PerfTimer.cs
- BokuGame.cs, BokuGame.Designer.cs
- Program.cs
- Scenes/MainMenu.cs, InGame/*.cs
- Web/Community.cs, Request.cs
- SimWorld/Terra/VirtualMap.cs
- And ~30+ others

---

## PHASE 3: Replace Platform-Specific APIs

### Step 3.1: Replace P/Invoke Dependencies

**3.1a: Replace WinKeyboard.cs P/Invoke**
**File:** `main/Boku/Common/WinKeyboard.cs`
**Current:** Uses `DllImport("user32.dll")` for `ToUnicode()`, `GetKeyboardState()`
**Action:** Replace with MonoGame's `Keyboard.GetState()` and `TextInput` event:
```csharp
// MonoGame provides a TextInput event on the GameWindow:
Game.Window.TextInput += (sender, e) => {
    char character = e.Character;
    // Handle text input
};
```
**Alternative:** Keep a simplified version using MonoGame's `Keys` enum mapping.

**3.1b: Replace PerfTimer.cs P/Invoke**
**File:** `main/Boku/Common/PerfTimer.cs`
**Current:** `DllImport("kernel32.dll")` for `QueryPerformanceCounter/Frequency`
**Action:** Replace with `System.Diagnostics.Stopwatch`:
```csharp
// BEFORE:
[DllImport("Kernel32.dll")]
private static extern bool QueryPerformanceCounter(out long perfcount);

// AFTER:
private static readonly Stopwatch _stopwatch = Stopwatch.StartNew();
public static long GetTicks() => _stopwatch.ElapsedTicks;
public static long GetFrequency() => Stopwatch.Frequency;
```

**3.1c: Replace Microbit Serial P/Invoke**
**File:** `main/Boku/Input/Microbit/CommBase.cs`
**Current:** Win32 serial port via kernel32.dll `CreateFile()`
**Action:** Replace with `System.IO.Ports.SerialPort` (available in .NET 9):
```csharp
// BEFORE: Win32 CreateFile, ReadFile, WriteFile P/Invoke
// AFTER:  var port = new SerialPort("COM3", 115200);
```
**Note:** Add `<PackageReference Include="System.IO.Ports" Version="9.0.*" />` to boku.csproj

### Step 3.2: Replace Windows.Storage APIs
**Files:** Storage4.cs, LevelPackage.cs, and any file using `Windows.Storage`
**Action:** All `StorageFolder`/`StorageFile` operations become `System.IO.Directory`/`System.IO.File`:

| Windows.Storage | System.IO Replacement |
|----------------|----------------------|
| `StorageFolder.GetFilesAsync()` | `Directory.GetFiles()` |
| `StorageFolder.GetFoldersAsync()` | `Directory.GetDirectories()` |
| `StorageFolder.CreateFileAsync()` | `File.Create()` |
| `StorageFile.OpenAsync(FileAccessMode.Read)` | `File.OpenRead()` |
| `StorageFolder.TryGetItemAsync()` | `File.Exists()` / `Directory.Exists()` |
| `ApplicationData.Current.LocalFolder` | `Environment.GetFolderPath(SpecialFolder.ApplicationData)` |

### Step 3.3: Replace Windows.UI / Application Lifecycle
**Action:** Replace all UWP application lifecycle calls:
```csharp
// Windows.UI.Xaml.Application.Current.Exit() → Environment.Exit(0) or game.Exit()
// Windows.ApplicationModel.Core.CoreApplication.Run() → game.Run()
```

### Step 3.4: Replace Auth.cs Cryptography
**File:** `main/BokuShared/Auth.cs`
**Current:** `#if NETFX_CORE` uses `Windows.Security.Cryptography`
**Action:** Use `System.Security.Cryptography` (the !NETFX_CORE path is already correct):
```csharp
using System.Security.Cryptography;
// Keep the existing RSA/hash implementations from the desktop code path
```

### Step 3.5: Replace DotNetZip with System.IO.Compression
**Files:** `Common/LevelPackage.cs` and any file using `Ionic.Zip`
**Current:** Uses `Ionic.Zip.ZipFile` for level packages
**Action:** Replace with `System.IO.Compression.ZipFile`:
```csharp
// BEFORE:
using (var zip = new Ionic.Zip.ZipFile(path))
{
    zip.AddFile(filename);
    zip.Save(outputPath);
}

// AFTER:
using System.IO.Compression;
ZipFile.CreateFromDirectory(sourceDir, outputPath);
// Or for individual entries:
using (var archive = ZipFile.Open(path, ZipArchiveMode.Create))
{
    archive.CreateEntryFromFile(filename, entryName);
}
```

---

## PHASE 4: Content Pipeline Port

### Step 4.1: Move Content Assets to New Structure
**Action:** Create the `main/Content/Assets/` directory tree and move/copy assets:
```bash
mkdir -p main/Content/Assets/{Shaders,Textures,Models,Fonts,Audio,Xml,Text,Video}
cp -r main/Boku/Content/Shaders/* main/Content/Assets/Shaders/
cp -r main/Boku/Content/Textures/* main/Content/Assets/Textures/
cp -r main/Boku/Content/Models/* main/Content/Assets/Models/
cp -r main/Boku/Content/Fonts/* main/Content/Assets/Fonts/
cp -r main/Boku/Content/Audio/*.wav main/Content/Assets/Audio/  # WAV files only
cp -r main/Boku/Content/Xml/* main/Content/Assets/Xml/
cp -r main/Boku/Content/Text/* main/Content/Assets/Text/
```
**Note:** Do NOT copy .xgs, .xwb, .xsb files — those are XACT-specific and will be replaced.

### Step 4.2: Port Custom Content Processors
**Files:** `main/BokuContentProcessors/` (6 files: CensorContent pipeline)
**Action:**
- Create a new `main/Content/Source/Processors/` directory
- Port CensorContentImporter, CensorContentProcessor, CensorContentWriter to work with MonoGame Content Pipeline
- Update `Builder.cs` to reference the custom processors:
```csharp
contentCollection.Include<WildcardRule>("Text/Censor/*.csv",
    new CensorContentImporter(), new CensorContentProcessor());
```

**Also port AnimContentProc (Animation processor):**
- Port `AnimationProcessor` and `AnimatedModelProcessor` to MonoGame pipeline
- These process .fbx + .xml animation pairs
- Add to Builder.cs content collection

### Step 4.3: Port Animation Content Pipeline
**Files:** `main/AnimContentProc/` and `main/AnimWindows/`
**Current:** XNA 4.0 content pipeline libraries for skeletal animation
**Key classes:**
- `AnimationProcessor` → `ContentProcessor(DisplayName = "ModelAnimationCollection")`
- `AnimatedModelProcessor` → `ContentProcessor(DisplayName = "Model - Animation Library")`
- `AnimationReader` → `ContentTypeReader<AnimationInfoCollection>`
- `AnimationWriter` → `ContentTypeWriter<AnimationContentDictionary>`
**Action:**
- Port these to .NET 9.0 + MonoGame.Framework.Content.Pipeline
- Keep the same import/process/write/read pattern
- Add processor assembly reference in Builder.csproj
- Register in Builder.cs for .fbx model files

### Step 4.4: Update Content Load Paths in C# Code
**Key file:** `main/Boku/BokuGame.cs` (Load<T> method, lines 263-310)
**Current:** Uses `ContentLoader.ContentManager.Load<T>(path)` with HiDef/Reach fallback via string replacement: tries `ContentHiDef` path first, falls back to `Content`
**Action — HiDef Only:** Remove the entire HiDef/Reach fallback mechanism. Since we only support HiDef now, simplify Load<T>() to a single direct load:
```csharp
public static T Load<T>(string path)
{
    return ContentLoader.ContentManager.Load<T>(path);
}
```
- Remove `BokuSettings.Settings.PreferReach` checks
- Remove the `path.Replace("Content", "ContentHiDef")` fallback logic
- Remove `hwSupportsReach`, `hwSupportsHiDef` flags from BokuGame
- Always use `GraphicsProfile.HiDef` — remove profile detection/selection logic
- Update paths to match new Content/Assets/ structure (forward slashes, no MediaPath prefix)

**Pattern for all content loading calls across the codebase:**
```csharp
// BEFORE:
BokuGame.Load<Effect>(BokuGame.Settings.MediaPath + @"Shaders\Standard");

// AFTER:
BokuGame.Load<Effect>("Shaders/Standard");
// Note: Use forward slashes for cross-platform, Content.RootDirectory handles the root
```

**Search for all content load calls:**
```bash
grep -rn "Content.Load\|BokuGame.Load\|ContentLoader" main/Boku --include="*.cs"
```
Update each to use the new relative path format without backslashes.

### Step 4.5: Handle XML Content (Levels, Localization)
**Current:** Many .xml files are loaded directly via XmlSerializer, not through the content pipeline
**Action:** XML files that are loaded at runtime via XmlSerializer should be copied as raw files (not processed through the content pipeline). Configure Builder.cs to exclude or copy-as-is:
```csharp
// In Builder.cs:
contentCollection.Exclude<WildcardRule>("Xml/**/*.xml");  // Don't process XML
// These will be copied as raw files to the output directory
```
**Alternative:** Add them as Content items with `CopyToOutputDirectory` in boku.csproj.

---

## PHASE 5: Audio System Replacement (XACT → SoundEffect)

MonoGame DesktopGL does NOT support XACT (AudioEngine, WaveBank, SoundBank). This requires building a replacement audio system.

### Step 5.1: Create New Audio Manager Class
**File:** Create `main/Boku/Audio/AudioManager.cs`
**Purpose:** Replace XACT's AudioEngine/WaveBank/SoundBank with MonoGame SoundEffect
**Architecture:**
```csharp
public class AudioManager
{
    Dictionary<string, SoundEffect> soundEffects = new();
    Dictionary<string, SoundEffectInstance> activeSounds = new();
    Dictionary<string, float> categoryVolumes = new()
    {
        { "Music", 1.0f },
        { "Foley", 1.0f },
        { "UI", 1.0f }
    };

    public void LoadContent(ContentManager content)
    {
        // Load all WAV files as SoundEffect assets
        // Map cue names to SoundEffect instances
    }

    public SoundEffectInstance GetCue(string name) { ... }
    public void SetCategoryVolume(string category, float volume) { ... }
    public void Update() { /* cleanup finished instances */ }
}
```

### Step 5.2: Create Cue-to-WAV Mapping
**Action:** Create a mapping file or dictionary that maps the 80+ XACT cue names to their WAV file paths:
```csharp
// CueMapping.cs
static readonly Dictionary<string, (string path, string category)> CueMap = new()
{
    { "KA_Boom", ("Audio/Foley/KeyAction/Boom", "Foley") },
    { "KA_Create", ("Audio/Foley/KeyAction/Create", "Foley") },
    { "UI_Back", ("Audio/UI/Back", "UI") },
    { "UI_ClickUp", ("Audio/UI/ClickUp", "UI") },
    // ... 80+ entries
};
```
**Note:** The exact WAV file names need to be mapped from the XACT .xap project file or by examining the Content/Audio/ directory structure.

### Step 5.3: Rewrite Audio.cs
**File:** `main/Boku/Audio/Audio.cs` (487 lines)
**Action:** Replace XACT initialization with AudioManager:
```csharp
// BEFORE:
private AudioEngine engine;
private WaveBank inMemoryWavebank;
private SoundBank soundbank;

// AFTER:
private AudioManager audioManager;

// Init:
audioManager = new AudioManager();
audioManager.LoadContent(contentManager);

// Playback:
// BEFORE: soundbank.GetCue("KA_Boom")
// AFTER:  audioManager.GetCue("KA_Boom")
```

### Step 5.4: Rewrite AudioCue.cs for SoundEffectInstance
**File:** `main/Boku/Audio/AudioCue.cs`
**Current:** Wraps XACT `Cue` class with 3D spatial audio support
**Action:** Wrap `SoundEffectInstance` instead:
```csharp
public class AudioCue
{
    private SoundEffectInstance instance;
    private string category;

    // 3D Audio simplified approach:
    // MonoGame DesktopGL SoundEffectInstance supports Pan (-1 to 1)
    // We can simulate basic directionality using Pan
    public void Apply3D(AudioListener listener, AudioEmitter emitter)
    {
        // Calculate relative position and set Pan
        Vector3 toSource = emitter.Position - listener.Position;
        Vector3 right = Vector3.Cross(listener.Forward, listener.Up);
        float pan = Vector3.Dot(Vector3.Normalize(toSource), right);
        instance.Pan = MathHelper.Clamp(pan, -1f, 1f);

        // Attenuate by distance
        float distance = toSource.Length();
        instance.Volume = MathHelper.Clamp(1f - (distance / maxDistance), 0f, 1f);
    }
}
```

### Step 5.5: Update Foley.cs
**File:** `main/Boku/Audio/Foley.cs` (600+ lines)
**Current:** Uses `Audio.GetCue(name)` throughout — 80+ cue references
**Action:** The interface stays the same (GetCue returns AudioCue), but underlying implementation uses SoundEffect. No changes needed to Foley.cs if AudioCue interface is preserved.

### Step 5.6: Handle Music Playback
**Current:** XACT category "Music" with streaming WaveBank
**Action:** Use MonoGame's `MediaPlayer` and `Song` for music:
```csharp
Song bgm = Content.Load<Song>("Audio/Music/TrackName");
MediaPlayer.Play(bgm);
MediaPlayer.Volume = categoryVolumes["Music"];
MediaPlayer.IsRepeating = true;
```

---

## PHASE 6: Shader Porting (HiDef Only)

Since we target HiDef only, we use the ContentHiDef shaders as our primary source (~34 files), supplemented by any unique shaders from Content/Shaders/ that don't have HiDef variants. All SM2-only shader variants are removed.

### Step 6.1: Add OpenGL Shader Model Defines
**Action:** Add MonoGame-compatible shader model defines to ALL .fx files.
**Pattern** (add at top of each .fx file, before any other code):
```hlsl
#if OPENGL
    #define VS_SHADERMODEL vs_3_0
    #define PS_SHADERMODEL ps_3_0
#else
    #define VS_SHADERMODEL vs_4_0_level_9_1
    #define PS_SHADERMODEL ps_4_0_level_9_1
#endif
```
**Files:** All .fx files in Content/Assets/Shaders/ (post-merge from ContentHiDef)
**Note:** Since we're HiDef-only, all shaders target vs_3_0/ps_3_0 minimum.

### Step 6.2: Update Technique Declarations
**Current XNA syntax:**
```hlsl
technique TexturedColorPass_SM2
{
    pass P0
    {
        VertexShader = compile vs_2_0 ColorTexVS_SM2();
        PixelShader  = compile ps_2_0 TexturedColorPS_SM2();
    }
}
```
**MonoGame syntax (same but with defines):**
```hlsl
technique TexturedColorPass
{
    pass P0
    {
        VertexShader = compile VS_SHADERMODEL ColorTexVS();
        PixelShader  = compile PS_SHADERMODEL TexturedColorPS();
    }
}
```
**Note:** Since HiDef-only, always use SM3 function implementations where separate SM2/SM3 variants existed.

### Step 6.3: Handle Render State Declarations in Passes
**Current:** Shaders set render states inline in pass blocks:
```hlsl
pass P0
{
    AlphaBlendEnable = false;
    ZEnable = true;
    CullMode = CCW;
    VertexShader = compile vs_2_0 MyVS();
    PixelShader = compile ps_2_0 MyPS();
}
```
**MonoGame:** Render states in pass blocks are NOT supported — they must be set from C# code.
**Action:** For each shader with inline render states:
1. Document the render state in a comment
2. Remove the render state from the pass block
3. Ensure the C# rendering code sets these states before drawing:
```csharp
GraphicsDevice.BlendState = BlendState.Opaque;
GraphicsDevice.DepthStencilState = DepthStencilState.Default;
GraphicsDevice.RasterizerState = RasterizerState.CullCounterClockwise;
```

### Step 6.4: Verify #include Resolution
**Current:** All shaders use `#include "Globals.fx"` and feature includes
**MonoGame:** The content pipeline effect processor supports `#include` directives
**Action:** Ensure all included files are in the same directory. This should work as-is.

### Step 6.5: Handle the `shared` Keyword
**File:** `Globals.fx` uses `shared` keyword for cross-effect parameter sharing
**MonoGame:** The `shared` keyword may not be supported
**Action:** If `shared` causes compilation errors, remove it. Parameters are set per-effect from ShaderGlobals C# code.

### Step 6.6: Remove SM2 Shader Variants and Reach Profile Code
**Action:** Since we're HiDef-only:
1. **Delete all `*_SM2.fx` files** (~7 files: Standard_SM2.fx, Surface_SM2.fx, Road_SM2.fx, Ghost_Stand_SM2.fx, Ghost_SURF_SM2.fx, etc.)
2. **Keep SM3 variants** (rename if desired, e.g., Standard_SM3.fx → Standard.fx)
3. **Update C# code** that selects SM2 vs SM3 techniques to always use SM3:
   - Search for: `GraphicsProfile.Reach`, `PreferReach`, `hwSupportsReach`, technique name strings containing "SM2"
   - Remove all Reach-related branching
   - Remove `BokuSettings.PreferReach` option
4. **Remove ContentHiDef directory** after merging into Content/Assets/Shaders/
5. **Simplify ShaderGlobals.cs** — remove HiDef/Reach conditional loading
6. **Remove `hidef` flag** and profile detection from BokuGame.cs

---

## PHASE 7: BokuGame Class & Game Loop Modernization

### Step 7.1: Clean Up BokuGame.cs (HiDef Only)
**File:** `main/Boku/BokuGame.cs` (partial class)
**Current:** `partial class BokuGame : Microsoft.Xna.Framework.Game` (correct for MonoGame)
**Action:**
- Ensure constructor creates `GraphicsDeviceManager`:
```csharp
public BokuGame()
{
    _graphics = new GraphicsDeviceManager(this);
    _graphics.GraphicsProfile = GraphicsProfile.HiDef;  // Always HiDef
    Content.RootDirectory = "Content";
    IsMouseVisible = true;
}
```
- Remove any references to `MainForm`, `XNAControl`, `GraphicsDeviceControl`
- Remove `#if NETFX_CORE` conditionals
- **Remove Reach/HiDef detection:** Delete `hwSupportsReach`, `hwSupportsHiDef`, `hidef` flags
- **Remove profile selection logic:** Always use `GraphicsProfile.HiDef`
- **Simplify Load<T>():** Remove the `ContentHiDef` fallback path — always load directly
- Keep the existing `Initialize()`, `LoadContent()`, `Update()`, `Draw()` overrides

### Step 7.2: Clean Up BokuGame.Designer.cs
**File:** `main/Boku/BokuGame.Designer.cs`
**Current:** Contains `PreparingDeviceSettingsHandler` for graphics setup
**Action:** Move the graphics configuration logic into `BokuGame.Initialize()` and delete the Designer file (it's a WinForms artifact):
```csharp
protected override void Initialize()
{
    _graphics.PreferredBackBufferWidth = 1280;
    _graphics.PreferredBackBufferHeight = 720;
    _graphics.PreferMultiSampling = true;
    _graphics.ApplyChanges();
    base.Initialize();
}
```

### Step 7.3: Update INeedsDeviceReset Pattern
**Current:** 100+ classes implement `INeedsDeviceReset` interface for device lost/reset handling
**Action:** MonoGame handles device reset differently. Keep the interface but simplify:
- Device reset events fire much less frequently on modern hardware
- The pattern should still work — just verify it compiles and runs

---

## PHASE 8: Fix Remaining Compilation Issues

### Step 8.1: Remove Xbox 360 Code
**Action:** Search for `#if XBOX` (4 occurrences) and resolve:
- Remove Xbox-specific code paths
- Keep the non-Xbox path

### Step 8.2: Fix Missing Type References
**Action:** After removing WinForms and UWP references, fix any remaining type resolution errors:
- `System.Windows.Forms.Keys` → `Microsoft.Xna.Framework.Input.Keys`
- `System.Drawing.Point` → `Microsoft.Xna.Framework.Point`
- `System.Drawing.Rectangle` → `Microsoft.Xna.Framework.Rectangle`
- `System.Drawing.Color` → `Microsoft.Xna.Framework.Color`

### Step 8.3: Handle Web/Community Service References
**Files:** `Web/Community.cs`, `Web/Trans/*.cs`
**Current:** SOAP web service calls to `kodu.cloudapp.net`
**Action:** Keep the web service code but ensure it uses .NET HttpClient:
```csharp
// If using legacy WebRequest/HttpWebRequest, update to:
using var client = new HttpClient();
var response = await client.PostAsync(url, content);
```

### Step 8.4: Handle Removed Features Gracefully
**Action:** Some features may need to be stubbed out initially:
- **Twitter/Twitch integration** — stub with no-op implementations
- **Facebook login** — stub or remove
- **BrowserForm** — already deleted; stub any callers
- **Microbit** — keep but guard behind runtime platform check

### Step 8.5: Fix Namespace and Using Issues
**Action:** After all changes, do a full build and fix remaining issues:
```bash
dotnet build main/Boku/boku.csproj 2>&1 | head -100
```
Iterate on compilation errors until the project builds cleanly.

---

## PHASE 9: Integration Testing & Polish

### Step 9.1: Content Pipeline Build Test
**Action:** Build the Content Builder and verify it processes all assets:
```bash
cd main/Content
dotnet build Builder.csproj
dotnet run --project Builder.csproj -- build -p DesktopGL -s Assets -o bin/Content -i obj/Content
```
Fix any content build failures (likely shader compilation issues first).

### Step 9.2: Full Application Build
**Action:**
```bash
dotnet build main/Boku/boku.csproj --configuration Release
```

### Step 9.3: Runtime Smoke Test
**Action:** Launch the application and verify:
- Window opens at correct resolution
- Title screen renders
- Basic UI is functional
- Audio plays (even if simplified)
- Content loads without crashes

### Step 9.4: Create .gitignore Updates
**Action:** Update `.gitignore` for new build artifacts:
```
main/Content/bin/
main/Content/obj/
main/Boku/bin/
main/Boku/obj/
```

---

## Appendix A: File Count Summary

| Category | Count | Action |
|----------|-------|--------|
| C# source files | 928 | Modify ~250, delete ~15 |
| WinForms files to delete | ~15 | Delete |
| NETFX_CORE conditionals | 206 | Resolve each |
| Shader files (.fx) | ~60 (HiDef only) | Port to MonoGame HLSL, delete SM2 variants |
| Content assets | ~2,700 | Move to new structure |
| Audio WAV files | 602 | Keep, load as SoundEffect |
| XACT files (.xgs/.xwb/.xsb) | 9 | Delete (replaced by direct WAV) |
| Custom content processors | 2 | Port to MonoGame pipeline |
| P/Invoke sites | 5 files | Replace with cross-platform |

## Appendix B: Key Code Patterns for Agents

### Pattern: Resolving #if NETFX_CORE
```csharp
// Step 1: Identify the block
#if NETFX_CORE
    // UWP code
#else
    // Desktop code
#endif

// Step 2: Choose the cross-platform version
// - If UWP uses Windows.* APIs → use the desktop path (System.IO, etc.)
// - If desktop uses WinForms → use neither, write new cross-platform code
// - If both are valid → prefer the simpler/more standard one

// Step 3: Remove the #if/#else/#endif, keep only the chosen code
```

### Pattern: Replacing MessageBox
```csharp
// BEFORE:
#if !NETFX_CORE
    MessageBox.Show(message, title, MessageBoxButtons.OK);
#endif

// AFTER:
Debug.WriteLine($"[{title}] {message}");
// For fatal errors:
Console.Error.WriteLine($"FATAL: [{title}] {message}");
Environment.Exit(1);
```

### Pattern: Content Loading
```csharp
// BEFORE:
Content.Load<Texture2D>(BokuGame.Settings.MediaPath + @"Textures\MyTexture");

// AFTER:
Content.Load<Texture2D>("Textures/MyTexture");
```

### Pattern: Effect Loading
```csharp
// BEFORE:
BokuGame.Load<Effect>(BokuGame.Settings.MediaPath + @"Shaders\Standard");

// AFTER:
BokuGame.Load<Effect>("Shaders/Standard");
```

## Appendix C: Risk Assessment

| Risk | Impact | Mitigation |
|------|--------|------------|
| Shader compilation failures | High | Test each shader individually, fix HLSL syntax |
| XACT audio replacement loses 3D spatial audio | Medium | Implement Pan-based approximation in AudioCue |
| Custom animation processor incompatible | Medium | Port step-by-step, test with a single model first |
| Storage4 refactoring breaks save/load | High | Test with existing save files after porting |
| Content path changes break runtime loading | High | Search-and-replace all content load calls |
| Web services break due to async changes | Low | Keep synchronous for initial port |
| Missing XNA APIs in MonoGame | Medium | Check MonoGame API compatibility for each usage |

## Appendix D: Dependency Graph (Build Order)

```
1. BokuShared (.NET 9.0 port)          — no dependencies
2. Content Builder (Builder.csproj)     — depends on MonoGame.Content.Pipeline
3. Content Processors (in Builder)      — depends on BokuShared for CensorContent types
4. Boku (main game)                     — depends on BokuShared, Content output
```
