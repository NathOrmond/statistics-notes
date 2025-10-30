#!/bin/bash

# Unified test runner for this repo
# Modes:
#   Default (no args) → Manual build test locally
#   --ci              → Test GitHub Actions locally using `act`
#
# Flags (both modes where applicable):
#   --port <n>        Port to use for any local server (unused currently)
#   --amd64           Force linux/amd64 container architecture (Apple Silicon)
#   --token <tok>     Explicit GitHub token for act (fallbacks to gh auth token)
#   --yes             Non-interactive where supported

set -euo pipefail

MODE="manual"
PORT="8080"
ARCH_FLAG=""
TOKEN=""
YES_FLAG=""

while [[ $# -gt 0 ]]; do
  case "$1" in
    --ci) MODE="ci"; shift ;;
    --port) PORT="$2"; shift 2 ;;
    --amd64) ARCH_FLAG="--container-architecture linux/amd64"; shift ;;
    --token) TOKEN="$2"; shift 2 ;;
    --yes|-y) YES_FLAG="--yes"; shift ;;
    *) echo "Unknown option: $1"; exit 1 ;;
  esac
done

# Ensure we're in repo root
if ! git rev-parse --show-toplevel >/dev/null 2>&1; then
  echo "❌ Not a git repository. Run from within the repo." >&2
  exit 1
fi
cd "$(git rev-parse --show-toplevel)"

if [[ "$MODE" == "manual" ]]; then
  echo "🧪 Manual build test (simulating CI steps)..."
  echo "Step 1: Restoring renv packages..."
  Rscript -e "renv::restore()" && echo "✅ Packages restored" || { echo "❌ Package restore failed"; exit 1; }

  echo "\nStep 2: Generating navigation..."
  Rscript scripts/generate_nav.R && echo "✅ Navigation generated" || { echo "❌ Navigation generation failed"; exit 1; }

  echo "\nStep 3: Rendering site with Quarto..."
  quarto render && echo "✅ Render complete" || { echo "❌ Render failed"; exit 1; }

  if [[ -f "_site/index.html" ]]; then
    echo "\n📊 Build Summary"
    echo " - Packages: ✅"
    echo " - Navigation: ✅"
    echo " - Rendering: ✅"
    echo " - Output: ✅ _site/"
    echo "\n✅ All manual test steps passed"
  else
    echo "❌ _site/index.html not found"
    exit 1
  fi
  exit 0
fi

# CI mode with act
echo "🧪 CI test using act"

if ! command -v act >/dev/null 2>&1; then
  echo "❌ 'act' not found. Install with: brew install act (macOS)"
  exit 1
fi

# Resolve token
if [[ -z "$TOKEN" ]]; then
  if command -v gh >/dev/null 2>&1; then
    set +e
    TOKEN=$(gh auth token 2>/dev/null)
    set -e
  fi
fi
if [[ -z "$TOKEN" ]]; then
  echo "❌ No GitHub token available. Provide one with --token or 'gh auth login'"
  echo "   For public repos, a fine-scoped token with 'public_repo' is sufficient."
  exit 1
fi

ARTIFACT_DIR="/tmp/act-artifacts"
mkdir -p "$ARTIFACT_DIR"

echo "Running: act push --job build-deploy $ARCH_FLAG --artifact-server-path $ARTIFACT_DIR"
ACT_EXTRA=""
[[ -n "$YES_FLAG" ]] && ACT_EXTRA+=" --yes"

act push \
  --job build-deploy \
  -s GITHUB_TOKEN="$TOKEN" \
  --artifact-server-path "$ARTIFACT_DIR" \
  $ARCH_FLAG \
  $ACT_EXTRA || true

echo "\n⚠️  Note: Quarto setup may fail in act containers (requires gh CLI)."
echo "   Use manual mode for reliable local build validation:"
echo "     ./scripts/test.sh"
echo "\n✅ CI test completed (see output above)"


