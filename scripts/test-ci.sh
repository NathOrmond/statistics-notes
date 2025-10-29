#!/bin/bash
# Test GitHub Actions workflow locally using act
# Usage: ./scripts/test-ci.sh
#
# Note: Requires GITHUB_TOKEN environment variable or GitHub CLI authentication
# to clone action repositories. Run 'gh auth login' if you have gh CLI installed.

set -e

echo "🧪 Testing GitHub Actions workflow locally with act..."
echo ""

# Check for GitHub token (needed to clone action repositories)
if [ -z "$GITHUB_TOKEN" ] && command -v gh &> /dev/null; then
  # Try to use gh CLI token if available
  export GITHUB_TOKEN=$(gh auth token 2>/dev/null || echo "")
fi

if [ -z "$GITHUB_TOKEN" ]; then
  echo "⚠️  Error: GITHUB_TOKEN is required for act to clone action repositories."
  echo ""
  echo "To test workflows locally, you need a GitHub token. Options:"
  echo ""
  echo "1. Use GitHub CLI (recommended - easiest):"
  echo "   gh auth login"
  echo "   Then re-run this script"
  echo ""
  echo "2. Export a GitHub token manually:"
  echo "   export GITHUB_TOKEN=your_token_here"
  echo "   ./scripts/test-ci.sh"
  echo ""
  echo "3. Create a token at: https://github.com/settings/tokens"
  echo "   (Only needs 'public_repo' scope for public action repos)"
  echo ""
  exit 1
fi

echo "✓ Using GITHUB_TOKEN for action repository access"
echo ""
echo "⚠️  Note: act has limitations and may not fully replicate GitHub Actions."
echo "   Some steps (like Quarto setup) require tools not available in act's containers."
echo "   For full testing, push to a GitHub branch and check Actions logs."
echo ""

# Test the build-deploy job (publish will fail without real token, but build should succeed)
echo "Running workflow (build-deploy job)..."
echo "Note: Some steps may fail due to act limitations - this validates workflow syntax"
echo ""

# Check if on Apple Silicon
if [[ $(uname -m) == "arm64" ]]; then
  echo "Detected Apple Silicon - using linux/amd64 architecture"
  ARCH_FLAG="--container-architecture linux/amd64"
else
  ARCH_FLAG=""
fi

act push \
  --job build-deploy \
  -s GITHUB_TOKEN="$GITHUB_TOKEN" \
  --artifact-server-path /tmp/act-artifacts \
  $ARCH_FLAG

echo ""
echo "⚠️  Note: If the test fails at Quarto setup, this is expected."
echo "   The quarto-actions/setup requires GitHub CLI which isn't available in act's containers."
echo ""
echo "💡 For reliable testing, use manual build commands:"
echo "   1. Rscript -e 'renv::restore()'"
echo "   2. Rscript scripts/generate_nav.R"
echo "   3. quarto render"
echo ""
echo "✅ Test complete! Check output above for any errors."
