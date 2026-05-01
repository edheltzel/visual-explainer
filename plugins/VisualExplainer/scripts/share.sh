#!/bin/bash

# Share Visual Explainer HTML via Vercel CLI
# Usage: ./share.sh <html-file>
# Requires: vercel CLI on PATH, authenticated session (`vercel login`)

set -e

RED='\033[0;31m'
GREEN='\033[0;32m'
CYAN='\033[0;36m'
NC='\033[0m'

HTML_FILE="${1}"

if [ -z "$HTML_FILE" ]; then
    echo -e "${RED}Error: Please provide an HTML file to share${NC}" >&2
    echo "Usage: $0 <html-file>" >&2
    exit 1
fi

if [ ! -f "$HTML_FILE" ]; then
    echo -e "${RED}Error: File not found: $HTML_FILE${NC}" >&2
    exit 1
fi

if ! command -v vercel >/dev/null 2>&1; then
    echo -e "${RED}Error: vercel CLI not found on PATH${NC}" >&2
    echo "Install: npm i -g vercel    (or: bun add -g vercel)" >&2
    exit 1
fi

if ! vercel whoami >/dev/null 2>&1; then
    echo -e "${RED}Error: not authenticated with Vercel${NC}" >&2
    echo "Run: vercel login" >&2
    exit 1
fi

TEMP_DIR=$(mktemp -d)
trap 'rm -rf "$TEMP_DIR"' EXIT

# Use a stable subdir name so Vercel derives a clean project name from it
DEPLOY_DIR="$TEMP_DIR/visual-explainer"
mkdir -p "$DEPLOY_DIR"
cp "$HTML_FILE" "$DEPLOY_DIR/index.html"

echo -e "${CYAN}Sharing $(basename "$HTML_FILE") via Vercel...${NC}" >&2

set +e
RESULT=$(cd "$DEPLOY_DIR" && vercel deploy --yes 2>&1)
DEPLOY_EXIT=$?
set -e

if [ $DEPLOY_EXIT -ne 0 ]; then
    echo -e "${RED}Error: vercel deploy failed${NC}" >&2
    echo "$RESULT" >&2
    exit 1
fi

PREVIEW_URL=$(echo "$RESULT" | grep -oE 'https://[a-zA-Z0-9.-]+\.vercel\.app' | head -1)

if [ -z "$PREVIEW_URL" ]; then
    echo -e "${RED}Error: could not parse preview URL from vercel output${NC}" >&2
    echo "$RESULT" >&2
    exit 1
fi

echo "" >&2
echo -e "${GREEN}✓ Shared successfully!${NC}" >&2
echo "" >&2
echo -e "${GREEN}Live URL:  ${PREVIEW_URL}${NC}" >&2
echo "" >&2

# JSON for programmatic callers
printf '{"previewUrl":"%s"}\n' "$PREVIEW_URL"
