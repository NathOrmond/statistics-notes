#!/bin/bash
# Manual build test - simulates CI build steps locally
# This is more reliable than act for testing the actual build process

set -e

echo "🧪 Testing build process manually (simulating CI steps)..."
echo ""

# Step 1: Restore renv packages
echo "Step 1: Restoring renv packages..."
Rscript -e "renv::restore()"
if [ $? -eq 0 ]; then
  echo "✅ Packages restored successfully"
else
  echo "❌ Package restoration failed"
  exit 1
fi
echo ""

# Step 2: Generate navigation
echo "Step 2: Generating navigation..."
Rscript scripts/generate_nav.R
if [ $? -eq 0 ]; then
  echo "✅ Navigation generated successfully"
else
  echo "❌ Navigation generation failed"
  exit 1
fi
echo ""

# Step 3: Verify _quarto.yml was updated
if [ -f "_quarto.yml" ]; then
  echo "✅ _quarto.yml exists"
else
  echo "❌ _quarto.yml not found"
  exit 1
fi
echo ""

# Step 4: Render website
echo "Step 3: Rendering website with Quarto..."
quarto render
if [ $? -eq 0 ]; then
  echo "✅ Website rendered successfully"
else
  echo "❌ Rendering failed"
  exit 1
fi
echo ""

# Step 5: Verify output
if [ -d "_site" ] && [ -f "_site/index.html" ]; then
  echo "✅ Output directory created with index.html"
  echo ""
  echo "📊 Build Summary:"
  echo "   - Packages: ✅ Restored"
  echo "   - Navigation: ✅ Generated"
  echo "   - Rendering: ✅ Complete"
  echo "   - Output: ✅ Available in _site/"
  echo ""
  echo "✅ All build steps completed successfully!"
else
  echo "❌ Output directory or index.html not found"
  exit 1
fi

