#!/bin/bash
# scripts/manifest.sh
# Generate a manifest of all files in the repo with size + SHA256 hash

# Where to write the manifest
OUTFILE="repo_manifest.txt"

echo "# Repository Manifest — $(basename "$(git rev-parse --show-toplevel)")" > "$OUTFILE"
echo "- Commit: $(git rev-parse HEAD)" >> "$OUTFILE"
echo "- Generated: $(date -u)" >> "$OUTFILE"
echo "" >> "$OUTFILE"
echo "## Tracked files" >> "$OUTFILE"
echo "" >> "$OUTFILE"
echo "| Path | Size (bytes) | Hash (sha256) |" >> "$OUTFILE"
echo "|---|---:|---|" >> "$OUTFILE"

# Loop through all tracked files
git ls-files | while read -r file; do
    if [ -f "$file" ]; then
        size=$(wc -c < "$file" | tr -d ' ')
        hash=$(shasum -a 256 "$file" | cut -d ' ' -f1)
        echo "| $file | $size | $hash |" >> "$OUTFILE"
    fi
done

echo "Manifest written to $OUTFILE"
