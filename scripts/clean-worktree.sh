#!/bin/bash

# Robust cleanup for this repo.
# Defaults:
#   - Remove untracked files/dirs (respects .gitignore)
#   - Remove Quarto outputs (_site, .quarto)
#   - Remove R artifacts (.Rproj.user, .RData, .Rhistory)
#   - KEEP tracked changes (no reset)
#
# Options:
#   --dry-run            Preview actions; make no changes
#   --hard               Also discard tracked changes (git reset --hard)
#   --include-ignored    Also remove files ignored by .gitignore (-x)
#   --no-quarto          Do not remove Quarto artifacts
#   --no-r               Do not remove R artifacts
#   --yes | -y           Do not prompt for confirmation

set -euo pipefail

DRY_RUN=false
HARD_RESET=false
INCLUDE_IGNORED=false
ASSUME_YES=false
REMOVE_QUARTO=true
REMOVE_R_ARTIFACTS=true

while [[ $# -gt 0 ]]; do
  case "$1" in
    --dry-run) DRY_RUN=true; shift ;;
    --hard) HARD_RESET=true; shift ;;
    --include-ignored) INCLUDE_IGNORED=true; shift ;;
    --no-quarto) REMOVE_QUARTO=false; shift ;;
    --no-r) REMOVE_R_ARTIFACTS=false; shift ;;
    --yes|-y) ASSUME_YES=true; shift ;;
    *) echo "Unknown option: $1"; exit 1 ;;
  esac
done

# Ensure repo
if ! git rev-parse --show-toplevel >/dev/null 2>&1; then
  echo "❌ Not a git repository. Run from within the repo." >&2
  exit 1
fi

REPO_ROOT=$(git rev-parse --show-toplevel)
cd "$REPO_ROOT"

echo "🧹 Cleaning in: $REPO_ROOT"
$DRY_RUN && echo "(dry run)"

# Build git clean flags
if $DRY_RUN; then
  CLEAN_FLAGS="-fdn"   # preview untracked removals
else
  CLEAN_FLAGS="-fd"    # remove untracked
fi
if $INCLUDE_IGNORED; then
  CLEAN_FLAGS+="x"      # include ignored
fi

echo "• git clean $CLEAN_FLAGS (untracked files/dirs)"
git clean $CLEAN_FLAGS || true

if $HARD_RESET; then
  echo "• Tracked changes that would be discarded (git status --porcelain):"
  git status --porcelain | sed -n '/^[ MADRCU?!]/p' || true
fi

if $REMOVE_QUARTO; then
  echo "• Quarto artifacts to remove: _site/ .quarto/"
fi
if $REMOVE_R_ARTIFACTS; then
  echo "• R artifacts to remove: .Rproj.user/ .RData .Rhistory"
fi

if ! $ASSUME_YES; then
  read -r -p "Proceed with cleanup? (y/N) " ans
  case "$ans" in
    [yY][eE][sS]|[yY]) ;;
    *) echo "Aborted."; exit 0 ;;
  esac
fi

if $DRY_RUN; then
  echo "✅ Dry run complete. No changes made."
  exit 0
fi

# Remove untracked
git clean $CLEAN_FLAGS

# Optionally reset tracked
if $HARD_RESET; then
  git reset --hard
fi

# Explicit removals so you get desired cleanup regardless of gitignore state
if $REMOVE_QUARTO; then
  # Use quarto clean if available, then hard-remove known dirs
  if command -v quarto >/dev/null 2>&1; then
    quarto clean || true
  fi
  rm -rf _site .quarto || true
fi

if $REMOVE_R_ARTIFACTS; then
  rm -rf .Rproj.user .RData .Rhistory || true
fi

echo ""
echo "✅ Cleanup complete. Current status:"
git status --short

echo "Tip: commit this script so future cleans don't remove it:"
echo "     git add scripts/clean-worktree.sh && git commit -m 'chore: add cleaner'"


