#!/bin/zsh
set -euo pipefail

launcher_script="/Users/castao/Desktop/SheetSnap/SheetSnapOFFICIAL/tools/launch_sheetsnap.sh"

osascript >/dev/null 2>&1 <<'EOF' || true
tell application "SheetSnap" to quit
EOF

sleep 1
/bin/zsh "$launcher_script"

