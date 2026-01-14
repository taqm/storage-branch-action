#!/bin/bash
set -euo pipefail

# Required environment variables:
#   INPUT_BRANCH - storage branch name
#   INPUT_FILES - file mappings (src dest per line)
#   INPUT_WORKING_DIR - working directory for source paths
#   INPUT_MESSAGE - commit message
#   SCRIPT_DIR - directory containing scripts
#   GITHUB_WORKSPACE - workspace directory
#   GITHUB_SERVER_URL - GitHub server URL
#   GITHUB_REPOSITORY - repository name
#   GITHUB_RUN_ID - workflow run ID

STORAGE_BRANCH="$INPUT_BRANCH"
WORKING_DIR="$INPUT_WORKING_DIR"
RUN_URL="$GITHUB_SERVER_URL/$GITHUB_REPOSITORY/actions/runs/$GITHUB_RUN_ID"
COMMIT_MESSAGE="$INPUT_MESSAGE

Run: $RUN_URL"

# Create a temporary directory for storage branch
TEMP_DIR=$(mktemp -d)
trap "rm -rf $TEMP_DIR" EXIT

# Check if branch exists
BRANCH_EXISTS=false
if git ls-remote --exit-code --heads origin "$STORAGE_BRANCH" > /dev/null 2>&1; then
  BRANCH_EXISTS=true
fi

# Setup git config
git config user.name "github-actions[bot]"
git config user.email "github-actions[bot]@users.noreply.github.com"

cd "$TEMP_DIR"
git init -q

if [ "$BRANCH_EXISTS" = "true" ]; then
  # Fetch existing branch
  git fetch "$GITHUB_WORKSPACE/.git" "$STORAGE_BRANCH" --depth=1
  git checkout -b "$STORAGE_BRANCH" FETCH_HEAD
else
  # Create orphan branch
  git checkout --orphan "$STORAGE_BRANCH"
  git rm -rf . 2>/dev/null || true
  echo "::notice::Creating new orphan branch '$STORAGE_BRANCH'"
fi

# Copy files
echo "$INPUT_FILES" | python3 "$SCRIPT_DIR/parse_files.py" | while IFS=$'\t' read -r src dest; do
  if [ -z "$src" ] || [ -z "$dest" ]; then
    continue
  fi

  # Apply working directory to source
  if [ "$WORKING_DIR" != "." ]; then
    src_path="$GITHUB_WORKSPACE/$WORKING_DIR/$src"
  else
    src_path="$GITHUB_WORKSPACE/$src"
  fi

  if [ ! -f "$src_path" ]; then
    echo "::error::Source file '$src_path' not found"
    exit 1
  fi

  # Create destination directory and copy file
  mkdir -p "$(dirname "$dest")"
  cp "$src_path" "$dest"
  echo "✓ Staged: $src -> $dest"
done

# Stage all changes
git add -A

# Check if there are changes to commit
if git diff --cached --quiet; then
  echo "::notice::No changes to commit"
  exit 0
fi

# Commit and push
git commit -m "$COMMIT_MESSAGE"
git push -f "$GITHUB_WORKSPACE/.git" "$STORAGE_BRANCH:$STORAGE_BRANCH"

# Push to remote
cd "$GITHUB_WORKSPACE"
git push origin "$STORAGE_BRANCH"

echo "✓ Successfully committed to '$STORAGE_BRANCH'"
