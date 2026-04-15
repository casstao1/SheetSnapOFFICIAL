#!/bin/zsh
set -euo pipefail

repo_root="/Users/castao/Desktop/SheetSnap/SheetSnapOFFICIAL"

candidates=(
  "/tmp/SheetSnapUIBuild/Build/Products/Debug/SheetSnap.app"
  "/tmp/SheetSnapReleaseDerivedDataBA3/Build/Products/Release/SheetSnap.app"
  "/tmp/SheetSnapReleaseDerivedDataBA/Build/Products/Release/SheetSnap.app"
  "/tmp/SheetSnapReleaseDerivedData/Build/Products/Release/SheetSnap.app"
  "/tmp/SheetSnapDerivedDataBA/Build/Products/Debug/SheetSnap.app"
  "/tmp/SheetSnapDerivedData/Build/Products/Debug/SheetSnap.app"
)

is_runnable_app() {
  local app_path="$1"
  [[ -d "$app_path" && -x "$app_path/Contents/MacOS/SheetSnap" ]]
}

app_mtime() {
  local app_path="$1"
  stat -f "%m" "$app_path/Contents/MacOS/SheetSnap" 2>/dev/null || echo 0
}

launch_app() {
  local app_path="$1"
  local app_exec="$app_path/Contents/MacOS/SheetSnap"
  "$app_exec" >/tmp/sheetsnap-launcher.log 2>&1 </dev/null &
}

newest_runnable_app() {
  local newest_path=""
  local newest_mtime=0
  local app_path mtime

  for app_path in "${candidates[@]}"; do
    if is_runnable_app "$app_path"; then
      mtime=$(app_mtime "$app_path")
      if (( mtime > newest_mtime )); then
        newest_mtime=$mtime
        newest_path="$app_path"
      fi
    fi
  done

  while IFS= read -r -d '' app_path; do
    if is_runnable_app "$app_path"; then
      mtime=$(app_mtime "$app_path")
      if (( mtime > newest_mtime )); then
        newest_mtime=$mtime
        newest_path="$app_path"
      fi
    fi
  done < <(
    find "$HOME/Library/Developer/Xcode/DerivedData" \
      -path "*/Build/Products/*/SheetSnap.app" \
      -type d \
      ! -path "*/Index.noindex/*" \
      -print0 2>/dev/null
  )

  [[ -n "$newest_path" ]] && print -r -- "$newest_path"
}

newest_source_mtime=$(
  find "$repo_root" \
    \( -path "*/.git/*" -o -path "*/docs/app-store/*" -o -path "*/tools/*" \) -prune \
    -o \
    -type f \
    \( -name "*.swift" -o -name "*.plist" -o -name "*.json" -o -name "*.xcconfig" -o -name "*.entitlements" -o -name "project.pbxproj" \) \
    -exec stat -f "%m" {} \; 2>/dev/null \
    | sort -nr \
    | head -n 1
)

latest_app="$(newest_runnable_app || true)"

if [[ -n "${latest_app:-}" ]]; then
  latest_app_mtime=$(app_mtime "$latest_app")
  if [[ -n "${newest_source_mtime:-}" ]] && (( newest_source_mtime > latest_app_mtime )); then
    echo "Your latest SheetSnap code changes are newer than the newest built app bundle. Build the app once in Xcode, then use this launcher again." >&2
    exit 1
  fi

  launch_app "$latest_app"
  exit 0
fi

echo "No built SheetSnap.app was found yet. Build the app once in Xcode, then use this launcher again." >&2
exit 1
