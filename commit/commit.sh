#!/bin/bash
set -euo pipefail

# Required environment variables:
#   INPUT_BRANCH - storage branch name
#   INPUT_FROM - source file path
#   INPUT_TO - destination file path
#   INPUT_WORKING_DIR - working directory for source path
#   INPUT_MESSAGE - commit message
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

# Check if branch exists and fetch to workspace if needed
BRANCH_EXISTS=false
if git ls-remote --exit-code --heads origin "$STORAGE_BRANCH" > /dev/null 2>&1; then
  BRANCH_EXISTS=true
  # Fetch to workspace so we can use it
  git fetch origin "$STORAGE_BRANCH:$STORAGE_BRANCH" --depth=1 2>/dev/null || true
fi

cd "$TEMP_DIR"
git init -q

# Setup git config (must be after git init)
git config user.name "github-actions[bot]"
git config user.email "github-actions[bot]@users.noreply.github.com"

if [ "$BRANCH_EXISTS" = "true" ]; then
  # Fetch existing branch from workspace
  git fetch "$GITHUB_WORKSPACE/.git" "$STORAGE_BRANCH" --depth=1
  git checkout -b "$STORAGE_BRANCH" FETCH_HEAD
else
  # Create orphan branch
  git checkout --orphan "$STORAGE_BRANCH"
  git rm -rf . 2>/dev/null || true
  echo "::notice::Creating new orphan branch '$STORAGE_BRANCH'"
fi

# Copy file
src="$INPUT_FROM"
dest="$INPUT_TO"

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

# Push to remote from workspace
cd "$GITHUB_WORKSPACE"
git fetch . "$STORAGE_BRANCH:$STORAGE_BRANCH" 2>/dev/null || true
git push origin "$STORAGE_BRANCH"

echo "✓ Successfully committed to '$STORAGE_BRANCH'"
