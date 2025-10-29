#!/bin/bash
# Render Quarto site and serve it locally
# Usage: ./scripts/serve.sh [port]

set -e  # Exit on error

# Configuration
OUTPUT_DIR="_site"
DEFAULT_PORT=8080
PORT="${1:-$DEFAULT_PORT}"

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

echo -e "${GREEN} Rendering Quarto website...${NC}"
quarto render

if [ $? -ne 0 ]; then
    echo -e "${RED} Rendering failed. Aborting.${NC}"
    exit 1
fi

if [ ! -d "$OUTPUT_DIR" ]; then
    echo -e "${RED} Output directory '$OUTPUT_DIR' not found after rendering.${NC}"
    exit 1
fi

echo -e "${GREEN} Rendering complete!${NC}"
echo -e "${YELLOW} Starting local server on port $PORT...${NC}"
echo -e "${YELLOW}   Press Ctrl+C to stop the server${NC}"
echo ""

cd "$OUTPUT_DIR"

# Function to cleanup on exit
cleanup() {
    echo ""
    echo -e "${YELLOW} Stopping server...${NC}"
    cd ..
    exit 0
}

trap cleanup INT TERM

# Try different server options
if command -v python3 &> /dev/null; then
    # Python 3
    echo -e "${GREEN} Serving with Python 3 at http://localhost:$PORT${NC}"
    python3 -m http.server "$PORT"
elif command -v python &> /dev/null; then
    # Python 2 (fallback)
    echo -e "${GREEN} Serving with Python 2 at http://localhost:$PORT${NC}"
    python -m SimpleHTTPServer "$PORT"
elif command -v npx &> /dev/null; then
    # Node.js http-server
    echo -e "${GREEN} Serving with Node.js http-server at http://localhost:$PORT${NC}"
    npx --yes http-server -p "$PORT" --cors
else
    echo -e "${RED} No suitable web server found.${NC}"
    echo -e "${YELLOW}   Please install one of:${NC}"
    echo -e "${YELLOW}   - Python 3 (python3)${NC}"
    echo -e "${YELLOW}   - Node.js with http-server (npx http-server)${NC}"
    cd ..
    exit 1
fi

