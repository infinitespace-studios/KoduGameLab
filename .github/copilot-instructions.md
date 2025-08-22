# Kodu Game Lab Development Instructions

Always reference these instructions first and fallback to search or bash commands only when you encounter unexpected information that does not match the info here.

## Overview

Kodu Game Lab is a 3D game development environment designed to teach kids basic programming principles using a visual programming language. The project originated as Microsoft Research project "Boku" targeting Xbox 360 with XNA, and is currently transitioning from legacy Windows XNA to cross-platform MonoGame/.NET.

**CRITICAL**: This repository is in a **transition state** from legacy XNA/.NET Framework to modern MonoGame/.NET. Only specific workflows are currently functional.

## Working Effectively

### Current Build Status
- **Modern Build**: The main Boku application uses .NET 8.0 with MonoGame but has compilation issues requiring fixes
- **Legacy Build**: Original VS2010/XNA toolchain documented in README.md but not tested in this environment
- **Cross-platform**: Only the modernized components can potentially run on Linux/macOS

### Validated Build Commands
```bash
# Navigate to repository root
cd /home/runner/work/KoduGameLab/KoduGameLab

# Modern .NET Build (HAS COMPILATION ERRORS - DO NOT EXPECT SUCCESS)
dotnet build main/Boku/boku.csproj --configuration Release
# Expected result: Build fails with preprocessor directive errors
# Timeout: Set to 60+ minutes for safety, but typically fails within 10 seconds

# Check available .NET version
dotnet --version
# Expected: 8.0.119 or similar

# Legacy projects (WILL NOT BUILD on Linux)
# These target .NET Framework 3.5 and require Windows + Visual Studio
dotnet build main/BokuShared/BokuShared.csproj --configuration Release
# Expected result: Reference assemblies not found error
```

### CRITICAL LIMITATIONS - NEVER CANCEL, BUT BE AWARE

- **DO NOT attempt full solution builds** - Most projects target incompatible .NET Framework versions
- **DO NOT expect the main application to run** - MonoGame conversion has unresolved compilation errors  
- **DO NOT try Windows-specific components on Linux** - Installer, WiX projects, some utilities are Windows-only
- **COMPILATION ISSUES EXIST**: Current main project has syntax errors that prevent successful builds

## Repository Structure

### Key Projects
- **main/Boku/** - Primary application (transitioning to MonoGame/.NET 8.0) 
- **main/BokuShared/** - Shared library (.NET Framework 3.5)
- **main/MicrobitHex/** - BBC micro:bit integration firmware
- **main/BokuSetup/** - Windows installer (WiX-based)
- **main/Tests/** - Unit test projects
- **main/Documents/** - Design and production documentation

### Important Files
```
main/
├── Boku.sln                  # Legacy VS2010 solution
├── Boku2017.sln             # VS2017 solution  
├── Boku/boku.csproj         # Modern .NET project (HAS ISSUES)
├── BuildRelease.bat         # Legacy Windows build script
├── BuildInstaller.bat       # Legacy Windows installer build
└── MicrobitHex/
    ├── README.md            # Microbit development guide
    ├── TESTS.md            # Comprehensive testing procedures
    └── FUTURE.md           # Planned microbit enhancements
```

## Testing and Validation

### Microbit Testing (MOST COMPREHENSIVE TESTING AVAILABLE)
The microbit integration provides the most thorough testing documentation:

```bash
# Navigate to microbit documentation
cd main/MicrobitHex
cat TESTS.md    # Read comprehensive test procedures
cat README.md   # Development setup for microbit firmware
```

**Key Microbit Test Scenarios:**
1. **Serial Terminal Testing**: Use RS-232 terminal to send commands like `P|` for ping
2. **Firmware Flashing**: Copy `.hex` files to microbit drive
3. **Kodu Integration**: Test microbit tiles in Kodu visual programming interface
4. **Expected behaviors**: "Kodu" scrolls on display, tilt controls work, button responses

### Manual Validation Requirements
**CURRENT STATE**: Due to compilation issues, manual application testing is not possible. When these are resolved:

1. **Launch Application**: Start Kodu Game Lab
2. **Create Simple World**: Basic terrain and character placement
3. **Test Visual Programming**: Create simple behaviors using visual tiles
4. **Microbit Integration**: If microbit available, test physical device integration
5. **Save/Load**: Test world persistence

### Build Time Expectations
- **Modern .NET builds**: 10-60 seconds (currently fail due to syntax errors)
- **Legacy builds on Windows**: 5-45 minutes for full solution
- **Content processing**: Additional time for XNA content pipeline (Windows only)

## Common Development Tasks

### Repository Exploration
```bash
# View repository structure
ls -la /home/runner/work/KoduGameLab/KoduGameLab/

# Check project files
find main -name "*.csproj" | head -10

# Find documentation
find . -name "*.md" | head -20

# Check build outputs (may be empty due to build issues)
ls -la main/Boku/bin/Release/net8.0/ 2>/dev/null || echo "No build outputs"
```

### Understanding Project Dependencies
- **MonoGame.Framework.DesktopGL**: Graphics framework (modern replacement for XNA)
- **System.Resources.Extensions**: Required for resource handling
- **Legacy XNA dependencies**: Only available on Windows with appropriate SDK

### Code Navigation
- **main/Boku/Tutorial/**: Tutorial system implementation
- **main/Boku/Programming/**: Visual programming language logic
- **main/Boku/SimWorld/**: 3D world simulation
- **main/Boku/Input/**: Input handling including microbit integration
- **main/Boku/UI/**: User interface systems

## Troubleshooting

### Expected Build Failures
```bash
# Modern .NET compilation errors
error CS1028: Unexpected preprocessor directive
error CS1002: ; expected
# These indicate the MonoGame conversion is incomplete

# Legacy .NET Framework issues  
error MSB3644: The reference assemblies for .NETFramework,Version=v3.5 were not found
# These require Windows + appropriate .NET Framework targeting packs
```

### Working Around Limitations
1. **Focus on documentation and architecture understanding** rather than runtime testing
2. **Use microbit documentation** as the primary testing reference
3. **Examine code structure** for understanding rather than execution
4. **Reference README.md** for legacy Windows build requirements when needed

## Important Notes for Agents

- **REALITY CHECK**: This codebase cannot currently be built and run in this environment
- **PRIMARY VALUE**: Rich documentation, especially microbit integration guides
- **LEARNING RESOURCE**: Excellent example of XNA to MonoGame transition challenges
- **WINDOWS DEPENDENCY**: Full functionality requires Windows + Visual Studio + XNA SDK

Always set realistic expectations about what can be accomplished with this codebase in its current state.