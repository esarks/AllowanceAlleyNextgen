#!/usr/bin/env bash
# combine_swift.sh
# Combine all .swift files under a directory into a single Markdown file.
# Compatible with macOS default bash (3.2) and zsh via shebang.

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
  echo "_Generated on $(date) from directory: ${DIR}_"
  echo
} > "$OUT"

# --- Collect & append file sections (streamed) ---
COUNT=0
while IFS= read -r FILE; do
  [[ -n "${FILE:-}" ]] || continue

  case "$FILE" in
    "$DIR"/*) REL="${FILE#$DIR/}";;
    *)        REL="$FILE";;
  esac

  {
    echo "## File: ${REL}"
    echo
    echo '```swift'
    cat "$FILE"
    echo '```'
    echo
  } >> "$OUT"

  COUNT=$((COUNT + 1))
done < <(
  find "$DIR" -type f -name "*.swift" \
    ! -path "*/Pods/*" \
    ! -path "*/Carthage/*" \
    ! -path "*/.build/*" \
    ! -path "*/DerivedData/*" \
    ! -path "*/.git/*" 2>/dev/null \
  | LC_ALL=C sort || true
)

if [[ $COUNT -eq 0 ]]; then
  echo "No .swift files found under $DIR"
  exit 0
fi

echo "Wrote $COUNT Swift file(s) to $OUT"
