#!/bin/bash
#
# Upgrades FBX files to FBX 2013 (version 7.3) format using Autodesk FBX Converter.
# - Detects both binary and ASCII FBX files
# - Skips files already at version 7300+
# - Converts in-place (overwrites original)

CONVERTER="/Applications/Autodesk/FBX Converter/2013.3/FbxConverterUI.app/Contents/MacOS/bin/FbxConverter"
TARGET_VERSION=7300  # FBX 2013
SEARCH_DIR="${1:-main/Boku/Content/Models}"

if [ ! -x "$CONVERTER" ]; then
    echo "ERROR: FBX Converter not found at: $CONVERTER"
    exit 1
fi

get_fbx_version() {
    local file="$1"
    python3 -c "
import struct, sys, re

with open('$file', 'rb') as f:
    header = f.read(27)

    # Binary FBX: starts with 'Kaydara FBX Binary'
    if header[:18] == b'Kaydara FBX Binary':
        version = struct.unpack('<I', header[23:27])[0]
        print(version)
        sys.exit(0)

    # ASCII FBX: starts with '; FBX x.y.z project file'
    f.seek(0)
    first_line = f.readline().decode('ascii', errors='ignore')
    if first_line.startswith('; FBX'):
        # Extract version from header comment, e.g. '; FBX 6.1.0 project file'
        m = re.search(r'FBX (\d+)\.(\d+)', first_line)
        if m:
            major, minor = int(m.group(1)), int(m.group(2))
            # Also check FBXVersion property for the actual internal version
            f.seek(0)
            content = f.read(4096).decode('ascii', errors='ignore')
            vm = re.search(r'FBXVersion:\s*(\d+)', content)
            if vm:
                print(vm.group(1))
                sys.exit(0)
            # Fallback: synthesize from header (6.1 -> 6100)
            print(major * 1000 + minor * 100)
            sys.exit(0)

print(0)
"
}

version_label() {
    local ver="$1"
    if [ "$ver" -ge 7300 ]; then echo "FBX 2013 (7.3)"
    elif [ "$ver" -ge 7200 ]; then echo "FBX 2012 (7.2)"
    elif [ "$ver" -ge 7100 ]; then echo "FBX 2011 (7.1)"
    elif [ "$ver" -ge 7000 ]; then echo "FBX 2010 (7.0)"
    elif [ "$ver" -ge 6100 ]; then echo "FBX 2006.11 (6.1)"
    elif [ "$ver" -ge 6000 ]; then echo "FBX 2006.09 (6.0)"
    else echo "Unknown ($ver)"
    fi
}

upgraded=0
skipped=0
failed=0

echo "Scanning for FBX files in: $SEARCH_DIR"
echo "Target format: FBX 2013 (version $TARGET_VERSION)"
echo "=========================================="

while IFS= read -r -d '' fbx_file; do
    version=$(get_fbx_version "$fbx_file")
    label=$(version_label "$version")

    if [ "$version" -ge "$TARGET_VERSION" ]; then
        echo "SKIP  $fbx_file ($label)"
        skipped=$((skipped + 1))
        continue
    fi

    echo -n "UPGRADE  $fbx_file ($label) -> FBX 2013 ... "

    tmp_file="${fbx_file}.tmp.fbx"

    # Convert to FBX 2013 binary format
    "$CONVERTER" "$fbx_file" "$tmp_file" /sffFBX /dffFBX /f201300 /v > /dev/null 2>&1

    if [ $? -eq 0 ] && [ -f "$tmp_file" ]; then
        mv "$tmp_file" "$fbx_file"
        echo "OK"
        upgraded=$((upgraded + 1))
    else
        echo "FAILED"
        rm -f "$tmp_file"
        failed=$((failed + 1))
    fi
done < <(find "$SEARCH_DIR" -name "*.fbx" -print0 | sort -z)

echo "=========================================="
echo "Done. Upgraded: $upgraded | Skipped: $skipped | Failed: $failed"
