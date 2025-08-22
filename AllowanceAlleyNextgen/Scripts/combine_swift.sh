#!/usr/bin/env bash
# combine_swift.sh
# Combine all .swift files under a directory into a single Markdown file.

set -euo pipefail

usage() {
  cat <<'EOF'
Usage: combine_swift.sh [-d DIR] [-o OUT.md] [-t "TITLE"]

Combines all Swift files found under DIR (recursively) into a single Markdown file.
Defaults:
  DIR   = .
  OUT   = AllSwiftFiles.md
  TITLE = Swift Sources

Excludes common build/vendor folders: Pods, Carthage, .build, DerivedData, .git
EOF
}

DIR="."
OUT="AllSwiftFiles.md"
TITLE="Swift Sources"

# --- Parse args ---
while [[ $# -gt 0 ]]; do
  case "$1" in
    -d|--dir)
      [[ $# -ge 2 ]] || { echo "Missing value for $1" >&2; exit 1; }
      DIR="$2"; shift 2;;
    -o|--out)
      [[ $# -ge 2 ]] || { echo "Missing value for $1" >&2; exit 1; }
      OUT="$2"; shift 2;;
    -t|--title)
      [[ $# -ge 2 ]] || { echo "Missing value for $1" >&2; exit 1; }
      TITLE="$2"; shift 2;;
    -h|--help)
      usage; exit 0;;
    *)
      echo "Unknown option: $1" >&2
      usage; exit 1;;
  esac
done

if [[ ! -d "$DIR" ]]; then
  echo "Directory not found: $DIR" >&2
  exit 1
fi

# --- Start output ---
{
  echo "# $TITLE"
  echo
  # NOTE: use ${DIR} so the trailing underscore isn't parsed as part of the var name.
  echo "_Generated on $(date) from directory: ${DIR}_"
  echo
} > "$OUT"

# --- Collect files (newline-delimited; sorted) ---
FILES_LIST=$(find "$DIR" -type f -name "*.swift" \
  ! -path "*/Pods/*" ! -path "*/Carthage/*" ! -path "*/.build/*" \
  ! -path "*/DerivedData/*" ! -path "*/.git/*" | LC_ALL=C sort)

COUNT=0
if [[ -z "$FILES_LIST" ]]; then
  echo "No .swift files found under $DIR"
  exit 0
fi

# --- Append file sections ---
while IFS= read -r FILE; do
  REL="${FILE#$DIR/}"
  {
    echo "## File: ${REL}"
    echo
    echo '```swift'
    cat "$FILE"
    echo '```'
    echo
  } >> "$OUT"
  COUNT=$((COUNT+1))
done <<< "$FILES_LIST"

echo "Wrote $COUNT Swift file(s) to $OUT"
