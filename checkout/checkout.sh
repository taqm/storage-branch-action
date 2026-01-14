#!/bin/bash
set -euo pipefail

# Required environment variables:
#   INPUT_BRANCH - storage branch name
#   INPUT_FILES - file mappings (src dest per line)
#   INPUT_WORKING_DIR - working directory for destination paths
#   INPUT_FAIL_ON_MISSING - fail if source file not found
#   SCRIPT_DIR - directory containing scripts

STORAGE_BRANCH="$INPUT_BRANCH"
WORKING_DIR="$INPUT_WORKING_DIR"
FAIL_ON_MISSING="$INPUT_FAIL_ON_MISSING"

# Check if branch exists
if ! git ls-remote --exit-code --heads origin "$STORAGE_BRANCH" > /dev/null 2>&1; then
  echo "::warning::Storage branch '$STORAGE_BRANCH' does not exist. Skipping checkout."
  exit 0
fi

# Fetch the storage branch
git fetch origin "$STORAGE_BRANCH" --depth=1

# Process each file mapping
echo "$INPUT_FILES" | python3 "$SCRIPT_DIR/parse_files.py" | while IFS=$'\t' read -r src dest; do
  if [ -z "$src" ] || [ -z "$dest" ]; then
    continue
  fi

  # Apply working directory to destination
  if [ "$WORKING_DIR" != "." ]; then
    dest="$WORKING_DIR/$dest"
  fi

  # Create destination directory
  mkdir -p "$(dirname "$dest")"

  # Try to checkout the file from storage branch
  if git show "origin/$STORAGE_BRANCH:$src" > "$dest" 2>/dev/null; then
    echo "✓ Checked out: $src -> $dest"
  else
    if [ "$FAIL_ON_MISSING" = "true" ]; then
      echo "::error::File '$src' not found in branch '$STORAGE_BRANCH'"
      exit 1
    else
      echo "::warning::File '$src' not found in branch '$STORAGE_BRANCH'. Skipping."
      rm -f "$dest"
    fi
  fi
done
